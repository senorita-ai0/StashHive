import 'dart:convert';

import '../models/saved_item.dart';

const int maxLibraryCsvItems = 10000;
const int maxLibraryCsvCharacters = 5 * 1024 * 1024;

/// Exports library metadata and user-entered text as UTF-8-compatible CSV text.
/// Attachment bytes are intentionally excluded; use the versioned JSON backup
/// when the goal is complete library recovery.
String buildLibraryCsv(List<SavedItem> items) {
  if (items.length > maxLibraryCsvItems) {
    throw const FormatException('The library has too many items for CSV export.');
  }
  final buffer = StringBuffer();
  buffer.writeln(const [
    'id',
    'type',
    'title',
    'url',
    'content',
    'tags',
    'collection',
    'is_favorite',
    'reading_status',
    'reading_progress',
    'created_at_ms',
    'updated_at_ms',
    'attachment_name',
  ].map(_csvField).join(','));

  for (final item in items) {
    final row = <String>[
      item.id,
      item.kind.name,
      item.title,
      item.url ?? '',
      item.content,
      item.tags.join('|'),
      item.collection ?? '',
      item.isFavorite ? 'true' : 'false',
      item.readingStatus.name,
      item.readingProgress.toString(),
      item.createdAtMs.toString(),
      item.updatedAtMs.toString(),
      item.attachmentName ?? '',
    ];
    buffer.writeln(row.map(_csvField).join(','));
    if (buffer.length > maxLibraryCsvCharacters) {
      throw const FormatException(
        'The CSV export is too large. Export a smaller library or use JSON backup.',
      );
    }
  }
  return buffer.toString();
}

String _csvField(String value) {
  // Spreadsheet programs may interpret leading formula markers as executable
  // formulas. Prefix those cells with an apostrophe before CSV quoting.
  final safeValue = RegExp(r'^[=+\-@\t\r]').hasMatch(value) ? "'$value" : value;
  final escaped = safeValue.replaceAll('"', '""');
  if (escaped.contains(',') ||
      escaped.contains('"') ||
      escaped.contains('\n') ||
      escaped.contains('\r')) {
    return '"$escaped"';
  }
  return escaped;
}

/// Reports the encoded size without allocating another full export copy.
int libraryCsvUtf8Size(String value) => utf8.encode(value).length;
