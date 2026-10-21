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

  bool get darkMode => _preferencesBox.get('darkMode') == true;

  static Future<LibraryRepository> open() async {
    await Hive.initFlutter();
    final itemsBox = await Hive.openBox<dynamic>('stashhive_items_v1');
    final attachmentsBox = await Hive.openBox<dynamic>('stashhive_attachments_v1');
    final preferencesBox = await Hive.openBox<dynamic>('stashhive_preferences_v1');
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
    if (key != null && attachmentBytes == null && !_attachmentsBox.containsKey(key)) {
      throw StateError('The selected attachment is not available locally. Please select it again.');
    }
    var attachmentWritten = false;
    if (key != null && attachmentBytes != null) {
      await _attachmentsBox.put(key, attachmentBytes);
      attachmentWritten = true;
    }
    try {
      await _itemsBox.put(item.id, item.toMap());
    } catch (_) {
      if (attachmentWritten && key != null) {
        await _attachmentsBox.delete(key);
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
    final current = collections.value.map((item) => item == oldName ? cleaned : item).toList();
    await _preferencesBox.put('collections', current);
    for (final item in List<SavedItem>.from(items.value)) {
      if (item.collection == oldName) {
        await save(item.copyWith(
          collection: cleaned,
          updatedAtMs: DateTime.now().toUtc().millisecondsSinceEpoch,
        ));
      }
    }
    _refreshCollections();
    _refreshItems();
  }

  Future<void> deleteCollection(String name) async {
    final current = collections.value.where((item) => item != name).toList();
    await _preferencesBox.put('collections', current);
    for (final item in List<SavedItem>.from(items.value)) {
      if (item.collection == name) {
        await save(item.copyWith(
          clearCollection: true,
          updatedAtMs: DateTime.now().toUtc().millisecondsSinceEpoch,
        ));
      }
    }
    _refreshCollections();
    _refreshItems();
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
    final reserved = items.value.map((item) => item.id).toSet();
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

    final writtenItems = <String>[];
    final writtenAttachments = <String>[];
    try {
      for (final entry in staged) {
        final key = entry.item.attachmentKey;
        if (key != null && entry.bytes != null) {
          await _attachmentsBox.put(key, entry.bytes);
          writtenAttachments.add(key);
        }
        await _itemsBox.put(entry.item.id, entry.item.toMap());
        writtenItems.add(entry.item.id);
      }
      final merged = List<String>.from(collections.value);
      for (final name in decoded.collections) {
        if (!merged.any((value) => value.toLowerCase() == name.toLowerCase())) {
          merged.add(name);
        }
      }
      await _preferencesBox.put('collections', merged);
    } catch (_) {
      for (final id in writtenItems) {
        await _itemsBox.delete(id);
      }
      for (final key in writtenAttachments) {
        await _attachmentsBox.delete(key);
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
