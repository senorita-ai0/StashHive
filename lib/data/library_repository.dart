import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import '../models/saved_item.dart';
import '../services/backup_codec.dart';

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

  /// Fault-injection seam for verifying that a failed restore removes writes
  /// already staged before the collection preferences are committed.
  @visibleForTesting
  static Future<void> Function()? restoreBeforeCollectionsCommitForTesting;

  /// Fault-injection seam for testing the save path after attachment bytes are
  /// staged but before the saved-item record is committed.
  @visibleForTesting
  static Future<void> Function()? saveBeforeItemCommitForTesting;

  /// Fault-injection seam for collection rename/delete rollback tests.
  @visibleForTesting
  static Future<void> Function(int index)? collectionBeforeItemWriteForTesting;

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

  void _refreshItems() {
    final result = <SavedItem>[];
    for (final value in _itemsBox.values) {
      if (value is Map) {
        try {
          result.add(SavedItem.fromMap(value));
        } on FormatException {
          // An unreadable record is skipped rather than crashing the whole library.
        }
      }
    }
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

  Future<void> save(SavedItem item, {List<int>? attachmentBytes}) async {
    final key = item.attachmentKey;
    if (key != null &&
        attachmentBytes == null &&
        !_attachmentsBox.containsKey(key)) {
      throw StateError(
        'The selected attachment is not available locally. Please select it again.',
      );
    }

    final hadPreviousAttachment =
        key != null && _attachmentsBox.containsKey(key);
    final previousAttachment =
        hadPreviousAttachment ? _attachmentsBox.get(key) : null;
    var attachmentWritten = false;
    if (key != null && attachmentBytes != null) {
      await _attachmentsBox.put(key, attachmentBytes);
      attachmentWritten = true;
    }
    try {
      final beforeItemCommit = saveBeforeItemCommitForTesting;
      if (beforeItemCommit != null) await beforeItemCommit();
      await _itemsBox.put(item.id, item.toMap());
    } catch (_) {
      // A failed edit must not destroy the previously saved attachment. Restore
      // its exact stored value if one existed; only remove staged bytes for a
      // brand-new attachment. Rollback errors must not mask the write error.
      if (attachmentWritten && key != null) {
        try {
          if (hadPreviousAttachment) {
            await _attachmentsBox.put(key, previousAttachment);
          } else {
            await _attachmentsBox.delete(key);
          }
        } catch (_) {
          // Best-effort recovery; retain the original save failure.
        }
      }
      rethrow;
    }
    _refreshItems();
  }

  Future<void> delete(String id) async {
    final item = findById(id);
    await _itemsBox.delete(id);
    if (item?.attachmentKey != null) {
      await _attachmentsBox.delete(item!.attachmentKey);
    }
    _refreshItems();
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
    if (value is List) {
      return value.whereType<int>().toList(growable: false);
    }
    return null;
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
      if (key == null) continue;
      final value = _attachmentsBox.get(key);
      if (value is List) {
        byteMap[key] = Uint8List.fromList(value.whereType<int>().toList(growable: false));
      }
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
      final mappedKey = attachment == null ? null : newId;
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
        attachmentName: attachment?.name ?? item.attachmentName,
        attachmentMimeType: attachment?.mimeType ?? item.attachmentMimeType,
      );
      staged.add((item: restored, bytes: attachment?.bytes.toList(growable: false)));
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
  }
}
