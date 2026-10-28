import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import '../models/saved_item.dart';
import '../services/backup_codec.dart';
import '../services/attachment_bytes.dart';

/// Exposes notifications and the current value without leaking the
/// underlying mutable ValueNotifier to UI consumers.
class _ReadOnlyValueListenable<T> implements ValueListenable<T> {
  const _ReadOnlyValueListenable(this._source);

  final ValueListenable<T> _source;

  @override
  T get value => _source.value;

  @override
  void addListener(VoidCallback listener) => _source.addListener(listener);

  @override
  void removeListener(VoidCallback listener) =>
      _source.removeListener(listener);
}

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

  // Serialize repository operations that need a stable view of persisted
  // state. Mutations, backup snapshots and attachment reads share this queue
  // so callers cannot observe half-committed item/attachment relationships.
  Future<void> _mutationTail = Future<void>.value();
  int _operationSequence = 0;
  final Map<String, ({int sequence, Future<Uint8List?> future})>
      _pendingAttachmentReads = {};

  Future<T> _serializeOperation<T>(Future<T> Function() operation) {
    _operationSequence++;
    return _serializeOperationAtSequence(operation);
  }

  Future<T> _serializeOperationAtSequence<T>(
    Future<T> Function() operation,
  ) {
    // The sequence is allocated when a caller queues its operation, not when
    // it starts running. Attachment-read coalescing uses it to avoid joining a
    // read that would cross a save/delete/restore queued in the meantime.
    final previous = _mutationTail;
    final release = Completer<void>();
    _mutationTail = release.future;

    return () async {
      await previous;
      try {
        return await operation();
      } finally {
        release.complete();
      }
    }();
  }

  final ValueNotifier<List<SavedItem>> _items =
      ValueNotifier<List<SavedItem>>(<SavedItem>[]);
  late final ValueListenable<List<SavedItem>> items =
      _ReadOnlyValueListenable<List<SavedItem>>(_items);

  // Synchronous lookups use the last published item snapshot, not raw Hive
  // records that may be temporarily staged inside an in-flight mutation.
  final Map<String, SavedItem> _visibleItemsById = <String, SavedItem>{};

  final ValueNotifier<List<String>> _collections =
      ValueNotifier<List<String>>(<String>[]);
  late final ValueListenable<List<String>> collections =
      _ReadOnlyValueListenable<List<String>>(_collections);

  /// Raw local records skipped because their shape could not be read.
  final ValueNotifier<int> _skippedRecordCount = ValueNotifier<int>(0);
  late final ValueListenable<int> skippedRecordCount =
      _ReadOnlyValueListenable<int>(_skippedRecordCount);

  /// Invalid, duplicate or over-limit collection preference entries skipped
  /// while recovering the collection list.
  final ValueNotifier<int> _skippedCollectionCount = ValueNotifier<int>(0);
  late final ValueListenable<int> skippedCollectionCount =
      _ReadOnlyValueListenable<int>(_skippedCollectionCount);

  /// Fault-injection seam for verifying that a failed restore removes writes
  /// already staged before the collection preferences are committed.
  @visibleForTesting
  static Future<void> Function()? restoreBeforeCollectionsCommitForTesting;

  /// Fault-injection seam for a staged item deletion that fails during restore
  /// rollback, so attachment cleanup can be checked against surviving references.
  @visibleForTesting
  static Future<void> Function(String itemId)?
      restoreBeforeRollbackItemDeleteForTesting;

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

  /// Fault-injection seam for collection rename/delete when the preference
  /// write commits and then reports an error.
  @visibleForTesting
  static Future<void> Function()?
      collectionAfterPreferencesWriteForTesting;

  /// Fault-injection seam for a delete failure after attachment removal.
  @visibleForTesting
  static Future<void> Function()? deleteAfterAttachmentDeleteForTesting;

  /// Fault-injection seam for a collection preference write that reports an
  /// error after the underlying write has completed.
  @visibleForTesting
  static Future<void> Function()? addCollectionAfterWriteForTesting;

  /// Fault-injection seam to pause restore after its owned input snapshot
  /// has been validated but before any persistent writes begin.
  @visibleForTesting
  static Future<void> Function()? restoreAfterSnapshotForTesting;

  /// Optional read hook for proving attachment thumbnails reuse their pending
  /// future across harmless parent rebuilds in widget tests.
  @visibleForTesting
  static Future<void> Function(String key)? readAttachmentBeforeReadForTesting;

  /// Fault-injection seam for a theme preference write that fails after commit.
  @visibleForTesting
  static Future<void> Function()? setDarkModeAfterWriteForTesting;

  /// Fault-injection seam for a text-size preference write that fails late.
  @visibleForTesting
  static Future<void> Function()? setTextScaleMultiplierAfterWriteForTesting;

  /// Fault-injection seam for backup status storage failing after its write.
  @visibleForTesting
  static Future<void> Function()? backupPreparedAtAfterWriteForTesting;

  bool get darkMode => _preferencesBox.get('darkMode') == true;

  /// Extra app text scaling layered on top of platform accessibility scaling.
  /// Invalid legacy preference values fall back to the system default.
  double get textScaleMultiplier {
    const supported = <double>{1.0, 1.15, 1.3};
    final value = _preferencesBox.get('textScaleMultiplier');
    if (value is num && supported.contains(value.toDouble())) {
      return value.toDouble();
    }
    return 1.0;
  }

  /// Whether the one-time local-storage safety reminder has been dismissed.
  bool get hasSeenStorageReminder =>
      _preferencesBox.get('storageReminderSeen') == true;

  /// Most recent time a portable backup JSON was successfully generated.
  ///
  /// This records file preparation, not whether a destination in the platform
  /// share sheet ultimately saved the file. Invalid legacy values are ignored.
  int? get lastBackupPreparedAtMs {
    final value = _preferencesBox.get('lastBackupPreparedAtMs');
    if (value is! int || value <= 0) return null;
    final latestPlausible =
        DateTime.now().millisecondsSinceEpoch + const Duration(minutes: 5).inMilliseconds;
    if (value > latestPlausible) return null;
    return value;
  }

  /// Stores backup-preparation time in the local app/browser profile.
  /// This metadata is not included in the portable backup itself.
  Future<void> recordBackupPreparedAt(int timestampMs) =>
      _serializeOperation(() => _writeBackupPreparedAt(timestampMs));

  /// Performs the timestamp preference write without taking the mutation
  /// queue itself. Backup creation calls this while it already owns the queue,
  /// keeping the recorded time atomic with its metadata/attachment snapshot.
  Future<void> _writeBackupPreparedAt(int timestampMs) async {
    final latestPlausible =
        DateTime.now().millisecondsSinceEpoch +
        const Duration(minutes: 5).inMilliseconds;
    if (timestampMs <= 0 || timestampMs > latestPlausible) {
      throw const FormatException('The backup timestamp is invalid.');
    }

    const key = 'lastBackupPreparedAtMs';
    final hadPreviousValue = _preferencesBox.containsKey(key);
    final previousValue = _preferencesBox.get(key);
    try {
      await _preferencesBox.put(key, timestampMs);
      final afterWrite = backupPreparedAtAfterWriteForTesting;
      if (afterWrite != null) await afterWrite();
    } catch (_) {
      // A preference write may commit then report a late error. Restore the
      // prior informational value where possible without masking the original
      // failure or losing a prepared backup.
      try {
        if (hadPreviousValue) {
          await _preferencesBox.put(key, previousValue);
        } else {
          await _preferencesBox.delete(key);
        }
      } catch (_) {
        // Best-effort rollback; retain the original timestamp write failure.
      }
      rethrow;
    }
  }

  /// Persists the reminder acknowledgement in this local app/browser profile.
  Future<void> markStorageReminderSeen() =>
      _preferencesBox.put('storageReminderSeen', true);

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
    for (final storedId in _itemsBox.keys) {
      final value = _itemsBox.get(storedId);
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
        if (storedId is! String || storedId != item.id) {
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
    _skippedRecordCount.value = skipped;
    result.sort((a, b) => b.updatedAtMs.compareTo(a.updatedAtMs));
    _publishVisibleItems(result);
  }

  void _publishVisibleItems(List<SavedItem> nextItems) {
    final snapshot = List<SavedItem>.unmodifiable(nextItems);
    // Update the index before notifying listeners so a synchronous lookup
    // triggered by an items listener sees the same published revision.
    _visibleItemsById
      ..clear()
      ..addEntries(snapshot.map((item) => MapEntry(item.id, item)));
    _items.value = snapshot;
  }

  void _refreshCollections() {
    final value = _preferencesBox.get('collections');
    final names = <String>[];
    final seen = <String>{};
    var skipped = 0;

    if (value is List) {
      for (final rawName in value) {
        if (rawName is! String || rawName.length > 80) {
          skipped++;
          continue;
        }
        final name = rawName.trim();
        if (name.isEmpty) {
          skipped++;
          continue;
        }
        if (!seen.add(name.toLowerCase())) {
          skipped++;
          continue;
        }
        if (names.length >= BackupCodec.maxCollections) {
          skipped++;
          continue;
        }
        names.add(name);
      }
    } else if (value != null) {
      skipped++;
    }

    // Some older records can have a collection assignment even if its name
    // was absent from the preference list. Include those valid assignments so
    // they remain reachable in Collections and selectable when editing.
    for (final item in items.value) {
      final rawName = item.collection;
      if (rawName == null) continue;
      if (rawName.length > 80) {
        skipped++;
        continue;
      }
      final name = rawName.trim();
      if (name.isEmpty) {
        skipped++;
        continue;
      }
      if (!seen.add(name.toLowerCase())) continue;
      if (names.length >= BackupCodec.maxCollections) {
        skipped++;
        continue;
      }
      names.add(name);
    }

    names.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    final canonicalNames = <String, String>{
      for (final name in names) name.toLowerCase(): name,
    };
    final normalizedItems = items.value.map((item) {
      final assigned = item.collection;
      if (assigned == null) return item;
      final canonical = canonicalNames[assigned.toLowerCase()];
      if (canonical == null || canonical == assigned) return item;
      return item.copyWith(collection: canonical);
    }).toList(growable: false);
    if (normalizedItems.indexed.any(
      (entry) => !identical(entry.$2, items.value[entry.$1]),
    )) {
      _publishVisibleItems(normalizedItems);
    }
    _skippedCollectionCount.value = skipped;
    _collections.value = List<String>.unmodifiable(names);
  }

  SavedItem _canonicalizeCollectionAssignment(SavedItem item) {
    final assigned = item.collection;
    if (assigned == null) return item;
    for (final name in collections.value) {
      if (name.toLowerCase() == assigned.toLowerCase()) {
        return name == assigned ? item : item.copyWith(collection: name);
      }
    }
    return item;
  }

  /// Returns the last published repository view of an item.
  ///
  /// Reading the raw box here would expose a staged item record between the
  /// metadata write and the commit/rollback of its attachment relationship.
  /// The visible index is updated together with [items] after each operation.
  SavedItem? findById(String id) => _visibleItemsById[id];

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

  Future<void> save(SavedItem item, {List<int>? attachmentBytes}) {
    // Capture mutable inputs when save is requested, not when its queued
    // operation eventually starts. Otherwise a caller could mutate tags/bytes
    // while this save waits behind an earlier repository operation.
    try {
      // Guard tag dimensions before any model serialization can copy the list,
      // then validate all item fields before allocating an attachment snapshot.
      if (item.tags.length > 100 || item.tags.any((tag) => tag.length > 100)) {
        throw const FormatException('A saved item exceeds supported limits.');
      }
      BackupCodec.validateSavedItem(item);
      if (attachmentBytes != null &&
          item.kind != ItemKind.image &&
          item.kind != ItemKind.document) {
        throw const FormatException(
          'Attachments can only be saved for image or document items.',
        );
      }
      if (attachmentBytes != null) {
        if (attachmentBytes.length > BackupCodec.maxAttachmentBytes) {
          throw const FormatException('Attachments must be 15 MB or smaller.');
        }
        if (attachmentBytes.isEmpty ||
            attachmentBytes.any((byte) => byte < 0 || byte > 255)) {
          throw const FormatException(
            'The selected attachment is empty or contains invalid byte values.',
          );
        }
      }

      final itemSnapshot = item.copyWith(
        tags: List<String>.unmodifiable(item.tags),
      );
      final attachmentSnapshot = attachmentBytes == null
          ? null
          : Uint8List.fromList(attachmentBytes);
      return _serializeOperation(
        () => _save(itemSnapshot, attachmentBytes: attachmentSnapshot),
      );
    } catch (error, stackTrace) {
      // Keep save's Future-based error contract even for invalid input rejected
      // before it enters the operation queue.
      return Future<void>.error(error, stackTrace);
    }
  }

  Future<void> _save(SavedItem item, {List<int>? attachmentBytes}) async {
    final saveItem = _canonicalizeCollectionAssignment(item);
    BackupCodec.validateSavedItem(saveItem);
    final alreadyVisible = items.value.any((saved) => saved.id == saveItem.id);
    BackupCodec.validateItemCount(
      currentCount: items.value.length,
      incomingCount: alreadyVisible ? 0 : 1,
    );
    final assignedCollection = saveItem.collection;
    if (assignedCollection != null &&
        !collections.value.any(
          (name) =>
              name.toLowerCase() == assignedCollection.toLowerCase(),
        ) &&
        collections.value.length >= BackupCodec.maxCollections) {
      throw const FormatException(
        'StashHive supports up to 500 collections. '
        'Choose an existing collection before saving this item.',
      );
    }
    final key = saveItem.attachmentKey;
    final hadPreviousItem = _itemsBox.containsKey(saveItem.id);
    final previousItemValue = _itemsBox.get(saveItem.id);
    final previousAttachmentKey = previousItemValue is Map &&
            previousItemValue['attachmentKey'] is String
        ? previousItemValue['attachmentKey'] as String
        : null;
    final requiresAttachment =
        saveItem.kind == ItemKind.image || saveItem.kind == ItemKind.document;

    if (requiresAttachment != (key != null)) {
      throw const FormatException(
        'Only image/document items may reference an attachment, and both require one.',
      );
    }
    if (key != null && (key.length > 128 || key.trim().isEmpty)) {
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
    if (key != null && attachmentBytes != null) {
      if (_attachmentsBox.containsKey(key) && previousAttachmentKey != key) {
        throw const FormatException(
          'That attachment key already contains another payload. Choose a new key rather than overwriting it.',
        );
      }
      if (isAttachmentReferencedByOtherItem(saveItem.id, key)) {
        throw const FormatException(
          'This attachment is shared with another item. Use a new attachment key when replacing its bytes.',
        );
      }
    }
    if (key != null && attachmentBytes == null) {
      final stored = _attachmentsBox.get(key);
      if (!isValidAttachmentByteList(stored)) {
        throw StateError(
          'The selected attachment is missing or unreadable. Please select it again.',
        );
      }
    }

    // Public save() already owns a bounded attachment snapshot before queue
    // entry. Internal favorite updates pass no bytes and reuse existing keys.
    final hadPreviousAttachment =
        key != null && _attachmentsBox.containsKey(key);
    final previousAttachment =
        hadPreviousAttachment ? _attachmentsBox.get(key) : null;
    var attachmentWriteAttempted = false;
    var itemWriteAttempted = false;

    try {
      if (key != null && attachmentBytes != null) {
        // Public save() owns the byte snapshot before queueing. Set the flag
        // before awaiting: storage may commit and then report an error.
        attachmentWriteAttempted = true;
        await _attachmentsBox.put(key, attachmentBytes);
      }
      final beforeItemCommit = saveBeforeItemCommitForTesting;
      if (beforeItemCommit != null) await beforeItemCommit();

      itemWriteAttempted = true;
      await _itemsBox.put(saveItem.id, saveItem.toMap());
      final afterItemCommit = saveAfterItemCommitForTesting;
      if (afterItemCommit != null) await afterItemCommit();
    } catch (_) {
      // Restore the previous record too: a write can persist and still report
      // an error. If this was a new item, remove its potentially staged key.
      if (itemWriteAttempted) {
        try {
          if (hadPreviousItem) {
            await _itemsBox.put(saveItem.id, previousItemValue);
          } else {
            await _itemsBox.delete(saveItem.id);
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
      _refreshCollections();
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
    _refreshCollections();
  }

  Future<void> delete(String id) =>
      _serializeOperation(() => _delete(id));

  Future<void> _delete(String id) async {
    final hadItemKey = _itemsBox.containsKey(id);
    if (!hadItemKey) return;

    final previousItemValue = _itemsBox.get(id);
    final item = findById(id);
    // Unreadable legacy records are not present in the parsed item list, but
    // a raw string attachment reference can still be reclaimed after delete.
    // Only trust this fallback when the record could not be decoded; a valid
    // record with no attachment must not accidentally delete an unrelated key.
    final rawAttachmentKey = previousItemValue is Map &&
            previousItemValue['attachmentKey'] is String
        ? previousItemValue['attachmentKey'] as String
        : null;
    final attachmentKey = item?.attachmentKey ??
        (item == null ? rawAttachmentKey : null);
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
      _refreshCollections();
      rethrow;
    }

    _refreshItems();
    _refreshCollections();
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

  Future<void> toggleFavorite(String id) =>
      _serializeOperation(() => _toggleFavorite(id));

  Future<void> _toggleFavorite(String id) async {
    // Read the current item only after this operation reaches the queue head.
    // Otherwise two rapid toggles can both calculate from the same old value.
    final item = findById(id);
    if (item == null) return;
    await _save(item.copyWith(
      isFavorite: !item.isFavorite,
      updatedAtMs: DateTime.now().toUtc().millisecondsSinceEpoch,
    ));
  }

  Future<Uint8List?> readAttachment(String key) {
    final existing = _pendingAttachmentReads[key];
    // Reuse an in-flight read only when no other repository operation has been
    // queued since it. If a write is queued between reads, the later request
    // must run after that write and observe the newly committed bytes.
    if (existing != null && existing.sequence == _operationSequence) {
      return existing.future;
    }

    final sequence = ++_operationSequence;
    late final Future<Uint8List?> future;
    future = _serializeOperationAtSequence(() async {
      try {
        final beforeRead = readAttachmentBeforeReadForTesting;
        if (beforeRead != null) await beforeRead(key);
        final value = _attachmentsBox.get(key);
        if (!isValidAttachmentByteList(value)) return null;
        return Uint8List.fromList((value as List).cast<int>());
      } finally {
        final active = _pendingAttachmentReads[key];
        if (active != null && identical(active.future, future)) {
          _pendingAttachmentReads.remove(key);
        }
      }
    });
    _pendingAttachmentReads[key] = (sequence: sequence, future: future);
    return future;
  }

  Future<void> setDarkMode(bool value) =>
      _serializeOperation(() => _setDarkMode(value));

  Future<void> _setDarkMode(bool value) async {
    final hadDarkModeKey = _preferencesBox.containsKey('darkMode');
    final previousValue = _preferencesBox.get('darkMode');
    try {
      await _preferencesBox.put('darkMode', value);
      final afterWrite = setDarkModeAfterWriteForTesting;
      if (afterWrite != null) await afterWrite();
    } catch (_) {
      // As with other preferences, the write may commit and then report an
      // error. Restore the previous value best-effort and preserve the cause.
      try {
        if (hadDarkModeKey) {
          await _preferencesBox.put('darkMode', previousValue);
        } else {
          await _preferencesBox.delete('darkMode');
        }
      } catch (_) {
        // Preserve the original storage failure.
      }
      rethrow;
    }
  }

  Future<void> setTextScaleMultiplier(double value) =>
      _serializeOperation(() => _setTextScaleMultiplier(value));

  Future<void> _setTextScaleMultiplier(double value) async {
    const supported = <double>{1.0, 1.15, 1.3};
    if (!supported.contains(value)) {
      throw const FormatException(
        'Choose System default, Large or Extra large text.',
      );
    }

    const key = 'textScaleMultiplier';
    final hadValue = _preferencesBox.containsKey(key);
    final previousValue = _preferencesBox.get(key);
    try {
      await _preferencesBox.put(key, value);
      final afterWrite = setTextScaleMultiplierAfterWriteForTesting;
      if (afterWrite != null) await afterWrite();
    } catch (_) {
      // The storage future can report a failure after committing its write.
      try {
        if (hadValue) {
          await _preferencesBox.put(key, previousValue);
        } else {
          await _preferencesBox.delete(key);
        }
      } catch (_) {
        // Preserve the original error.
      }
      rethrow;
    }
  }

  Future<void> addCollection(String name) =>
      _serializeOperation(() => _addCollection(name));

  Future<void> _addCollection(String name) async {
    if (name.length > 80) {
      throw const FormatException('Collection names must be between 1 and 80 characters.');
    }
    final cleaned = name.trim();
    if (cleaned.isEmpty) {
      throw const FormatException('Collection names must be between 1 and 80 characters.');
    }
    final current = List<String>.from(collections.value);
    if (current.any((item) => item.toLowerCase() == cleaned.toLowerCase())) {
      throw const FormatException('A collection with this name already exists.');
    }
    if (current.length >= BackupCodec.maxCollections) {
      throw const FormatException(
        'StashHive supports up to 500 collections so library backups remain portable.',
      );
    }
    current.add(cleaned);
    final hadCollectionsKey = _preferencesBox.containsKey('collections');
    final previousCollectionsValue = _preferencesBox.get('collections');
    try {
      await _preferencesBox.put('collections', current);
      final afterWrite = addCollectionAfterWriteForTesting;
      if (afterWrite != null) await afterWrite();
    } catch (_) {
      // A storage future can fail after the preference write has taken effect.
      // Restore the previous value best-effort and retain the original error.
      try {
        if (hadCollectionsKey) {
          await _preferencesBox.put('collections', previousCollectionsValue);
        } else {
          await _preferencesBox.delete('collections');
        }
      } catch (_) {
        // Continue with refresh; never mask the original add failure.
      }
      _refreshCollections();
      rethrow;
    }
    _refreshCollections();
  }

  Future<void> renameCollection(String oldName, String newName) =>
      _serializeOperation(() => _renameCollection(oldName, newName));

  Future<void> _renameCollection(String oldName, String newName) async {
    if (newName.length > 80) {
      throw const FormatException('Collection names must be between 1 and 80 characters.');
    }
    final cleaned = newName.trim();
    if (cleaned.isEmpty) {
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

  Future<void> deleteCollection(String name) =>
      _serializeOperation(() => _deleteCollection(name));

  Future<void> _deleteCollection(String name) async {
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
      final afterPreferencesWrite = collectionAfterPreferencesWriteForTesting;
      if (afterPreferencesWrite != null) await afterPreferencesWrite();
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

  int get unrepresentedCollectionAssignmentCount {
    final exportableCollections = <String>{
      for (final name in collections.value) name.toLowerCase(),
    };
    final snapshotItems =
        _buildBackupSnapshot(copyAttachmentBytes: false).items;
    return snapshotItems.where((item) {
      final assigned = item.collection;
      return assigned != null &&
          !exportableCollections.contains(assigned.toLowerCase());
    }).length;
  }

  /// Number of visible legacy items that cannot be safely represented in a
  /// backup because item validation, attachment bytes, or the combined
  /// attachment budget fails. These records remain unchanged in local storage.
  int get unexportableRecordCount =>
      _buildBackupSnapshot(copyAttachmentBytes: false).omitted;

  ({
    List<SavedItem> items,
    Map<String, Uint8List> attachmentBytes,
    int omitted,
  }) _buildBackupSnapshot({required bool copyAttachmentBytes}) {
    final exportableItems = <SavedItem>[];
    final byteMap = <String, Uint8List>{};
    final includedKeys = <String>{};
    final rejectedKeys = <String>{};
    var totalBytes = 0;
    var omitted = 0;

    for (final item in items.value) {
      // Legacy boxes can predate the portable count limit. Keep the first
      // MAX_ITEMS exportable records rather than letting one extra old record
      // make every backup fail after the partial-export confirmation.
      if (exportableItems.length >= BackupCodec.maxItems) {
        omitted++;
        continue;
      }
      try {
        BackupCodec.validateSavedItem(item);
      } catch (_) {
        omitted++;
        continue;
      }

      final key = item.attachmentKey;
      if (key != null) {
        if (rejectedKeys.contains(key)) {
          omitted++;
          continue;
        }
        if (!includedKeys.contains(key)) {
          final raw = _attachmentsBox.get(key);
          if (!isValidAttachmentByteList(raw)) {
            rejectedKeys.add(key);
            omitted++;
            continue;
          }
          final bytes = (raw as List).cast<int>();
          if (totalBytes + bytes.length > BackupCodec.maxTotalAttachmentBytes) {
            rejectedKeys.add(key);
            omitted++;
            continue;
          }
          totalBytes += bytes.length;
          includedKeys.add(key);
          if (copyAttachmentBytes) {
            byteMap[key] = Uint8List.fromList(bytes);
          }
        }
      }
      exportableItems.add(item);
    }

    return (
      items: List<SavedItem>.unmodifiable(exportableItems),
      attachmentBytes: byteMap,
      omitted: omitted,
    );
  }

  /// Takes the export snapshot behind pending writes so item metadata,
  /// attachment bytes and collection preferences come from one serialized
  /// repository state instead of interleaving with a save/delete/restore.
  Future<String> createBackup() => _serializeOperation(_createBackup);

  Future<String> _createBackup() async {
    final unrepresentedAssignments = unrepresentedCollectionAssignmentCount;
    if (unrepresentedAssignments > 0) {
      final itemLabel = unrepresentedAssignments == 1
          ? '1 saved item is'
          : '$unrepresentedAssignments saved items are';
      throw FormatException(
        '$itemLabel assigned to collection names that cannot be included '
        'within the 500-collection backup limit. Edit those items and move '
        'them to an available collection or choose No collection before exporting.',
      );
    }

    final snapshot = _buildBackupSnapshot(copyAttachmentBytes: true);
    final source = BackupCodec.encode(
      items: snapshot.items,
      attachmentBytes: snapshot.attachmentBytes,
      collections: List<String>.from(collections.value),
      omittedUnreadableRecordCount: skippedRecordCount.value,
      omittedCollectionEntryCount: skippedCollectionCount.value,
      omittedUnexportableRecordCount: snapshot.omitted,
    );

    // Keep preparation time within this serialized operation. Otherwise a
    // queued save could complete between snapshot generation and timestamp
    // storage, making the status appear newer than the backup contents.
    try {
      await _writeBackupPreparedAt(DateTime.now().millisecondsSinceEpoch);
    } catch (_) {
      // A backup has already been generated. This optional status must never
      // prevent the caller from receiving it.
    }
    return source;
  }

  Future<int> restoreBackup(String source) async {
    return restoreDecodedBackup(BackupCodec.decode(source));
  }

  /// Restores a backup that has already passed codec validation. The UI can
  /// decode once before confirmation and avoid parsing large JSON/base64 data
  /// a second time after the user accepts the merge.
  Future<int> restoreDecodedBackup(DecodedBackup decoded) {
    try {
      // Validate before copying so malformed public objects cannot force
      // unbounded allocations. Own every mutable component before queue entry:
      // the caller may change its lists/maps/byte buffers while this restore
      // waits behind another repository operation.
      BackupCodec.validateDecodedBackup(decoded);
      final backup = DecodedBackup(
        items: List<SavedItem>.unmodifiable(
          decoded.items.map(
            (item) => item.copyWith(
              tags: List<String>.unmodifiable(item.tags),
            ),
          ),
        ),
        attachments: Map<String, BackupAttachment>.unmodifiable({
          for (final entry in decoded.attachments.entries)
            entry.key: BackupAttachment(
              name: entry.value.name,
              mimeType: entry.value.mimeType,
              bytes: Uint8List.fromList(entry.value.bytes),
            ),
        }),
        collections: List<String>.unmodifiable(decoded.collections),
        exportedAt: decoded.exportedAt,
        omittedUnreadableRecordCount: decoded.omittedUnreadableRecordCount,
        omittedCollectionEntryCount: decoded.omittedCollectionEntryCount,
        omittedUnexportableRecordCount: decoded.omittedUnexportableRecordCount,
      );
      BackupCodec.validateDecodedBackup(backup);
      return _serializeOperation(() => _restoreDecodedBackup(backup));
    } catch (error, stackTrace) {
      // Preserve the async Future-based error contract even when validation
      // rejects the input before it enters the operation queue.
      return Future<int>.error(error, stackTrace);
    }
  }

  Future<int> _restoreDecodedBackup(DecodedBackup backup) async {
    final afterSnapshot = restoreAfterSnapshotForTesting;
    if (afterSnapshot != null) await afterSnapshot();

    BackupCodec.validateItemCount(
      currentCount: items.value.length,
      incomingCount: backup.items.length,
    );
    final mergedCollections = List<String>.from(collections.value);
    final importedCollectionNames = <String>[
      ...backup.collections,
      ...backup.items
          .map((item) => item.collection)
          .whereType<String>(),
    ];
    for (final name in importedCollectionNames) {
      if (!mergedCollections.any(
        (existing) => existing.toLowerCase() == name.toLowerCase(),
      )) {
        mergedCollections.add(name);
      }
    }
    if (mergedCollections.length > BackupCodec.maxCollections) {
      throw const FormatException(
        'Restore would exceed StashHive’s 500-collection limit. '
        'Remove some collections before restoring this backup.',
      );
    }
    final canonicalMergedCollections = <String, String>{
      for (final name in mergedCollections) name.toLowerCase(): name,
    };
    final staged = <({SavedItem item, List<int>? bytes})>[];
    // Reserve raw box keys too, including keys belonging to unreadable records
    // or orphaned attachments, so rollback can safely delete every staged ID.
    final reserved = <String>{
      ..._itemsBox.keys.whereType<String>(),
      ..._attachmentsBox.keys.whereType<String>(),
    };
    // Raw legacy records may reference a missing payload key. Reserve those
    // references too so restore cannot accidentally make a different item use
    // that key as its ID/attachment key and silently "heal" the legacy record.
    for (final storedId in _itemsBox.keys) {
      final value = _itemsBox.get(storedId);
      if (value is Map && value['attachmentKey'] is String) {
        reserved.add(value['attachmentKey'] as String);
      }
    }
    final seenImportedIds = <String>{};
    final mappedAttachmentKeys = <String, String>{};
    final stagedAttachmentKeys = <String>{};
    for (final item in backup.items) {
      var newId = item.id;
      if (reserved.contains(newId) || !seenImportedIds.add(newId)) {
        newId = createUniqueId();
        while (reserved.contains(newId) || seenImportedIds.contains(newId)) {
          newId = createUniqueId();
        }
        seenImportedIds.add(newId);
      }
      final oldKey = item.attachmentKey;
      final attachment = oldKey == null ? null : backup.attachments[oldKey];
      String? mappedKey;
      List<int>? bytesToWrite;
      if (oldKey != null && attachment != null) {
        // Preserve intentional shared-attachment relationships across restore.
        // Use one collision-safe new key and stage the bytes only once.
        mappedKey = mappedAttachmentKeys.putIfAbsent(oldKey, () => newId);
        if (stagedAttachmentKeys.add(oldKey)) {
          bytesToWrite = attachment.bytes;
        }
      }
      final incomingCollection = item.collection;
      final canonicalCollection = incomingCollection == null
          ? null
          : canonicalMergedCollections[
                  incomingCollection.toLowerCase()] ??
              incomingCollection;
      final restored = SavedItem(
        id: newId,
        kind: item.kind,
        title: item.title,
        content: item.content,
        url: item.url,
        tags: item.tags,
        collection: canonicalCollection,
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
      final beforeCollectionsCommit = restoreBeforeCollectionsCommitForTesting;
      if (beforeCollectionsCommit != null) {
        await beforeCollectionsCommit();
      }
      await _preferencesBox.put('collections', mergedCollections);
    } catch (_) {
      // Every staged ID is guaranteed not to have existed before this restore.
      // Remove item records first so attachment cleanup can check all surviving
      // references, including records whose rollback deletion itself failed.
      for (final entry in staged.reversed) {
        try {
          final beforeRollbackItemDelete =
              restoreBeforeRollbackItemDeleteForTesting;
          if (beforeRollbackItemDelete != null) {
            await beforeRollbackItemDelete(entry.item.id);
          }
          await _itemsBox.delete(entry.item.id);
        } catch (_) {
          // Preserve the original restore error; don't mask the primary failure.
        }
      }
      // Shared payload keys can be referenced by multiple imported records.
      // Only reclaim a payload after all item-delete attempts and only when no
      // surviving raw record (including an unreadable legacy-shaped record)
      // still references it.
      final rollbackAttachmentKeys = staged
          .map((entry) => entry.item.attachmentKey)
          .whereType<String>()
          .toSet();
      for (final key in rollbackAttachmentKeys) {
        if (_hasAttachmentReference(key)) continue;
        try {
          await _attachmentsBox.delete(key);
        } catch (_) {
          // Continue best-effort rollback of the remaining attachment payloads.
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
      // A best-effort rollback can leave staged records behind if storage
      // refuses deletion; keep the notifiers aligned with what is actually stored.
      _refreshItems();
      _refreshCollections();
      rethrow;
    }
    _refreshItems();
    _refreshCollections();
    return staged.length;
  }

  void dispose() {
    _items.dispose();
    _collections.dispose();
    _skippedRecordCount.dispose();
    _skippedCollectionCount.dispose();
  }
}
