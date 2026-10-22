import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../models/saved_item.dart';
import 'web_url.dart';

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
    this.omittedUnreadableRecordCount = 0,
    this.omittedCollectionEntryCount = 0,
    this.omittedUnexportableRecordCount = 0,
  });

  final List<SavedItem> items;
  final Map<String, BackupAttachment> attachments;
  final List<String> collections;
  final String exportedAt;

  /// Number of local records explicitly omitted by the exporter because their
  /// stored shape could not be decoded. Zero for old/complete backups.
  final int omittedUnreadableRecordCount;

  /// Number of legacy collection entries/assignments omitted or normalized
  /// during local collection recovery. Optional for backward compatibility.
  final int omittedCollectionEntryCount;

  /// Number of visible legacy item records omitted because strict backup
  /// validation or attachment checks could not safely represent them.
  final int omittedUnexportableRecordCount;
}

class BackupCodec {
  BackupCodec._();

  static const int formatVersion = 1;
  static const int maxItems = 10000;
  static const int maxCollections = 500;
  static const int maxAttachmentBytes = 15 * 1024 * 1024;
  static const int maxTotalAttachmentBytes = 100 * 1024 * 1024;
  static const int maxBackupBytes = 145 * 1024 * 1024;
  // Retained as the character guard for decoding in-memory JSON; the UTF-8
  // byte limit is the portable file-size boundary enforced on every path.
  static const int maxJsonCharacters = maxBackupBytes;
  static const int minSupportedTimestampMs = -8640000000000000;

  /// Counts the UTF-8 size without allocating a second full-size byte buffer.
  /// Stops as soon as the portable backup cap is exceeded.
  static int utf8ByteLength(String value) {
    var total = 0;
    for (final rune in value.runes) {
      total += rune <= 0x7F
          ? 1
          : rune <= 0x7FF
              ? 2
              : rune <= 0xFFFF
                  ? 3
                  : 4;
      if (total > maxBackupBytes) return total;
    }
    return total;
  }

  /// Maximum base64 character count needed to encode at most [maxDecodedBytes].
  /// The result rounds up to a full four-character base64 quantum.
  static int maxBase64CharactersForDecodedBytes(int maxDecodedBytes) {
    if (maxDecodedBytes < 0) {
      throw ArgumentError.value(
        maxDecodedBytes,
        'maxDecodedBytes',
        'Must not be negative.',
      );
    }
    return ((maxDecodedBytes + 2) ~/ 3) * 4;
  }

  /// Ensures repository mutations stay within the item count that backups can
  /// represent. [incomingCount] is zero for edits and the number of new records
  /// for restore/import preflight.
  static void validateItemCount({
    required int currentCount,
    required int incomingCount,
  }) {
    if (currentCount < 0 ||
        incomingCount < 0 ||
        currentCount + incomingCount > maxItems) {
      throw FormatException(
        'StashHive supports up to $maxItems saved items. '
        'Remove some items before saving or restoring more.',
      );
    }
  }
  static const int maxSupportedTimestampMs = 8640000000000000;

