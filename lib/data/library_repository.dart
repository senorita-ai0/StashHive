import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import '../models/saved_item.dart';
import '../services/backup_codec.dart';
import '../services/attachment_bytes.dart';

class LibraryRepository {
  LibraryRepository._({
    required Box<dynamic> itemsBox,
    required Box<dynamic> attachmentsBox,
    required Box<dynamic> preferencesBox,
  })  : _itemsBox = itemsBox,
        _attachmentsBox = attachmentsBox,
        _preferencesBox = preferencesBox {
    _refreshItems();
    _refreshCollections();
  }

  final Box<dynamic> _itemsBox;
  final Box<dynamic> _attachmentsBox;
  final Box<dynamic> _preferencesBox;

  final ValueNotifier<List<SavedItem>> items =
      ValueNotifier<List<SavedItem>>(<SavedItem>[]);
  final ValueNotifier<List<String>> collections =
      ValueNotifier<List<String>>(<String>[]);
  /// Number of raw local records skipped because their shape could not be read.
  final ValueNotifier<int> skippedRecordCount = ValueNotifier<int>(0);

  /// Fault-injection seam for verifying that a failed restore removes writes
  /// already staged before the collection preferences are committed.
  @visibleForTesting
  static Future<void> Function()? restoreBeforeCollectionsCommitForTesting;

  /// Fault-injection seam for testing the save path after attachment bytes are
  /// staged but before the saved-item record is committed.
  @visibleForTesting
  static Future<void> Function()? saveBeforeItemCommitForTesting;

  /// Fault-injection seam for errors reported after an item record was written.
  @visibleForTesting
  static Future<void> Function()? saveAfterItemCommitForTesting;

  /// Fault-injection seam for collection rename/delete rollback tests.
  @visibleForTesting
  static Future<void> Function(int index)? collectionBeforeItemWriteForTesting;

  /// Fault-injection seam for a delete failure after attachment removal.
  @visibleForTesting
  static Future<void> Function()? deleteAfterAttachmentDeleteForTesting;

  bool get darkMode => _preferencesBox.get('darkMode') == true;

  static Future<LibraryRepository> open() async {
    await Hive.initFlutter();
    return _openBoxes();
  }

  @visibleForTesting
  static Future<LibraryRepository> openInitializedForTesting() async {
    return _openBoxes();
  }

  static Future<LibraryRepository> _openBoxes() async {
    final itemsBox = await Hive.openBox<dynamic>('stashhive_items_v1');
    final attachmentsBox =
        await Hive.openBox<dynamic>('stashhive_attachments_v1');
    final preferencesBox =
        await Hive.openBox<dynamic>('stashhive_preferences_v1');
    return LibraryRepository._(
      itemsBox: itemsBox,
      attachmentsBox: attachmentsBox,
      preferencesBox: preferencesBox,
    );
  }

  static String createId() {
    final random = Random();
    final time = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final suffix = random.nextInt(0x7fffffff).toRadixString(36);
    return time + '-' + suffix;
  }

  /// Generates an ID not currently used by either records or attachment keys.
  /// Item IDs often double as attachment keys, so reserve against both boxes.
  String createUniqueId() {
    var id = createId();
    while (_itemsBox.containsKey(id) ||
        _attachmentsBox.containsKey(id) ||
        _isAttachmentKeyReferencedByAnyItem(id)) {
      id = createId();
    }
    return id;
  }

  bool _isAttachmentKeyReferencedByAnyItem(String key) {
    for (final storedId in _itemsBox.keys) {
      final value = _itemsBox.get(storedId);
      if (value is Map && value['attachmentKey'] == key) return true;
    }
    return false;
  }

  void _refreshItems() {
    final result = <SavedItem>[];
    var skipped = 0;
    for (final entry in _itemsBox.toMap().entries) {
      final value = entry.value;
      if (value is! Map) {
        skipped++;
        continue;
      }
      try {
        // Validate raw field types first. Keep parseable legacy records visible
        // so missing attachments or unsafe URLs can show recovery feedback;
        // strict save/export rules must not make such records disappear.
        BackupCodec.validateStoredRecordMap(value);
        final item = SavedItem.fromMap(value);
        if (entry.key is! String || entry.key != item.id) {
          throw const FormatException(
            'A saved item key does not match its item identifier.',
          );
        }
        result.add(item);
      } catch (_) {
        // Keep the usable library open; damaged records are skipped rather
        // than preventing valid saved items from loading. Surface the count
        // so the user is not left unaware that some records need recovery.
        skipped++;
      }
    }
    skippedRecordCount.value = skipped;
    result.sort((a, b) => b.updatedAtMs.compareTo(a.updatedAtMs));
    items.value = List<SavedItem>.unmodifiable(result);
  }

