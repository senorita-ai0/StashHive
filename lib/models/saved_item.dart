import 'package:flutter/material.dart';

const int maxSavedItemUrlCharacters = 4096;

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
    return ItemKind.values.firstWhere(
      (kind) => kind.name == value,
      orElse: () => throw FormatException('Unknown saved-item type: $value'),
    );
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

  bool matchesQuery(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    final searchable = <String>[
      title,
      content,
      if (url != null) url!,
      if (collection != null) collection!,
      ...tags,
    ];
    return searchable.any((value) => value.toLowerCase().contains(normalized));
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
    final tagsValue = raw['tags'];
    final tags = tagsValue is List
        ? tagsValue
            .whereType<String>()
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty)
            .toSet()
            .toList()
        : <String>[];
    return SavedItem(
      id: raw['id'] is String ? raw['id'] as String : '',
      kind: ItemKind.fromWire(raw['kind']),
      title: raw['title'] is String ? raw['title'] as String : '',
      content: raw['content'] is String ? raw['content'] as String : '',
      url: raw['url'] is String ? raw['url'] as String : null,
      tags: List<String>.unmodifiable(tags),
      collection: raw['collection'] is String ? raw['collection'] as String : null,
      isFavorite: raw['isFavorite'] == true,
      createdAtMs: raw['createdAtMs'] is int ? raw['createdAtMs'] as int : 0,
      updatedAtMs: raw['updatedAtMs'] is int ? raw['updatedAtMs'] as int : 0,
      attachmentKey: raw['attachmentKey'] is String
          ? raw['attachmentKey'] as String
          : null,
      attachmentName: raw['attachmentName'] is String
          ? raw['attachmentName'] as String
          : null,
      attachmentMimeType: raw['attachmentMimeType'] is String
          ? raw['attachmentMimeType'] as String
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
