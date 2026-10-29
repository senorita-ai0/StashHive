import '../models/saved_item.dart';

const int maxSelectedMarkdownExportItems = 2000;
const int maxSelectedMarkdownExportCharacters = 2 * 1024 * 1024;

/// Builds a portable Markdown index of selected library records.
///
/// This intentionally exports metadata and user-entered text only; attachment
/// bytes remain in StashHive's versioned JSON backup. No network access occurs.
String buildSelectedItemsMarkdown(List<SavedItem> items) {
  if (items.isEmpty) {
    throw const FormatException('Select at least one item to export.');
  }
  if (items.length > maxSelectedMarkdownExportItems) {
    throw const FormatException('Export up to 2,000 selected items at a time.');
  }

  final buffer = StringBuffer('# StashHive selected items\n\n');
  for (final item in items) {
    final safeTitle = item.title.replaceAll('\n', ' ').replaceAll('\r', ' ');
    buffer.writeln('## $safeTitle');
    buffer.writeln('- Type: ${item.kind.label}');
    if (item.url != null) buffer.writeln('- URL: ${item.url}');
    if (item.collection != null) buffer.writeln('- Collection: ${item.collection}');
    if (item.tags.isNotEmpty) buffer.writeln('- Tags: ${item.tags.join(', ')}');
    if (item.isFavorite) buffer.writeln('- Favorite: yes');
    buffer.writeln('- Reading status: ${item.readingStatus.label}');
    buffer.writeln('- Reading progress: ${item.readingProgress}%');
    if (item.attachmentName != null) {
      buffer.writeln('- Attachment: ${item.attachmentName}');
    }
    if (item.content.trim().isNotEmpty) {
      buffer.writeln();
      buffer.writeln(item.content.trim());
    }
    if (item.annotations.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('### Highlights & annotations');
      for (final annotation in item.annotations) {
        if (annotation.quote.trim().isNotEmpty) {
          buffer.writeln();
          for (final line in annotation.quote.split('\n')) {
            buffer.writeln('> $line');
          }
        }
        if (annotation.note.trim().isNotEmpty) {
          buffer.writeln();
          buffer.writeln('**Note:**');
          for (final line in annotation.note.split('\n')) {
            buffer.writeln('> $line');
          }
        }
      }
    }
    buffer.writeln();
    if (buffer.length > maxSelectedMarkdownExportCharacters) {
      throw const FormatException(
        'This selection is too large to export as one list. Select fewer items.',
      );
    }
  }
  return buffer.toString();
}