  void _refreshCollections() {
    final value = _preferencesBox.get('collections');
    final names = value is List
        ? value
            .whereType<String>()
            .map((name) => name.trim())
            .where((name) => name.isNotEmpty)
            .toSet()
            .toList()
        : <String>[];
    names.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    collections.value = List<String>.unmodifiable(names);
  }

  SavedItem? findById(String id) {
    final value = _itemsBox.get(id);
    if (value is Map) {
      try {
        return SavedItem.fromMap(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Selects a safe key for replacement bytes without overwriting another
  /// item's shared payload or an orphaned/corrupt attachment record.
  String attachmentKeyForReplacement(
    String itemId, {
    String? currentAttachmentKey,
  }) {
    final targetHasStoredPayload = _attachmentsBox.containsKey(itemId);
    final targetIsCurrentKey = currentAttachmentKey == itemId;
    final targetIsReferencedByOther =
        isAttachmentReferencedByOtherItem(itemId, itemId);

    if (!targetHasStoredPayload && !targetIsReferencedByOther) {
      return itemId;
    }
    if (targetIsCurrentKey &&
        targetHasStoredPayload &&
        !targetIsReferencedByOther) {
      return itemId;
    }

    return createUniqueId();
  }

  /// True if a raw item record other than [itemId] references [key].
  ///
  /// Inspect raw records, not only decoded items, so a malformed record does
  /// not cause its shared payload to be overwritten by a replacement.
  bool isAttachmentReferencedByOtherItem(String itemId, String key) {
    for (final storedId in _itemsBox.keys) {
      if (storedId == itemId) continue;
      final value = _itemsBox.get(storedId);
      if (value is Map && value['attachmentKey'] == key) return true;
    }
    return false;
  }

  Future<void> save(SavedItem item, {List<int>? attachmentBytes}) async {
    BackupCodec.validateSavedItem(item);
    final key = item.attachmentKey;
    final requiresAttachment =
        item.kind == ItemKind.image || item.kind == ItemKind.document;

    if (requiresAttachment != (key != null)) {
      throw const FormatException(
        'Only image/document items may reference an attachment, and both require one.',
      );
    }
    if (key != null && (key.trim().isEmpty || key.length > 128)) {
      throw const FormatException('The attachment reference is invalid.');
    }
    if (attachmentBytes != null && !requiresAttachment) {
      throw const FormatException(
        'Attachments can only be saved for image or document items.',
      );
    }
    if (attachmentBytes != null &&
        attachmentBytes.length > BackupCodec.maxAttachmentBytes) {
      throw const FormatException('Attachments must be 15 MB or smaller.');
    }
    if (attachmentBytes != null &&
        (attachmentBytes.isEmpty ||
            attachmentBytes.any((byte) => byte < 0 || byte > 255))) {
      throw const FormatException(
        'The selected attachment is empty or contains invalid byte values.',
      );
    }
    if (key != null &&
        attachmentBytes != null &&
        isAttachmentReferencedByOtherItem(item.id, key)) {
      throw const FormatException(
        'This attachment is shared with another item. Use a new attachment key when replacing its bytes.',
      );
    }
    if (key != null && attachmentBytes == null) {
      final stored = _attachmentsBox.get(key);
      if (!_isValidAttachmentBytes(stored)) {
        throw StateError(
          'The selected attachment is missing or unreadable. Please select it again.',
        );
      }
    }

    final hadPreviousItem = _itemsBox.containsKey(item.id);
    final previousItemValue = _itemsBox.get(item.id);
    final previousAttachmentKey = previousItemValue is Map &&
            previousItemValue['attachmentKey'] is String
        ? previousItemValue['attachmentKey'] as String
        : null;
    final hadPreviousAttachment =
        key != null && _attachmentsBox.containsKey(key);
    final previousAttachment =
        hadPreviousAttachment ? _attachmentsBox.get(key) : null;
    var attachmentWriteAttempted = false;
    var itemWriteAttempted = false;

    try {
      if (key != null && attachmentBytes != null) {
        // Set the flag before awaiting: the storage call may take effect and
        // then report an error, in which case rollback still needs to run.
        attachmentWriteAttempted = true;
        await _attachmentsBox.put(key, attachmentBytes);
      }
      final beforeItemCommit = saveBeforeItemCommitForTesting;
      if (beforeItemCommit != null) await beforeItemCommit();

      itemWriteAttempted = true;
      await _itemsBox.put(item.id, item.toMap());
      final afterItemCommit = saveAfterItemCommitForTesting;
      if (afterItemCommit != null) await afterItemCommit();
    } catch (_) {
      // Restore the previous record too: a write can persist and still report
      // an error. If this was a new item, remove its potentially staged key.
      if (itemWriteAttempted) {
        try {
          if (hadPreviousItem) {
            await _itemsBox.put(item.id, previousItemValue);
          } else {
            await _itemsBox.delete(item.id);
          }
        } catch (_) {
          // Best-effort recovery; continue restoring any staged attachment.
        }
      }
      // Restore the exact prior attachment value, or remove a newly introduced
      // value. The rollback must not mask the original save error.
      if (attachmentWriteAttempted && key != null) {
        try {
          if (hadPreviousAttachment) {
            await _attachmentsBox.put(key, previousAttachment);
          } else {
            await _attachmentsBox.delete(key);
          }
        } catch (_) {
          // Retain the original save failure.
        }
      }
      _refreshItems();
      rethrow;
    }
    // If an edit removed/replaced its attachment reference, reclaim the old
    // payload only after the new item record committed and only when no other
    // raw (including unreadable legacy) item still points at that key.
    if (previousAttachmentKey != null &&
        previousAttachmentKey != key &&
        !_hasAttachmentReference(previousAttachmentKey)) {
      try {
        await _attachmentsBox.delete(previousAttachmentKey);
      } catch (_) {
        // Orphan cleanup is best-effort and must not turn a committed edit
        // into a reported save failure.
      }
    }
    _refreshItems();
  }

  Future<void> delete(String id) async {
    final hadItemKey = _itemsBox.containsKey(id);
    if (!hadItemKey) return;

    final previousItemValue = _itemsBox.get(id);
    final item = findById(id);
    final attachmentKey = item?.attachmentKey;
    final hadAttachment = attachmentKey != null &&
        _attachmentsBox.containsKey(attachmentKey);
    final previousAttachment =
        hadAttachment ? _attachmentsBox.get(attachmentKey) : null;
    var itemDeleteAttempted = false;
    var attachmentDeleteAttempted = false;

    try {
      // Mark each operation before awaiting it: a storage future can fail after
      // the underlying write has already taken effect.
      itemDeleteAttempted = true;
      await _itemsBox.delete(id);

      if (attachmentKey != null &&
          hadAttachment &&
          !_hasAttachmentReference(attachmentKey)) {
        attachmentDeleteAttempted = true;
        await _attachmentsBox.delete(attachmentKey);
        final afterAttachmentDelete = deleteAfterAttachmentDeleteForTesting;
        if (afterAttachmentDelete != null) await afterAttachmentDelete();
      }
    } catch (_) {
      // Restore in reverse order so a failed deletion cannot leave the item
      // pointing at attachment bytes that were successfully removed.
      if (attachmentDeleteAttempted &&
          attachmentKey != null &&
          hadAttachment) {
        try {
          await _attachmentsBox.put(attachmentKey, previousAttachment);
        } catch (_) {
          // Best-effort recovery; continue restoring the item record.
        }
      }
      if (itemDeleteAttempted) {
        try {
          await _itemsBox.put(id, previousItemValue);
        } catch (_) {
          // Preserve the original delete error.
        }
      }
      _refreshItems();
      rethrow;
    }

    _refreshItems();
  }

  bool _hasAttachmentReference(String attachmentKey) {
    // Scan raw records as well as parsed notifier values so a legacy or
    // unreadable item still protects an attachment that it references.
    for (final key in _itemsBox.keys) {
      final value = _itemsBox.get(key);
      if (value is Map && value['attachmentKey'] == attachmentKey) {
        return true;
      }
    }
    return false;
  }

  Future<void> toggleFavorite(String id) async {
    final item = findById(id);
    if (item == null) return;
    await save(item.copyWith(
      isFavorite: !item.isFavorite,
      updatedAtMs: DateTime.now().toUtc().millisecondsSinceEpoch,
    ));
  }

  Future<List<int>?> readAttachment(String key) async {
    final value = _attachmentsBox.get(key);
    if (!isValidAttachmentByteList(value)) return null;
    return List<int>.unmodifiable((value as List).cast<int>());
  }

  Future<void> setDarkMode(bool value) async {
    await _preferencesBox.put('darkMode', value);
  }

  Future<void> addCollection(String name) async {
    final cleaned = name.trim();
    if (cleaned.isEmpty || cleaned.length > 80) {
      throw const FormatException('Collection names must be between 1 and 80 characters.');
    }
    final current = List<String>.from(collections.value);
    if (current.any((item) => item.toLowerCase() == cleaned.toLowerCase())) {
      throw const FormatException('A collection with this name already exists.');
    }
    current.add(cleaned);
    await _preferencesBox.put('collections', current);
    _refreshCollections();
  }

  Future<void> renameCollection(String oldName, String newName) async {
    final cleaned = newName.trim();
    if (cleaned.isEmpty || cleaned.length > 80) {
      throw const FormatException('Collection names must be between 1 and 80 characters.');
    }
    if (collections.value.any((item) =>
        item.toLowerCase() == cleaned.toLowerCase() &&
        item.toLowerCase() != oldName.toLowerCase())) {
      throw const FormatException('A collection with this name already exists.');
    }
    final oldIndex = collections.value.indexWhere(
      (item) => item.toLowerCase() == oldName.toLowerCase(),
    );
    if (oldIndex < 0) {
      throw const FormatException('The collection does not exist.');
    }

    final renamedCollections = List<String>.from(collections.value);
    renamedCollections[oldIndex] = cleaned;
    final affectedItems = items.value
        .where((item) => item.collection?.toLowerCase() == oldName.toLowerCase())
        .toList(growable: false);
    await _commitCollectionMutation(
      updatedCollections: renamedCollections,
      affectedItems: affectedItems,
      transform: (item) => item.copyWith(
        collection: cleaned,
        updatedAtMs: DateTime.now().toUtc().millisecondsSinceEpoch,
      ),
    );
  }

  Future<void> deleteCollection(String name) async {
    final exists = collections.value.any(
      (item) => item.toLowerCase() == name.toLowerCase(),
    );
    if (!exists) {
      throw const FormatException('The collection does not exist.');
    }
    final remainingCollections = collections.value
        .where((item) => item.toLowerCase() != name.toLowerCase())
        .toList(growable: false);
    final affectedItems = items.value
        .where((item) => item.collection?.toLowerCase() == name.toLowerCase())
        .toList(growable: false);
    await _commitCollectionMutation(
      updatedCollections: remainingCollections,
      affectedItems: affectedItems,
      transform: (item) => item.copyWith(
        clearCollection: true,
        updatedAtMs: DateTime.now().toUtc().millisecondsSinceEpoch,
      ),
    );
  }

  Future<void> _commitCollectionMutation({
    required List<String> updatedCollections,
    required List<SavedItem> affectedItems,
    required SavedItem Function(SavedItem item) transform,
  }) async {
    final hadCollectionsKey = _preferencesBox.containsKey('collections');
    final previousCollectionsValue = _preferencesBox.get('collections');
    final hadItemKeys = <String, bool>{
      for (final item in affectedItems)
        item.id: _itemsBox.containsKey(item.id),
    };
    final previousItemValues = <String, Object?>{
      for (final item in affectedItems) item.id: _itemsBox.get(item.id),
    };
    final attemptedItemIds = <String>[];

    try {
      for (var index = 0; index < affectedItems.length; index++) {
        final item = affectedItems[index];
        // Include the current key before writing: a storage call may fail after
        // committing, so rollback must attempt to restore it too.
        attemptedItemIds.add(item.id);
        final beforeItemWrite = collectionBeforeItemWriteForTesting;
        if (beforeItemWrite != null) await beforeItemWrite(index);
        await _itemsBox.put(item.id, transform(item).toMap());
      }
      await _preferencesBox.put('collections', updatedCollections);
    } catch (_) {
      for (final id in attemptedItemIds.reversed) {
        try {
          if (hadItemKeys[id] == true) {
            await _itemsBox.put(id, previousItemValues[id]);
          } else {
            await _itemsBox.delete(id);
          }
        } catch (_) {
          // Best-effort rollback; keep attempting the remaining records.
        }
      }
      try {
        if (hadCollectionsKey) {
          await _preferencesBox.put('collections', previousCollectionsValue);
        } else {
          await _preferencesBox.delete('collections');
        }
      } catch (_) {
        // Preserve the original operation error if preferences cannot roll back.
      }
      _refreshItems();
      _refreshCollections();
      rethrow;
    }

    _refreshItems();
    _refreshCollections();
  }

  Future<String> createBackup() async {
    final byteMap = <String, Uint8List>{};
    for (final item in items.value) {
      final key = item.attachmentKey;
      if (key == null || byteMap.containsKey(key)) continue;
      final value = _attachmentsBox.get(key);
      if (!isValidAttachmentByteList(value)) {
        throw FormatException(
          'The local attachment for "${item.title}" is missing or damaged. '
          'Select the file again or restore a backup before exporting.',
        );
      }
      byteMap[key] = Uint8List.fromList((value as List).cast<int>());
    }
    return BackupCodec.encode(
      items: List<SavedItem>.from(items.value),
      attachmentBytes: byteMap,
      collections: List<String>.from(collections.value),
    );
  }

  Future<int> restoreBackup(String source) async {
    final decoded = BackupCodec.decode(source);
    final staged = <({SavedItem item, List<int>? bytes})>[];
    // Reserve raw box keys too, including keys belonging to unreadable records
    // or orphaned attachments, so rollback can safely delete every staged ID.
    final reserved = <String>{
      ..._itemsBox.keys.whereType<String>(),
      ..._attachmentsBox.keys.whereType<String>(),
    };
    final seenImportedIds = <String>{};
    final mappedAttachmentKeys = <String, String>{};
    final stagedAttachmentKeys = <String>{};
    for (final item in decoded.items) {
      var newId = item.id;
      if (reserved.contains(newId) || !seenImportedIds.add(newId)) {
        newId = createId();
        while (reserved.contains(newId) || seenImportedIds.contains(newId)) {
          newId = createId();
        }
        seenImportedIds.add(newId);
      }
      final oldKey = item.attachmentKey;
      final attachment = oldKey == null ? null : decoded.attachments[oldKey];
      String? mappedKey;
      List<int>? bytesToWrite;
      if (oldKey != null && attachment != null) {
        // Preserve intentional shared-attachment relationships across restore.
        // Use one collision-safe new key and stage the bytes only once.
        mappedKey = mappedAttachmentKeys.putIfAbsent(oldKey, () => newId);
        if (stagedAttachmentKeys.add(oldKey)) {
          bytesToWrite = attachment.bytes.toList(growable: false);
        }
      }
      final restored = SavedItem(
        id: newId,
        kind: item.kind,
        title: item.title,
        content: item.content,
        url: item.url,
        tags: item.tags,
        collection: item.collection,
        isFavorite: item.isFavorite,
        createdAtMs: item.createdAtMs,
        updatedAtMs: DateTime.now().toUtc().millisecondsSinceEpoch,
        attachmentKey: mappedKey,
        attachmentName: item.attachmentName ?? attachment?.name,
        attachmentMimeType: item.attachmentMimeType ?? attachment?.mimeType,
      );
      staged.add((item: restored, bytes: bytesToWrite));
      reserved.add(newId);
    }

    final hadCollectionsKey = _preferencesBox.containsKey('collections');
    final previousCollectionsValue = _preferencesBox.get('collections');
    try {
      for (final entry in staged) {
        final key = entry.item.attachmentKey;
        if (key != null && entry.bytes != null) {
          await _attachmentsBox.put(key, entry.bytes);
        }
        await _itemsBox.put(entry.item.id, entry.item.toMap());
      }
      final merged = List<String>.from(collections.value);
      for (final name in decoded.collections) {
        if (!merged.any((value) => value.toLowerCase() == name.toLowerCase())) {
          merged.add(name);
        }
      }
      final beforeCollectionsCommit = restoreBeforeCollectionsCommitForTesting;
      if (beforeCollectionsCommit != null) {
        await beforeCollectionsCommit();
      }
      await _preferencesBox.put('collections', merged);
    } catch (_) {
      // Every staged ID is guaranteed not to have existed before this restore.
      // Attempt cleanup item-by-item so one rollback failure does not prevent
      // cleanup attempts for other records or attachment payloads.
      for (final entry in staged.reversed) {
        try {
          await _itemsBox.delete(entry.item.id);
        } catch (_) {
          // Preserve the original restore error; don't mask the primary failure.
        }
        final key = entry.item.attachmentKey;
        if (key != null) {
          try {
            await _attachmentsBox.delete(key);
          } catch (_) {
            // Continue best-effort rollback of the remaining staged entries.
          }
        }
      }
      try {
        if (hadCollectionsKey) {
          await _preferencesBox.put('collections', previousCollectionsValue);
        } else {
          await _preferencesBox.delete('collections');
        }
      } catch (_) {
        // Preserve the original restore error if preferences cannot be rolled
        // back. Storage-interruption recovery still requires platform testing.
      }
      rethrow;
    }
    _refreshItems();
    _refreshCollections();
    return staged.length;
  }

  void dispose() {
    items.dispose();
    collections.dispose();
    skippedRecordCount.dispose();
  }
}
