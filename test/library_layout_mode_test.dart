import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:stashhive/data/library_repository.dart';
import 'package:stashhive/main.dart' as app;
import 'package:stashhive/models/saved_item.dart';

late Directory testDirectory;
late LibraryRepository repository;

SavedItem buildLink() {
  return SavedItem(
    id: 'layout-link',
    kind: ItemKind.link,
    title: 'Flutter layout reference',
    content: 'A saved link for testing the Library view modes.',
    url: 'https://flutter.dev',
    tags: const <String>['Layout'],
    collection: null,
    isFavorite: false,
    createdAtMs: 1000,
    updatedAtMs: 1000,
  );
}

void main() {
  setUp(() async {
    testDirectory =
        await Directory.systemTemp.createTemp('stashhive_library_layout_test_');
    Hive.init(testDirectory.path);
    repository = await LibraryRepository.openInitializedForTesting();
  });

  tearDown(() async {
    LibraryRepository.setLibraryLayoutModeAfterWriteForTesting = null;
    repository.dispose();
    await Hive.close();
    await testDirectory.delete(recursive: true);
  });

  test('defaults to grid and ignores an unknown stored layout mode', () async {
    expect(repository.libraryLayoutMode, 'grid');

    final preferences =
        await Hive.openBox<dynamic>('stashhive_preferences_v1');
    await preferences.put('libraryLayoutMode', 'masonry');

    expect(repository.libraryLayoutMode, 'grid');
  });

  test('persists supported layout modes locally and rejects unknown modes',
      () async {
    await repository.setLibraryLayoutMode('list');
    expect(repository.libraryLayoutMode, 'list');

    await expectLater(
      repository.setLibraryLayoutMode('masonry'),
      throwsFormatException,
    );
    expect(repository.libraryLayoutMode, 'list');
  });

  test('rolls back a layout preference write that fails after commit', () async {
    LibraryRepository.setLibraryLayoutModeAfterWriteForTesting = () async {
      throw StateError('private storage diagnostic');
    };

    await expectLater(
      repository.setLibraryLayoutMode('list'),
      throwsStateError,
    );
    expect(repository.libraryLayoutMode, 'grid');
  });

  testWidgets('Library toggles between grid and list layouts', (tester) async {
    await repository.save(buildLink());

    await tester.pumpWidget(
      MaterialApp(
        home: app.LibraryPage(
          repository: repository,
          onAdd: (_) {},
          onSearch: (_) {},
          onOpenItem: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('library-grid-layout')), findsOneWidget);
    expect(find.text('Flutter layout reference'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('library-layout-toggle')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('library-list-layout')), findsOneWidget);
    expect(find.byKey(const ValueKey('library-grid-layout')), findsNothing);
    expect(repository.libraryLayoutMode, 'list');
    expect(find.text('Flutter layout reference'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Recreating the page uses the saved profile preference instead of
    // resetting the user to the default grid view.
    await tester.pumpWidget(
      MaterialApp(
        home: app.LibraryPage(
          key: const ValueKey('recreated-library-page'),
          repository: repository,
          onAdd: (_) {},
          onSearch: (_) {},
          onOpenItem: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('library-list-layout')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('library-layout-toggle')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('library-grid-layout')), findsOneWidget);
    expect(repository.libraryLayoutMode, 'grid');
    expect(tester.takeException(), isNull);
  });
}
