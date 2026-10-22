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

  test('restores item and attachment if save fails after item write', () async {
    final originalBytes = Uint8List.fromList([1, 3, 5, 7]);
    final replacementBytes = Uint8List.fromList([2, 4, 6, 8]);
    final original = buildImage();
    await repository.save(original, attachmentBytes: originalBytes);

    LibraryRepository.saveAfterItemCommitForTesting = () async {
      throw StateError('simulated error after item record write');
    };
    try {
      await expectLater(
        repository.save(
          original.copyWith(title: 'Edited after write'),
          attachmentBytes: replacementBytes,
        ),
        throwsA(isA<StateError>()),
      );
    } finally {
      LibraryRepository.saveAfterItemCommitForTesting = null;
    }

    expect(repository.findById(original.id)?.title, original.title);
    expect(repository.items.value.single.title, original.title);
    expect(
      await repository.readAttachment(original.attachmentKey!),
      orderedEquals(originalBytes),
    );
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

  test('backup restore preserves shared attachment references', () async {
    final originalBytes = Uint8List.fromList([7, 8, 9, 10]);
    final first = buildImage(id: 'shared-image-1', attachmentKey: 'shared-bytes')
        .copyWith(title: 'First shared view', attachmentName: 'first.png');
    final second = buildImage(id: 'shared-image-2', attachmentKey: 'shared-bytes')
        .copyWith(title: 'Second shared view', attachmentName: 'second.png');
    await repository.save(first, attachmentBytes: originalBytes);
    await repository.save(second);

    final backup = await repository.createBackup();
    final restoredCount = await repository.restoreBackup(backup);

    expect(restoredCount, 2);
    final restoredItems = repository.items.value
        .where((item) => item.id != first.id && item.id != second.id)
        .toList(growable: false);
    expect(restoredItems, hasLength(2));
    expect(
      restoredItems.singleWhere((item) => item.title == 'First shared view').attachmentName,
      'first.png',
    );
    expect(
      restoredItems.singleWhere((item) => item.title == 'Second shared view').attachmentName,
      'second.png',
    );
    final restoredKeys = restoredItems.map((item) => item.attachmentKey).toSet();
    expect(restoredKeys, hasLength(1));

    final restoredKey = restoredKeys.single!;
    expect(
      await repository.readAttachment(restoredKey),
      orderedEquals(originalBytes),
    );
    expect(
      Hive.box<dynamic>('stashhive_attachments_v1').length,
      2,
      reason: 'The original shared payload and one restored copy should exist.',
    );
  });

  test('rejects attachment references inconsistent with an item kind', () async {
    await expectLater(
      repository.save(buildLink().copyWith(attachmentKey: 'wrong-kind')),
      throwsFormatException,
    );
    await expectLater(
      repository.save(buildImage().copyWith(clearAttachment: true)),
      throwsFormatException,
    );
    await expectLater(
      repository.save(
        buildLink(id: 'stray-attachment-metadata')
            .copyWith(attachmentName: 'stale.png'),
      ),
      throwsFormatException,
    );
    final overlongUrl = 'https://example.com/' +
        List<String>.filled(4096, 'a').join();
    await expectLater(
      repository.save(buildLink(id: 'overlong-url').copyWith(url: overlongUrl)),
      throwsFormatException,
    );
    expect(repository.items.value, isEmpty);
  });

  test('skips malformed or mismatched raw records without hiding valid items', () async {
    await Hive.box<dynamic>('stashhive_items_v1').put(
      'unknown-kind',
      <String, Object?>{
        'id': 'unknown-kind',
        'kind': 'future-kind',
        'title': 'Unsupported legacy value',
        'content': '',
        'tags': <String>[],
        'isFavorite': false,
        'createdAtMs': 1000,
        'updatedAtMs': 1000,
      },
    );
    await Hive.box<dynamic>('stashhive_items_v1').put(
      'wrong-box-key',
      buildLink(id: 'different-record-id').toMap(),
    );
    await Hive.box<dynamic>('stashhive_items_v1').put(
      'oversized-legacy-content',
      <String, Object?>{
        'id': 'oversized-legacy-content',
        'kind': 'note',
        'title': 'Oversized legacy record',
        'content': List<String>.filled(1000001, 'x').join(),
        'tags': <String>[],
        'isFavorite': false,
        'createdAtMs': 1000,
        'updatedAtMs': 1000,
      },
    );
    await Hive.box<dynamic>('stashhive_items_v1').put(
      'out-of-range-timestamp',
      <String, Object?>{
        'id': 'out-of-range-timestamp',
        'kind': 'note',
        'title': 'Bad timestamp',
        'content': 'Legacy record with unformattable date.',
        'tags': <String>[],
        'isFavorite': false,
        'createdAtMs': 1000,
        'updatedAtMs': 9000000000000000,
      },
    );

    await repository.save(buildLink(id: 'valid-record'));

    expect(
      repository.items.value.map((item) => item.id),
      ['valid-record'],
    );
    expect(repository.findById('unknown-kind'), isNull);
    expect(repository.findById('wrong-box-key'), isNull);
    expect(repository.skippedRecordCount.value, 4);
  });

  test('keeps parseable legacy records visible for recovery actions', () async {
    final unsafeLink = SavedItem(
      id: 'legacy-unsafe-link',
      kind: ItemKind.link,
      title: 'Legacy unsafe link',
      content: '',
      url: 'javascript:alert(1)',
      tags: const [],
      collection: null,
      isFavorite: false,
      createdAtMs: 1000,
      updatedAtMs: 1000,
    );
    final missingImage = SavedItem(
      id: 'legacy-missing-image',
      kind: ItemKind.image,
      title: 'Legacy missing image',
      content: '',
      tags: const [],
      collection: null,
      isFavorite: false,
      createdAtMs: 1000,
      updatedAtMs: 1000,
    );
    await Hive.box<dynamic>('stashhive_items_v1')
        .put(unsafeLink.id, unsafeLink.toMap());
    await Hive.box<dynamic>('stashhive_items_v1')
        .put(missingImage.id, missingImage.toMap());

    await repository.save(buildLink(id: 'valid-after-legacy'));

    expect(repository.findById(unsafeLink.id)?.url, 'javascript:alert(1)');
    expect(repository.findById(missingImage.id)?.kind, ItemKind.image);
    expect(repository.items.value.map((item) => item.id), containsAll([
      unsafeLink.id,
      missingImage.id,
      'valid-after-legacy',
    ]));
  });

  test('rejects an out-of-range saved timestamp before writing', () async {
    final invalidDate = buildLink(id: 'invalid-date').copyWith(
      updatedAtMs: 9000000000000000,
    );

    await expectLater(
      repository.save(invalidDate),
      throwsFormatException,
    );
    expect(repository.findById(invalidDate.id), isNull);
  });

  test('rejects an empty note before writing it', () async {
    final emptyNote = SavedItem(
      id: 'empty-note',
      kind: ItemKind.note,
      title: 'Blank note',
      content: '   ',
      tags: const [],
      collection: null,
      isFavorite: false,
      createdAtMs: 1000,
      updatedAtMs: 1000,
    );

    await expectLater(
      repository.save(emptyNote),
      throwsFormatException,
    );
    expect(repository.findById(emptyNote.id), isNull);
    expect(repository.items.value, isEmpty);
  });

  test('rejects empty or untrimmed tags before repository writes', () async {
    await expectLater(
      repository.save(buildLink(id: 'empty-tag').copyWith(tags: const [''])),
      throwsFormatException,
    );
    await expectLater(
      repository.save(
        buildLink(id: 'spaced-tag').copyWith(tags: const [' Reading']),
      ),
      throwsFormatException,
    );
    await expectLater(
      repository.save(
        buildLink(id: 'duplicate-case-tags')
            .copyWith(tags: const ['Reading', 'reading']),
      ),
      throwsFormatException,
    );
    expect(repository.items.value, isEmpty);
  });

  test('removing an item attachment reference reclaims unused bytes', () async {
    final original = buildImage(id: 'convertible-image');
    final originalBytes = Uint8List.fromList([1, 4, 9, 16]);
    await repository.save(original, attachmentBytes: originalBytes);
    expect(
      await repository.readAttachment(original.attachmentKey!),
      orderedEquals(originalBytes),
    );

    final note = SavedItem(
      id: original.id,
      kind: ItemKind.note,
      title: 'Converted note',
      content: 'The image is no longer attached.',
      tags: const ['Converted'],
      collection: null,
      isFavorite: false,
      createdAtMs: original.createdAtMs,
      updatedAtMs: original.updatedAtMs + 1,
    );
    await repository.save(note);

    expect(repository.findById(original.id)?.kind, ItemKind.note);
    expect(repository.findById(original.id)?.attachmentKey, isNull);
    expect(
      Hive.box<dynamic>('stashhive_attachments_v1')
          .containsKey(original.attachmentKey),
      isFalse,
    );
  });

  test('keeps an old attachment when another saved item still references it', () async {
    const attachmentKey = 'shared-during-kind-change';
    final originalBytes = Uint8List.fromList([3, 1, 4, 1, 5]);
    final original = buildImage(
      id: 'owner-image',
      attachmentKey: attachmentKey,
    );
    final dependent = buildImage(
      id: 'dependent-image',
      attachmentKey: attachmentKey,
    );
    await repository.save(original, attachmentBytes: originalBytes);
    await repository.save(dependent);

    final note = SavedItem(
      id: original.id,
      kind: ItemKind.note,
      title: 'Image description',
      content: 'This note still shares storage with another item.',
      tags: const [],
      collection: null,
      isFavorite: false,
      createdAtMs: original.createdAtMs,
      updatedAtMs: original.updatedAtMs + 1,
    );
    await repository.save(note);

    expect(repository.findById(original.id)?.attachmentKey, isNull);
    expect(repository.findById(dependent.id)?.attachmentKey, attachmentKey);
    expect(
      await repository.readAttachment(attachmentKey),
      orderedEquals(originalBytes),
    );
  });

  test('new IDs avoid existing item IDs and attachment keys', () async {
    await repository.save(buildLink(id: 'reserved-item-id'));
    await Hive.box<dynamic>('stashhive_attachments_v1')
        .put('reserved-attachment-id', <int>[1, 2, 3]);

    final id = repository.createUniqueId();

    expect(id, isNot('reserved-item-id'));
    expect(id, isNot('reserved-attachment-id'));
    expect(
      Hive.box<dynamic>('stashhive_items_v1').containsKey(id),
      isFalse,
    );
    expect(
      Hive.box<dynamic>('stashhive_attachments_v1').containsKey(id),
      isFalse,
    );
  });

  test('repository refuses in-place writes to a shared attachment key', () async {
    const sharedKey = 'shared-direct-save';
    final originalBytes = Uint8List.fromList([10, 20, 30, 40]);
    final owner = buildImage(id: 'direct-owner', attachmentKey: sharedKey);
    final dependent = buildImage(id: 'direct-dependent', attachmentKey: sharedKey);
    await repository.save(owner, attachmentBytes: originalBytes);
    await repository.save(dependent);

    await expectLater(
      repository.save(
        owner.copyWith(
          title: 'Should not commit',
          updatedAtMs: owner.updatedAtMs + 1,
        ),
        attachmentBytes: Uint8List.fromList([40, 30, 20, 10]),
      ),
      throwsFormatException,
    );

    expect(repository.findById(owner.id)?.title, owner.title);
    expect(repository.findById(dependent.id)?.attachmentKey, sharedKey);
    expect(
      await repository.readAttachment(sharedKey),
      orderedEquals(originalBytes),
    );
  });

  test('replacement key avoids overwriting bytes shared by other items', () async {
    const sharedKey = 'owner-image';
    final bytes = Uint8List.fromList([11, 22, 33, 44]);
    final owner = buildImage(id: 'owner-image', attachmentKey: sharedKey);
    final dependent = buildImage(id: 'dependent-image', attachmentKey: sharedKey);
    await repository.save(owner, attachmentBytes: bytes);
    await repository.save(dependent);

    expect(
      repository.isAttachmentReferencedByOtherItem(owner.id, sharedKey),
      isTrue,
    );
    final replacementKey = repository.attachmentKeyForReplacement(
      owner.id,
      currentAttachmentKey: owner.attachmentKey,
    );

    expect(replacementKey, isNot(sharedKey));
    expect(
      await repository.readAttachment(sharedKey),
      orderedEquals(bytes),
    );
    expect(
      Hive.box<dynamic>('stashhive_attachments_v1').containsKey(replacementKey),
      isFalse,
    );
  });

  test('replacement keeps own attachment key when it is not shared', () async {
    final item = buildImage(id: 'solo-image');
    await repository.save(
      item,
      attachmentBytes: Uint8List.fromList([5, 4, 3, 2, 1]),
    );

    expect(
      repository.attachmentKeyForReplacement(
        item.id,
        currentAttachmentKey: item.attachmentKey,
      ),
      item.id,
    );
  });

  test('replacement avoids a key referenced by damaged legacy records', () async {
    const preferredKey = 'missing-shared-bytes';
    final dependent = buildImage(
      id: 'legacy-dependent',
      attachmentKey: preferredKey,
    );
    // Seed a legacy record whose payload is missing; it bypasses current save
    // validation to represent data written by an older version.
    await Hive.box<dynamic>('stashhive_items_v1')
        .put(dependent.id, dependent.toMap());

    expect(
      await repository.readAttachment(preferredKey),
      isNull,
    );
    expect(
      repository.isAttachmentReferencedByOtherItem(
        'new-item',
        preferredKey,
      ),
      isTrue,
    );
    expect(
      repository.attachmentKeyForReplacement('new-item'),
      isNot(preferredKey),
    );
  });

  test('replacement avoids overwriting an unrelated orphan payload', () async {
    const itemId = 'would-collide';
    final orphanBytes = Uint8List.fromList([7, 7, 7]);
    await Hive.box<dynamic>('stashhive_attachments_v1')
        .put(itemId, orphanBytes.toList());

    final replacementKey = repository.attachmentKeyForReplacement(itemId);

    expect(replacementKey, isNot(itemId));
    expect(
      await repository.readAttachment(itemId),
      orderedEquals(orphanBytes),
    );
  });

  test('damaged legacy attachment bytes are not silently filtered', () async {
    final item = buildImage(id: 'damaged-legacy-image');
    await repository.save(
      item,
      attachmentBytes: Uint8List.fromList([1, 2, 3]),
    );
    await Hive.box<dynamic>('stashhive_attachments_v1')
        .put(item.attachmentKey, <dynamic>[1, 'not-a-byte', 3]);

    expect(await repository.readAttachment(item.attachmentKey!), isNull);
    await expectLater(
      repository.createBackup(),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('missing or damaged'),
        ),
      ),
    );
  });

  test('rejects empty or invalid attachment bytes on save', () async {
    final item = buildImage();
    await expectLater(
      repository.save(item, attachmentBytes: const []),
      throwsFormatException,
    );
    await expectLater(
      repository.save(item, attachmentBytes: const [1, 256]),
      throwsFormatException,
    );

    await Hive.box<dynamic>('stashhive_attachments_v1').put(item.id, <int>[]);
    await expectLater(
      repository.save(item),
      throwsA(isA<StateError>()),
    );
    expect(repository.items.value, isEmpty);
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
