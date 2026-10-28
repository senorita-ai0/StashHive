import 'package:flutter/material.dart';

const int maxSavedItemUrlCharacters = 4096;
const int maxSearchQueryCharacters = 4096;

enum ItemKind {
  link,
  note,
  image,
  document;

  String get label => switch (this) {
        ItemKind.link => 'Link',
        ItemKind.note => 'Note',
        ItemKind.image => 'Image',
        ItemKind.document => 'Document',
      };

  String get pluralLabel => switch (this) {
        ItemKind.link => 'Links',
        ItemKind.note => 'Notes',
        ItemKind.image => 'Images',
        ItemKind.document => 'Files',
      };

  IconData get icon => switch (this) {
        ItemKind.link => Icons.link_rounded,
        ItemKind.note => Icons.notes_rounded,
        ItemKind.image => Icons.image_outlined,
        ItemKind.document => Icons.description_outlined,
      };

  Color get accent => switch (this) {
        ItemKind.link => const Color(0xFF5B5CE2),
        ItemKind.note => const Color(0xFFB87A22),
        ItemKind.image => const Color(0xFF218F84),
        ItemKind.document => const Color(0xFF3673BE),
      };

  /// Darker foreground colours for small labels over each pastel chip fill.
  /// [accent] remains the more flexible icon/border colour used on other surfaces.
  Color get readableTextAccent => switch (this) {
        ItemKind.link => const Color(0xFF5152C5),
        ItemKind.note => const Color(0xFF8B5614),
        ItemKind.image => const Color(0xFF176B61),
        ItemKind.document => const Color(0xFF2B5F9F),
      };

  Color get softAccent => switch (this) {
        ItemKind.link => const Color(0xFFEEF0FF),
        ItemKind.note => const Color(0xFFFFF2DF),
        ItemKind.image => const Color(0xFFE2F6F2),
        ItemKind.document => const Color(0xFFEAF3FF),
      };

  static ItemKind fromWire(Object? value) {
    // Wire values may come from malformed local records or user-supplied
    // backups. Bound them before comparison and never echo arbitrary input in
    // an exception that may reach a UI error message.
    if (value is! String || value.length > 16) {
      throw const FormatException('Unknown saved-item type.');
    }
    for (final kind in ItemKind.values) {
      if (kind.name == value) return kind;
    }
    throw const FormatException('Unknown saved-item type.');
  }
}

