import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:cross_file/cross_file.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../models/saved_item.dart';

const int maxIncomingAttachmentBytes = 15 * 1024 * 1024;
const int maxIncomingTextCharacters = 1000000;

/// A user-selected or OS-shared item ready to prefill StashHive's save form.
class IncomingShare {
  const IncomingShare({
    required this.kind,
    this.title = '',
    this.url,
    this.content = '',
    this.bytes,
    this.fileName,
    this.mimeType,
    this.sharePosition = 1,
    this.shareTotal = 1,
  });

  final ItemKind kind;
  final String title;
  final String? url;
  final String content;
  final Uint8List? bytes;
  final String? fileName;
  final String? mimeType;
  final int sharePosition;
  final int shareTotal;

  IncomingShare withShareProgress({
    required int position,
    required int total,
  }) {
    final safeTotal = total < 1 ? 1 : total;
    final safePosition = position < 1
        ? 1
        : position > safeTotal
            ? safeTotal
            : position;
    return IncomingShare(
      kind: kind,
      title: title,
      url: url,
      content: content,
      bytes: bytes,
      fileName: fileName,
      mimeType: mimeType,
      sharePosition: safePosition,
      shareTotal: safeTotal,
    );
  }
}

/// Filters only near-simultaneous duplicate deliveries from the initial intent
/// API and the broadcast stream. A later deliberate share of the same URL is
/// accepted after the short de-duplication window.
class ShareEventDeduplicator {
  ShareEventDeduplicator({
    this.window = const Duration(seconds: 3),
    this.maxEntries = 64,
  })  : assert(window > Duration.zero),
        assert(maxEntries > 0);

  final Duration window;
  final int maxEntries;
  final Map<String, DateTime> _seen = <String, DateTime>{};

  bool shouldAccept(
    List<SharedMediaFile> media, {
    DateTime? now,
  }) {
    if (media.isEmpty) return false;
    final timestamp = now ?? DateTime.now();
    _seen.removeWhere((_, seenAt) {
      final age = timestamp.difference(seenAt);
      return age.isNegative || age > window;
    });

    // Hash the canonical ordered fields so the bounded cache retains only a
    // fixed-size digest, not copies of potentially large shared text/paths.
    // Canonical JSON preserves field and batch boundaries before hashing.
    final canonical = jsonEncode(
      media
          .map((item) => <Object?>[item.type.name, item.path, item.mimeType, item.message])
          .toList(growable: false),
    );
    final fingerprint = sha256.convert(utf8.encode(canonical)).toString();
    final previous = _seen[fingerprint];
    if (previous != null && timestamp.difference(previous) <= window) {
      return false;
    }

    while (_seen.length >= maxEntries) {
      _seen.remove(_seen.keys.first);
    }
    _seen[fingerprint] = timestamp;
    return true;
  }
}

/// Converts Android OS shares into draft values. It never saves automatically;
/// the user reviews and confirms the item in Quick Save.
class ShareIntake {
  ShareIntake._();

  static const Set<String> _imageExtensions = <String>{
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
    'bmp',
    'heic',
    'heif',
  };
  static const Set<String> _documentExtensions = <String>{
    'pdf',
    'txt',
    'doc',
    'docx',
    'rtf',
    'csv',
  };
  static const Set<String> _documentMimeTypes = <String>{
    'application/pdf',
    'text/plain',
    'text/csv',
    'application/msword',
    'application/rtf',
    'text/rtf',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  };

  static Future<IncomingShare?> fromSharedMedia(SharedMediaFile media) async {
    final path = media.path.trim();
    if (path.isEmpty) {
      throw const FormatException('The shared item did not contain any content.');
    }

    switch (media.type) {
      case SharedMediaType.url:
        final uri = _parseWebUrl(path);
        if (uri == null) {
          throw const FormatException('Only http and https links can be saved.');
        }
        return IncomingShare(
          kind: ItemKind.link,
          title: uri.host,
          url: uri.toString(),
          content: media.message?.trim() ?? '',
        );
      case SharedMediaType.text:
        final text = (media.message?.trim().isNotEmpty ?? false)
            ? media.message!.trim()
            : path;
        return _fromText(text);
      case SharedMediaType.image:
        return _fromFile(media, forceImage: true);
      case SharedMediaType.file:
        return _fromFile(media);
      case SharedMediaType.video:
        return null;
    }
  }

