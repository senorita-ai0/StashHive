import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../models/saved_item.dart';
import 'duplicate_detector.dart';

const int maxBookmarkHtmlBytes = 10 * 1024 * 1024;
const int maxImportedBookmarks = 10000;

class BookmarkHtmlEntry {
  const BookmarkHtmlEntry({
    required this.title,
    required this.url,
    this.collection,
  });

  final String title;
  final String url;
  final String? collection;
}

class BookmarkHtmlImportResult {
  const BookmarkHtmlImportResult({
    required this.entries,
    required this.duplicateCount,
    required this.invalidCount,
    required this.collections,
  });

  final List<BookmarkHtmlEntry> entries;
  final int duplicateCount;
  final int invalidCount;
  final List<String> collections;
}

/// Parses browser-exported Netscape bookmark HTML without executing markup or
/// fetching links. Scripts and all non-anchor content are treated as inert text.
BookmarkHtmlImportResult parseBookmarkHtml(String source) {
  if (source.isEmpty) {
    throw const FormatException('The selected bookmark file is empty.');
  }
  if (source.length > maxBookmarkHtmlBytes ||
      utf8.encode(source).length > maxBookmarkHtmlBytes) {
    throw const FormatException('The bookmark file is too large to import.');
  }

  final inertSource = source
      .replaceAll(
        RegExp(r'<script\b[^>]*>.*?</script\s*>', caseSensitive: false, dotAll: true),
        ' ',
      )
      .replaceAll(
        RegExp(r'<style\b[^>]*>.*?</style\s*>', caseSensitive: false, dotAll: true),
        ' ',
      );
  final tokenPattern = RegExp(
    r'<h3\b[^>]*>.*?</h3\s*>|<a\b[^>]*>.*?</a\s*>|</?dl\b[^>]*>',
    caseSensitive: false,
    dotAll: true,
  );
  final anchorPattern = RegExp(
    r'^<a\b([^>]*)>(.*?)</a\s*>$',
    caseSensitive: false,
    dotAll: true,
  );
  final h3Pattern = RegExp(
    r'^<h3\b[^>]*>(.*?)</h3\s*>$',
    caseSensitive: false,
    dotAll: true,
  );
  final attributePattern = RegExp(
    r'([a-zA-Z_:][a-zA-Z0-9_:.-]*)\s*=\s*(?:"([^"]*)"|\'([^\']*)\'|([^\s>]+))',
    caseSensitive: false,
  );

  String? pendingFolder;
  final folderStack = <String?>[];
  final entries = <BookmarkHtmlEntry>[];
  final seenUrls = <String>{};
  final collections = <String>{};
  var duplicateCount = 0;
  var invalidCount = 0;

  for (final token in tokenPattern.allMatches(inertSource)) {
    final value = token.group(0)!;
    if (RegExp(r'^</dl\b', caseSensitive: false).hasMatch(value)) {
      if (folderStack.isNotEmpty) folderStack.removeLast();
      pendingFolder = null;
      continue;
    }
    if (RegExp(r'^<dl\b', caseSensitive: false).hasMatch(value)) {
      folderStack.add(pendingFolder);
      pendingFolder = null;
      continue;
    }

    final heading = h3Pattern.firstMatch(value);
    if (heading != null) {
      final name = _plainText(heading.group(1)!).trim();
      pendingFolder = name.isEmpty || name.length > 80 ? null : name;
      continue;
    }

    final anchor = anchorPattern.firstMatch(value);
    if (anchor == null) continue;
    String? href;
    for (final match in attributePattern.allMatches(anchor.group(1)!)) {
      final name = match.group(1)!.toLowerCase();
      if (name == 'href') {
        href = _decodeEntities(match.group(2) ?? match.group(3) ?? match.group(4) ?? '');
        break;
      }
    }
    final uri = href == null ? null : Uri.tryParse(href.trim());
    if (uri == null ||
        (uri.scheme.toLowerCase() != 'http' && uri.scheme.toLowerCase() != 'https') ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.toString().length > maxSavedItemUrlCharacters) {
      invalidCount++;
      continue;
    }

    final url = uri.toString();
    final key = normalizeUrlForDuplicateCheck(url);
    if (key == null) {
      invalidCount++;
      continue;
    }
    if (!seenUrls.add(key)) {
      duplicateCount++;
      continue;
    }
    if (entries.length >= maxImportedBookmarks) {
      throw const FormatException('The bookmark file contains too many links to import.');
    }

    var folderName = '';
    for (final folder in folderStack.reversed) {
      if (folder != null && folder.isNotEmpty) {
        folderName = folder;
        break;
      }
    }
    final collection = folderName.isEmpty ? null : folderName;
    if (collection != null) collections.add(collection);

    var title = _plainText(anchor.group(2)!).trim();
    if (title.isEmpty) title = uri.host;
    if (title.length > 500) title = title.substring(0, 500);
    entries.add(BookmarkHtmlEntry(
      title: title,
      url: url,
      collection: collection,
    ));
  }

  if (entries.isEmpty && invalidCount == 0) {
    throw const FormatException('No web bookmarks were found in this file.');
  }
  return BookmarkHtmlImportResult(
    entries: List<BookmarkHtmlEntry>.unmodifiable(entries),
    duplicateCount: duplicateCount,
    invalidCount: invalidCount,
    collections: List<String>.unmodifiable(collections),
  );
}

String _plainText(String html) =>
    _decodeEntities(html.replaceAll(RegExp(r'<[^>]*>'), ' '));

String _decodeEntities(String value) {
  return value.replaceAllMapped(RegExp(r'&(#x[0-9a-fA-F]+|#\d+|amp|quot|apos|lt|gt);'), (match) {
    final entity = match.group(1)!;
    switch (entity.toLowerCase()) {
      case 'amp':
        return '&';
      case 'quot':
        return '"';
      case 'apos':
        return "'";
      case 'lt':
        return '<';
      case 'gt':
        return '>';
      default:
        try {
          final number = entity.startsWith('#x') || entity.startsWith('#X')
              ? int.parse(entity.substring(2), radix: 16)
              : int.parse(entity.substring(1));
          if (number <= 0 || number > 0x10FFFF || (number >= 0xD800 && number <= 0xDFFF)) {
            return '';
          }
          return String.fromCharCode(number);
        } catch (_) {
          return '';
        }
    }
  });
}

/// Stable, non-sensitive ID seed for one import operation. The timestamp and
/// entry index avoid ID collisions between separate imports; URL deduplication
/// remains the primary protection against repeated imports.
String importedBookmarkId(String url, int index, int timestampMs) =>
    sha256.convert(utf8.encode('$url|$index|$timestampMs')).toString().substring(0, 32);