@immutable
class SavedItem {
  const SavedItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.content,
    required this.tags,
    required this.isFavorite,
    required this.createdAtMs,
    required this.updatedAtMs,
    this.url,
    this.collection,
    this.attachmentKey,
    this.attachmentName,
    this.attachmentMimeType,
  });

  final String id;
  final ItemKind kind;
  final String title;
  final String content;
  final String? url;
  final List<String> tags;
  final String? collection;
  final bool isFavorite;
  final int createdAtMs;
  final int updatedAtMs;
  final String? attachmentKey;
  final String? attachmentName;
  final String? attachmentMimeType;

  bool get hasAttachment => attachmentKey != null && attachmentKey!.isNotEmpty;

  DateTime get createdAt =>
      DateTime.fromMillisecondsSinceEpoch(createdAtMs, isUtc: true).toLocal();

  DateTime get updatedAt =>
      DateTime.fromMillisecondsSinceEpoch(updatedAtMs, isUtc: true).toLocal();

  bool matchesQuery(String query) =>
      matchesNormalizedQuery(query.trim().toLowerCase());

  /// Matches an already trimmed, lower-case query. Search views can normalize
  /// once and reuse the result across many items instead of allocating the
  /// same lower-case query again for every saved record.
  bool matchesNormalizedQuery(String normalizedQuery) {
    if (normalizedQuery.isEmpty) return true;
    final searchable = <String>[
      title,
      content,
      if (url != null) url!,
      if (collection != null) collection!,
      ...tags,
    ];
    return searchable.any(
      (value) => value.toLowerCase().contains(normalizedQuery),
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'kind': kind.name,
        'title': title,
        'content': content,
        'url': url,
        'tags': List<String>.from(tags),
        'collection': collection,
        'isFavorite': isFavorite,
        'createdAtMs': createdAtMs,
        'updatedAtMs': updatedAtMs,
        'attachmentKey': attachmentKey,
        'attachmentName': attachmentName,
        'attachmentMimeType': attachmentMimeType,
      };

  factory SavedItem.fromMap(Map<dynamic, dynamic> raw) {
    final idValue = raw['id'];
    final kindValue = raw['kind'];
    final titleValue = raw['title'];
    final contentValue = raw['content'];
    final urlValue = raw['url'];
    final collectionValue = raw['collection'];
    final attachmentKeyValue = raw['attachmentKey'];
    final attachmentNameValue = raw['attachmentName'];
    final attachmentMimeTypeValue = raw['attachmentMimeType'];

    // This factory is public and may be called without the repository/backup
    // validators. Reject overlong strings before normalization or copying.
    if ((idValue is String && idValue.length > 128) ||
        (kindValue is String && kindValue.length > 16) ||
        (titleValue is String && titleValue.length > 500) ||
        (contentValue is String && contentValue.length > 1000000) ||
        (urlValue is String && urlValue.length > maxSavedItemUrlCharacters) ||
        (collectionValue is String && collectionValue.length > 80) ||
        (attachmentKeyValue is String && attachmentKeyValue.length > 128) ||
        (attachmentNameValue is String && attachmentNameValue.length > 255) ||
        (attachmentMimeTypeValue is String && attachmentMimeTypeValue.length > 128)) {
      throw const FormatException(
        'A saved item contains fields beyond supported storage limits.',
      );
    }

    final tagsValue = raw['tags'];
    if (tagsValue is List) {
      if (tagsValue.length > 100 ||
          tagsValue.any((tag) => tag is String && tag.length > 100)) {
        throw const FormatException(
          'A saved item contains an invalid or oversized tag list.',
        );
      }
    }
    final seenTags = <String>{};
    final tags = <String>[];
    if (tagsValue is List) {
      for (final value in tagsValue) {
        if (value is! String) continue;
        final tag = value.trim();
        if (tag.isNotEmpty && seenTags.add(tag.toLowerCase())) {
          // Preserve the spelling of the first occurrence while treating tags
          // case-insensitively, consistent with Quick Save and tag filters.
          tags.add(tag);
        }
      }
    }
    return SavedItem(
      id: raw['id'] is String ? raw['id'] as String : '',
      kind: ItemKind.fromWire(raw['kind']),
      title: raw['title'] is String ? (raw['title'] as String).trim() : '',
      content: raw['content'] is String ? raw['content'] as String : '',
      url: raw['url'] is String ? (raw['url'] as String).trim() : null,
      tags: List<String>.unmodifiable(tags),
      collection: raw['collection'] is String
          ? (raw['collection'] as String).trim().isEmpty
              ? null
              : (raw['collection'] as String).trim()
          : null,
      isFavorite: raw['isFavorite'] == true,
      createdAtMs: raw['createdAtMs'] is int ? raw['createdAtMs'] as int : 0,
      updatedAtMs: raw['updatedAtMs'] is int ? raw['updatedAtMs'] as int : 0,
      attachmentKey: raw['attachmentKey'] is String
          ? raw['attachmentKey'] as String
          : null,
      attachmentName: raw['attachmentName'] is String
          ? (raw['attachmentName'] as String).trim()
          : null,
      attachmentMimeType: raw['attachmentMimeType'] is String
          ? (raw['attachmentMimeType'] as String).trim().toLowerCase()
          : null,
    );
  }

  SavedItem copyWith({
    String? title,
    String? content,
    String? url,
    bool clearUrl = false,
    List<String>? tags,
    String? collection,
    bool clearCollection = false,
    bool? isFavorite,
    int? updatedAtMs,
    String? attachmentKey,
    bool clearAttachment = false,
    String? attachmentName,
    String? attachmentMimeType,
  }) {
    return SavedItem(
      id: id,
      kind: kind,
      title: title ?? this.title,
      content: content ?? this.content,
      url: clearUrl ? null : (url ?? this.url),
      tags: tags ?? this.tags,
      collection: clearCollection ? null : (collection ?? this.collection),
      isFavorite: isFavorite ?? this.isFavorite,
      createdAtMs: createdAtMs,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
      attachmentKey: clearAttachment ? null : (attachmentKey ?? this.attachmentKey),
      attachmentName: clearAttachment ? null : (attachmentName ?? this.attachmentName),
      attachmentMimeType: clearAttachment
          ? null
          : (attachmentMimeType ?? this.attachmentMimeType),
    );
  }
}


/// Stable ordering for the Library and Search views. The primary key matches
/// the visible sort label; equal primary values use deterministic secondary
/// fields and finish with the persisted item ID so list order doesn't flicker.
enum SavedItemSort {
  recentlySaved,
  oldestFirst,
  titleAZ,
}

int compareSavedItemsForSort(
  SavedItem a,
  SavedItem b,
  SavedItemSort sort,
) {
  final primary = switch (sort) {
    SavedItemSort.recentlySaved =>
      b.updatedAtMs.compareTo(a.updatedAtMs),
    SavedItemSort.oldestFirst =>
      a.createdAtMs.compareTo(b.createdAtMs),
    SavedItemSort.titleAZ =>
      a.title.toLowerCase().compareTo(b.title.toLowerCase()),
  };
  if (primary != 0) return primary;

  if (sort == SavedItemSort.recentlySaved) {
    final byCreation = b.createdAtMs.compareTo(a.createdAtMs);
    if (byCreation != 0) return byCreation;
  } else if (sort == SavedItemSort.oldestFirst) {
    final byUpdated = a.updatedAtMs.compareTo(b.updatedAtMs);
    if (byUpdated != 0) return byUpdated;
  }

  final byFoldedTitle =
      a.title.toLowerCase().compareTo(b.title.toLowerCase());
  if (byFoldedTitle != 0) return byFoldedTitle;
  final byExactTitle = a.title.compareTo(b.title);
  if (byExactTitle != 0) return byExactTitle;
  return a.id.compareTo(b.id);
}
