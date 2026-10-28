import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show ValueListenable, ValueNotifier;
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
  String url = 'https://flutter.dev',
}) {
  return SavedItem(
    id: id,
    kind: ItemKind.link,
    title: 'Flutter documentation',
    content: 'Read about local persistence.',
    url: url,
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

  test(
    'publishes read-only reactive item and collection listenables',
    () async {
      final ValueListenable<List<SavedItem>> visibleItems = repository.items;
      final ValueListenable<List<String>> visibleCollections =
          repository.collections;
      expect(
        visibleItems,
        isNot(isA<ValueNotifier<List<SavedItem>>>()),
        reason: 'The public wrapper must not expose the private mutable notifier.',
      );
      expect(
        visibleCollections,
        isNot(isA<ValueNotifier<List<String>>>()),
        reason: 'The public wrapper must not expose the private mutable notifier.',
      );
      var itemNotifications = 0;
      var collectionNotifications = 0;
      void onItemsChanged() => itemNotifications++;
      void onCollectionsChanged() => collectionNotifications++;
      visibleItems.addListener(onItemsChanged);
      visibleCollections.addListener(onCollectionsChanged);

      try {
        await repository.addCollection('Learning');
        await repository.save(buildLink(collection: 'Learning'));

        expect(itemNotifications, greaterThan(0));
        expect(collectionNotifications, greaterThan(0));
        expect(
          () => visibleItems.value.clear(),
          throwsUnsupportedError,
        );
        expect(
          () => visibleCollections.value.add('Injected collection'),
          throwsUnsupportedError,
        );
        expect(visibleCollections.value, ['Learning']);
        expect(visibleItems.value.single.collection, 'Learning');
      } finally {
        visibleItems.removeListener(onItemsChanged);
        visibleCollections.removeListener(onCollectionsChanged);
      }
    },
  );

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

  test('rolls back dark-mode preference after a late write failure', () async {
    expect(repository.darkMode, isFalse);
    LibraryRepository.setDarkModeAfterWriteForTesting = () async {
      throw StateError('simulated dark-mode preference failure');
    };
    try {
      await expectLater(
        repository.setDarkMode(true),
        throwsA(isA<StateError>()),
      );
    } finally {
      LibraryRepository.setDarkModeAfterWriteForTesting = null;
    }

    expect(repository.darkMode, isFalse);
    expect(
      Hive.box<dynamic>('stashhive_preferences_v1').containsKey('darkMode'),
      isFalse,
    );
  });

  test('text-size preference persists across box reopen', () async {
    expect(repository.textScaleMultiplier, 1.0);
    await repository.setTextScaleMultiplier(1.15);
    expect(repository.textScaleMultiplier, 1.15);

    repository.dispose();
    await Hive.close();
    Hive.init(testDirectory.path);
    repository = await LibraryRepository.openInitializedForTesting();

    expect(repository.textScaleMultiplier, 1.15);
  });

  test('text-size preference rolls back a late failed write', () async {
    expect(repository.textScaleMultiplier, 1.0);
    LibraryRepository.setTextScaleMultiplierAfterWriteForTesting = () async {
      throw StateError('simulated text-size preference failure');
    };
    try {
      await expectLater(
        repository.setTextScaleMultiplier(1.3),
        throwsA(isA<StateError>()),
      );
    } finally {
      LibraryRepository.setTextScaleMultiplierAfterWriteForTesting = null;
    }

    expect(repository.textScaleMultiplier, 1.0);
    expect(
      Hive.box<dynamic>('stashhive_preferences_v1')
          .containsKey('textScaleMultiplier'),
      isFalse,
    );
  });

  test('serializes dark-mode writes after a late failure', () async {
    final firstWriteEntered = Completer<void>();
    final releaseFirstFailure = Completer<void>();
    var hookCalls = 0;

    LibraryRepository.setDarkModeAfterWriteForTesting = () async {
      hookCalls++;
      if (hookCalls == 1) {
        firstWriteEntered.complete();
        await releaseFirstFailure.future;
        throw StateError('simulated late dark-mode failure');
      }
    };

    final first = repository.setDarkMode(true);
    await firstWriteEntered.future;
    final second = repository.setDarkMode(false);
    await Future<void>.delayed(Duration.zero);
    final secondOvertookFirst = hookCalls > 1;
    final firstFailure = expectLater(first, throwsA(isA<StateError>()));

    releaseFirstFailure.complete();
    try {
      await firstFailure;
      await second;
    } finally {
      LibraryRepository.setDarkModeAfterWriteForTesting = null;
    }

    final preferences = Hive.box<dynamic>('stashhive_preferences_v1');
    expect(secondOvertookFirst, isFalse);
    expect(repository.darkMode, isFalse);
    expect(preferences.containsKey('darkMode'), isTrue);
    expect(preferences.get('darkMode'), isFalse);
  });

  test('serializes text-size writes after a late failure', () async {
    final firstWriteEntered = Completer<void>();
    final releaseFirstFailure = Completer<void>();
    var hookCalls = 0;

    LibraryRepository.setTextScaleMultiplierAfterWriteForTesting = () async {
      hookCalls++;
      if (hookCalls == 1) {
        firstWriteEntered.complete();
        await releaseFirstFailure.future;
        throw StateError('simulated late text-size failure');
      }
    };

    final first = repository.setTextScaleMultiplier(1.3);
    await firstWriteEntered.future;
    final second = repository.setTextScaleMultiplier(1.15);
    await Future<void>.delayed(Duration.zero);
    final secondOvertookFirst = hookCalls > 1;
    final firstFailure = expectLater(first, throwsA(isA<StateError>()));

    releaseFirstFailure.complete();
    try {
      await firstFailure;
      await second;
    } finally {
      LibraryRepository.setTextScaleMultiplierAfterWriteForTesting = null;
    }

    final preferences = Hive.box<dynamic>('stashhive_preferences_v1');
    expect(secondOvertookFirst, isFalse);
    expect(repository.textScaleMultiplier, 1.15);
    expect(preferences.get('textScaleMultiplier'), 1.15);
  });

  test('last backup-prepared timestamp persists across box reopen', () async {
    expect(repository.lastBackupPreparedAtMs, isNull);

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    await repository.recordBackupPreparedAt(timestamp);
    expect(repository.lastBackupPreparedAtMs, timestamp);

    await expectLater(
      repository.recordBackupPreparedAt(0),
      throwsFormatException,
    );
    expect(repository.lastBackupPreparedAtMs, timestamp);

    repository.dispose();
    await Hive.close();
    Hive.init(testDirectory.path);
    repository = await LibraryRepository.openInitializedForTesting();

    expect(repository.lastBackupPreparedAtMs, timestamp);
  });

  test('backup generation survives a late failure storing its optional timestamp', () async {
    final previousTimestamp = DateTime.now().millisecondsSinceEpoch -
        const Duration(minutes: 1).inMilliseconds;
    await repository.recordBackupPreparedAt(previousTimestamp);

    LibraryRepository.backupPreparedAtAfterWriteForTesting = () async {
      throw StateError('simulated backup status write failure');
    };
    try {
      final source = await repository.createBackup();
      final decoded = BackupCodec.decode(source);

      expect(decoded.items, isEmpty);
      expect(repository.lastBackupPreparedAtMs, previousTimestamp);
      expect(
        Hive.box<dynamic>('stashhive_preferences_v1')
            .get('lastBackupPreparedAtMs'),
        previousTimestamp,
      );
    } finally {
      LibraryRepository.backupPreparedAtAfterWriteForTesting = null;
    }
  });

  test('storage reminder acknowledgement persists across box reopen', () async {
    expect(repository.hasSeenStorageReminder, isFalse);
    await repository.markStorageReminderSeen();
    expect(repository.hasSeenStorageReminder, isTrue);

    repository.dispose();
    await Hive.close();
    Hive.init(testDirectory.path);
    repository = await LibraryRepository.openInitializedForTesting();

    expect(repository.hasSeenStorageReminder, isTrue);
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

  test('restore canonicalizes imported collection casing to destination names', () async {
    await repository.addCollection('Learning');
    final incoming = buildLink(
      id: 'restore-lowercase-collection',
      collection: 'learning',
    );
    final backup = BackupCodec.encode(
      items: [incoming],
      attachmentBytes: const {},
      collections: const ['learning'],
    );

    await repository.restoreBackup(backup);

    final restored = repository.findById(incoming.id);
    final raw = Hive.box<dynamic>('stashhive_items_v1').get(incoming.id);
    expect(restored?.collection, 'Learning');
    expect(raw['collection'], 'Learning');
    expect(
      repository.collections.value
          .where((name) => name.toLowerCase() == 'learning'),
      hasLength(1),
    );
  });

  test('restore avoids attachment keys referenced by missing legacy payloads', () async {
    const incomingId = 'incoming-image-key';
    final legacyBrokenImage = buildImage(
      id: 'legacy-missing-image-owner',
      attachmentKey: incomingId,
    );
    await Hive.box<dynamic>('stashhive_items_v1')
        .put(legacyBrokenImage.id, legacyBrokenImage.toMap());

    final incomingBytes = Uint8List.fromList([19, 29, 39, 49]);
    final incomingImage = SavedItem(
      id: incomingId,
      kind: ItemKind.image,
      title: 'Image from backup',
      content: '',
      tags: const ['Backup'],
      collection: null,
      isFavorite: false,
      createdAtMs: 1000,
      updatedAtMs: 2000,
      attachmentKey: incomingId,
      attachmentName: 'backup.png',
      attachmentMimeType: 'image/png',
    );
    final source = BackupCodec.encode(
      items: [incomingImage],
      attachmentBytes: {incomingId: incomingBytes},
      collections: const [],
    );

    final count = await repository.restoreBackup(source);
    final restored = repository.items.value.singleWhere(
      (item) => item.title == 'Image from backup',
    );

    expect(count, 1);
    expect(restored.id, isNot(incomingId));
    expect(restored.attachmentKey, restored.id);
    expect(
      await repository.readAttachment(restored.attachmentKey!),
      orderedEquals(incomingBytes),
    );
    expect(
      await repository.readAttachment(incomingId),
      isNull,
      reason: 'The legacy missing payload must not be accidentally repaired by another import.',
    );
    expect(
      repository.findById(legacyBrokenImage.id)?.attachmentKey,
      incomingId,
    );
  });

  test('restoreDecodedBackup revalidates objects before any storage writes', () async {
    final invalidImage = buildImage(
      id: 'constructed-backup-image',
      attachmentKey: 'missing-constructed-payload',
    );
    final decoded = DecodedBackup(
      items: [invalidImage],
      attachments: const {},
      collections: const ['Ideas'],
      exportedAt: '2026-10-22T00:00:00Z',
    );

    await expectLater(
      repository.restoreDecodedBackup(decoded),
      throwsFormatException,
    );

    expect(repository.items.value, isEmpty);
    expect(
      Hive.box<dynamic>('stashhive_items_v1').isEmpty,
      isTrue,
    );
    expect(
      Hive.box<dynamic>('stashhive_attachments_v1').isEmpty,
      isTrue,
    );
    expect(repository.collections.value, isEmpty);
  });

  test('restore owns mutable decoded inputs before its first storage await', () async {
    final mutableTags = <String>['Original tag'];
    final originalBytes = Uint8List.fromList([4, 5, 6, 7]);
    final replacementBytes = Uint8List.fromList([99, 98, 97, 96]);
    final mutableCollections = <String>['Original collection'];
    final mutableItems = <SavedItem>[
      buildImage(
        id: 'mutable-restore-input',
        attachmentKey: 'mutable-restore-source-key',
      ).copyWith(
        tags: mutableTags,
        collection: 'Original collection',
      ),
    ];
    final mutableAttachments = <String, BackupAttachment>{
      'mutable-restore-source-key': BackupAttachment(
        name: 'original.png',
        mimeType: 'image/png',
        bytes: originalBytes,
      ),
    };
    final decoded = DecodedBackup(
      items: mutableItems,
      attachments: mutableAttachments,
      collections: mutableCollections,
      exportedAt: '2026-10-28T00:00:00Z',
    );
    final snapshotTaken = Completer<void>();
    final releaseRestore = Completer<void>();
    LibraryRepository.restoreAfterSnapshotForTesting = () async {
      snapshotTaken.complete();
      await releaseRestore.future;
    };

    final pendingRestore = repository.restoreDecodedBackup(decoded);
    int? imported;
    try {
      await snapshotTaken.future;

      // Mutate every caller-owned collection after validation/snapshot but
      // before the restore is allowed to proceed to its first persistent write.
      mutableTags
        ..[0] = 'Injected tag'
        ..add('Injected extra tag');
      originalBytes[0] = 0;
      mutableCollections
        ..[0] = 'Injected collection'
        ..add('Injected extra collection');
      mutableItems.clear();
      mutableAttachments['mutable-restore-source-key'] = BackupAttachment(
        name: 'replacement.png',
        mimeType: 'image/png',
        bytes: replacementBytes,
      );
    } finally {
      if (!releaseRestore.isCompleted) releaseRestore.complete();
      try {
        imported = await pendingRestore;
      } finally {
        LibraryRepository.restoreAfterSnapshotForTesting = null;
      }
    }

    expect(imported, 1);
    expect(repository.items.value, hasLength(1));
    final restored = repository.items.value.single;
    expect(restored.title, 'Reference image');
    expect(restored.tags, ['Original tag']);
    expect(restored.collection, 'Original collection');
    expect(repository.collections.value, ['Original collection']);
    expect(
      await repository.readAttachment(restored.attachmentKey!),
      orderedEquals([4, 5, 6, 7]),
    );
  });

  test('restore includes valid item-assigned collections omitted from input list', () async {
    final item = buildLink(
      id: 'constructed-collection-assignment',
      collection: 'Assigned only on item',
    );
    final decoded = DecodedBackup(
      items: [item],
      attachments: const {},
      collections: const [],
      exportedAt: '2026-10-22T00:00:00Z',
    );

    final imported = await repository.restoreDecodedBackup(decoded);

    expect(imported, 1);
    expect(
      repository.collections.value,
      contains('Assigned only on item'),
    );
    expect(
      repository.findById(item.id)?.collection,
      'Assigned only on item',
    );
  });

  test('restore collection capacity includes item-only assignments before writes', () async {
    await Hive.box<dynamic>('stashhive_preferences_v1').put(
      'collections',
      List<String>.generate(
        BackupCodec.maxCollections,
        (index) => 'Existing $index',
      ),
    );
    repository.dispose();
    repository = await LibraryRepository.openInitializedForTesting();
    final item = buildLink(
      id: 'constructed-overflow-assignment',
      collection: 'Collection omitted from declared list',
    );
    final decoded = DecodedBackup(
      items: [item],
      attachments: const {},
      collections: const [],
      exportedAt: '2026-10-22T00:00:00Z',
    );

    await expectLater(
      repository.restoreDecodedBackup(decoded),
      throwsA(isA<FormatException>()),
    );

    expect(repository.findById(item.id), isNull);
    expect(repository.items.value, isEmpty);
    expect(
      repository.collections.value,
      hasLength(BackupCodec.maxCollections),
    );
  });

  test('restore rejects a merged collection count over the backup limit before writes', () async {
    await Hive.box<dynamic>('stashhive_preferences_v1').put(
      'collections',
      List<String>.generate(
        BackupCodec.maxCollections,
        (index) => 'Collection $index',
      ),
    );
    repository.dispose();
    repository = await LibraryRepository.openInitializedForTesting();
    await repository.save(buildLink(
      id: 'existing-before-overlimit-restore',
      collection: 'Collection 0',
    ));

    final incoming = buildLink(
      id: 'incoming-overlimit-restore',
      collection: 'New imported collection',
    );
    final backup = BackupCodec.encode(
      items: [incoming],
      attachmentBytes: const {},
      collections: const ['New imported collection'],
    );

    await expectLater(
      repository.restoreBackup(backup),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('500-collection limit'),
        ),
      ),
    );

    expect(repository.items.value, hasLength(1));
    expect(repository.findById('existing-before-overlimit-restore'), isNotNull);
    expect(repository.findById('incoming-overlimit-restore'), isNull);
    expect(
      repository.collections.value,
      hasLength(BackupCodec.maxCollections),
    );
  });

  test('backup preserves skipped legacy record and collection counts', () async {
    await Hive.box<dynamic>('stashhive_preferences_v1').put(
      'collections',
      <Object?>['Learning', 'learning', '   '],
    );
    await Hive.box<dynamic>('stashhive_items_v1').put(
      'unreadable-omission-metadata-record',
      <String, Object?>{
        'id': 'unreadable-omission-metadata-record',
        'kind': 'unsupported-kind',
        'title': 'Unreadable legacy record',
        'content': '',
        'tags': <String>[],
        'isFavorite': false,
        'createdAtMs': 1,
        'updatedAtMs': 2,
      },
    );
    repository.dispose();
    repository = await LibraryRepository.openInitializedForTesting();
    await repository.save(
      buildLink(
        id: 'readable-record-in-partial-backup',
        collection: 'Learning',
      ),
    );

    final json = await repository.createBackup();
    final decoded = BackupCodec.decode(json);

    expect(decoded.items.map((item) => item.id), ['readable-record-in-partial-backup']);
    expect(decoded.omittedUnreadableRecordCount, 1);
    expect(decoded.omittedCollectionEntryCount, 2);
  });

  test('partial backup caps legacy libraries at the portable item limit', () async {
    final rawItems = <String, Object?>{};
    for (var index = 0; index < BackupCodec.maxItems + 1; index++) {
      final id = 'legacy-over-limit-$index';
      rawItems[id] = SavedItem(
        id: id,
        kind: ItemKind.note,
        title: 'Legacy note $index',
        content: 'Content $index',
        tags: const [],
        collection: null,
        isFavorite: false,
        createdAtMs: 1,
        updatedAtMs: index + 1,
      ).toMap();
    }
    await Hive.box<dynamic>('stashhive_items_v1').putAll(rawItems);
    repository.dispose();
    repository = await LibraryRepository.openInitializedForTesting();

    expect(repository.items.value, hasLength(BackupCodec.maxItems + 1));
    expect(repository.unexportableRecordCount, 1);

    final decoded = BackupCodec.decode(await repository.createBackup());
    expect(decoded.items, hasLength(BackupCodec.maxItems));
    expect(decoded.omittedUnexportableRecordCount, 1);
    expect(
      repository.items.value,
      hasLength(BackupCodec.maxItems + 1),
      reason: 'Portable export limits must not delete the extra local record.',
    );
  });

  test('partial backup omits unsafe legacy items and preserves their local records', () async {
    const unsafeId = 'legacy-unsafe-url-for-backup';
    final unsafe = buildLink(
      id: unsafeId,
      url: 'javascript:alert(1)',
    );
    await Hive.box<dynamic>('stashhive_items_v1').put(
      unsafeId,
      unsafe.toMap(),
    );
    await repository.save(
      buildLink(id: 'valid-item-next-to-unsafe-legacy'),
    );

    expect(repository.findById(unsafeId), isNotNull);
    expect(repository.unexportableRecordCount, 1);

    final decoded = BackupCodec.decode(await repository.createBackup());
    expect(
      decoded.items.map((item) => item.id),
      contains('valid-item-next-to-unsafe-legacy'),
    );
    expect(decoded.items.any((item) => item.id == unsafeId), isFalse);
    expect(decoded.omittedUnexportableRecordCount, 1);
    expect(repository.findById(unsafeId), isNotNull);
  });

  test('partial backup omits missing-payload images without deleting them', () async {
    const imageId = 'legacy-image-with-no-bytes';
    final missingImage = buildImage(id: imageId);
    await Hive.box<dynamic>('stashhive_items_v1').put(
      imageId,
      missingImage.toMap(),
    );
    await repository.save(
      buildLink(id: 'valid-item-next-to-missing-image'),
    );

    expect(repository.findById(imageId), isNotNull);
    expect(repository.unexportableRecordCount, 1);

    final decoded = BackupCodec.decode(await repository.createBackup());
    expect(
      decoded.items.map((item) => item.id),
      contains('valid-item-next-to-missing-image'),
    );
    expect(decoded.items.any((item) => item.id == imageId), isFalse);
    expect(decoded.omittedUnexportableRecordCount, 1);
    expect(repository.findById(imageId), isNotNull);
  });

  test('backup gives repair guidance for item assignments beyond collection cap', () async {
    await Hive.box<dynamic>('stashhive_preferences_v1').put(
      'collections',
      List<String>.generate(
        BackupCodec.maxCollections,
        (index) => 'Collection $index',
      ),
    );
    final overflowItem = buildLink(
      id: 'overflow-assigned-collection',
      collection: 'Collection beyond limit',
    );
    await Hive.box<dynamic>('stashhive_items_v1')
        .put(overflowItem.id, overflowItem.toMap());
    repository.dispose();
    repository = await LibraryRepository.openInitializedForTesting();

    expect(repository.findById(overflowItem.id), isNotNull);
    expect(repository.skippedCollectionCount.value, 1);
    await expectLater(
      repository.createBackup(),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('move them to an available collection'),
        ),
      ),
    );
    expect(repository.findById(overflowItem.id), isNotNull);
  });

  test('collection creation stops at the portable backup limit', () async {
    await Hive.box<dynamic>('stashhive_preferences_v1').put(
      'collections',
      List<String>.generate(
        BackupCodec.maxCollections,
        (index) => 'Collection $index',
      ),
    );
    repository.dispose();
    repository = await LibraryRepository.openInitializedForTesting();

    expect(
      repository.collections.value,
      hasLength(BackupCodec.maxCollections),
    );
    await expectLater(
      repository.addCollection('One too many'),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('up to 500 collections'),
        ),
      ),
    );
    expect(
      repository.collections.value,
      hasLength(BackupCodec.maxCollections),
    );
    final backup = await repository.createBackup();
    expect(
      BackupCodec.decode(backup).collections,
      hasLength(BackupCodec.maxCollections),
    );
  });

  test('repository rejects a new assigned collection over the portability cap', () async {
    await Hive.box<dynamic>('stashhive_preferences_v1').put(
      'collections',
      List<String>.generate(
        BackupCodec.maxCollections,
        (index) => 'Existing $index',
      ),
    );
    repository.dispose();
    repository = await LibraryRepository.openInitializedForTesting();

    await expectLater(
      repository.save(
        buildLink(
          id: 'overlimit-assigned-collection',
          collection: 'Not in existing list',
        ),
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('up to 500 collections'),
        ),
      ),
    );
    expect(repository.findById('overlimit-assigned-collection'), isNull);
    expect(repository.items.value, isEmpty);
    expect(repository.collections.value, hasLength(BackupCodec.maxCollections));
  });

  test('canonicalizes case-only collection assignments for legacy and new items', () async {
    await Hive.box<dynamic>('stashhive_preferences_v1').put(
      'collections',
      <String>['Learning'],
    );
    final legacy = buildLink(
      id: 'legacy-lowercase-collection',
      collection: 'learning',
    );
    await Hive.box<dynamic>('stashhive_items_v1')
        .put(legacy.id, legacy.toMap());

    repository.dispose();
    repository = await LibraryRepository.openInitializedForTesting();

    expect(
      repository.findById(legacy.id)?.collection,
      'Learning',
    );
    expect(
      repository.items.value
          .singleWhere((item) => item.id == legacy.id)
          .collection,
      'Learning',
    );

    final newItem = buildLink(
      id: 'new-lowercase-collection',
      collection: 'learning',
    );
    await repository.save(newItem);

    final stored = Hive.box<dynamic>('stashhive_items_v1').get(newItem.id);
    expect(stored['collection'], 'Learning');
    expect(repository.findById(newItem.id)?.collection, 'Learning');
  });

  test('item-assigned collections remain reachable without preference entries', () async {
    await repository.save(
      buildLink(
        id: 'implicit-collection-item',
        collection: 'Research only on the item',
      ),
    );

    expect(
      repository.collections.value,
      contains('Research only on the item'),
      reason: 'A saved item must not point at a collection hidden from navigation.',
    );
    final backup = await repository.createBackup();
    expect(
      BackupCodec.decode(backup).collections,
      contains('Research only on the item'),
    );
  });

  test('rolls back collection creation when preference write reports late failure', () async {
    LibraryRepository.addCollectionAfterWriteForTesting = () async {
      throw StateError('simulated post-write collection failure');
    };
    try {
      await expectLater(
        repository.addCollection('Needs rollback'),
        throwsA(isA<StateError>()),
      );
    } finally {
      LibraryRepository.addCollectionAfterWriteForTesting = null;
    }

    expect(repository.collections.value, isEmpty);
    expect(
      Hive.box<dynamic>('stashhive_preferences_v1').containsKey('collections'),
      isFalse,
    );
  });

  test('skips oversized legacy collection names during local recovery', () async {
    final preferences = Hive.box<dynamic>('stashhive_preferences_v1');
    await preferences.put(
      'collections',
      <String>[
        'Learning',
        List<String>.filled(100000, ' ').join(),
      ],
    );

    repository.dispose();
    repository = await LibraryRepository.openInitializedForTesting();

    expect(repository.collections.value, ['Learning']);
    expect(repository.skippedCollectionCount.value, 1);
  });

  test('serializes concurrent collection creation without losing updates', () async {
    final firstWriteEntered = Completer<void>();
    final releaseFirstWrite = Completer<void>();
    var hookCalls = 0;

    LibraryRepository.addCollectionAfterWriteForTesting = () async {
      hookCalls++;
      if (hookCalls == 1) {
        firstWriteEntered.complete();
        await releaseFirstWrite.future;
      }
    };
    final first = repository.addCollection('First');
    await firstWriteEntered.future;
    final second = repository.addCollection('Second');
    await Future<void>.delayed(Duration.zero);
    final secondOvertookFirst = hookCalls > 1;

    releaseFirstWrite.complete();
    try {
      await Future.wait([first, second]);
    } finally {
      LibraryRepository.addCollectionAfterWriteForTesting = null;
    }

    expect(secondOvertookFirst, isFalse);
    expect(repository.collections.value, containsAll(['First', 'Second']));
    expect(
      Hive.box<dynamic>('stashhive_preferences_v1').get('collections'),
      containsAll(['First', 'Second']),
    );
  });

  test('releases the mutation queue after a collection creation failure', () async {
    final firstWriteEntered = Completer<void>();
    final releaseFirstFailure = Completer<void>();
    var hookCalls = 0;

    LibraryRepository.addCollectionAfterWriteForTesting = () async {
      hookCalls++;
      if (hookCalls == 1) {
        firstWriteEntered.complete();
        await releaseFirstFailure.future;
        throw StateError('simulated post-write collection failure');
      }
    };

    final first = repository.addCollection('Fails');
    await firstWriteEntered.future;
    final second = repository.addCollection('Survives');
    await Future<void>.delayed(Duration.zero);
    final secondOvertookFirst = hookCalls > 1;

    final firstFailure = expectLater(first, throwsA(isA<StateError>()));
    releaseFirstFailure.complete();
    try {
      await Future.wait<void>([firstFailure, second]);
    } finally {
      LibraryRepository.addCollectionAfterWriteForTesting = null;
    }

    expect(secondOvertookFirst, isFalse);
    expect(repository.collections.value, equals(['Survives']));
    expect(
      Hive.box<dynamic>('stashhive_preferences_v1').get('collections'),
      equals(['Survives']),
    );
  });

  test('serializes simultaneous favorite toggles from the latest record', () async {
    final item = buildLink(id: 'favorite-double-toggle');
    await repository.save(item);

    final first = repository.toggleFavorite(item.id);
    final second = repository.toggleFavorite(item.id);
    await Future.wait<void>([first, second]);

    final stored = repository.findById(item.id);
    final raw = Hive.box<dynamic>('stashhive_items_v1').get(item.id) as Map;
    expect(stored?.isFavorite, item.isFavorite);
    expect(
      repository.items.value.singleWhere((saved) => saved.id == item.id).isFavorite,
      item.isFavorite,
    );
    expect(raw['isFavorite'], item.isFavorite);
  });

  test('normalizes legacy collection names and counts malformed entries', () async {
    final preferences = Hive.box<dynamic>('stashhive_preferences_v1');
    await preferences.put(
      'collections',
      <Object?>[
        'Learning',
        'learning',
        '',
        42,
        List<String>.filled(81, 'x').join(),
        'Research',
      ],
    );
    repository.dispose();
    repository = await LibraryRepository.openInitializedForTesting();

    expect(repository.collections.value, ['Learning', 'Research']);
    expect(repository.skippedCollectionCount.value, 4);
  });

  test('caps legacy collection preferences at the portable limit', () async {
    await Hive.box<dynamic>('stashhive_preferences_v1').put(
      'collections',
      List<String>.generate(
        BackupCodec.maxCollections + 1,
        (index) => 'Legacy Collection $index',
      ),
    );
    repository.dispose();
    repository = await LibraryRepository.openInitializedForTesting();

    expect(
      repository.collections.value,
      hasLength(BackupCodec.maxCollections),
    );
    expect(repository.skippedCollectionCount.value, 1);
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

  test('attachment reads wait for a replacement commit', () async {
    final originalBytes = Uint8List.fromList([1, 3, 5, 7]);
    final replacementBytes = Uint8List.fromList([2, 4, 6, 8]);
    final image = buildImage(id: 'attachment-read-commit-race');
    await repository.save(image, attachmentBytes: originalBytes);

    final writeEntered = Completer<void>();
    final releaseWrite = Completer<void>();
    LibraryRepository.saveBeforeItemCommitForTesting = () async {
      writeEntered.complete();
      await releaseWrite.future;
    };

    final pendingSave = repository.save(
      image.copyWith(title: 'Committed replacement'),
      attachmentBytes: replacementBytes,
    );
    await writeEntered.future;

    var readCompleted = false;
    final pendingRead = repository.readAttachment(image.attachmentKey!).then((bytes) {
      readCompleted = true;
      return bytes;
    });

    try {
      await Future<void>.delayed(Duration.zero);
      expect(
        readCompleted,
        isFalse,
        reason: 'A reader must not observe replacement bytes before the item commit.',
      );
    } finally {
      if (!releaseWrite.isCompleted) releaseWrite.complete();
    }

    try {
      await pendingSave;
    } finally {
      LibraryRepository.saveBeforeItemCommitForTesting = null;
    }

    expect(await pendingRead, orderedEquals(replacementBytes));
    expect(repository.findById(image.id)?.title, 'Committed replacement');
  });

  test('attachment reads wait for failed replacement rollback', () async {
    final originalBytes = Uint8List.fromList([9, 2, 6, 5]);
    final replacementBytes = Uint8List.fromList([3, 5, 8, 9]);
    final image = buildImage(id: 'attachment-read-rollback-race');
    await repository.save(image, attachmentBytes: originalBytes);

    final writeEntered = Completer<void>();
    final releaseFailure = Completer<void>();
    LibraryRepository.saveBeforeItemCommitForTesting = () async {
      writeEntered.complete();
      await releaseFailure.future;
      throw StateError('simulated replacement failure');
    };

    final pendingSave = repository.save(
      image.copyWith(title: 'Failed replacement'),
      attachmentBytes: replacementBytes,
    );
    await writeEntered.future;
    final saveFailure = expectLater(
      pendingSave,
      throwsA(isA<StateError>()),
    );

    var readCompleted = false;
    final pendingRead = repository.readAttachment(image.attachmentKey!).then((bytes) {
      readCompleted = true;
      return bytes;
    });

    try {
      await Future<void>.delayed(Duration.zero);
      expect(
        readCompleted,
        isFalse,
        reason: 'A reader must wait while replacement bytes are being rolled back.',
      );
    } finally {
      if (!releaseFailure.isCompleted) releaseFailure.complete();
    }

    try {
      await saveFailure;
    } finally {
      LibraryRepository.saveBeforeItemCommitForTesting = null;
    }

    expect(await pendingRead, orderedEquals(originalBytes));
    expect(repository.findById(image.id)?.title, image.title);
    expect(
      await repository.readAttachment(image.attachmentKey!),
      orderedEquals(originalBytes),
    );
  });

  test('clears a failed attachment read so the same key can be retried', () async {
    final bytes = Uint8List.fromList([3, 1, 4, 1, 5]);
    final image = buildImage(id: 'retry-failed-attachment-read');
    await repository.save(image, attachmentBytes: bytes);

    var readAttempts = 0;
    LibraryRepository.readAttachmentBeforeReadForTesting = (_) async {
      readAttempts++;
      if (readAttempts == 1) {
        throw StateError('simulated transient attachment read failure');
      }
    };

    try {
      await expectLater(
        repository.readAttachment(image.attachmentKey!),
        throwsA(isA<StateError>()),
      );

      expect(
        await repository.readAttachment(image.attachmentKey!),
        orderedEquals(bytes),
      );
      expect(readAttempts, 2);
    } finally {
      LibraryRepository.readAttachmentBeforeReadForTesting = null;
    }
  });

  test('coalesces overlapping attachment reads without crossing a queued write', () async {
    final originalBytes = Uint8List.fromList([2, 7, 1, 8]);
    final replacementBytes = Uint8List.fromList([2, 8, 1, 8]);
    final image = buildImage(id: 'coalesced-attachment-read');
    await repository.save(image, attachmentBytes: originalBytes);

    final firstReadEntered = Completer<void>();
    final releaseFirstRead = Completer<void>();
    var readStarts = 0;
    LibraryRepository.readAttachmentBeforeReadForTesting = (_) async {
      readStarts++;
      if (readStarts == 1) {
        firstReadEntered.complete();
        await releaseFirstRead.future;
      }
    };

    final firstRead = repository.readAttachment(image.attachmentKey!);
    await firstReadEntered.future;
    try {
      final secondRead = repository.readAttachment(image.attachmentKey!);
      expect(
        readStarts,
        1,
        reason: 'A concurrent read for the same key should share the pending future.',
      );

      final pendingSave = repository.save(
        image.copyWith(title: 'Updated after first read'),
        attachmentBytes: replacementBytes,
      );
      // This read is requested after the save is queued; it must not reuse the
      // old read future, even though that future is still awaiting its test gate.
      final afterWriteRead = repository.readAttachment(image.attachmentKey!);
      expect(readStarts, 1);

      releaseFirstRead.complete();
      final firstBytes = await firstRead;
      final secondBytes = await secondRead;
      await pendingSave;
      final afterWriteBytes = await afterWriteRead;

      expect(firstBytes, orderedEquals(originalBytes));
      expect(secondBytes, orderedEquals(originalBytes));
      expect(afterWriteBytes, orderedEquals(replacementBytes));
      expect(readStarts, 2);
      expect(repository.findById(image.id)?.title, 'Updated after first read');
    } finally {
      if (!releaseFirstRead.isCompleted) releaseFirstRead.complete();
      LibraryRepository.readAttachmentBeforeReadForTesting = null;
    }
  });

  test('creates a consistent backup after a pending attachment replacement', () async {
    final originalBytes = Uint8List.fromList([1, 3, 5, 7]);
    final replacementBytes = Uint8List.fromList([2, 4, 6, 8]);
    final original = buildImage(id: 'backup-snapshot-race');
    await repository.save(original, attachmentBytes: originalBytes);

    final writeEntered = Completer<void>();
    final releaseWrite = Completer<void>();
    LibraryRepository.saveAfterItemCommitForTesting = () async {
      writeEntered.complete();
      await releaseWrite.future;
    };

    final edited = original.copyWith(title: 'Updated attachment metadata');
    final pendingSave = repository.save(
      edited,
      attachmentBytes: replacementBytes,
    );
    await writeEntered.future;

    var backupCompleted = false;
    final pendingBackup = repository.createBackup().then((source) {
      backupCompleted = true;
      return source;
    });
    try {
      await Future<void>.delayed(Duration.zero);
      expect(
        backupCompleted,
        isFalse,
        reason: 'Backup export must wait for the in-flight item/attachment commit.',
      );
    } finally {
      if (!releaseWrite.isCompleted) releaseWrite.complete();
    }

    try {
      await pendingSave;
    } finally {
      LibraryRepository.saveAfterItemCommitForTesting = null;
    }
    final source = await pendingBackup;
    final decoded = BackupCodec.decode(source);

    expect(
      repository.lastBackupPreparedAtMs,
      isNotNull,
      reason: 'A generated portable backup records its preparation time.',
    );
    expect(decoded.items, hasLength(1));
    expect(decoded.items.single.title, 'Updated attachment metadata');
    expect(
      decoded.attachments[original.attachmentKey!]!.bytes,
      orderedEquals(replacementBytes),
      reason: 'Backup metadata and bytes must reflect the same committed edit.',
    );
  });

  test('backup waits for collection rename before snapshotting assignments', () async {
    await repository.addCollection('Before');
    await repository.save(
      buildLink(id: 'backup-collection-race', collection: 'Before'),
    );

    final renameEntered = Completer<void>();
    final releaseRename = Completer<void>();
    LibraryRepository.collectionAfterPreferencesWriteForTesting = () async {
      renameEntered.complete();
      await releaseRename.future;
    };

    final pendingRename = repository.renameCollection('Before', 'After');
    await renameEntered.future;

    var backupCompleted = false;
    final pendingBackup = repository.createBackup().then((source) {
      backupCompleted = true;
      return source;
    });

    try {
      await Future<void>.delayed(Duration.zero);
      expect(
        backupCompleted,
        isFalse,
        reason: 'Backup must wait until the collection and item updates commit.',
      );
    } finally {
      if (!releaseRename.isCompleted) releaseRename.complete();
    }

    try {
      await pendingRename;
    } finally {
      LibraryRepository.collectionAfterPreferencesWriteForTesting = null;
    }

    final source = await pendingBackup;
    final decoded = BackupCodec.decode(source);

    expect(decoded.collections, ['After']);
    expect(decoded.items, hasLength(1));
    expect(decoded.items.single.collection, 'After');
    expect(repository.collections.value, ['After']);
    expect(repository.items.value.single.collection, 'After');
  });

  test('backup waits for a failed save to restore previous attachment state', () async {
    final originalBytes = Uint8List.fromList([1, 4, 1, 4]);
    final replacementBytes = Uint8List.fromList([2, 7, 1, 8]);
    final original = buildImage(id: 'backup-save-rollback-race');
    await repository.save(original, attachmentBytes: originalBytes);

    final saveEntered = Completer<void>();
    final releaseSaveFailure = Completer<void>();
    LibraryRepository.saveAfterItemCommitForTesting = () async {
      saveEntered.complete();
      await releaseSaveFailure.future;
      throw StateError('simulated late save failure');
    };

    final pendingSave = repository.save(
      original.copyWith(title: 'Uncommitted replacement'),
      attachmentBytes: replacementBytes,
    );
    await saveEntered.future;
    final saveFailure = expectLater(
      pendingSave,
      throwsA(isA<StateError>()),
    );

    var backupCompleted = false;
    final pendingBackup = repository.createBackup().then((source) {
      backupCompleted = true;
      return source;
    });

    try {
      await Future<void>.delayed(Duration.zero);
      expect(
        backupCompleted,
        isFalse,
        reason: 'Backup must wait until the failed save has restored prior state.',
      );
    } finally {
      if (!releaseSaveFailure.isCompleted) {
        releaseSaveFailure.complete();
      }
    }

    try {
      await saveFailure;
    } finally {
      LibraryRepository.saveAfterItemCommitForTesting = null;
    }

    final source = await pendingBackup;
    final decoded = BackupCodec.decode(source);

    expect(decoded.items, hasLength(1));
    expect(decoded.items.single.title, original.title);
    expect(
      decoded.attachments[original.attachmentKey!]!.bytes,
      orderedEquals(originalBytes),
      reason: 'The failed replacement bytes must not leak into the queued backup.',
    );
    expect(repository.findById(original.id)?.title, original.title);
    expect(
      await repository.readAttachment(original.attachmentKey!),
      orderedEquals(originalBytes),
    );
  });

  test('backup waits for a failed delete to restore its item and attachment', () async {
    final originalBytes = Uint8List.fromList([4, 2, 4, 2]);
    final image = buildImage(id: 'backup-delete-rollback-race');
    await repository.save(image, attachmentBytes: originalBytes);

    final deleteEntered = Completer<void>();
    final releaseDeleteFailure = Completer<void>();
    LibraryRepository.deleteAfterAttachmentDeleteForTesting = () async {
      deleteEntered.complete();
      await releaseDeleteFailure.future;
      throw StateError('simulated late delete failure');
    };

    final pendingDelete = repository.delete(image.id);
    await deleteEntered.future;
    final deleteFailure = expectLater(
      pendingDelete,
      throwsA(isA<StateError>()),
    );

    var backupCompleted = false;
    final pendingBackup = repository.createBackup().then((source) {
      backupCompleted = true;
      return source;
    });

    try {
      await Future<void>.delayed(Duration.zero);
      expect(
        backupCompleted,
        isFalse,
        reason: 'Backup must wait while delete rollback is still in progress.',
      );
      expect(repository.items.value, hasLength(1));
    } finally {
      if (!releaseDeleteFailure.isCompleted) {
        releaseDeleteFailure.complete();
      }
    }

    try {
      await deleteFailure;
      LibraryRepository.deleteAfterAttachmentDeleteForTesting = null;
    } finally {
      LibraryRepository.deleteAfterAttachmentDeleteForTesting = null;
    }

    final source = await pendingBackup;
    final decoded = BackupCodec.decode(source);

    expect(repository.items.value, hasLength(1));
    expect(repository.findById(image.id)?.title, image.title);
    expect(decoded.items, hasLength(1));
    expect(decoded.items.single.id, image.id);
    expect(
      decoded.attachments[image.attachmentKey!]!.bytes,
      orderedEquals(originalBytes),
      reason: 'The backup must include the bytes restored after delete rollback.',
    );
  });

  test('backup waits for an interrupted restore to roll back staged data', () async {
    await repository.addCollection('Existing');
    await repository.save(
      buildLink(id: 'restore-backup-race-existing', collection: 'Existing'),
    );

    final importedBytes = Uint8List.fromList([5, 9, 2, 6]);
    const incomingImage = SavedItem(
      id: 'restore-backup-race-incoming',
      kind: ItemKind.image,
      title: 'Staged image',
      content: '',
      url: null,
      tags: ['Import'],
      collection: 'Imported',
      isFavorite: false,
      createdAtMs: 1000,
      updatedAtMs: 2000,
      attachmentKey: 'restore-backup-race-incoming',
      attachmentName: 'staged.png',
      attachmentMimeType: 'image/png',
    );
    final incomingBackup = BackupCodec.encode(
      items: const [incomingImage],
      attachmentBytes: {
        incomingImage.attachmentKey!: importedBytes,
      },
      collections: const ['Imported'],
    );

    final restoreEntered = Completer<void>();
    final releaseRestoreFailure = Completer<void>();
    LibraryRepository.restoreBeforeCollectionsCommitForTesting = () async {
      restoreEntered.complete();
      await releaseRestoreFailure.future;
      throw StateError('simulated restore interruption');
    };

    final pendingRestore = repository.restoreBackup(incomingBackup);
    await restoreEntered.future;
    final restoreFailure = expectLater(
      pendingRestore,
      throwsA(isA<StateError>()),
    );

    var backupCompleted = false;
    final pendingBackup = repository.createBackup().then((source) {
      backupCompleted = true;
      return source;
    });

    try {
      await Future<void>.delayed(Duration.zero);
      expect(
        backupCompleted,
        isFalse,
        reason: 'Backup must wait until staged restore writes are committed or rolled back.',
      );
    } finally {
      if (!releaseRestoreFailure.isCompleted) {
        releaseRestoreFailure.complete();
      }
    }

    try {
      await restoreFailure;
    } finally {
      LibraryRepository.restoreBeforeCollectionsCommitForTesting = null;
    }

    final source = await pendingBackup;
    final decoded = BackupCodec.decode(source);

    expect(
      decoded.items.map((item) => item.id),
      ['restore-backup-race-existing'],
    );
    expect(decoded.collections, ['Existing']);
    expect(decoded.attachments, isEmpty);
    expect(repository.findById(incomingImage.id), isNull);
    expect(
      Hive.box<dynamic>('stashhive_attachments_v1')
          .containsKey(incomingImage.attachmentKey),
      isFalse,
    );
  });

  test('snapshots caller-owned item tags before storage awaits', () async {
    final callerTags = <String>['Original tag'];
    final item = buildLink(id: 'caller-tags-snapshot').copyWith(
      tags: callerTags,
    );
    final beforeItemCommit = Completer<void>();
    final releaseItemCommit = Completer<void>();
    LibraryRepository.saveBeforeItemCommitForTesting = () async {
      beforeItemCommit.complete();
      await releaseItemCommit.future;
    };

    final pendingSave = repository.save(item);
    try {
      await beforeItemCommit.future;
      callerTags
        ..[0] = 'Mutated tag'
        ..add('Injected tag');
    } finally {
      if (!releaseItemCommit.isCompleted) releaseItemCommit.complete();
      try {
        await pendingSave;
      } finally {
        LibraryRepository.saveBeforeItemCommitForTesting = null;
      }
    }

    final saved = repository.findById(item.id);
    expect(saved, isNotNull);
    expect(saved!.tags, ['Original tag']);
    final raw = Hive.box<dynamic>('stashhive_items_v1').get(item.id) as Map;
    expect(raw['tags'], ['Original tag']);
  });

  test('snapshots caller-owned attachment bytes before storage awaits', () async {
    final callerBuffer = Uint8List.fromList([1, 2, 3, 4, 250]);
    final expected = Uint8List.fromList(callerBuffer);
    final image = buildImage(id: 'caller-buffer-snapshot');

    LibraryRepository.saveBeforeItemCommitForTesting = () async {
      callerBuffer[0] = 99;
      callerBuffer[4] = 0;
    };
    try {
      await repository.save(image, attachmentBytes: callerBuffer);
    } finally {
      LibraryRepository.saveBeforeItemCommitForTesting = null;
    }

    expect(
      await repository.readAttachment(image.attachmentKey!),
      orderedEquals(expected),
    );
    expect(callerBuffer, isNot(orderedEquals(expected)));
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

  test('restore rollback preserves bytes when staged item deletion fails', () async {
    await repository.addCollection('Existing');
    await repository.save(buildLink(id: 'existing-before-rollback-failure'));

    final importedBytes = Uint8List.fromList([3, 1, 4, 1, 5]);
    const incomingImage = SavedItem(
      id: 'incoming-image-rollback-failure',
      kind: ItemKind.image,
      title: 'Imported image retained after rollback failure',
      content: 'Restore interruption recovery',
      url: null,
      tags: ['Recovery'],
      collection: 'Imported',
      isFavorite: false,
      createdAtMs: 1000,
      updatedAtMs: 2000,
      attachmentKey: 'incoming-image-rollback-failure',
      attachmentName: 'imported.png',
      attachmentMimeType: 'image/png',
    );
    final backup = BackupCodec.encode(
      items: const [incomingImage],
      attachmentBytes: {
        'incoming-image-rollback-failure': importedBytes,
      },
      collections: const ['Imported'],
    );

    LibraryRepository.restoreBeforeCollectionsCommitForTesting = () async {
      throw StateError('simulated restore interruption');
    };
    LibraryRepository.restoreBeforeRollbackItemDeleteForTesting =
        (itemId) async {
      if (itemId == incomingImage.id) {
        throw StateError('simulated rollback item-delete failure');
      }
    };
    try {
      await expectLater(
        repository.restoreBackup(backup),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'simulated restore interruption',
          ),
        ),
      );
    } finally {
      LibraryRepository.restoreBeforeCollectionsCommitForTesting = null;
      LibraryRepository.restoreBeforeRollbackItemDeleteForTesting = null;
    }

    // The failed rollback may leave this staged record on disk, but it must
    // never leave that record pointing at attachment bytes that were deleted.
    expect(
      Hive.box<dynamic>('stashhive_items_v1')
          .containsKey(incomingImage.id),
      isTrue,
    );
    expect(
      await repository.readAttachment(incomingImage.attachmentKey!),
      orderedEquals(importedBytes),
    );
    expect(repository.findById(incomingImage.id), isNotNull);
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

  test(
    'findById stays on the published snapshot during an in-flight save',
    () async {
      final originalBytes = Uint8List.fromList([1, 3, 5, 7]);
      final replacementBytes = Uint8List.fromList([2, 4, 6, 8]);
      final original = buildImage(id: 'published-lookup-snapshot');
      await repository.save(original, attachmentBytes: originalBytes);

      final writeEntered = Completer<void>();
      final releaseWrite = Completer<void>();
      LibraryRepository.saveAfterItemCommitForTesting = () async {
        writeEntered.complete();
        await releaseWrite.future;
      };
      final updated = original.copyWith(
        title: 'Replacement is still pending',
        updatedAtMs: 3000,
      );
      final pendingSave = repository.save(
        updated,
        attachmentBytes: replacementBytes,
      );

      try {
        await writeEntered.future;
        final raw = Hive.box<dynamic>('stashhive_items_v1')
            .get(original.id) as Map;
        expect(raw['title'], 'Replacement is still pending');
        expect(
          repository.items.value.single.title,
          original.title,
          reason: 'The visible notifier is not published until save completes.',
        );
        expect(
          repository.findById(original.id)?.title,
          original.title,
          reason: 'Synchronous lookups must not expose the raw staged record.',
        );
      } finally {
        if (!releaseWrite.isCompleted) releaseWrite.complete();
        try {
          await pendingSave;
        } finally {
          LibraryRepository.saveAfterItemCommitForTesting = null;
        }
      }

      expect(
        repository.findById(original.id)?.title,
        'Replacement is still pending',
      );
      expect(
        await repository.readAttachment(original.attachmentKey!),
        orderedEquals(replacementBytes),
      );
    },
  );

  test(
    'findById keeps the published item visible while delete rollback is pending',
    () async {
      final originalBytes = Uint8List.fromList([8, 6, 7, 5]);
      final image = buildImage(id: 'published-lookup-delete-rollback');
      await repository.save(image, attachmentBytes: originalBytes);

      final deleteEntered = Completer<void>();
      final releaseDeleteFailure = Completer<void>();
      LibraryRepository.deleteAfterAttachmentDeleteForTesting = () async {
        deleteEntered.complete();
        await releaseDeleteFailure.future;
        throw StateError('simulated delayed delete failure');
      };
      final pendingDelete = repository.delete(image.id);

      try {
        await deleteEntered.future;
        expect(
          Hive.box<dynamic>('stashhive_items_v1').containsKey(image.id),
          isFalse,
          reason: 'The raw record is staged as deleted before rollback is released.',
        );
        expect(
          repository.items.value.single.id,
          image.id,
          reason: 'The public list remains on the last published snapshot.',
        );
        expect(
          repository.findById(image.id)?.id,
          image.id,
          reason: 'Synchronous lookup must not expose a staged deletion.',
        );
      } finally {
        if (!releaseDeleteFailure.isCompleted) {
          releaseDeleteFailure.complete();
        }
        try {
          await expectLater(
            pendingDelete,
            throwsA(isA<StateError>()),
          );
        } finally {
          LibraryRepository.deleteAfterAttachmentDeleteForTesting = null;
        }
      }

      expect(repository.findById(image.id)?.title, image.title);
      expect(
        await repository.readAttachment(image.attachmentKey!),
        orderedEquals(originalBytes),
      );
    },
  );

  test(
    'findById does not expose staged restore records before commit',
    () async {
      await repository.save(
        buildLink(id: 'restore-published-existing', collection: null),
      );
      final incoming = buildLink(
        id: 'restore-published-pending',
        collection: 'Imported',
        url: 'https://example.com/imported',
      );
      final source = BackupCodec.encode(
        items: [incoming],
        attachmentBytes: const <String, Uint8List>{},
        collections: const ['Imported'],
      );

      final restoreEntered = Completer<void>();
      final releaseRestore = Completer<void>();
      LibraryRepository.restoreBeforeCollectionsCommitForTesting = () async {
        restoreEntered.complete();
        await releaseRestore.future;
      };
      final pendingRestore = repository.restoreBackup(source);

      try {
        await restoreEntered.future;
        expect(
          Hive.box<dynamic>('stashhive_items_v1')
              .containsKey(incoming.id),
          isTrue,
          reason: 'The restore has staged its raw item record.',
        );
        expect(
          repository.findById(incoming.id),
          isNull,
          reason: 'A staged record must not appear before restore commit.',
        );
        expect(
          repository.items.value.any((item) => item.id == incoming.id),
          isFalse,
        );
        expect(
          repository.findById('restore-published-existing')?.id,
          'restore-published-existing',
        );
      } finally {
        if (!releaseRestore.isCompleted) releaseRestore.complete();
        try {
          await pendingRestore;
        } finally {
          LibraryRepository.restoreBeforeCollectionsCommitForTesting = null;
        }
      }

      expect(repository.findById(incoming.id)?.title, incoming.title);
      expect(
        repository.items.value.map((item) => item.id),
        containsAll(['restore-published-existing', incoming.id]),
      );
      expect(repository.collections.value, contains('Imported'));
    },
  );

  test(
    'snapshots mutable save inputs before waiting in the mutation queue',
    () async {
      final blockerWriteEntered = Completer<void>();
      final releaseBlocker = Completer<void>();
      var afterWriteCalls = 0;
      LibraryRepository.saveAfterItemCommitForTesting = () async {
        afterWriteCalls++;
        if (afterWriteCalls == 1) {
          blockerWriteEntered.complete();
          await releaseBlocker.future;
        }
      };

      final blockerSave = repository.save(
        buildLink(id: 'save-input-queue-blocker', collection: null),
      );
      Future<void>? pendingSave;
      final callerTags = <String>['Original tag'];
      final callerBytes = Uint8List.fromList([3, 1, 4, 1, 5]);
      final expectedBytes = Uint8List.fromList(callerBytes);
      final queuedImage = buildImage(id: 'queued-save-captured-inputs')
          .copyWith(tags: callerTags);

      try {
        await blockerWriteEntered.future;
        pendingSave = repository.save(
          queuedImage,
          attachmentBytes: callerBytes,
        );

        // The next repository save is waiting behind the paused blocker.
        // These mutations must not change the values captured by save().
        callerTags
          ..[0] = 'Mutated after enqueue'
          ..add('Late tag');
        callerBytes[0] = 99;
        callerBytes[4] = 0;
      } finally {
        if (!releaseBlocker.isCompleted) releaseBlocker.complete();
        try {
          await blockerSave;
          if (pendingSave != null) await pendingSave;
        } finally {
          LibraryRepository.saveAfterItemCommitForTesting = null;
        }
      }

      final saved = repository.findById(queuedImage.id);
      expect(saved, isNotNull);
      expect(saved!.tags, ['Original tag']);
      final raw = Hive.box<dynamic>('stashhive_items_v1')
          .get(queuedImage.id) as Map;
      expect(raw['tags'], ['Original tag']);
      expect(
        await repository.readAttachment(queuedImage.attachmentKey!),
        orderedEquals(expectedBytes),
      );
      expect(callerTags, ['Mutated after enqueue', 'Late tag']);
    },
  );

  test(
    'snapshots decoded restore inputs before waiting in the mutation queue',
    () async {
      final blockerWriteEntered = Completer<void>();
      final releaseBlocker = Completer<void>();
      var afterWriteCalls = 0;
      LibraryRepository.saveAfterItemCommitForTesting = () async {
        afterWriteCalls++;
        if (afterWriteCalls == 1) {
          blockerWriteEntered.complete();
          await releaseBlocker.future;
        }
      };

      final blockerSave = repository.save(
        buildLink(id: 'restore-input-queue-blocker', collection: null),
      );
      final callerTags = <String>['Original restore tag'];
      final sourceItems = <SavedItem>[
        SavedItem(
          id: 'queued-restore-snapshot-image',
          kind: ItemKind.image,
          title: 'Queued restore image',
          content: '',
          tags: callerTags,
          collection: 'Imported original',
          isFavorite: false,
          createdAtMs: 1000,
          updatedAtMs: 2000,
          attachmentKey: 'queued-restore-snapshot-image',
          attachmentName: 'queued.png',
          attachmentMimeType: 'image/png',
        ),
      ];
      final sourceCollections = <String>['Imported original'];
      final sourceBytes = Uint8List.fromList([2, 7, 1, 8, 2]);
      final expectedBytes = Uint8List.fromList(sourceBytes);
      final sourceAttachments = <String, BackupAttachment>{
        'queued-restore-snapshot-image': BackupAttachment(
          name: 'queued.png',
          mimeType: 'image/png',
          bytes: sourceBytes,
        ),
      };
      final decoded = DecodedBackup(
        items: sourceItems,
        attachments: sourceAttachments,
        collections: sourceCollections,
        exportedAt: '2026-10-28T00:00:00Z',
      );

      Future<int>? pendingRestore;
      try {
        await blockerWriteEntered.future;
        pendingRestore = repository.restoreDecodedBackup(decoded);

        // The restore is waiting behind the blocker. Its submitted snapshot
        // must not change when the caller mutates every source collection.
        callerTags
          ..[0] = 'Mutated tag'
          ..add('Late tag');
        sourceItems.clear();
        sourceCollections[0] = 'Mutated collection';
        sourceAttachments.clear();
        sourceBytes[0] = 99;
        sourceBytes[4] = 0;
      } finally {
        if (!releaseBlocker.isCompleted) releaseBlocker.complete();
        try {
          await blockerSave;
          if (pendingRestore != null) await pendingRestore;
        } finally {
          LibraryRepository.saveAfterItemCommitForTesting = null;
        }
      }

      expect(pendingRestore, isNotNull);
      final restored = repository.findById('queued-restore-snapshot-image');
      expect(restored, isNotNull);
      expect(restored!.tags, ['Original restore tag']);
      expect(restored.collection, 'Imported original');
      expect(repository.collections.value, contains('Imported original'));
      expect(
        await repository.readAttachment('queued-restore-snapshot-image'),
        orderedEquals(expectedBytes),
      );
    },
  );

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

  test('rolls back collection rename after preferences write then error', () async {
    await repository.addCollection('Learning');
    final first = buildLink(id: 'late-rename-1', collection: 'Learning');
    final second = buildLink(id: 'late-rename-2', collection: 'Learning');
    await repository.save(first);
    await repository.save(second);

    LibraryRepository.collectionAfterPreferencesWriteForTesting = () async {
      throw StateError('simulated post-commit preference failure');
    };
    try {
      await expectLater(
        repository.renameCollection('Learning', 'Reading'),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'simulated post-commit preference failure',
          ),
        ),
      );
    } finally {
      LibraryRepository.collectionAfterPreferencesWriteForTesting = null;
    }

    expect(repository.collections.value, ['Learning']);
    expect(repository.items.value, hasLength(2));
    expect(
      repository.items.value.map((item) => item.collection),
      everyElement('Learning'),
    );
    final storedItems = Hive.box<dynamic>('stashhive_items_v1');
    expect(storedItems.get(first.id)['collection'], 'Learning');
    expect(storedItems.get(second.id)['collection'], 'Learning');
    expect(
      Hive.box<dynamic>('stashhive_preferences_v1').get('collections'),
      ['Learning'],
    );
  });

  test('deleting an unreadable legacy item reclaims its unreferenced attachment', () async {
    const itemId = 'unreadable-image-record';
    const attachmentKey = 'unreadable-orphan-payload';
    final storedItems = Hive.box<dynamic>('stashhive_items_v1');
    final storedAttachments = Hive.box<dynamic>('stashhive_attachments_v1');
    await storedItems.put(itemId, <String, Object?>{
      'id': itemId,
      'kind': 'unknown-kind',
      'attachmentKey': attachmentKey,
    });
    await storedAttachments.put(
      attachmentKey,
      Uint8List.fromList([3, 1, 4, 1, 5]),
    );
    repository.dispose();
    repository = await LibraryRepository.openInitializedForTesting();

    expect(repository.skippedRecordCount.value, 1);
    await repository.delete(itemId);

    expect(storedItems.containsKey(itemId), isFalse);
    expect(storedAttachments.containsKey(attachmentKey), isFalse);
    expect(repository.skippedRecordCount.value, 0);
  });

  test('deleting an unreadable record keeps bytes still referenced by another item', () async {
    const itemId = 'unreadable-shared-record';
    const attachmentKey = 'payload-shared-with-valid-item';
    final bytes = Uint8List.fromList([2, 7, 1, 8]);
    await repository.save(
      buildImage(id: 'valid-shared-reference', attachmentKey: attachmentKey),
      attachmentBytes: bytes,
    );
    await Hive.box<dynamic>('stashhive_items_v1').put(itemId, <String, Object?>{
      'id': itemId,
      'kind': 'unknown-kind',
      'attachmentKey': attachmentKey,
    });
    repository.dispose();
    repository = await LibraryRepository.openInitializedForTesting();

    expect(repository.skippedRecordCount.value, 1);
    await repository.delete(itemId);

    expect(
      Hive.box<dynamic>('stashhive_attachments_v1').containsKey(attachmentKey),
      isTrue,
    );
    expect(
      await repository.readAttachment(attachmentKey),
      orderedEquals(bytes),
    );
    expect(repository.findById('valid-shared-reference')?.hasAttachment, isTrue);
    expect(repository.skippedRecordCount.value, 0);
  });

  test('rolls back deletion of an unreadable legacy record and its attachment', () async {
    const itemId = 'unreadable-rollback-record';
    const attachmentKey = 'unreadable-rollback-payload';
    final bytes = Uint8List.fromList([6, 2, 6, 4]);
    final storedItems = Hive.box<dynamic>('stashhive_items_v1');
    final storedAttachments = Hive.box<dynamic>('stashhive_attachments_v1');
    await storedItems.put(itemId, <String, Object?>{
      'id': itemId,
      'kind': 'unknown-kind',
      'attachmentKey': attachmentKey,
    });
    await storedAttachments.put(attachmentKey, bytes);
    repository.dispose();
    repository = await LibraryRepository.openInitializedForTesting();

    LibraryRepository.deleteAfterAttachmentDeleteForTesting = () async {
      throw StateError('simulated error after attachment removal');
    };
    try {
      await expectLater(
        repository.delete(itemId),
        throwsA(isA<StateError>()),
      );
    } finally {
      LibraryRepository.deleteAfterAttachmentDeleteForTesting = null;
    }

    expect(storedItems.get(itemId), isA<Map>());
    expect(storedAttachments.containsKey(attachmentKey), isTrue);
    expect(await repository.readAttachment(attachmentKey), orderedEquals(bytes));
    expect(repository.skippedRecordCount.value, 1);
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

  test('skips a raw record with an oversized saved-item kind', () async {
    const itemId = 'oversized-kind-record';
    await Hive.box<dynamic>('stashhive_items_v1').put(
      itemId,
      <String, Object?>{
        'id': itemId,
        'kind': List<String>.filled(100000, 'x').join(),
        'title': 'Malformed type',
        'content': '',
        'tags': <String>[],
        'isFavorite': false,
        'createdAtMs': 1000,
        'updatedAtMs': 1000,
      },
    );
    await repository.save(buildLink(id: 'valid-beside-oversized-kind'));
    repository.dispose();
    repository = await LibraryRepository.openInitializedForTesting();

    expect(repository.skippedRecordCount.value, 1);
    expect(repository.findById(itemId), isNull);
    expect(
      repository.items.value.map((item) => item.id),
      ['valid-beside-oversized-kind'],
    );
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
    expect(repository.findById('oversized-legacy-content'), isNull);
    expect(repository.findById('out-of-range-timestamp'), isNull);
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

  test('repository refuses to overwrite an unrelated orphan payload', () async {
    const orphanKey = 'orphan-image-id';
    final orphanBytes = Uint8List.fromList([14, 15, 16, 17]);
    await Hive.box<dynamic>('stashhive_attachments_v1')
        .put(orphanKey, orphanBytes.toList());
    final incoming = buildImage(id: orphanKey, attachmentKey: orphanKey);

    await expectLater(
      repository.save(
        incoming,
        attachmentBytes: Uint8List.fromList([99, 98, 97]),
      ),
      throwsFormatException,
    );

    expect(repository.findById(orphanKey), isNull);
    expect(
      await repository.readAttachment(orphanKey),
      orderedEquals(orphanBytes),
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
