import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stashhive/models/saved_item.dart';
import 'package:stashhive/services/backup_codec.dart';

final class _OversizedGuardedTagList extends ListBase<String> {
  @override
  int get length => 101;

  @override
  set length(int value) => throw UnsupportedError('This list has a fixed size.');

  @override
  String operator [](int index) =>
      throw StateError('Oversized tags were copied before validation.');

  @override
  void operator []=(int index, String value) =>
      throw UnsupportedError('This list is immutable.');
}

SavedItem sampleLink() => SavedItem(
      id: 'link-1',
      kind: ItemKind.link,
      title: 'Flutter',
      content: 'Read storage documentation later.',
      url: 'https://flutter.dev',
      tags: const ['Flutter', 'Reading'],
      collection: 'Learning',
      isFavorite: true,
      createdAtMs: 1000,
      updatedAtMs: 2000,
    );

void main() {
  group('BackupCodec', () {
    test('counts UTF-8 bytes without allocating an encoded buffer', () {
      for (final value in <String>[
        'plain ASCII',
        'قابلِ تلاش متن',
        'An emoji: 😀🧰',
      ]) {
        expect(
          BackupCodec.utf8ByteLength(value),
          utf8.encode(value).length,
          reason: 'The byte count must match UTF-8 for ${value.runtimeType}.',
        );
      }
      expect(BackupCodec.utf8ByteLength('abc'), 3);
      expect(BackupCodec.utf8ByteLength('😀'), 4);
      expect('😀'.length, 2);
    });

    test(
      'rejects oversized tag lists before copying caller-owned tags',
      () {
        final item = sampleLink().copyWith(tags: _OversizedGuardedTagList());

        Matcher tagLimitError() => throwsA(
              isA<FormatException>().having(
                (error) => error.message,
                'message',
                'A saved item exceeds supported limits.',
              ),
            );

        expect(() => BackupCodec.validateSavedItem(item), tagLimitError());
        expect(
          () => BackupCodec.encode(
            items: [item],
            attachmentBytes: const <String, Uint8List>{},
            collections: const <String>[],
          ),
          tagLimitError(),
        );
        expect(
          () => BackupCodec.validateDecodedBackup(
            DecodedBackup(
              items: [item],
              attachments: const <String, BackupAttachment>{},
              collections: const <String>[],
              exportedAt: '2026-10-28T00:00:00Z',
            ),
          ),
          tagLimitError(),
        );
      },
    );

    test('calculates a safe preflight for base64 decoded-byte budgets', () {
      expect(BackupCodec.maxBase64CharactersForDecodedBytes(0), 0);
      expect(BackupCodec.maxBase64CharactersForDecodedBytes(1), 4);
      expect(BackupCodec.maxBase64CharactersForDecodedBytes(2), 4);
      expect(BackupCodec.maxBase64CharactersForDecodedBytes(3), 4);
      expect(BackupCodec.maxBase64CharactersForDecodedBytes(4), 8);
      expect(
        () => BackupCodec.maxBase64CharactersForDecodedBytes(-1),
        throwsArgumentError,
      );
    });

    test('validates repository item counts against the backup limit', () {
      expect(
        () => BackupCodec.validateItemCount(
          currentCount: BackupCodec.maxItems - 1,
          incomingCount: 1,
        ),
        returnsNormally,
      );
      expect(
        () => BackupCodec.validateItemCount(
          currentCount: BackupCodec.maxItems,
          incomingCount: 0,
        ),
        returnsNormally,
      );
      expect(
        () => BackupCodec.validateItemCount(
          currentCount: BackupCodec.maxItems,
          incomingCount: 1,
        ),
        throwsFormatException,
      );
      expect(
        () => BackupCodec.validateItemCount(
          currentCount: -1,
          incomingCount: 0,
        ),
        throwsFormatException,
      );
    });

    test('revalidates manually constructed decoded backups', () {
      final image = SavedItem(
        id: 'decoded-image',
        kind: ItemKind.image,
        title: 'Decoded image',
        content: '',
        tags: const ['Reference'],
        collection: 'Ideas',
        isFavorite: false,
        createdAtMs: 1000,
        updatedAtMs: 2000,
        attachmentKey: 'decoded-image',
        attachmentName: 'image.png',
        attachmentMimeType: 'image/png',
      );

      final valid = DecodedBackup(
        items: [image],
        attachments: {
          'decoded-image': BackupAttachment(
            name: 'image.png',
            mimeType: 'image/png',
            bytes: Uint8List.fromList([1, 2, 3]),
          ),
        },
        collections: const ['Ideas'],
        exportedAt: '2026-10-22T00:00:00Z',
      );
      expect(() => BackupCodec.validateDecodedBackup(valid), returnsNormally);

      final missingPayload = DecodedBackup(
        items: [image],
        attachments: const {},
        collections: const ['Ideas'],
        exportedAt: '2026-10-22T00:00:00Z',
      );
      expect(
        () => BackupCodec.validateDecodedBackup(missingPayload),
        throwsFormatException,
      );

      final invalidMetadata = DecodedBackup(
        items: [image],
        attachments: {
          'decoded-image': BackupAttachment(
            name: ' ',
            mimeType: 'image/png',
            bytes: Uint8List.fromList([1, 2, 3]),
          ),
        },
        collections: const ['Ideas'],
        exportedAt: '2026-10-22T00:00:00Z',
      );
      expect(
        () => BackupCodec.validateDecodedBackup(invalidMetadata),
        throwsFormatException,
      );

      final duplicateIds = DecodedBackup(
        items: [sampleLink(), sampleLink()],
        attachments: const {},
        collections: const ['Learning'],
        exportedAt: '2026-10-22T00:00:00Z',
      );
      expect(
        () => BackupCodec.validateDecodedBackup(duplicateIds),
        throwsFormatException,
      );
    });

    test('keeps legacy case-only collection duplicates normalizable', () {
      final source = BackupCodec.encode(
        items: [sampleLink()],
        attachmentBytes: const {},
        collections: const ['Learning'],
      );
      final payload = jsonDecode(source) as Map<String, dynamic>;
      payload['collections'] = <String>['Learning', 'learning'];

      final decoded = BackupCodec.decode(jsonEncode(payload));
      expect(
        () => BackupCodec.validateDecodedBackup(decoded),
        returnsNormally,
      );
      expect(decoded.collections, ['Learning', 'learning']);
    });

    test('round-trips omission metadata and old backups default to complete', () {
      final completeBackup = BackupCodec.encode(
        items: [sampleLink()],
        attachmentBytes: const {},
        collections: const ['Learning'],
      );
      final completeDecoded = BackupCodec.decode(completeBackup);
      expect(completeDecoded.omittedUnreadableRecordCount, 0);
      expect(completeDecoded.omittedCollectionEntryCount, 0);
      expect(completeDecoded.omittedUnexportableRecordCount, 0);

      final partialBackup = BackupCodec.encode(
        items: [sampleLink()],
        attachmentBytes: const {},
        collections: const ['Learning'],
        omittedUnreadableRecordCount: 3,
        omittedCollectionEntryCount: 2,
        omittedUnexportableRecordCount: 4,
      );
      final partialDecoded = BackupCodec.decode(partialBackup);
      expect(partialDecoded.omittedUnreadableRecordCount, 3);
      expect(partialDecoded.omittedCollectionEntryCount, 2);
      expect(partialDecoded.omittedUnexportableRecordCount, 4);
    });

    test('rejects malformed partial-backup omission metadata', () {
      final valid = BackupCodec.encode(
        items: [sampleLink()],
        attachmentBytes: const {},
        collections: const ['Learning'],
      );
      for (final invalidCount in <Object?>[-1, 1.5, 'two']) {
        final badCollectionCount =
            jsonDecode(valid) as Map<String, dynamic>;
        badCollectionCount['omittedCollectionEntryCount'] = invalidCount;
        expect(
          () => BackupCodec.decode(jsonEncode(badCollectionCount)),
          throwsFormatException,
          reason: 'Collection omission metadata must be a non-negative integer.',
        );

        final badRecordCount = jsonDecode(valid) as Map<String, dynamic>;
        badRecordCount['omittedUnreadableRecordCount'] = invalidCount;
        expect(
          () => BackupCodec.decode(jsonEncode(badRecordCount)),
          throwsFormatException,
          reason: 'Record omission metadata must be a non-negative integer.',
        );

        final badUnexportableCount = jsonDecode(valid) as Map<String, dynamic>;
        badUnexportableCount['omittedUnexportableRecordCount'] = invalidCount;
        expect(
          () => BackupCodec.decode(jsonEncode(badUnexportableCount)),
          throwsFormatException,
          reason: 'Unexportable record metadata must be a non-negative integer.',
        );
      }
    });

    test('round-trips items and collection names', () {
      final json = BackupCodec.encode(
        items: [sampleLink()],
        attachmentBytes: <String, Uint8List>{},
        collections: const ['Learning'],
      );
      final decoded = BackupCodec.decode(json);

      expect(decoded.items, hasLength(1));
      expect(decoded.items.single.title, 'Flutter');
      expect(decoded.items.single.isFavorite, isTrue);
      expect(decoded.collections, contains('Learning'));
      expect(decoded.exportedAt, isNotEmpty);
    });

    test('round-trips a copied attachment', () {
      final bytes = Uint8List.fromList([1, 2, 3, 4, 255]);
      final image = SavedItem(
        id: 'image-1',
        kind: ItemKind.image,
        title: 'Local image',
        content: 'Concept reference',
        tags: const ['Design'],
        collection: null,
        isFavorite: false,
        createdAtMs: 1000,
        updatedAtMs: 2000,
        attachmentKey: 'image-1',
        attachmentName: 'concept.png',
        attachmentMimeType: 'image/png',
      );
      final json = BackupCodec.encode(
        items: [image],
        attachmentBytes: {'image-1': bytes},
        collections: const [],
      );
      final decoded = BackupCodec.decode(json);

      expect(decoded.attachments['image-1']!.name, 'concept.png');
      expect(decoded.attachments['image-1']!.bytes, orderedEquals(bytes));
      expect(decoded.items.single.hasAttachment, isTrue);
    });


    test('preflight accepts UTF-8 and escaped attachment metadata accurately', () {
      final keys = <String>[
        'plain-key',
        'quoted"key',
        r'back\\slash',
        '图像-🚀',
      ];
      final payloads = <String, Uint8List>{
        for (var index = 0; index < keys.length; index++)
          keys[index]: Uint8List.fromList(
            List<int>.generate(index + 1, (byte) => (byte * 41 + 7) % 256),
          ),
      };
      final items = <SavedItem>[
        for (var index = 0; index < keys.length; index++)
          SavedItem(
            id: 'preflight-image-$index',
            kind: ItemKind.image,
            title: index == 0 ? 'Café "launch" 🚀' : 'Image $index',
            content: 'ملاحظة; path: C:\\design; emoji 🚀',
            tags: const ['设计', 'emoji 🚀'],
            collection: 'Ideas / 设计',
            isFavorite: index.isEven,
            createdAtMs: 1000 + index,
            updatedAtMs: 2000 + index,
            attachmentKey: keys[index],
            attachmentName: index == 0 ? '方案 "A" 🚀.png' : 'image-$index.png',
            attachmentMimeType: 'image/png',
          ),
      ];

      final json = BackupCodec.encode(
        items: items,
        attachmentBytes: payloads,
        collections: const ['Ideas / 设计'],
      );

      expect(BackupCodec.utf8ByteLength(json), utf8.encode(json).length);
      expect(BackupCodec.utf8ByteLength(json), lessThanOrEqualTo(
        BackupCodec.maxBackupBytes,
      ));

      final decoded = BackupCodec.decode(json);
      expect(decoded.items, hasLength(keys.length));
      for (final key in keys) {
        expect(
          decoded.attachments[key]!.bytes,
          orderedEquals(payloads[key]!),
          reason: 'Preflight must preserve payload bytes for attachment key $key.',
        );
      }
    });

    test('exports a shared attachment payload only once', () {
      final first = SavedItem(
        id: 'image-1',
        kind: ItemKind.image,
        title: 'First view',
        content: '',
        tags: const [],
        collection: null,
        isFavorite: false,
        createdAtMs: 1000,
        updatedAtMs: 1000,
        attachmentKey: 'shared-image',
        attachmentName: 'shared.png',
        attachmentMimeType: 'image/png',
      );
      final second = SavedItem(
        id: 'image-2',
        kind: ItemKind.image,
        title: 'Second view',
        content: '',
        tags: const [],
        collection: null,
        isFavorite: false,
        createdAtMs: 1000,
        updatedAtMs: 1000,
        attachmentKey: 'shared-image',
        attachmentName: 'shared.png',
        attachmentMimeType: 'image/png',
      );
      final bytes = Uint8List.fromList([1, 2, 3, 4]);
      final json = BackupCodec.encode(
        items: [first, second],
        attachmentBytes: {'shared-image': bytes},
        collections: const [],
      );

      final decoded = BackupCodec.decode(json);
      expect(decoded.attachments.keys, ['shared-image']);
      expect(decoded.items, hasLength(2));
      expect(
        decoded.items.map((item) => item.attachmentKey),
        everyElement('shared-image'),
      );
    });

    test('counts shared attachment bytes only once against the backup limit', () {
      final bytes = Uint8List(13 * 1024 * 1024);
      final items = List<SavedItem>.generate(
        8,
        (index) => SavedItem(
          id: 'shared-large-$index',
          kind: ItemKind.image,
          title: 'View $index',
          content: '',
          tags: const [],
          collection: null,
          isFavorite: false,
          createdAtMs: 1000,
          updatedAtMs: 1000,
          attachmentKey: 'shared-large',
          attachmentName: 'large.png',
          attachmentMimeType: 'image/png',
        ),
      );

      final json = BackupCodec.encode(
        items: items,
        attachmentBytes: {'shared-large': bytes},
        collections: const [],
      );

      final decoded = BackupCodec.decode(json);
      expect(decoded.items, hasLength(8));
      expect(decoded.attachments.keys, ['shared-large']);
      expect(decoded.attachments['shared-large']!.bytes, hasLength(bytes.length));
    });

    test('rejects invalid attachment references on export', () {
      SavedItem image({String? attachmentKey}) => SavedItem(
            id: 'image',
            kind: ItemKind.image,
            title: 'Image',
            content: '',
            tags: const [],
            collection: null,
            isFavorite: false,
            createdAtMs: 1000,
            updatedAtMs: 1000,
            attachmentKey: attachmentKey,
            attachmentName: 'image.png',
            attachmentMimeType: 'image/png',
          );
      final noteWithAttachment = SavedItem(
        id: 'note-with-attachment',
        kind: ItemKind.note,
        title: 'Invalid note',
        content: 'This kind must not reference image/file bytes.',
        tags: const [],
        collection: null,
        isFavorite: false,
        createdAtMs: 1000,
        updatedAtMs: 1000,
        attachmentKey: 'unexpected',
        attachmentName: 'unexpected.bin',
        attachmentMimeType: 'application/octet-stream',
      );

      expect(
        () => BackupCodec.encode(
          items: [image()],
          attachmentBytes: const {},
          collections: const [],
        ),
        throwsFormatException,
      );
      expect(
        () => BackupCodec.encode(
          items: [image(attachmentKey: '')],
          attachmentBytes: const {},
          collections: const [],
        ),
        throwsFormatException,
      );
      expect(
        () => BackupCodec.encode(
          items: [noteWithAttachment],
          attachmentBytes: {
            'unexpected': Uint8List.fromList([1, 2, 3]),
          },
          collections: const [],
        ),
        throwsFormatException,
      );
    });

    test('writes attachment checksums and rejects modified payload bytes', () {
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final image = SavedItem(
        id: 'image-checksum',
        kind: ItemKind.image,
        title: 'Checksum reference',
        content: '',
        tags: const [],
        collection: null,
        isFavorite: false,
        createdAtMs: 1000,
        updatedAtMs: 1000,
        attachmentKey: 'image-checksum',
        attachmentName: 'checksum.png',
        attachmentMimeType: 'image/png',
      );
      final source = BackupCodec.encode(
        items: [image],
        attachmentBytes: {'image-checksum': bytes},
        collections: const [],
      );
      final payload = jsonDecode(source) as Map<String, dynamic>;
      final attachments =
          payload['attachments'] as Map<String, dynamic>;
      final attachment =
          attachments['image-checksum'] as Map<String, dynamic>;

      expect(attachment['sha256'], sha256.convert(bytes).toString());
      attachment['base64'] = base64Encode([9, 8, 7, 6, 5]);

      expect(
        () => BackupCodec.decode(jsonEncode(payload)),
        throwsFormatException,
      );
    });

    test('accepts legacy version-one backups without attachment checksums', () {
      final bytes = Uint8List.fromList([1, 2, 3]);
      final image = SavedItem(
        id: 'legacy-image',
        kind: ItemKind.image,
        title: 'Legacy backup',
        content: '',
        tags: const [],
        collection: null,
        isFavorite: false,
        createdAtMs: 1000,
        updatedAtMs: 1000,
        attachmentKey: 'legacy-image',
        attachmentName: 'legacy.png',
        attachmentMimeType: 'image/png',
      );
      final source = BackupCodec.encode(
        items: [image],
        attachmentBytes: {'legacy-image': bytes},
        collections: const [],
      );
      final payload = jsonDecode(source) as Map<String, dynamic>;
      final attachments = payload['attachments'] as Map<String, dynamic>;
      (attachments['legacy-image'] as Map<String, dynamic>).remove('sha256');

      final decoded = BackupCodec.decode(jsonEncode(payload));
      expect(
        decoded.attachments['legacy-image']!.bytes,
        orderedEquals(bytes),
      );
    });

    test('export rejects empty, untrimmed or case-duplicate tags', () {
      for (final tags in <List<String>>[
        const [''],
        const ['   '],
        const ['Reading '],
        const ['Reading', 'reading'],
      ]) {
        expect(
          () => BackupCodec.encode(
            items: [sampleLink().copyWith(tags: tags)],
            attachmentBytes: const {},
            collections: const ['Learning'],
          ),
          throwsFormatException,
          reason: 'Invalid tag lists should not enter portable backups.',
        );
      }
    });

    test('rejects oversized aggregate item JSON before full backup serialization', () {
      // Reuse one moderate input string across many records: after JSON
      // escaping, the combined export exceeds the portable byte cap without
      // requiring a huge fixture allocation.
      final largeContent = ''.padRight(750000, '\n');
      final items = List<SavedItem>.generate(
        105,
        (index) => SavedItem(
          id: 'large-content-$index',
          kind: ItemKind.link,
          title: 'Large content $index',
          content: largeContent,
          url: 'https://example.com/$index',
          tags: const [],
          collection: null,
          isFavorite: false,
          createdAtMs: 1000,
          updatedAtMs: index + 1000,
        ),
      );

      expect(
        () => BackupCodec.encode(
          items: items,
          attachmentBytes: const {},
          collections: const [],
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('too large to share or restore'),
          ),
        ),
      );
    });

    test('export rejects duplicate saved-item IDs', () {
      final original = sampleLink();
      final conflicting = original.copyWith(
        title: 'Different title, same identifier',
        updatedAtMs: original.updatedAtMs + 1,
      );

      expect(
        () => BackupCodec.encode(
          items: [original, conflicting],
          attachmentBytes: const {},
          collections: const ['Learning'],
        ),
        throwsFormatException,
      );
    });

    test('export rejects saved URLs the restore format cannot accept', () {
      final overlongUrl = 'https://example.com/' +
          List<String>.filled(maxSavedItemUrlCharacters, 'a').join();
      expect(overlongUrl.length, greaterThan(maxSavedItemUrlCharacters));

      expect(
        () => BackupCodec.encode(
          items: [sampleLink().copyWith(url: overlongUrl)],
          attachmentBytes: const {},
          collections: const ['Learning'],
        ),
        throwsFormatException,
      );
    });

    test('export rejects attachment metadata that restore would reject', () {
      final image = SavedItem(
        id: 'bad-meta-image',
        kind: ItemKind.image,
        title: 'Bad metadata',
        content: '',
        tags: const [],
        collection: null,
        isFavorite: false,
        createdAtMs: 1000,
        updatedAtMs: 1000,
        attachmentKey: 'bad-meta-image',
        attachmentName: '   ',
        attachmentMimeType: 'image/png',
      );

      expect(
        () => BackupCodec.encode(
          items: [image],
          attachmentBytes: {
            'bad-meta-image': Uint8List.fromList([1, 2, 3]),
          },
          collections: const [],
        ),
        throwsFormatException,
      );
    });

    test('rejects empty attachment bytes during export and restore', () {
      final image = SavedItem(
        id: 'empty-image',
        kind: ItemKind.image,
        title: 'Empty image',
        content: '',
        tags: const [],
        collection: null,
        isFavorite: false,
        createdAtMs: 1000,
        updatedAtMs: 1000,
        attachmentKey: 'empty-image',
        attachmentName: 'empty.png',
        attachmentMimeType: 'image/png',
      );

      expect(
        () => BackupCodec.encode(
          items: [image],
          attachmentBytes: {'empty-image': Uint8List(0)},
          collections: const [],
        ),
        throwsFormatException,
      );

      final payload = <String, Object?>{
        'app': 'StashHive',
        'formatVersion': BackupCodec.formatVersion,
        'exportedAt': '2026-10-22T00:00:00Z',
        'collections': <String>[],
        'items': [image.toMap()],
        'attachments': <String, Object?>{
          'empty-image': <String, Object?>{
            'name': 'empty.png',
            'mimeType': 'image/png',
            'base64': '',
          },
        },
      };
      expect(
        () => BackupCodec.decode(jsonEncode(payload)),
        throwsFormatException,
      );
    });

    test('rejects attachment metadata without an attachment reference', () {
      final linkWithStaleMetadata = sampleLink().copyWith(
        attachmentName: 'old-image.png',
        attachmentMimeType: 'image/png',
      );

      expect(
        () => BackupCodec.encode(
          items: [linkWithStaleMetadata],
          attachmentBytes: const {},
          collections: const ['Learning'],
        ),
        throwsFormatException,
      );
    });

    test('export rejects an empty or whitespace-only note', () {
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

      expect(
        () => BackupCodec.encode(
          items: [emptyNote],
          attachmentBytes: const {},
          collections: const [],
        ),
        throwsFormatException,
      );
    });

    test('export rejects timestamps outside the supported date range', () {
      final invalidDate = sampleLink().copyWith(
        updatedAtMs: 9000000000000000,
      );

      expect(
        () => BackupCodec.encode(
          items: [invalidDate],
          attachmentBytes: const {},
          collections: const ['Learning'],
        ),
        throwsFormatException,
      );
    });

    test('rejects orphan attachment payloads before decoding base64', () {
      final source = jsonEncode(<String, Object?>{
        'app': 'StashHive',
        'formatVersion': BackupCodec.formatVersion,
        'exportedAt': '2026-10-22T00:00:00Z',
        'collections': <String>[],
        'items': <Object?>[],
        'attachments': <String, Object?>{
          'orphan-key': <String, Object?>{
            'name': 'unused.png',
            'mimeType': 'image/png',
            // Invalid base64 makes this prove the reference check happens
            // before the decoder tries to allocate/decode this unused entry.
            'base64': '%%%not-base64%%%',
          },
        },
      });

      expect(
        () => BackupCodec.decode(source),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('no saved item references'),
          ),
        ),
      );
    });

    test('restore preflight rejects orphan attachments in a decoded object', () {
      final decoded = DecodedBackup(
        items: [sampleLink()],
        attachments: {
          'unused-payload': BackupAttachment(
            name: 'unused.png',
            mimeType: 'image/png',
            bytes: Uint8List.fromList([1, 2, 3]),
          ),
        },
        collections: const [],
        exportedAt: '2026-10-22T00:00:00Z',
      );

      expect(
        () => BackupCodec.validateDecodedBackup(decoded),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('no saved item references'),
          ),
        ),
      );
    });

    test('rejects files which are not StashHive backups', () {
      expect(
        () => BackupCodec.decode(jsonEncode({'app': 'OtherApp', 'formatVersion': 1})),
        throwsFormatException,
      );
    });

    test('rejects unknown format versions with the numeric version', () {
      expect(
        () => BackupCodec.decode(jsonEncode({
          'app': 'StashHive',
          'formatVersion': 999,
          'items': [],
          'attachments': {},
        })),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'Unsupported backup version: 999.',
          ),
        ),
      );
    });

    test(
      'does not echo a large malformed format-version field into errors',
      () {
        final rawVersion = List<String>.filled(100000, 'x').join();
        final source = jsonEncode(<String, Object?>{
          'app': 'StashHive',
          'formatVersion': rawVersion,
        });

        expect(
          () => BackupCodec.decode(source),
          throwsA(
            isA<FormatException>().having(
              (error) => error.message,
              'message',
              'The backup format version is invalid.',
            ),
          ),
        );
      },
    );

    test('rejects unsafe or invalid URL schemes', () {
      final item = sampleLink().copyWith(url: 'javascript:alert(1)');
      final payload = <String, Object?>{
        'app': 'StashHive',
        'formatVersion': BackupCodec.formatVersion,
        'exportedAt': '2026-10-21T00:00:00Z',
        'collections': [],
        'items': [item.toMap()],
        'attachments': {},
      };
      expect(() => BackupCodec.decode(jsonEncode(payload)), throwsFormatException);
    });

    test('rejects saved-item fields with invalid types instead of defaulting them', () {
      final malformedItem = <String, Object?>{
        ...sampleLink().toMap(),
        'content': 42,
      };
      final payload = <String, Object?>{
        'app': 'StashHive',
        'formatVersion': BackupCodec.formatVersion,
        'exportedAt': '2026-10-21T00:00:00Z',
        'collections': ['Learning'],
        'items': [malformedItem],
        'attachments': <String, Object?>{},
      };

      expect(() => BackupCodec.decode(jsonEncode(payload)), throwsFormatException);
    });

    test('preserves item-assigned collections missing from the top-level list', () {
      final json = BackupCodec.encode(
        items: [sampleLink().copyWith(collection: 'Research')],
        attachmentBytes: <String, Uint8List>{},
        collections: const [],
      );

      final decoded = BackupCodec.decode(json);

      expect(decoded.collections, contains('Research'));
      expect(decoded.items.single.collection, 'Research');
    });

    test('canonicalizes assigned collection names case-insensitively', () {
      final json = BackupCodec.encode(
        items: [sampleLink().copyWith(collection: 'research')],
        attachmentBytes: <String, Uint8List>{},
        collections: const ['Research'],
      );

      final decoded = BackupCodec.decode(json);

      expect(decoded.collections, ['Research']);
      expect(decoded.items.single.collection, 'Research');
    });

    test('rejects attachment payloads not referenced by any item', () {
      final payload = <String, Object?>{
        'app': 'StashHive',
        'formatVersion': BackupCodec.formatVersion,
        'exportedAt': '2026-10-21T00:00:00Z',
        'collections': ['Learning'],
        'items': [sampleLink().toMap()],
        'attachments': <String, Object?>{
          'orphan': <String, Object?>{
            'name': 'orphan.bin',
            'mimeType': 'application/octet-stream',
            'base64': 'AQID',
          },
        },
      };

      expect(() => BackupCodec.decode(jsonEncode(payload)), throwsFormatException);
    });

    test('rejects backup records with missing attachment bytes', () {
      final item = SavedItem(
        id: 'image-1',
        kind: ItemKind.image,
        title: 'An image',
        content: '',
        tags: const [],
        collection: null,
        isFavorite: false,
        createdAtMs: 1000,
        updatedAtMs: 1000,
        attachmentKey: 'missing',
        attachmentName: 'image.png',
        attachmentMimeType: 'image/png',
      );
      final payload = <String, Object?>{
        'app': 'StashHive',
        'formatVersion': BackupCodec.formatVersion,
        'items': [item.toMap()],
        'attachments': {},
        'collections': [],
      };
      expect(() => BackupCodec.decode(jsonEncode(payload)), throwsFormatException);
    });

    test(
      'rejects more attachment entries than saved items',
      () {
        final oneAttachment = BackupAttachment(
          name: 'orphan.bin',
          mimeType: 'application/octet-stream',
          bytes: Uint8List.fromList([1]),
        );
        final tooManyInMemory = <String, BackupAttachment>{
          for (var i = 0; i <= BackupCodec.maxItems; i++)
            'orphan-$i': oneAttachment,
        };
        final decoded = DecodedBackup(
          items: [sampleLink()],
          attachments: tooManyInMemory,
          collections: const [],
          exportedAt: '2026-10-28T00:00:00Z',
        );

        expect(
          () => BackupCodec.validateDecodedBackup(decoded),
          throwsA(
            isA<FormatException>().having(
              (error) => error.message,
              'message',
              'The backup contains more attachment entries than saved items.',
            ),
          ),
        );

        final tooManyJsonEntries = <String, Object?>{
          for (var i = 0; i <= BackupCodec.maxItems; i++)
            'orphan-$i': <String, Object?>{},
        };
        final source = jsonEncode(<String, Object?>{
          'app': 'StashHive',
          'formatVersion': BackupCodec.formatVersion,
          'exportedAt': '2026-10-28T00:00:00Z',
          'collections': <String>[],
          'items': <Object?>[sampleLink().toMap()],
          'attachments': tooManyJsonEntries,
        });

        expect(
          () => BackupCodec.decode(source),
          throwsA(
            isA<FormatException>().having(
              (error) => error.message,
              'message',
              'The backup contains more attachment entries than saved items.',
            ),
          ),
        );
      },
    );

    test('preserves the version-1 StashHive marker for backup compatibility', () {
      final legacyPayload = <String, Object?>{
        'app': 'StashHive',
        'formatVersion': BackupCodec.formatVersion,
        'exportedAt': '2026-10-22T00:00:00Z',
        'collections': <String>['Learning'],
        'items': <Object?>[sampleLink().toMap()],
        'attachments': <String, Object?>{},
      };

      final decoded = BackupCodec.decode(jsonEncode(legacyPayload));
      final reencoded = BackupCodec.encode(
        items: decoded.items,
        attachmentBytes: const {},
        collections: decoded.collections,
      );

      expect(jsonDecode(reencoded)['app'], 'StashHive');
    });
  });
}
