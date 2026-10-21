import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:stashhive/data/library_repository.dart';
import 'package:stashhive/models/saved_item.dart';
import 'package:stashhive/main.dart' as app;

void main() {
  late Directory testDirectory;
  late LibraryRepository repository;

  setUp(() async {
    testDirectory = await Directory.systemTemp.createTemp('stashhive_a11y_test_');
    Hive.init(testDirectory.path);
    repository = await LibraryRepository.openInitializedForTesting();
  });

  tearDown(() async {
    repository.dispose();
    await Hive.close();
    await testDirectory.delete(recursive: true);
  });

  testWidgets('Library search teaser exposes and handles semantic activation', (tester) async {
    final semantics = tester.ensureSemantics();
    addTearDown(semantics.dispose);
    var openedSearch = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: app.LibraryPage(
            repository: repository,
            onAdd: (_) {},
            onSearch: (_) => openedSearch = true,
            onOpenItem: (_) {},
          ),
        ),
      ),
    );

    final search = find.bySemanticsLabel('Search your library');
    expect(search, findsOneWidget);
    final node = tester.getSemantics(search);
    expect(node.hasAction(SemanticsAction.tap), isTrue);
    node.performAction(SemanticsAction.tap);
    expect(openedSearch, isTrue);
  });

  testWidgets('favorite state is exposed with a meaningful semantic label', (tester) async {
    final semantics = tester.ensureSemantics();
    addTearDown(semantics.dispose);
    const item = SavedItem(
      id: 'favorite-link',
      kind: ItemKind.link,
      title: 'Accessible Flutter guide',
      content: 'Guide',
      url: 'https://flutter.dev',
      tags: ['Accessibility'],
      collection: null,
      isFavorite: true,
      createdAtMs: 1,
      updatedAtMs: 2,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: app.SavedItemTile(
            item: item,
            repository: repository,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Saved as a favorite'), findsOneWidget);
  });
}
