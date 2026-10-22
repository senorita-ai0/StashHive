import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:stashhive/data/library_repository.dart';
import 'package:stashhive/main.dart' as app;
import 'package:stashhive/models/saved_item.dart';

late Directory testDirectory;
late LibraryRepository repository;

SavedItem buildImage({
  required String id,
  required String attachmentKey,
}) {
  return SavedItem(
    id: id,
    kind: ItemKind.image,
    title: 'Shared reference',
    content: '',
    tags: const ['Reference'],
    collection: null,
    isFavorite: false,
    createdAtMs: 1000,
    updatedAtMs: 2000,
    attachmentKey: attachmentKey,
    attachmentName: 'reference.png',
    attachmentMimeType: 'image/png',
  );
}

Future<void> openEditor(WidgetTester tester, SavedItem item) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              key: const ValueKey('open-editor'),
              onPressed: () {
                Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => app.QuickSavePage(
                      repository: repository,
                      existingItem: item,
                    ),
                  ),
                );
              },
              child: const Text('Open editor'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.byKey(const ValueKey('open-editor')));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() async {
    testDirectory =
        await Directory.systemTemp.createTemp('stashhive_quick_save_test_');
    Hive.init(testDirectory.path);
    repository = await LibraryRepository.openInitializedForTesting();
  });

  tearDown(() async {
    repository.dispose();
    await Hive.close();
    await testDirectory.delete(recursive: true);
  });

  testWidgets('metadata-only edit preserves a shared attachment key', (tester) async {
    const sharedKey = 'shared-reference-bytes';
    final bytes = Uint8List.fromList([8, 6, 7, 5, 3, 0, 9]);
    final owner = buildImage(id: 'owner-image', attachmentKey: sharedKey);
    final edited = buildImage(id: 'edited-image', attachmentKey: sharedKey);
    await repository.save(owner, attachmentBytes: bytes);
    await repository.save(edited);

    await openEditor(tester, edited);
    await tester.ensureVisible(find.text('Save changes'));
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(repository.findById(edited.id)?.attachmentKey, sharedKey);
    expect(
      await repository.readAttachment(sharedKey),
      orderedEquals(bytes),
    );
    expect(repository.findById(edited.id)?.title, edited.title);
  });

  testWidgets('changing an image to a note clears its attachment', (tester) async {
    final bytes = Uint8List.fromList([2, 7, 1, 8]);
    final image = buildImage(id: 'convert-image', attachmentKey: 'convert-image');
    await repository.save(image, attachmentBytes: bytes);

    await openEditor(tester, image);
    final noteChoice = find.text('Note');
    await tester.ensureVisible(noteChoice);
    await tester.tap(noteChoice);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).at(1),
      'A note kept after removing its image attachment.',
    );
    await tester.ensureVisible(find.text('Save changes'));
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    final saved = repository.findById(image.id);
    expect(saved?.kind, ItemKind.note);
    expect(saved?.attachmentKey, isNull);
    expect(saved?.attachmentName, isNull);
    expect(saved?.attachmentMimeType, isNull);
    expect(
      Hive.box<dynamic>('stashhive_attachments_v1').containsKey('convert-image'),
      isFalse,
    );
  });
}