  static IncomingShare _fromText(String text) {
    if (text.trim().isEmpty) {
      throw const FormatException('The shared text is empty.');
    }
    if (text.length > maxIncomingTextCharacters) {
      throw const FormatException('Shared text is over the 1,000,000-character limit.');
    }

    final standalone = _parseWebUrl(text.trim());
    if (standalone != null) {
      return IncomingShare(
        kind: ItemKind.link,
        title: standalone.host,
        url: standalone.toString(),
      );
    }

    final match = RegExp(
      r'''https?://[^\s<>"']+''',
      caseSensitive: false,
    ).firstMatch(text);
    if (match != null) {
      final rawUrl = _trimTrailingShareUrlPunctuation(match.group(0) ?? '');
      final uri = _parseWebUrl(rawUrl);
      if (uri != null) {
        final before = text.substring(0, match.start).trim();
        final after = text.substring(match.end).trim();
        final beforeLines = before
            .split(RegExp(r'[\r\n]+'))
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty)
            .toList(growable: false);
        final titleLine =
            beforeLines.isEmpty ? uri.host : beforeLines.first;
        final additionalBefore = beforeLines.length <= 1
            ? ''
            : beforeLines.skip(1).join('\n').trim();
        final noteParts = <String>[
          if (additionalBefore.isNotEmpty) additionalBefore,
          if (after.isNotEmpty) after,
        ];
        final title =
            titleLine.length > 500 ? titleLine.substring(0, 500) : titleLine;
        return IncomingShare(
          kind: ItemKind.link,
          title: title,
          url: uri.toString(),
          content: noteParts.join('\n'),
        );
      }
    }

