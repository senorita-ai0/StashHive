import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:stashhive/data/library_repository.dart';
import 'package:stashhive/models/saved_item.dart';
import 'package:stashhive/services/backup_codec.dart';

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

SavedItem buildImage({
  String id = 'image-1',
  String? attachmentKey,
}) {
  return SavedItem(
    id: id,
    kind: ItemKind.image,
    title: 'Reference image',
    content: 'Design inspiration',
    url: null,
    tags: const ['Design'],
    collection: 'Ideas',
    isFavorite: false,
    createdAtMs: 1000,
    updatedAtMs: 2000,
    attachmentKey: attachmentKey ?? id,
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

  test('rejects a malformed backup before writing any part of the import', () async {
    await repository.addCollection('Existing');
    await repository.save(buildLink(id: 'existing-1', collection: 'Existing'));

    final validIncoming = buildLink(
      id: 'incoming-1',
      collection: 'Incoming',
    ).toMap();
    final malformedIncoming = <String, Object?>{
      ...buildLink(id: 'broken-1', collection: 'Incoming').toMap(),
      'content': 17,
    };
    final backup = jsonEncode(<String, Object?>{
      'app': 'StashHive',
      'formatVersion': 1,
      'exportedAt': '2026-10-21T00:00:00Z',
      'collections': ['Incoming'],
      'items': [validIncoming, malformedIncoming],
      'attachments': <String, Object?>{},
    });

    await expectLater(repository.restoreBackup(backup), throwsFormatException);

    expect(repository.items.value.map((item) => item.id), ['existing-1']);
    expect(repository.collections.value, ['Existing']);
  });

  test('restores the previous attachment if an edited item write fails', () async {
    final originalBytes = Uint8List.fromList([1, 3, 5, 7]);
    final editedBytes = Uint8List.fromList([2, 4, 6, 8]);
    final image = buildImage();
    await repository.save(image, attachmentBytes: originalBytes);

    LibraryRepository.saveBeforeItemCommitForTesting = () async {
      throw StateError('simulated item write failure');
    };
    try {
      await expectLater(
        repository.save(image.copyWith(title: 'Edited image'), attachmentBytes: editedBytes),
        throwsA(isA<StateError>()),
      );
    } finally {
      LibraryRepository.saveBeforeItemCommitForTesting = null;
    }

    expect(repository.findById(image.id)!.title, image.title);
    expect(
      await repository.readAttachment(image.attachmentKey!),
      orderedEquals(originalBytes),
    );
  });

  test('rolls back staged items and attachments when restore is interrupted', () async {
    await repository.addCollection('Existing');
    await repository.save(buildLink(id: 'existing-1', collection: 'Existing'));

    final importedBytes = Uint8List.fromList([8, 7, 6, 5, 4]);
    const incomingImage = SavedItem(
      id: 'incoming-image-1',
      kind: ItemKind.image,
      title: 'Imported image',
      content: 'From the backup',
      url: null,
      tags: ['Recovery'],
      collection: 'Imported',
      isFavorite: false,
      createdAtMs: 1000,
      updatedAtMs: 2000,
      attachmentKey: 'incoming-image-1',
      attachmentName: 'imported.png',
      attachmentMimeType: 'image/png',
    );
    final backup = BackupCodec.encode(
      items: const [incomingImage],
      attachmentBytes: {'incoming-image-1': importedBytes},
      collections: const ['Imported'],
    );

    LibraryRepository.restoreBeforeCollectionsCommitForTesting = () async {
      throw StateError('simulated restore interruption');
    };
    try {
      await expectLater(
        repository.restoreBackup(backup),
        throwsA(isA<StateError>()),
      );
    } finally {
      LibraryRepository.restoreBeforeCollectionsCommitForTesting = null;
    }

    expect(
      repository.items.value.map((item) => item.id),
      orderedEquals(['existing-1']),
    );
    expect(
      Hive.box<dynamic>('stashhive_items_v1').containsKey('incoming-image-1'),
      isFalse,
    );
    expect(
      Hive.box<dynamic>('stashhive_attachments_v1').containsKey('incoming-image-1'),
      isFalse,
    );
    expect(
      Hive.box<dynamic>('stashhive_preferences_v1').get('collections'),
      ['Existing'],
    );
    expect(repository.collections.value, ['Existing']);
  });

  test('rolls back a partially written collection rename', () async {
    await repository.addCollection('Learning');
    await repository.save(buildLink(id: 'learning-1', collection: 'Learning'));
    await repository.save(buildLink(id: 'learning-2', collection: 'Learning'));

    LibraryRepository.collectionBeforeItemWriteForTesting = (index) async {
      if (index == 1) {
        throw StateError('simulated collection item write failure');
      }
    };
    try {
      await expectLater(
        repository.renameCollection('Learning', 'Reading'),
        throwsA(isA<StateError>()),
      );
    } finally {
      LibraryRepository.collectionBeforeItemWriteForTesting = null;
    }

    expect(repository.collections.value, ['Learning']);
    expect(repository.items.value, hasLength(2));
    expect(
      repository.items.value.map((item) => item.collection),
      everyElement('Learning'),
    );
  });

  test('restores item and attachment when delete fails after attachment removal', () async {
    final originalBytes = Uint8List.fromList([9, 8, 7, 6]);
    final image = buildImage();
    await repository.save(image, attachmentBytes: originalBytes);

    LibraryRepository.deleteAfterAttachmentDeleteForTesting = () async {
      throw StateError('simulated post-delete failure');
    };
    try {
      await expectLater(
        repository.delete(image.id),
        throwsA(isA<StateError>()),
      );
    } finally {
      LibraryRepository.deleteAfterAttachmentDeleteForTesting = null;
    }

    expect(repository.findById(image.id)?.title, image.title);
    expect(repository.items.value, hasLength(1));
    expect(
      await repository.readAttachment(image.attachmentKey!),
      orderedEquals(originalBytes),
    );
  });

  test('keeps attachment bytes while another item still references them', () async {
    final originalBytes = Uint8List.fromList([4, 5, 6, 7]);
    await repository.save(buildImage(), attachmentBytes: originalBytes);
    await repository.save(
      buildImage(id: 'image-2', attachmentKey: 'image-1'),
    );

    await repository.delete('image-1');

    expect(repository.findById('image-1'), isNull);
    expect(repository.findById('image-2')?.hasAttachment, isTrue);
    expect(
      await repository.readAttachment('image-1'),
      orderedEquals(originalBytes),
    );
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
