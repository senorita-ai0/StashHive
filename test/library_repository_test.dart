import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:stashhive/data/library_repository.dart';
import 'package:stashhive/models/saved_item.dart';

late Directory testDirectory;
late LibraryRepository repository;

SavedItem buildLink({
  String id = 'link-1',
  String? collection = 'Learning',
}) {
  return SavedItem(
    id: id,
    kind: ItemKind.link,
    title: 'Flutter documentation',
    content: 'Read about local persistence.',
    url: 'https://flutter.dev',
    tags: const ['Flutter', 'Reading'],
    collection: collection,
    isFavorite: true,
    createdAtMs: 1000,
    updatedAtMs: 2000,
  );
}

SavedItem buildImage() {
  return const SavedItem(
    id: 'image-1',
    kind: ItemKind.image,
    title: 'Reference image',
    content: 'Design inspiration',
    url: null,
    tags: ['Design'],
    collection: 'Ideas',
    isFavorite: false,
    createdAtMs: 1000,
    updatedAtMs: 2000,
    attachmentKey: 'image-1',
    attachmentName: 'reference.png',
    attachmentMimeType: 'image/png',
  );
}

Future<void> clearBoxes() async {
  await (await Hive.openBox<dynamic>('stashhive_items_v1')).clear();
  await (await Hive.openBox<dynamic>('stashhive_attachments_v1')).clear();
  await (await Hive.openBox<dynamic>('stashhive_preferences_v1')).clear();
}

void main() {
  setUpAll(() async {
    testDirectory = await Directory.systemTemp.createTemp('stashhive_repository_test_');
    Hive.init(testDirectory.path);
  });

  setUp(() async {
    await clearBoxes();
    repository = await LibraryRepository.openInitializedForTesting();
  });

  tearDown(() {
    repository.dispose();
  });

  tearDownAll(() async {
    await Hive.close();
    await testDirectory.delete(recursive: true);
  });

  test('saved metadata survives closing and reopening the local boxes', () async {
    await repository.save(buildLink());
    repository.dispose();

    await Hive.close();
    Hive.init(testDirectory.path);
    repository = await LibraryRepository.openInitializedForTesting();

    expect(repository.items.value, hasLength(1));
    expect(repository.items.value.single.title, 'Flutter documentation');
    expect(repository.findById('link-1')!.tags, contains('Reading'));
  });

  test('copied attachment survives backup restore when its ID collides', () async {
    final originalBytes = Uint8List.fromList([0, 1, 2, 3, 255]);
    await repository.save(buildImage(), attachmentBytes: originalBytes);
    final backup = await repository.createBackup();

    final restoredCount = await repository.restoreBackup(backup);
    final restored = repository.items.value.singleWhere((item) => item.id != 'image-1');

    expect(restoredCount, 1);
    expect(repository.items.value, hasLength(2));
    expect(restored.hasAttachment, isTrue);
    expect(restored.attachmentKey, restored.id);
    expect(
      await repository.readAttachment(restored.attachmentKey!),
      orderedEquals(originalBytes),
    );
  });

  test('deleting a collection unassigns but does not delete its items', () async {
    await repository.addCollection('Learning');
    await repository.save(buildLink(collection: 'Learning'));

    await repository.deleteCollection('Learning');

    expect(repository.collections.value, isNot(contains('Learning')));
    expect(repository.items.value, hasLength(1));
    expect(repository.items.value.single.collection, isNull);
  });

  test('a missing attachment cannot be saved as though it were local', () async {
    final item = buildImage();
    await expectLater(
      repository.save(item),
      throwsA(isA<StateError>()),
    );
    expect(repository.items.value, isEmpty);
  });
}
