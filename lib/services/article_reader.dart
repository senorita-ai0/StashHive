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

/// Validates a URL before any request is attempted. Network-address validation
/// is repeated by the native transport after DNS resolution.
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
  final host = uri.host.toLowerCase().replaceAll(RegExp(r'\\. The result is transient and is
/// never written to LibraryRepository or included in backups.
Future<ArticleReaderResult> loadArticleForReader(
  String url, {
  Duration timeout = defaultArticleReaderTimeout,
}) {
  return platform.loadArticleForReader(url, timeout: timeout);
}
), '');
  if (host == 'localhost' ||
      host.endsWith('.localhost') ||
      host.endsWith('.local') ||
      host.endsWith('.internal') ||
      host.contains('%') ||
      _isPrivateIpv4Literal(host) ||
      host.startsWith('[') && host.endsWith(']')) {
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
/// The result is always plain text and is safe to display as text, not HTML.
String sanitizeArticleMarkup(String source, {bool isHtml = true}) {
  var text = source;
  if (isHtml) {
    text = text.replaceAll(
      RegExp(r'<(script|style|noscript|svg|iframe|object|template)\\b[^>]*>[\\s\\S]*?</\\1\\s*>', caseSensitive: false),
      ' ',
    );
    text = text.replaceAll(RegExp(r'<!--[\\s\\S]*?-->'), ' ');
    text = text.replaceAll(RegExp(r'<br\\s*/?>|</(p|div|article|section|h[1-6]|li|tr)\\s*>', caseSensitive: false), '\\n');
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
    RegExp(r'&(?:amp|lt|gt|quot|apos|nbsp|mdash|ndash|hellip|#39);', caseSensitive: false),
    (match) => entities[match[0]!.toLowerCase()] ?? match[0]!,
  );
  text = text.replaceAllMapped(RegExp(r'&#(\\d{1,7});'), (match) {
    final code = int.tryParse(match.group(1)!);
    if (code == null || code < 1 || code > 0x10FFFF || (code >= 0xD800 && code <= 0xDFFF)) return ' ';
    return String.fromCharCode(code);
  });
  text = text.replaceAllMapped(RegExp(r'&#x([0-9a-f]{1,6});', caseSensitive: false), (match) {
    final code = int.tryParse(match.group(1)!, radix: 16);
    if (code == null || code < 1 || code > 0x10FFFF || (code >= 0xD800 && code <= 0xDFFF)) return ' ';
    return String.fromCharCode(code);
  });
  text = text.replaceAll('\\r', '\\n').replaceAll(RegExp(r'[\\t\\f\\v ]+'), ' ');
  text = text.replaceAll(RegExp(r' *\\n *'), '\\n').replaceAll(RegExp(r'\\n{3,}'), '\\n\\n');
  return text.trim();
}

/// Called only from an explicit reader action. The result is transient and is
/// never written to LibraryRepository or included in backups.
Future<ArticleReaderResult> loadArticleForReader(
  String url, {
  Duration timeout = defaultArticleReaderTimeout,
}) {
  return platform.loadArticleForReader(url, timeout: timeout);
}
