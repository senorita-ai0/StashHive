import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:stashhive/data/library_repository.dart';
import 'package:stashhive/main.dart' as app;
import 'package:stashhive/models/saved_item.dart';

late Directory testDirectory;
late LibraryRepository repository;

void main() {
  setUp(() async {
    testDirectory =
        await Directory.systemTemp.createTemp('stashhive_external_url_test_');
    Hive.init(testDirectory.path);
    repository = await LibraryRepository.openInitializedForTesting();
  });

  tearDown(() async {
    repository.dispose();
    await Hive.close();
    await testDirectory.delete(recursive: true);
  });

  testWidgets('missing legacy image payload shows recovery feedback', (tester) async {
    const legacyId = 'legacy-missing-image-detail';
    final legacyItem = SavedItem(
      id: legacyId,
      kind: ItemKind.image,
      title: 'Old image reference',
      content: '',
      tags: const [],
      collection: null,
      isFavorite: false,
      createdAtMs: 1000,
      updatedAtMs: 1000,
      attachmentKey: 'missing-image-payload',
      attachmentName: 'reference.png',
      attachmentMimeType: 'image/png',
    );
    await Hive.box<dynamic>('stashhive_items_v1')
        .put(legacyId, legacyItem.toMap());

    await tester.pumpWidget(
      MaterialApp(
        home: app.ItemDetailsPage(
          repository: repository,
          itemId: legacyId,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('View image'));
    await tester.pumpAndSettle();

    expect(find.text('The local image is missing.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('missing legacy document payload recommends restore', (tester) async {
    const legacyId = 'legacy-missing-document-detail';
    final legacyItem = SavedItem(
      id: legacyId,
      kind: ItemKind.document,
      title: 'Old document reference',
      content: '',
      tags: const [],
      collection: null,
      isFavorite: false,
      createdAtMs: 1000,
      updatedAtMs: 1000,
      attachmentKey: 'missing-document-payload',
      attachmentName: 'report.pdf',
      attachmentMimeType: 'application/pdf',
    );
    await Hive.box<dynamic>('stashhive_items_v1')
        .put(legacyId, legacyItem.toMap());

    await tester.pumpWidget(
      MaterialApp(
        home: app.ItemDetailsPage(
          repository: repository,
          itemId: legacyId,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open / share file'));
    await tester.pumpAndSettle();

    expect(
      find.text('The local file is missing. Restore a backup if you have one.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('legacy non-web URL is rejected before external launch', (tester) async {
    const legacyId = 'legacy-malicious-link';
    final legacyItem = SavedItem(
      id: legacyId,
      kind: ItemKind.link,
      title: 'Old imported link',
      content: '',
      url: 'javascript:alert(1)',
      tags: const [],
      collection: null,
      isFavorite: false,
      createdAtMs: 1000,
      updatedAtMs: 1000,
    );

    // Seed raw storage to simulate a record written before strict validation.
    await Hive.box<dynamic>('stashhive_items_v1').put(
      legacyId,
      legacyItem.toMap(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: app.ItemDetailsPage(
          repository: repository,
          itemId: legacyId,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Open link'), findsOneWidget);
    await tester.tap(find.text('Open link'));
    await tester.pumpAndSettle();

    expect(
      find.text('This saved URL is not a valid HTTP or HTTPS link.'),
      findsOneWidget,
    );
    expect(
      find.text('Could not open this link. It is still saved in your library.'),
      findsNothing,
      reason: 'A non-web URL should be rejected before calling the platform launcher.',
    );
  });
}
