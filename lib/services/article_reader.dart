import 'dart:typed_data';

import 'package:flutter/foundation.dart' show visibleForTesting;

import 'article_reader_stub.dart'
    if (dart.library.io) 'article_reader_io.dart'
    if (dart.library.js_interop) 'article_reader_web.dart' as platform;

const int maxArticleResponseBytes = 1024 * 1024;
const int maxArticleTextCharacters = 60000;
const Duration defaultArticleReaderTimeout = Duration(seconds: 12);

enum ArticleReaderState {
  success,
  invalidUrl,
  blockedAddress,
  unsupportedContent,
  tooLarge,
  timedOut,
  unavailableInBrowser,
  networkError,
}

class ArticleReaderResult {
  const ArticleReaderResult({
    required this.state,
    this.title,
    this.text = '',
    this.message,
  });

  final ArticleReaderState state;
  final String? title;
  final String text;
  final String? message;

  bool get isSuccess => state == ArticleReaderState.success;
}

/// Bounded, already-received HTTP response data. This DTO is shared so the
/// native request pipeline can be tested with a fake response and no network.
class ArticleReaderTransportResponse {
  ArticleReaderTransportResponse({
    required this.statusCode,
    required this.contentType,
    required List<int> body,
  }) : body = Uint8List.fromList(body);

  final int statusCode;
  final String contentType;
  final Uint8List body;
}

typedef ArticleReaderDnsResolver = Future<List<String>> Function(String host);
typedef ArticleReaderTransport = Future<ArticleReaderTransportResponse> Function(
  Uri uri,
  List<String> vettedIpv4Addresses,
  Duration timeout,
);

/// Test seams only. Production leaves these null and uses OS DNS + direct
/// socket networking, with validated addresses pinned to the connection.
@visibleForTesting
ArticleReaderDnsResolver? articleReaderDnsResolverForTesting;

@visibleForTesting
ArticleReaderTransport? articleReaderTransportForTesting;

/// Validates a URL before any request is attempted. Native transport repeats
/// destination checks after DNS resolution and pins its connection to that IP.
Uri? parseArticleReaderUrl(String value) {
  final uri = Uri.tryParse(value.trim());
  if (uri == null ||
      (uri.scheme.toLowerCase() != 'http' &&
          uri.scheme.toLowerCase() != 'https') ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty ||
      uri.host.length > 253 ||
      uri.toString().length > 4096) {
    return null;
  }
  final host = uri.host.toLowerCase().replaceAll(RegExp(r'\.$'), '');
  if (host == 'localhost' ||
      host.endsWith('.localhost') ||
      host.endsWith('.local') ||
      host.endsWith('.internal') ||
      host.contains('%') ||
      host.contains(':') ||
      _isPrivateIpv4Literal(host) ||
      (host.startsWith('[') && host.endsWith(']'))) {
    // Literal IPv6 destinations are conservatively excluded in this first
    // slice. A public IPv6 URL can still be opened in the external browser.
    return null;
  }
  return uri;
}

bool _isPrivateIpv4Literal(String host) {
  final parts = host.split('.');
  if (parts.length != 4) return false;
  final octets = parts.map(int.tryParse).toList(growable: false);
  if (octets.any((value) => value == null || value < 0 || value > 255)) {
    return false;
  }
  final a = octets[0]!, b = octets[1]!, c = octets[2]!;
  return a == 0 ||
      a == 10 ||
      a == 127 ||
      a >= 224 ||
      (a == 100 && b >= 64 && b <= 127) ||
      (a == 169 && b == 254) ||
      (a == 172 && b >= 16 && b <= 31) ||
      (a == 192 && b == 168) ||
      (a == 192 && b == 0 && (c == 0 || c == 2)) ||
      (a == 192 && b == 88 && c == 99) ||
      (a == 198 && (b == 18 || b == 19)) ||
      (a == 198 && b == 51 && c == 100) ||
      (a == 203 && b == 0 && c == 113);
}

/// Removes active markup and decodes a conservative set of text entities.
/// The result is plain text and must never be interpreted as HTML.
String sanitizeArticleMarkup(String source, {bool isHtml = true}) {
  var text = source;
  if (isHtml) {
    // Prefer semantic article/main containers when available. This is a
    // lightweight fallback, not a full readability engine; some sites will
    // still include navigation or omit their main content from these tags.
    final article = RegExp(
      r'<article\b[^>]*>([\s\S]*?)</article\s*>',
      caseSensitive: false,
    ).firstMatch(source);
    final main = RegExp(
      r'<main\b[^>]*>([\s\S]*?)</main\s*>',
      caseSensitive: false,
    ).firstMatch(source);
    text = article?.group(1) ?? main?.group(1) ?? source;
    text = text.replaceAll(
      RegExp(
        r'<(script|style|noscript|svg|iframe|object|template|nav|footer|aside)\b[^>]*>[\s\S]*?</\1\s*>',
        caseSensitive: false,
      ),
      ' ',
    );
    text = text.replaceAll(RegExp(r'<!--[\s\S]*?-->'), ' ');
    text = text.replaceAll(
      RegExp(
        r'<br\s*/?>|</(p|div|article|section|h[1-6]|li|tr)\s*>',
        caseSensitive: false,
      ),
      '\n',
    );
    text = text.replaceAll(RegExp(r'<[^>]{0,2048}>'), ' ');
  }
  const entities = <String, String>{
    '&amp;': '&',
    '&lt;': '<',
    '&gt;': '>',
    '&quot;': '"',
    '&#39;': "'",
    '&apos;': "'",
    '&nbsp;': ' ',
    '&mdash;': '—',
    '&ndash;': '–',
    '&hellip;': '…',
  };
  text = text.replaceAllMapped(
    RegExp(r'&(?:amp|lt|gt|quot|apos|nbsp|mdash|ndash|hellip|#39);',
        caseSensitive: false),
    (match) => entities[match[0]!.toLowerCase()] ?? match[0]!,
  );
  text = text.replaceAllMapped(RegExp(r'&#(\d{1,7});'), (match) {
    final code = int.tryParse(match.group(1)!);
    if (code == null ||
        code < 1 ||
        code > 0x10FFFF ||
        (code >= 0xD800 && code <= 0xDFFF)) {
      return ' ';
    }
    return String.fromCharCode(code);
  });
  text = text.replaceAllMapped(
    RegExp(r'&#x([0-9a-f]{1,6});', caseSensitive: false),
    (match) {
      final code = int.tryParse(match.group(1)!, radix: 16);
      if (code == null ||
          code < 1 ||
          code > 0x10FFFF ||
          (code >= 0xD800 && code <= 0xDFFF)) {
        return ' ';
      }
      return String.fromCharCode(code);
    },
  );
  text = text.replaceAll('\r', '\n').replaceAll(RegExp(r'[\t\f\v ]+'), ' ');
  text = text
      .replaceAll(RegExp(r' *\n *'), '\n')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n');
  return text.trim();
}

/// Test seam for deterministic reader UI tests. Production leaves this unset.
@visibleForTesting
Future<ArticleReaderResult> Function(String url, Duration timeout)?
    articleReaderLoaderForTesting;

/// Called only from an explicit reader action. The result is transient and is
/// never written to LibraryRepository or included in backups.
Future<ArticleReaderResult> loadArticleForReader(
  String url, {
  Duration timeout = defaultArticleReaderTimeout,
}) {
  final testLoader = articleReaderLoaderForTesting;
  if (testLoader != null) return testLoader(url, timeout);
  return platform.loadArticleForReader(url, timeout: timeout);
}
