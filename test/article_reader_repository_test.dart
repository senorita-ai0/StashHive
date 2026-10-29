import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:stashhive/data/library_repository.dart';
import 'package:stashhive/main.dart' show ItemDetailsPage;
import 'package:stashhive/models/saved_item.dart';
import 'package:stashhive/services/article_reader.dart';

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
}
