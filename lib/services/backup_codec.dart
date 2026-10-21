import 'dart:convert';
import 'dart:typed_data';

import '../models/saved_item.dart';

class BackupAttachment {
  const BackupAttachment({
    required this.name,
    required this.mimeType,
    required this.bytes,
  });

  final String name;
  final String mimeType;
  final Uint8List bytes;
}

class DecodedBackup {
  const DecodedBackup({
    required this.items,
    required this.attachments,
    required this.collections,
    required this.exportedAt,
  });

  final List<SavedItem> items;
  final Map<String, BackupAttachment> attachments;
  final List<String> collections;
  final String exportedAt;
}

class BackupCodec {
  BackupCodec._();

  static const int formatVersion = 1;
  static const int maxItems = 10000;
  static const int maxAttachmentBytes = 15 * 1024 * 1024;
  static const int maxTotalAttachmentBytes = 100 * 1024 * 1024;
  static const int maxJsonCharacters = 145 * 1024 * 1024;

  static String encode({
    required List<SavedItem> items,
    required Map<String, Uint8List> attachmentBytes,
    required List<String> collections,
  }) {
    if (items.length > maxItems) {
      throw const FormatException('The library contains too many items to export.');
    }
    final attachments = <String, Object?>{};
    var totalBytes = 0;
    for (final item in items) {
      final key = item.attachmentKey;
      if (key == null || key.isEmpty) continue;
      final bytes = attachmentBytes[key];
      if (bytes == null) {
        throw FormatException(
          'The local attachment for "' + item.title + '" is missing. '
          'It was not included in the backup.',
        );
      }
      if (bytes.length > maxAttachmentBytes) {
        throw const FormatException('An attachment exceeds the 15 MB backup limit.');
      }
      totalBytes += bytes.length;
      if (totalBytes > maxTotalAttachmentBytes) {
        throw const FormatException('The combined attachments exceed 100 MB.');
      }
      attachments[key] = <String, Object?>{
        'name': item.attachmentName ?? 'attachment',
        'mimeType': item.attachmentMimeType ?? 'application/octet-stream',
        'base64': base64Encode(bytes),
      };
    }
    final output = jsonEncode(<String, Object?>{
      'app': 'StashHive',
      'formatVersion': formatVersion,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'collections': collections,
      'items': items.map((item) => item.toMap()).toList(),
      'attachments': attachments,
    });
    if (output.length > maxJsonCharacters) {
      throw const FormatException('The backup is too large to share or restore.');
    }
    return output;
  }

  static DecodedBackup decode(String source) {
    if (source.length > maxJsonCharacters) {
      throw const FormatException('The backup file is too large to import.');
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('The selected file is not valid JSON.');
    }
    if (decoded is! Map) {
      throw const FormatException('The backup file has an invalid structure.');
    }
    if (decoded['app'] != 'StashHive') {
      throw const FormatException('This file is not a StashHive backup.');
    }
    if (decoded['formatVersion'] != formatVersion) {
      throw FormatException(
        'Unsupported backup version: ' + (decoded['formatVersion']?.toString() ?? 'unknown') + '.',
      );
    }
    final itemsValue = decoded['items'];
    final attachmentsValue = decoded['attachments'];
    final collectionsValue = decoded['collections'];
    if (itemsValue is! List || attachmentsValue is! Map) {
      throw const FormatException('The backup is missing required data.');
    }
    if (itemsValue.length > maxItems) {
      throw const FormatException('The backup contains too many items.');
    }

    final items = <SavedItem>[];
    final ids = <String>{};
    for (final value in itemsValue) {
      if (value is! Map) {
        throw const FormatException('A saved item in the backup is invalid.');
      }
      final item = SavedItem.fromMap(value);
      if (item.id.isEmpty || item.id.length > 128) {
        throw const FormatException('A saved item has an invalid identifier.');
      }
      if (item.title.trim().isEmpty || item.title.length > 500) {
        throw const FormatException('A saved item has an invalid title.');
      }
      if (!ids.add(item.id)) {
        throw const FormatException('The backup contains duplicate item IDs.');
      }
      if (item.content.length > 1000000 ||
          (item.url?.length ?? 0) > 4096 ||
          item.tags.length > 100 ||
          item.tags.any((tag) => tag.length > 100)) {
        throw const FormatException('A saved item exceeds supported limits.');
      }
      if (item.kind == ItemKind.link) {
        final uri = Uri.tryParse(item.url ?? '');
        if (uri == null ||
            (uri.scheme != 'https' && uri.scheme != 'http') ||
            uri.host.isEmpty) {
          throw const FormatException('A saved link in the backup is invalid.');
        }
      }
      if ((item.kind == ItemKind.image || item.kind == ItemKind.document) &&
          !item.hasAttachment) {
        throw const FormatException(
          'An image or document item has no local attachment reference.',
        );
      }
      items.add(item);
    }

    final attachments = <String, BackupAttachment>{};
    var totalBytes = 0;
    for (final entry in attachmentsValue.entries) {
      if (entry.key is! String || entry.value is! Map) {
        throw const FormatException('An attachment entry is invalid.');
      }
      final key = entry.key as String;
      final value = entry.value as Map;
      final name = value['name'];
      final mimeType = value['mimeType'];
      final encoded = value['base64'];
      if (name is! String ||
          name.isEmpty ||
          name.length > 255 ||
          mimeType is! String ||
          mimeType.length > 128 ||
          encoded is! String ||
          encoded.length > ((maxAttachmentBytes * 4 ~/ 3) + 8)) {
        throw const FormatException('An attachment entry exceeds supported limits.');
      }
      final Uint8List bytes;
      try {
        bytes = Uint8List.fromList(base64Decode(encoded));
      } on FormatException {
        throw const FormatException('An attachment contains invalid base64 data.');
      }
      if (bytes.length > maxAttachmentBytes) {
        throw const FormatException('An attachment exceeds 15 MB.');
      }
      totalBytes += bytes.length;
      if (totalBytes > maxTotalAttachmentBytes) {
        throw const FormatException('Combined attachments exceed 100 MB.');
      }
      attachments[key] = BackupAttachment(
        name: name,
        mimeType: mimeType,
        bytes: bytes,
      );
    }

    final referencedAttachmentKeys = items
        .where((item) => item.hasAttachment)
        .map((item) => item.attachmentKey!)
        .toSet();
    if (referencedAttachmentKeys.any((key) => !attachments.containsKey(key))) {
      throw const FormatException(
        'The backup is missing data for one or more attachments.',
      );
    }
    final collections = collectionsValue is List
        ? collectionsValue
            .whereType<String>()
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty && value.length <= 80)
            .toSet()
            .toList()
        : <String>[];
    if (collections.length > 500) {
      throw const FormatException('The backup contains too many collections.');
    }
    return DecodedBackup(
      items: List<SavedItem>.unmodifiable(items),
      attachments: Map<String, BackupAttachment>.unmodifiable(attachments),
      collections: List<String>.unmodifiable(collections),
      exportedAt: decoded['exportedAt'] is String ? decoded['exportedAt'] as String : '',
    );
  }
}