  /// Revalidates an in-memory decoded backup at the mutation boundary.
  ///
  /// DecodedBackup is publicly constructible and its lists/maps can be mutable,
  /// so callers must not be able to bypass JSON decoder limits by constructing
  /// an instance directly or modifying one after decode.
  static void validateDecodedBackup(DecodedBackup backup) {
    if (backup.items.length > maxItems) {
      throw const FormatException('The backup contains too many items.');
    }
    if (backup.collections.length > maxCollections) {
      throw const FormatException('The backup contains too many collections.');
    }
    if (backup.omittedUnreadableRecordCount < 0 ||
        backup.omittedCollectionEntryCount < 0 ||
        backup.omittedUnexportableRecordCount < 0) {
      throw const FormatException('The backup omission metadata is invalid.');
    }

    final ids = <String>{};
    final referencedAttachmentKeys = <String>{};
    for (final item in backup.items) {
      validateSavedItem(item);
      if (!ids.add(item.id)) {
        throw const FormatException('The backup contains duplicate item IDs.');
      }
      final key = item.attachmentKey;
      if (key != null) {
        referencedAttachmentKeys.add(key);
        if (!backup.attachments.containsKey(key)) {
          throw const FormatException(
            'The backup is missing bytes for an image or document attachment.',
          );
        }
      }
    }

    for (final key in backup.attachments.keys) {
      if (!referencedAttachmentKeys.contains(key)) {
        throw const FormatException(
          'The backup contains attachment bytes that no saved item references.',
        );
      }
    }

    for (final rawName in backup.collections) {
      final name = rawName.trim();
      if (name.isEmpty || name != rawName || name.length > 80) {
        throw const FormatException(
          'A collection name must be between 1 and 80 characters.',
        );
      }
      // Older version-1 exports could contain case-only duplicate names.
      // Restore merges collection labels case-insensitively, so keep those
      // backups recoverable rather than rejecting otherwise valid item data.
    }

    var totalBytes = 0;
    for (final entry in backup.attachments.entries) {
      final key = entry.key;
      final attachment = entry.value;
      if (key.trim().isEmpty || key.length > 128) {
        throw const FormatException('An attachment key is invalid.');
      }
      if (attachment.name.trim().isEmpty ||
          attachment.name.length > 255 ||
          attachment.mimeType.trim().isEmpty ||
          attachment.mimeType.length > 128) {
        throw const FormatException('An attachment has invalid metadata.');
      }
      if (attachment.bytes.isEmpty) {
        throw const FormatException('An attachment payload is empty.');
      }
      if (attachment.bytes.length > maxAttachmentBytes) {
        throw const FormatException('An attachment exceeds the 15 MB backup limit.');
      }
      totalBytes += attachment.bytes.length;
      if (totalBytes > maxTotalAttachmentBytes) {
        throw const FormatException(
          'The combined attachment data exceeds 100 MB.',
        );
      }
    }
  }

  /// Validates item fields shared by repository saves and backup export/import.
  /// Keeping these constraints aligned prevents StashHive from exporting a
  /// backup that its own decoder would later reject.
  static void validateSavedItem(SavedItem item) {
    _validateSavedItemMap(item.toMap());

    if (item.id.isEmpty || item.id.length > 128) {
      throw const FormatException('A saved item has an invalid identifier.');
    }
    if (item.title.trim().isEmpty || item.title.length > 500) {
      throw const FormatException('A saved item has an invalid title.');
    }
    if (item.kind == ItemKind.note && item.content.trim().isEmpty) {
      throw const FormatException('A saved note must contain some text.');
    }
    if (item.createdAtMs < minSupportedTimestampMs ||
        item.createdAtMs > maxSupportedTimestampMs ||
        item.updatedAtMs < minSupportedTimestampMs ||
        item.updatedAtMs > maxSupportedTimestampMs) {
      throw const FormatException(
        'A saved item has a timestamp outside the supported date range.',
      );
    }
    if (item.content.length > 1000000 ||
        (item.url?.length ?? 0) > maxSavedItemUrlCharacters ||
        item.tags.length > 100 ||
        item.tags.any((tag) => tag.length > 100)) {
      throw const FormatException('A saved item exceeds supported limits.');
    }
    if (item.tags.any((tag) => tag.isEmpty || tag.trim() != tag)) {
      throw const FormatException(
        'Tags must be non-empty and must not have surrounding whitespace.',
      );
    }
    final seenTagKeys = <String>{};
    if (item.tags.any((tag) => !seenTagKeys.add(tag.toLowerCase()))) {
      throw const FormatException(
        'Tags must be unique, ignoring case.',
      );
    }
    if ((item.attachmentName?.trim().isEmpty ?? false) ||
        (item.attachmentName?.length ?? 0) > 255 ||
        (item.attachmentMimeType?.trim().isEmpty ?? false) ||
        (item.attachmentMimeType?.length ?? 0) > 128) {
      throw const FormatException('A saved item has invalid attachment metadata.');
    }
    final collection = item.collection;
    if (collection != null &&
        (collection.trim().isEmpty ||
            collection.trim() != collection ||
            collection.length > 80)) {
      throw const FormatException('A saved item has an invalid collection name.');
    }
    if (item.attachmentKey != null &&
        item.kind != ItemKind.image &&
        item.kind != ItemKind.document) {
      throw const FormatException(
        'Only image and document items can contain an attachment.',
      );
    }
    if (item.attachmentKey == null &&
        (item.attachmentName != null || item.attachmentMimeType != null)) {
      throw const FormatException(
        'Attachment filename and MIME metadata require an attachment reference.',
      );
    }
    if (item.kind == ItemKind.link && parseHttpUrl(item.url) == null) {
      throw const FormatException('A saved link is not a valid HTTP or HTTPS URL.');
    }
    if ((item.kind == ItemKind.image || item.kind == ItemKind.document) &&
        !item.hasAttachment) {
      throw const FormatException(
        'An image or document item has no local attachment reference.',
      );
    }
  }

