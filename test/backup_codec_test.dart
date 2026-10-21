import 'dart:convert';
import 'dart:typed_data';

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
