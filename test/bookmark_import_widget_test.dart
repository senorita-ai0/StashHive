import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:stashhive/data/library_repository.dart';
import 'package:stashhive/main.dart' as app;
import 'package:stashhive/models/saved_item.dart';

late Directory testDirectory;
late LibraryRepository repository;

SavedItem buildExistingLink() => SavedItem(
      id: 'existing-link',
      kind: ItemKind.link,
      title: 'Existing link',
      content: '',
      url: 'https://example.com/existing?utm_source=saved',
      tags: const <String>[],
      collection: null,
      isFavorite: false,
      createdAtMs: 1000,
      updatedAtMs: 1000,
    );

PlatformFile bookmarkFile(String html) {
  final bytes = Uint8List.fromList(utf8.encode(html));
  return PlatformFile(
    name: 'bookmarks.html',
    size: bytes.length,
    bytes: bytes,
  );
}

const String mixedBookmarkHtml = '''
<!DOCTYPE NETSCAPE-Bookmark-file-1>
<DL><p>
  <DT><H3>Reading</H3>
  <DL><p>
    <DT><A HREF="https://example.com/new">New bookmark</A>
    <DT><A HREF="https://EXAMPLE.com/new/?utm_source=browser#section">Repeated bookmark</A>
    <DT><A HREF="https://example.com/existing#top">Already in library</A>
    <DT><A HREF="javascript:alert(1)">Unsafe bookmark</A>
  </DL><p>
</DL><p>
''';

void main() {
  setUp(() async {
    testDirectory =
        await Directory.systemTemp.createTemp('stashhive_bookmark_import_test_');
    Hive.init(testDirectory.path);
    repository = await LibraryRepository.openInitializedForTesting();
  });

  tearDown(() async {
    app.bookmarkFilePickerForTesting = null;
    repository.dispose();
    await Hive.close();
    await testDirectory.delete(recursive: true);
  });

  testWidgets(
    'previews bookmark import and imports only new safe links after confirmation',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await repository.save(buildExistingLink());
      app.bookmarkFilePickerForTesting = () async =>
          bookmarkFile(mixedBookmarkHtml);

      await tester.pumpWidget(
        MaterialApp(
          home: app.BackupPrivacyPage(repository: repository),
        ),
      );
      await tester.ensureVisible(find.text('Choose HTML file'));
      await tester.tap(find.text('Choose HTML file'));
      await tester.pumpAndSettle();

      expect(find.text('Preview bookmark import'), findsOneWidget);
      expect(find.text('1 new link can be imported.'), findsOneWidget);
      expect(find.text('1 link already exists and will be skipped.'), findsOneWidget);
      expect(
        find.text('1 repeated link inside the file was removed from the preview.'),
        findsOneWidget,
      );
      expect(find.text('1 invalid or non-web link will be skipped.'), findsOneWidget);
      expect(find.text('1 bookmark folder was found.'), findsOneWidget);
      expect(find.text('New bookmark'), findsOneWidget);

      await tester.tap(find.text('Import new links'));
      await tester.pumpAndSettle();

      expect(repository.items.value, hasLength(2));
      final imported = repository.items.value.singleWhere(
        (item) => item.title == 'New bookmark',
      );
      expect(imported.url, 'https://example.com/new');
      expect(imported.collection, 'Reading');
      expect(
        repository.items.value.where(
          (item) => item.url?.contains('/existing') ?? false,
        ),
        hasLength(1),
      );
      expect(
        repository.items.value.where((item) => item.url?.contains('/new') ?? false),
        hasLength(1),
      );
      expect(find.text('Imported 1 link. Skipped 2 duplicates. Skipped 1 invalid link.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('canceling bookmark preview leaves items and collections unchanged',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    app.bookmarkFilePickerForTesting = () async => bookmarkFile('''
<DL><A HREF="https://example.com/not-imported">Not imported</A></DL>
''');

    await tester.pumpWidget(
      MaterialApp(
        home: app.BackupPrivacyPage(repository: repository),
      ),
    );
    await tester.ensureVisible(find.text('Choose HTML file'));
    await tester.tap(find.text('Choose HTML file'));
    await tester.pumpAndSettle();

    expect(find.text('Preview bookmark import'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(repository.items.value, isEmpty);
    expect(repository.collections.value, isEmpty);
    expect(find.text('Preview bookmark import'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