    return IncomingShare(
      kind: ItemKind.note,
      content: text,
    );
  }

  static Future<IncomingShare> _fromFile(
    SharedMediaFile media, {
    bool forceImage = false,
  }) async {
    final rawPath = media.path.trim();
    final parsedPath = Uri.tryParse(rawPath);
    final localPath =
        parsedPath?.scheme == 'file' ? parsedPath!.toFilePath() : rawPath;
    final fileName = _basename(localPath);
    final extension = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : '';
    final sharedMime = media.mimeType?.toLowerCase().trim() ?? '';
    final guessedMime = _guessMimeType(extension);
    final mimeType =
        sharedMime.isEmpty || sharedMime == 'application/octet-stream'
            ? guessedMime
            : sharedMime;

    final isImage = forceImage ||
        mimeType.startsWith('image/') ||
        _imageExtensions.contains(extension);
    if (!isImage &&
        !_documentExtensions.contains(extension) &&
        !_documentMimeTypes.contains(mimeType)) {
      throw const FormatException(
        'StashHive currently accepts shared images and PDF, TXT, DOC/DOCX, RTF or CSV files.',
      );
    }

    final file = XFile(localPath, mimeType: mimeType);
    final length = await file.length();
    if (length > maxIncomingAttachmentBytes) {
      throw const FormatException('Shared files must be 15 MB or smaller.');
    }
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw const FormatException('The shared file is empty or unavailable.');
    }
    if (bytes.length > maxIncomingAttachmentBytes) {
      throw const FormatException('Shared files must be 15 MB or smaller.');
    }

    return IncomingShare(
      kind: isImage ? ItemKind.image : ItemKind.document,
      title: fileName.isEmpty
          ? (isImage ? 'Shared image' : 'Shared document')
          : fileName,
      content: '',
      bytes: Uint8List.fromList(bytes),
      fileName: fileName,
      mimeType: mimeType,
    );
  }

  /// Removes punctuation that surrounds a shared URL without removing
  /// balanced parentheses/brackets that are legitimately part of its path.
  static String _trimTrailingShareUrlPunctuation(String value) {
    var end = value.length;
    const trailingPunctuation = '.,;:!?';
    while (end > 0 && trailingPunctuation.contains(value[end - 1])) {
      end--;
    }
    final result = value.substring(0, end);
    const pairs = <String, String>{')': '(', ']': '[', '}': '{'};
    final openCounts = <String, int>{'(': 0, '[': 0, '{': 0};
    final closeCounts = <String, int>{')': 0, ']': 0, '}': 0};
    for (var index = 0; index < result.length; index++) {
      final character = result[index];
      if (openCounts.containsKey(character)) {
        openCounts[character] = openCounts[character]! + 1;
      }
      if (closeCounts.containsKey(character)) {
        closeCounts[character] = closeCounts[character]! + 1;
      }
    }
    end = result.length;
    while (end > 0) {
      final closing = result[end - 1];
      final opening = pairs[closing];
      if (opening == null || closeCounts[closing]! <= openCounts[opening]!) {
        break;
      }
      closeCounts[closing] = closeCounts[closing]! - 1;
      end--;
    }
    return result.substring(0, end);
  }

  static Uri? _parseWebUrl(String value) {
    final text = value.trim();
    if (text.isEmpty || text.contains(RegExp(r'\s'))) return null;
    final hostPort = RegExp(r'^([a-zA-Z0-9.-]+):[0-9]+').firstMatch(text);
    final hostPortName = hostPort?.group(1)?.toLowerCase();
    final hasBareHostPort = hostPortName != null &&
        (hostPortName.contains('.') || hostPortName == 'localhost');
    final explicitScheme =
        RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*:').hasMatch(text) &&
            !hasBareHostPort;
    if (explicitScheme &&
        !text.toLowerCase().startsWith('http://') &&
        !text.toLowerCase().startsWith('https://')) {
      return null;
    }
    final candidate = text.contains('://') ? text : 'https://' + text;
    final uri = Uri.tryParse(candidate);
    if (uri == null ||
        (uri.scheme.toLowerCase() != 'http' &&
            uri.scheme.toLowerCase() != 'https') ||
        uri.host.isEmpty) {
      return null;
    }
    final hasHttpScheme = text.toLowerCase().startsWith('http://') ||
        text.toLowerCase().startsWith('https://');
    if (!hasHttpScheme &&
        uri.host.toLowerCase() != 'localhost' &&
        !uri.host.contains('.')) {
      // A plain word such as "remember" is note text, not a web address.
      // Continue accepting bare domains like "example.com/path".
      return null;
    }
    return uri;
  }
  static String _basename(String path) {
    final normalized = path.replaceAll('\\', '/');
    final parts = normalized.split('/').where((part) => part.isNotEmpty);
    return parts.isEmpty ? '' : parts.last;
  }

  static String _guessMimeType(String extension) {
    return switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      'bmp' => 'image/bmp',
      'heic' => 'image/heic',
      'heif' => 'image/heif',
      'pdf' => 'application/pdf',
      'txt' => 'text/plain',
      'csv' => 'text/csv',
      'doc' => 'application/msword',
      'docx' =>
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'rtf' => 'application/rtf',
      _ => 'application/octet-stream',
    };
  }
}
), '');
    const pairs = <String, String>{')': '(', ']': '[', '}': '{'};
    while (result.isNotEmpty) {
      final closing = result.substring(result.length - 1);
      final opening = pairs[closing];
      if (opening == null) break;
      var openCount = 0;
      var closeCount = 0;
      for (final character in result.split('')) {
        if (character == opening) openCount++;
        if (character == closing) closeCount++;
      }
      if (closeCount <= openCount) break;
      result = result.substring(0, result.length - 1);
    }
    return result;
  }

  static Uri? _parseWebUrl(String value) {
    final text = value.trim();
    if (text.isEmpty || text.contains(RegExp(r'\s'))) return null;
    final explicitScheme =
        RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*:').hasMatch(text);
    if (explicitScheme &&
        !text.toLowerCase().startsWith('http://') &&
        !text.toLowerCase().startsWith('https://')) {
      return null;
    }
    final candidate = text.contains('://') ? text : 'https://' + text;
    final uri = Uri.tryParse(candidate);
    if (uri == null ||
        (uri.scheme.toLowerCase() != 'http' &&
            uri.scheme.toLowerCase() != 'https') ||
        uri.host.isEmpty) {
      return null;
    }
    return uri;
  }

  static String _basename(String path) {
    final normalized = path.replaceAll('\\', '/');
    final parts = normalized.split('/').where((part) => part.isNotEmpty);
    return parts.isEmpty ? '' : parts.last;
  }

  static String _guessMimeType(String extension) {
    return switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      'bmp' => 'image/bmp',
      'heic' => 'image/heic',
      'heif' => 'image/heif',
      'pdf' => 'application/pdf',
      'txt' => 'text/plain',
      'csv' => 'text/csv',
      'doc' => 'application/msword',
      'docx' =>
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'rtf' => 'application/rtf',
      _ => 'application/octet-stream',
    };
  }
}