  static String encode({
    required List<SavedItem> items,
    required Map<String, Uint8List> attachmentBytes,
    required List<String> collections,
    int omittedUnreadableRecordCount = 0,
    int omittedCollectionEntryCount = 0,
    int omittedUnexportableRecordCount = 0,
  }) {
    if (omittedUnreadableRecordCount < 0 ||
        omittedCollectionEntryCount < 0 ||
        omittedUnexportableRecordCount < 0) {
      throw const FormatException('The backup omission count is invalid.');
    }
    if (items.length > maxItems) {
      throw const FormatException('The library contains too many items to export.');
    }
    final ids = <String>{};
    for (final item in items) {
      validateSavedItem(item);
      if (!ids.add(item.id)) {
        throw const FormatException('The library contains duplicate item IDs.');
      }
    }
    final safeCollections = _normalizeCollectionNames(
      collections,
      items.map((item) => item.collection),
    );
    final itemMaps = items
        .map((item) => item.toMap())
        .toList(growable: false);
    final attachments = <String, Object?>{};
    final exportedAt = DateTime.now().toUtc().toIso8601String();
    // Build a tiny root skeleton and count each item JSON separately. A
    // full jsonEncode(items) here could allocate gigabytes before the final
    // 145 MiB cap is checked.
    final outputValue = <String, Object?>{
      'app': 'StashHive',
      'formatVersion': formatVersion,
      'exportedAt': exportedAt,
      'collections': safeCollections,
      'items': <Object?>[],
      'attachments': attachments,
      if (omittedUnreadableRecordCount > 0)
        'omittedUnreadableRecordCount': omittedUnreadableRecordCount,
      if (omittedCollectionEntryCount > 0)
        'omittedCollectionEntryCount': omittedCollectionEntryCount,
      if (omittedUnexportableRecordCount > 0)
        'omittedUnexportableRecordCount': omittedUnexportableRecordCount,
    };
    var estimatedJsonBytes = utf8ByteLength(jsonEncode(outputValue));
    for (var index = 0; index < itemMaps.length; index++) {
      estimatedJsonBytes += utf8ByteLength(jsonEncode(itemMaps[index]));
      if (index > 0) estimatedJsonBytes++; // Array comma.
      if (estimatedJsonBytes > maxBackupBytes) {
        throw const FormatException('The backup is too large to share or restore.');
      }
    }
    outputValue['items'] = itemMaps;

    final includedAttachmentKeys = <String>{};
    var totalBytes = 0;
    for (final item in items) {
      final key = item.attachmentKey;
      if (key == null) {
        if (item.kind == ItemKind.image || item.kind == ItemKind.document) {
          throw const FormatException(
            'An image or document item is missing its attachment key.',
          );
        }
        continue;
      }
      if (item.kind != ItemKind.image && item.kind != ItemKind.document) {
        throw const FormatException(
          'Only image and document items can contain an attachment.',
        );
      }
      if (key.trim().isEmpty || key.length > 128) {
        throw const FormatException('An attachment key is invalid.');
      }
      // Multiple saved items may intentionally reference the same attachment.
      // Include its bytes and count toward the backup budget only once.
      if (!includedAttachmentKeys.add(key)) continue;
      final bytes = attachmentBytes[key];
      if (bytes == null) {
        throw FormatException(
          'The local attachment for "' + item.title + '" is missing. '
          'It was not included in the backup.',
        );
      }
      if (bytes.isEmpty) {
        throw const FormatException('An attachment is empty and cannot be exported.');
      }
      if (bytes.length > maxAttachmentBytes) {
        throw const FormatException('An attachment exceeds the 15 MB backup limit.');
      }
      if (bytes.any((byte) => byte < 0 || byte > 255)) {
        throw const FormatException('An attachment contains invalid byte values.');
      }
      totalBytes += bytes.length;
      if (totalBytes > maxTotalAttachmentBytes) {
        throw const FormatException('The combined attachments exceed 100 MB.');
      }

      final name = item.attachmentName ?? 'attachment';
      final mimeType = item.attachmentMimeType ?? 'application/octet-stream';
      final checksum = sha256.convert(bytes).toString();
      // Base64 output is ASCII and never needs JSON escaping. Measure the
      // attachment object with an empty base64 value, then add the exact
      // encoded character count before allocating the base64 string itself.
      final emptyPayloadValue = jsonEncode(<String, Object?>{
        'name': name,
        'mimeType': mimeType,
        'base64': '',
        'sha256': checksum,
      });
      estimatedJsonBytes += utf8ByteLength(jsonEncode(key)) +
          1 +
          utf8ByteLength(emptyPayloadValue) +
          maxBase64CharactersForDecodedBytes(bytes.length) +
          (attachments.isEmpty ? 0 : 1);
      if (estimatedJsonBytes > maxBackupBytes) {
        throw const FormatException('The backup is too large to share or restore.');
      }

      attachments[key] = <String, Object?>{
        'name': name,
        'mimeType': mimeType,
        'base64': base64Encode(bytes),
        'sha256': checksum,
      };
    }
    final output = jsonEncode(outputValue);
    if (output.length > maxJsonCharacters ||
        utf8ByteLength(output) > maxBackupBytes) {
      throw const FormatException('The backup is too large to share or restore.');
    }
    return output;
  }

