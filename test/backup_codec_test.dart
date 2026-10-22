import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stashhive/models/saved_item.dart';
import 'package:stashhive/services/backup_codec.dart';

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

    test('rejects files which are not StashHive backups', () {
      expect(
        () => BackupCodec.decode(jsonEncode({'app': 'OtherApp', 'formatVersion': 1})),
        throwsFormatException,
      );
    });

    test('rejects unknown format versions', () {
      expect(
        () => BackupCodec.decode(jsonEncode({
          'app': 'StashHive',
          'formatVersion': 999,
          'items': [],
          'attachments': {},
        })),
        throwsFormatException,
      );
    });

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
  });
}
