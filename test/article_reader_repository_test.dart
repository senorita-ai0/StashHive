import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:stashhive/data/library_repository.dart';
import 'package:stashhive/main.dart' show ItemDetailsPage;
import 'package:stashhive/models/saved_item.dart';
import 'package:stashhive/services/article_reader.dart';
import 'package:stashhive/services/backup_codec.dart';
import 'package:stashhive/services/library_csv_export.dart';
import 'package:stashhive/services/selected_items_export.dart';

late Directory _testDirectory;
late LibraryRepository _repository;

SavedItem _linkItem() => SavedItem(
      id: 'reader-persistence-test',
      kind: ItemKind.link,
      title: 'Private saved title',
      content: 'A private note that must not be sent with a reader request.',
      url: 'https://example.com/article',
      tags: const <String>['Research'],
      collection: 'Reading',
      isFavorite: true,
      createdAtMs: 1000,
      updatedAtMs: 2000,
    );

Future<void> _clearBoxes() async {
  await (await Hive.openBox<dynamic>('stashhive_items_v1')).clear();
  await (await Hive.openBox<dynamic>('stashhive_attachments_v1')).clear();
  await (await Hive.openBox<dynamic>('stashhive_preferences_v1')).clear();
}

void main() {
  setUpAll(() async {
    _testDirectory =
        await Directory.systemTemp.createTemp('stashhive_reader_repository_');
    Hive.init(_testDirectory.path);
  });

  setUp(() async {
    await _clearBoxes();
    _repository = await LibraryRepository.openInitializedForTesting();
  });

  tearDown(() {
    _repository.dispose();
    articleReaderLoaderForTesting = null;
    articleReaderDnsResolverForTesting = null;
    articleReaderTransportForTesting = null;
  });

  tearDownAll(() async {
    await Hive.close();
    await _testDirectory.delete(recursive: true);
  });

  testWidgets('opening a temporary reader preview does not change the saved item',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final saved = _linkItem();
    await _repository.addCollection('Reading');
    await _repository.save(saved);
    final before = _repository.findById(saved.id)!.toMap();

    // A deterministic synthetic article proves the reader route without
    // making any external request or sending the saved note to the transport.
    var readerLoadCount = 0;
    String? requestedUrl;
    articleReaderLoaderForTesting = (url, timeout) async {
      readerLoadCount++;
      requestedUrl = url;
      return const ArticleReaderResult(
        state: ArticleReaderState.success,
        title: 'Temporary article preview',
        text: 'Synthetic page text that must remain outside library storage.',
      );
    };

    await tester.pumpWidget(
      MaterialApp(
        home: ItemDetailsPage(
          repository: _repository,
          itemId: saved.id,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(readerLoadCount, 0, reason: 'Details must not fetch on its own.');

    await tester.tap(find.byKey(const ValueKey('open-article-reader')));
    await tester.pumpAndSettle();

    expect(readerLoadCount, 1);
    expect(requestedUrl, 'https://example.com/article');
    expect(find.text('Temporary article preview'), findsOneWidget);
    expect(
      find.text('Synthetic page text that must remain outside library storage.'),
      findsOneWidget,
    );
    expect(_repository.findById(saved.id)!.toMap(), equals(before));
    expect(
      _repository.findById(saved.id)!.content,
      'A private note that must not be sent with a reader request.',
    );
  });
  testWidgets('saving a selected passage persists only the quote annotation',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final saved = _linkItem();
    const articleText =
        'The river flows through the quiet green valley, carrying stories from the old town.';
    await _repository.addCollection('Reading');
    await _repository.save(saved);

    articleReaderLoaderForTesting = (url, timeout) async =>
        const ArticleReaderResult(
          state: ArticleReaderState.success,
          title: 'Temporary article preview',
          text: articleText,
        );

    await tester.pumpWidget(
      MaterialApp(
        home: ItemDetailsPage(
          repository: _repository,
          itemId: saved.id,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('open-article-reader')));
    await tester.pumpAndSettle();

    await tester.longPress(find.byKey(const ValueKey('article-reader-text')));
    await tester.pumpAndSettle();
    expect(find.text('SELECTED PASSAGE'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('save-reader-highlight')));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Highlight saved to this item. It may not align if the article changes.',
      ),
      findsOneWidget,
    );

    final stored = _repository.findById(saved.id)!;
    expect(stored.annotations, hasLength(1));
    final annotation = stored.annotations.single;
    expect(annotation.quote, isNotEmpty);
    expect(annotation.sourceStartOffset, isNotNull);
    expect(
      annotation.sourceEndOffset! - annotation.sourceStartOffset!,
      annotation.quote.length,
    );
    expect(annotation.contextBefore.length,
        lessThanOrEqualTo(maxSavedAnnotationContextCharacters));
    expect(annotation.contextAfter.length,
        lessThanOrEqualTo(maxSavedAnnotationContextCharacters));
    expect(stored.content, saved.content);
    expect(stored.title, saved.title);
    expect(stored.url, saved.url);
    expect(stored.content, isNot(contains(articleText)));
    expect(stored.content, contains('A private note that must not be sent'));

    final decodedBackup = BackupCodec.decode(await _repository.createBackup());
    expect(decodedBackup.items, hasLength(1));
    expect(decodedBackup.items.single.content, saved.content);
    expect(decodedBackup.items.single.annotations, hasLength(1));
    expect(decodedBackup.items.single.annotations.single.quote, annotation.quote);
    expect(decodedBackup.items.single.content, isNot(contains(articleText)));

    // CSV and Markdown intentionally export the saved quote annotation, not
    // the temporary page body that was only displayed in the reader.
    final csv = buildLibraryCsv(<SavedItem>[stored]);
    final markdown = buildSelectedItemsMarkdown(<SavedItem>[stored]);
    expect(csv, contains(annotation.quote));
    expect(markdown, contains(annotation.quote));
    expect(csv, isNot(contains(articleText)));
    expect(markdown, isNot(contains(articleText)));
  });


  testWidgets('explicitly re-anchors a saved quote without changing its text or note',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const articleText =
        'Changed introduction. Before excerpt remains stable: highlight me'
        '. After excerpt remains stable.';
    final originalAnnotation = SavedAnnotation(
      id: 'reanchor-existing',
      quote: 'highlight me',
      note: 'Keep this personal note.',
      sourceStartOffset: 800,
      sourceEndOffset: 812,
      contextBefore: 'Old page context before the quote.',
      contextAfter: 'Old page context after the quote.',
      createdAtMs: 3000,
    );
    final saved = _linkItem().copyWith(
      annotations: <SavedAnnotation>[originalAnnotation],
    );
    await _repository.addCollection('Reading');
    await _repository.save(saved);

    articleReaderLoaderForTesting = (url, timeout) async =>
        const ArticleReaderResult(
          state: ArticleReaderState.success,
          title: 'Updated page',
          text: articleText,
        );

    await tester.pumpWidget(
      MaterialApp(
        home: ItemDetailsPage(
          repository: _repository,
          itemId: saved.id,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final locateButton =
        find.byKey(const ValueKey('locate-annotation-reanchor-existing'));
    await tester.ensureVisible(locateButton);
    await tester.tap(locateButton);
    await tester.pumpAndSettle();

    expect(find.text('Saved quote found'), findsOneWidget);
    expect(find.byKey(const ValueKey('update-annotation-anchor')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('update-annotation-anchor')));
    await tester.pumpAndSettle();

    final updated = _repository.findById(saved.id)!;
    final annotation = updated.annotations.single;
    expect(annotation.id, originalAnnotation.id);
    expect(annotation.quote, originalAnnotation.quote);
    expect(annotation.note, originalAnnotation.note);
    expect(annotation.createdAtMs, originalAnnotation.createdAtMs);
    expect(annotation.sourceStartOffset, articleText.indexOf('highlight me'));
    expect(
      annotation.sourceEndOffset! - annotation.sourceStartOffset!,
      originalAnnotation.quote.length,
    );
    expect(annotation.contextBefore, 'Changed introduction. Before excerpt remains stable: ');
    expect(annotation.contextAfter, '. After excerpt remains stable.');
    expect(updated.title, saved.title);
    expect(updated.content, saved.content);
    expect(updated.url, saved.url);
  });


  testWidgets('locating a quote does not change saved annotation metadata before confirmation',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final originalAnnotation = SavedAnnotation(
      id: 'reanchor-no-confirm',
      quote: 'keep this exact quote',
      note: 'Do not change this note.',
      sourceStartOffset: 120,
      sourceEndOffset: 141,
      contextBefore: 'The old page context.',
      contextAfter: 'The old following context.',
      createdAtMs: 3000,
    );
    final saved = _linkItem().copyWith(
      annotations: <SavedAnnotation>[originalAnnotation],
    );
    await _repository.addCollection('Reading');
    await _repository.save(saved);
    final before = _repository.findById(saved.id)!.toMap();

    articleReaderLoaderForTesting = (url, timeout) async =>
        const ArticleReaderResult(
          state: ArticleReaderState.success,
          title: 'Changed page',
          text: 'A completely new introduction. keep this exact quote is still here.',
        );

    await tester.pumpWidget(
      MaterialApp(
        home: ItemDetailsPage(
          repository: _repository,
          itemId: saved.id,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final locateButton =
        find.byKey(const ValueKey('locate-annotation-reanchor-no-confirm'));
    await tester.ensureVisible(locateButton);
    await tester.tap(locateButton);
    await tester.pumpAndSettle();

    expect(find.text('Saved quote found'), findsOneWidget);
    expect(find.byKey(const ValueKey('update-annotation-anchor')), findsOneWidget);
    expect(_repository.findById(saved.id)!.toMap(), equals(before));
  });

}