  static DecodedBackup decode(String source) {
    if (source.length > maxJsonCharacters ||
        utf8ByteLength(source) > maxBackupBytes) {
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
    final omittedRecordValue = decoded['omittedUnreadableRecordCount'];
    final omittedCollectionValue = decoded['omittedCollectionEntryCount'];
    final omittedUnexportableValue = decoded['omittedUnexportableRecordCount'];
    if ((omittedRecordValue != null &&
            (omittedRecordValue is! int || omittedRecordValue < 0)) ||
        (omittedCollectionValue != null &&
            (omittedCollectionValue is! int || omittedCollectionValue < 0)) ||
        (omittedUnexportableValue != null &&
            (omittedUnexportableValue is! int ||
                omittedUnexportableValue < 0))) {
      throw const FormatException(
        'The backup omission metadata is invalid.',
      );
    }
    final itemsValue = decoded['items'];
    final attachmentsValue = decoded['attachments'];
    final collectionsValue = decoded['collections'];
    if (itemsValue is! List ||
        attachmentsValue is! Map ||
        collectionsValue is! List) {
      throw const FormatException('The backup is missing required data.');
    }
    if (itemsValue.length > maxItems) {
      throw const FormatException('The backup contains too many items.');
    }

    if (collectionsValue.length > 500) {
      throw const FormatException('The backup contains too many collections.');
    }
    final declaredCollections = <String>[];
    for (final value in collectionsValue) {
      if (value is! String) {
        throw const FormatException('A collection name in the backup is invalid.');
      }
      final name = value.trim();
      if (name.isEmpty || name.length > 80) {
        throw const FormatException('A collection name must be between 1 and 80 characters.');
      }
      declaredCollections.add(name);
    }

    final items = <SavedItem>[];
    final ids = <String>{};
    for (final value in itemsValue) {
      if (value is! Map) {
        throw const FormatException('A saved item in the backup is invalid.');
      }
      _validateSavedItemMap(value);
      final item = SavedItem.fromMap(value);
      validateSavedItem(item);
      if (!ids.add(item.id)) {
        throw const FormatException('The backup contains duplicate item IDs.');
      }
      items.add(item);
    }

    // Reject unused payloads before base64 decoding them. The encoder only
    // writes attachments referenced by an item; accepting orphan payloads
    // would spend memory on data that restore can never attach to a record.
    final referencedAttachmentKeys = <String>{
      for (final item in items)
        if (item.attachmentKey != null) item.attachmentKey!,
    };
    for (final rawKey in attachmentsValue.keys) {
      if (rawKey is! String) {
        throw const FormatException('An attachment entry is invalid.');
      }
      if (!referencedAttachmentKeys.contains(rawKey)) {
        throw const FormatException(
          'The backup contains attachment bytes that no saved item references.',
        );
      }
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
      final checksum = value['sha256'];
      if (key.trim().isEmpty ||
          key.length > 128 ||
          name is! String ||
          name.trim().isEmpty ||
          name.length > 255 ||
          mimeType is! String ||
          mimeType.trim().isEmpty ||
          mimeType.length > 128 ||
          encoded is! String ||
          encoded.length > ((maxAttachmentBytes * 4 ~/ 3) + 8) ||
          (checksum != null &&
              (checksum is! String ||
                  checksum.length != 64 ||
                  !RegExp(r'^[0-9a-fA-F]{64}').hasMatch(checksum)))) {
        throw const FormatException('An attachment entry exceeds supported limits.');
      }
      final remainingBytes = maxTotalAttachmentBytes - totalBytes;
      if (encoded.length >
          maxBase64CharactersForDecodedBytes(remainingBytes)) {
        throw const FormatException(
          'The combined attachments exceed 100 MB.',
        );
      }
      final Uint8List bytes;
      try {
        bytes = base64Decode(encoded);
      } on FormatException {
        throw const FormatException('An attachment contains invalid base64 data.');
      }
      if (bytes.isEmpty) {
        throw const FormatException('An attachment payload is empty.');
      }
      if (bytes.length > maxAttachmentBytes) {
        throw const FormatException('An attachment exceeds 15 MB.');
      }
      if (checksum is String &&
          sha256.convert(bytes).toString() != checksum.toLowerCase()) {
        throw const FormatException(
          'An attachment failed its integrity check. The backup may be damaged.',
        );
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
      // jsonDecode keeps the original base64 strings in its dynamic tree.
      // Drop each one after validating/decoding it so large restores do not
      // retain both the full parsed base64 tree and decoded attachment bytes.
      value.remove('base64');
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
    if (attachments.keys.any((key) => !referencedAttachmentKeys.contains(key))) {
      throw const FormatException(
        'The backup contains attachment data that no saved item references.',
      );
    }

    // Older version-1 backups may have an assigned collection on an item
    // without listing it at the top level. Preserve that relationship by
    // including assigned names rather than leaving the item ungrouped.
    final safeRestoredCollections = _normalizeCollectionNames(
      declaredCollections,
      items.map((item) => item.collection),
    );
    final canonicalCollectionNames = <String, String>{
      for (final name in safeRestoredCollections) name.toLowerCase(): name,
    };
    final safeRestoredItems = items.map((item) {
      final assigned = item.collection;
      if (assigned == null) return item;
      final canonical = canonicalCollectionNames[assigned.toLowerCase()];
      return canonical == null || canonical == assigned
          ? item
          : item.copyWith(collection: canonical);
    }).toList(growable: false);
    return DecodedBackup(
      items: List<SavedItem>.unmodifiable(safeRestoredItems),
      attachments: Map<String, BackupAttachment>.unmodifiable(attachments),
      collections: safeRestoredCollections,
      exportedAt: decoded['exportedAt'] is String ? decoded['exportedAt'] as String : '',
      omittedUnreadableRecordCount:
          omittedRecordValue is int ? omittedRecordValue : 0,
      omittedCollectionEntryCount:
          omittedCollectionValue is int ? omittedCollectionValue : 0,
      omittedUnexportableRecordCount:
          omittedUnexportableValue is int ? omittedUnexportableValue : 0,
    );
  }
  /// Validates only the on-disk field types and collection sizes needed to
  /// safely materialize a legacy record for recovery. Business invariants such
  /// as URL scheme, required attachment reference and tag normalization belong
  /// to save/export validation, not to hiding an otherwise viewable local item.
  static void validateStoredRecordMap(Map<dynamic, dynamic> value) {
    if (value['id'] is! String ||
        value['kind'] is! String ||
        value['title'] is! String ||
        value['content'] is! String ||
        value['tags'] is! List ||
        value['isFavorite'] is! bool ||
        value['createdAtMs'] is! int ||
        value['updatedAtMs'] is! int) {
      throw const FormatException(
        'A saved item is missing required fields or has invalid field types.',
      );
    }
    final createdAtMs = value['createdAtMs'] as int;
    final updatedAtMs = value['updatedAtMs'] as int;
    if (createdAtMs < minSupportedTimestampMs ||
        createdAtMs > maxSupportedTimestampMs ||
        updatedAtMs < minSupportedTimestampMs ||
        updatedAtMs > maxSupportedTimestampMs) {
      throw const FormatException(
        'A saved item has a timestamp outside the supported date range.',
      );
    }
    if ((value['url'] != null && value['url'] is! String) ||
        (value['collection'] != null && value['collection'] is! String) ||
        (value['attachmentKey'] != null && value['attachmentKey'] is! String) ||
        (value['attachmentName'] != null && value['attachmentName'] is! String) ||
        (value['attachmentMimeType'] != null &&
            value['attachmentMimeType'] is! String)) {
      throw const FormatException(
        'A saved item contains invalid optional field types.',
      );
    }
    final id = value['id'] as String;
    final title = value['title'] as String;
    final content = value['content'] as String;
    final url = value['url'] as String?;
    final collection = value['collection'] as String?;
    final attachmentKey = value['attachmentKey'] as String?;
    final attachmentName = value['attachmentName'] as String?;
    final attachmentMimeType = value['attachmentMimeType'] as String?;
    if (id.isEmpty ||
        id.length > 128 ||
        title.length > 500 ||
        content.length > 1000000 ||
        (url?.length ?? 0) > maxSavedItemUrlCharacters ||
        (collection?.length ?? 0) > 80 ||
        (attachmentKey?.length ?? 0) > 128 ||
        (attachmentName?.length ?? 0) > 255 ||
        (attachmentMimeType?.length ?? 0) > 128) {
      throw const FormatException(
        'A saved item contains fields beyond supported storage limits.',
      );
    }
    final tags = value['tags'] as List;
    if (tags.length > 100 ||
        tags.any((tag) => tag is! String || (tag as String).length > 100)) {
      throw const FormatException(
        'A saved item contains an invalid or oversized tag list.',
      );
    }
  }

  /// Validates the raw record shape before model parsing can normalize
  /// malformed field values into defaults.
  static void validateSavedItemMap(Map<dynamic, dynamic> value) {
    _validateSavedItemMap(value);
  }

  static void _validateSavedItemMap(Map<dynamic, dynamic> value) {
    if (value['id'] is! String ||
        value['kind'] is! String ||
        value['title'] is! String ||
        value['content'] is! String ||
        value['tags'] is! List ||
        value['isFavorite'] is! bool ||
        value['createdAtMs'] is! int ||
        value['updatedAtMs'] is! int) {
      throw const FormatException(
        'A saved item is missing required fields or has invalid field types.',
      );
    }
    if ((value['url'] != null && value['url'] is! String) ||
        (value['collection'] != null && value['collection'] is! String) ||
        (value['attachmentKey'] != null && value['attachmentKey'] is! String) ||
        (value['attachmentName'] != null && value['attachmentName'] is! String) ||
        (value['attachmentMimeType'] != null &&
            value['attachmentMimeType'] is! String)) {
      throw const FormatException(
        'A saved item contains invalid optional field types.',
      );
    }
    final tags = value['tags'] as List;
    if (tags.length > 100 || tags.any((tag) => tag is! String)) {
      throw const FormatException('A saved item contains an invalid tag list.');
    }
    if (tags.cast<String>().any(
      (tag) =>
          tag.isEmpty ||
          tag.trim() != tag ||
          tag.length > 100,
    )) {
      throw const FormatException(
        'Tags must be non-empty, trimmed and 100 characters or shorter.',
      );
    }
    final collection = value['collection'];
    if (collection is String &&
        (collection.trim().isEmpty ||
            collection.trim() != collection ||
            collection.length > 80)) {
      throw const FormatException('A saved item has an invalid collection name.');
    }
    final attachmentKey = value['attachmentKey'];
    if (attachmentKey is String &&
        (attachmentKey.trim().isEmpty || attachmentKey.length > 128)) {
      throw const FormatException('A saved item has an invalid attachment key.');
    }
    final attachmentName = value['attachmentName'];
    if (attachmentName is String &&
        (attachmentName.isEmpty || attachmentName.length > 255)) {
      throw const FormatException('A saved item has an invalid attachment name.');
    }
    final mimeType = value['attachmentMimeType'];
    if (mimeType is String &&
        (mimeType.trim().isEmpty || mimeType.length > 128)) {
      throw const FormatException('A saved item has an invalid attachment MIME type.');
    }
  }

  static List<String> _normalizeCollectionNames(
    Iterable<String?> declared,
    Iterable<String?> assigned,
  ) {
    final result = <String>[];
    final seen = <String>{};
    for (final raw in [...declared, ...assigned]) {
      if (raw == null) continue;
      final name = raw.trim();
      if (name.isEmpty || name.length > 80) {
        throw const FormatException(
          'Collection names must be between 1 and 80 characters.',
        );
      }
      if (seen.add(name.toLowerCase())) result.add(name);
      if (result.length > maxCollections) {
        throw const FormatException('The backup contains too many collections.');
      }
    }
    return List<String>.unmodifiable(result);
  }

}
