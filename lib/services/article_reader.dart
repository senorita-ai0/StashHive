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

/// A selection from the temporary reader text with UTF-16 offsets and
/// bounded, well-formed surrounding context.
class ArticleReaderSelection {
  const ArticleReaderSelection({
    required this.quote,
    required this.startOffset,
    required this.endOffset,
    required this.contextBefore,
    required this.contextAfter,
  });

  final String quote;
  final int startOffset;
  final int endOffset;
  final String contextBefore;
  final String contextAfter;
}

/// Captures a selection without leaving either endpoint inside a UTF-16
/// surrogate pair. Context edges are adjusted the same way so persisted
/// excerpts remain valid Unicode even when a window lands on a pair boundary.
ArticleReaderSelection? captureArticleReaderSelection(
  String text,
  int startOffset,
  int endOffset, {
  int contextCharacters = 80,
}) {
  if (startOffset < 0 ||
      endOffset <= startOffset ||
      endOffset > text.length ||
      contextCharacters < 0) {
    return null;
  }

  var start = startOffset;
  var end = endOffset;
  if (_splitsSurrogatePair(text, start)) start--;
  if (_splitsSurrogatePair(text, end)) end++;

  var contextStart = (start - contextCharacters).clamp(0, start).toInt();
  var contextEnd = (end + contextCharacters).clamp(end, text.length).toInt();
  if (_splitsSurrogatePair(text, contextStart)) contextStart--;
  if (_splitsSurrogatePair(text, contextEnd)) contextEnd++;

  return ArticleReaderSelection(
    quote: text.substring(start, end),
    startOffset: start,
    endOffset: end,
    contextBefore: text.substring(contextStart, start),
    contextAfter: text.substring(end, contextEnd),
  );
}

bool _splitsSurrogatePair(String text, int offset) {
  if (offset <= 0 || offset >= text.length) return false;
  final previous = text.codeUnitAt(offset - 1);
  final next = text.codeUnitAt(offset);
  return previous >= 0xD800 &&
      previous <= 0xDBFF &&
      next >= 0xDC00 &&
      next <= 0xDFFF;
}

/// Bounded, already-received HTTP response data. This DTO is shared so the
/// native request pipeline can be tested with a fake response and no network.
class ArticleReaderTransportResponse {
  ArticleReaderTransportResponse({
    required this.statusCode,
    required this.contentType,
    required List<int> body,
  }) : body = List<int>.unmodifiable(body);

  final int statusCode;
  final String contentType;
  final List<int> body;
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
  final scheme = uri.scheme.toLowerCase();
  final standardPort = scheme == 'http' ? 80 : 443;
  if (uri.hasPort && uri.port != standardPort) {
    // Do not let a reader request probe arbitrary services on otherwise
    // public hosts; the external browser remains available for such URLs.
    return null;
  }
  final host = uri.host.toLowerCase();
  if (host.endsWith('.') ||
      host == 'localhost' ||
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

/// Finds the first complete semantic container without mistaking a nested
/// same-name element's closing tag for the end of its parent. The generic tag
/// scan consumes quoted attributes as one token, so markup-looking strings in
/// attributes cannot affect the nesting depth.
String? _extractFirstBalancedElementContents(String source, String tagName) {
  final tagTokens = RegExp(
    r'''<(?:[^>"']|"[^"]*"|'[^']*')*>''',
  );
  final targetOpening = RegExp(
    '^<\\s*$tagName\\b',
    caseSensitive: false,
  );
  final targetClosing = RegExp(
    '^<\\s*/\\s*$tagName\\b',
    caseSensitive: false,
  );

  var depth = 0;
  var contentStart = -1;
  for (final match in tagTokens.allMatches(source)) {
    final token = match[0]!;
    if (targetClosing.hasMatch(token)) {
      if (depth == 0) continue;
      depth--;
      if (depth == 0) {
        return source.substring(contentStart, match.start);
      }
      continue;
    }

    if (targetOpening.hasMatch(token) && !token.endsWith('/>')) {
      if (depth == 0) contentStart = match.end;
      depth++;
    }
  }

  // An incomplete first container is not a trustworthy extraction boundary;
  // let the caller fall back to another semantic container or the page body.
  return null;
}

/// Removes complete HTML tag tokens without ending at a \`>\` inside a
/// quoted attribute. Structural elements become line breaks; inline elements
/// become spaces so adjacent words do not accidentally concatenate.
String _stripHtmlTagsPreservingBlockBoundaries(String source) {
  const blockTags = <String>{
    'address',
    'article',
    'blockquote',
    'dd',
    'div',
    'dl',
    'dt',
    'fieldset',
    'figcaption',
    'figure',
    'h1',
    'h2',
    'h3',
    'h4',
    'h5',
    'h6',
    'li',
    'main',
    'ol',
    'p',
    'pre',
    'section',
    'table',
    'tbody',
    'td',
    'tfoot',
    'th',
    'thead',
    'tr',
    'ul',
    'br',
    'hr',
  };

  bool isAsciiLetter(int value) =>
      (value >= 0x41 && value <= 0x5A) ||
      (value >= 0x61 && value <= 0x7A);

  bool isTagNameCharacter(int value) =>
      isAsciiLetter(value) ||
      (value >= 0x30 && value <= 0x39) ||
      value == 0x2D ||
      value == 0x3A;

  final output = StringBuffer();
  var cursor = 0;
  while (cursor < source.length) {
    final opening = source.indexOf('<', cursor);
    if (opening < 0) {
      output.write(source.substring(cursor));
      break;
    }

    output.write(source.substring(cursor, opening));
    var nameStart = opening + 1;
    if (nameStart < source.length &&
        source.codeUnitAt(nameStart) == 0x2F) {
      nameStart++;
    }

    // HTML declarations and processing instructions are markup too, even
    // though they do not have an ordinary element name.
    if (nameStart < source.length) {
      final marker = source.codeUnitAt(nameStart);
      if (marker == 0x21 || marker == 0x3F) {
        var quote = 0;
        var declarationEnd = nameStart + 1;
        for (; declarationEnd < source.length; declarationEnd++) {
          final codeUnit = source.codeUnitAt(declarationEnd);
          if (quote != 0) {
            if (codeUnit == quote) quote = 0;
          } else if (codeUnit == 0x22 || codeUnit == 0x27) {
            quote = codeUnit;
          } else if (codeUnit == 0x3E) {
            break;
          }
        }
        if (declarationEnd >= source.length || quote != 0) {
          return output.toString();
        }
        output.write(' ');
        cursor = declarationEnd + 1;
        continue;
      }
    }

    // A less-than sign followed by ordinary text is not treated as markup.
    if (nameStart >= source.length ||
        !isAsciiLetter(source.codeUnitAt(nameStart))) {
      output.write('<');
      cursor = opening + 1;
      continue;
    }

    var nameEnd = nameStart;
    while (nameEnd < source.length &&
        isTagNameCharacter(source.codeUnitAt(nameEnd))) {
      nameEnd++;
    }
    final tagName = source.substring(nameStart, nameEnd).toLowerCase();

    // Find the real tag terminator, ignoring '>' characters inside either
    // quote style. If a quote or tag never closes, discard the malformed tail
    // instead of exposing attribute contents as article prose.
    var quote = 0;
    var tagEnd = nameEnd;
    for (; tagEnd < source.length; tagEnd++) {
      final codeUnit = source.codeUnitAt(tagEnd);
      if (quote != 0) {
        if (codeUnit == quote) quote = 0;
      } else if (codeUnit == 0x22 || codeUnit == 0x27) {
        quote = codeUnit;
      } else if (codeUnit == 0x3E) {
        break;
      }
    }

    if (tagEnd >= source.length || quote != 0) {
      return output.toString();
    }

    output.write(blockTags.contains(tagName) ? '\n' : ' ');
    cursor = tagEnd + 1;
  }

  return output.toString();
}

/// Removes active markup and decodes a conservative set of text entities.
/// The result is plain text and must never be interpreted as HTML.
String sanitizeArticleMarkup(String source, {bool isHtml = true}) {
  var text = source;
  if (isHtml) {
    // Remove active/embedded blocks, interactive widgets and comments before semantic extraction.
    // A literal "<article>" inside a script string or HTML comment must not be
    // mistaken for the real article and hide the page's actual readable text.
    var sourceWithoutActiveContent = source.replaceAll(
      RegExp(
        r'<(script|style|noscript|svg|iframe|object|template|nav|footer|aside|form|button|select|textarea|dialog)\b[^>]*>[\s\S]*?</\1\s*>',
        caseSensitive: false,
      ),
      ' ',
    );
    sourceWithoutActiveContent = sourceWithoutActiveContent.replaceAll(
      RegExp(
        r'<(script|style|noscript|svg|iframe|object|template|nav|footer|aside|form|button|select|textarea|dialog)\b[^>]*>[\s\S]*$',
        caseSensitive: false,
      ),
      ' ',
    );
    sourceWithoutActiveContent = sourceWithoutActiveContent
        .replaceAll(RegExp(r'<!--[\s\S]*?-->'), ' ')
        .replaceAll(RegExp(r'<!--[\s\S]*$'), ' ');

    // Prefer semantic article/main containers after removing embedded
    // active content and navigation chrome. This remains a lightweight
    // fallback, not a full readability engine.
    final article = _extractFirstBalancedElementContents(
      sourceWithoutActiveContent,
      'article',
    );
    final main = _extractFirstBalancedElementContents(
      sourceWithoutActiveContent,
      'main',
    );
    text = article ?? main ?? sourceWithoutActiveContent;

    // Remove remaining navigation chrome and any unclosed active blocks.
    text = text.replaceAll(
      RegExp(
        r'<(script|style|noscript|svg|iframe|object|template|nav|footer|aside|form|button|select|textarea|dialog)\b[^>]*>[\s\S]*?</\1\s*>',
        caseSensitive: false,
      ),
      ' ',
    );
    text = text.replaceAll(
      RegExp(
        r'<(script|style|noscript|svg|iframe|object|template|nav|footer|aside|form|button|select|textarea|dialog)\b[^>]*>[\s\S]*$',
        caseSensitive: false,
      ),
      ' ',
    );
    text = text.replaceAll(RegExp(r'<!--[\s\S]*?-->'), ' ');
    text = text.replaceAll(RegExp(r'<!--[\s\S]*$'), ' ');
    text = _stripHtmlTagsPreservingBlockBoundaries(text);
  }

  // Decode numeric references before named references so escaped ampersands
  // are not recursively decoded in the same sanitizer pass.
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

  const entities = <String, String>{
    '&amp;': '&',
    '&lt;': '<',
    '&gt;': '>',
    '&quot;': '"',
    '&apos;': "'",
    '&nbsp;': ' ',
    '&mdash;': '—',
    '&ndash;': '–',
    '&hellip;': '…',
    '&copy;': '©',
    '&reg;': '®',
    '&trade;': '™',
    '&euro;': '€',
    '&lsquo;': '‘',
    '&rsquo;': '’',
    '&ldquo;': '“',
    '&rdquo;': '”',
    '&bull;': '•',
    '&middot;': '·',
    '&deg;': '°',
    '&laquo;': '«',
    '&raquo;': '»',
    '&times;': '×',
    '&divide;': '÷',
    '&plusmn;': '±',
    '&cent;': '¢',
    '&pound;': '£',
    '&yen;': '¥',
    '&sect;': '§',
    '&para;': '¶',
  };
  text = text.replaceAllMapped(
    RegExp(
      r'&(?:amp|lt|gt|quot|apos|nbsp|mdash|ndash|hellip|copy|reg|trade|euro|lsquo|rsquo|ldquo|rdquo|bull|middot|deg|laquo|raquo|times|divide|plusmn|cent|pound|yen|sect|para);',
      caseSensitive: false,
    ),
    (match) => entities[match[0]!.toLowerCase()] ?? match[0]!,
  );
  // Remove non-printing control bytes; keep tabs and line separators for the
  // following whitespace normalization, and preserve meaningful Unicode.
  text = text.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), ' ');
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
  // Keep URL validation ahead of every transport path, including test seams,
  // so an injected transport cannot accidentally mask invalid-input behavior.
  if (parseArticleReaderUrl(url) == null) {
    return Future<ArticleReaderResult>.value(
      const ArticleReaderResult(state: ArticleReaderState.invalidUrl),
    );
  }
  final testLoader = articleReaderLoaderForTesting;
  if (testLoader != null) return testLoader(url, timeout);
  return platform.loadArticleForReader(url, timeout: timeout);
}
);

  var depth = 0;
  var contentStart = -1;
  for (final match in tagTokens.allMatches(source)) {
    final token = match[0]!;
    if (targetClosing.hasMatch(token)) {
      if (depth == 0) continue;
      depth--;
      if (depth == 0) {
        return source.substring(contentStart, match.start);
      }
      continue;
    }

    if (targetOpening.hasMatch(token) && !selfClosing.hasMatch(token)) {
      if (depth == 0) contentStart = match.end;
      depth++;
    }
  }

  // An incomplete first container is not a trustworthy extraction boundary;
  // let the caller fall back to another semantic container or the page body.
  return null;
}

/// Removes active markup and decodes a conservative set of text entities.
/// The result is plain text and must never be interpreted as HTML.
String sanitizeArticleMarkup(String source, {bool isHtml = true}) {
  var text = source;
  if (isHtml) {
    // Remove active/embedded blocks, interactive widgets and comments before semantic extraction.
    // A literal "<article>" inside a script string or HTML comment must not be
    // mistaken for the real article and hide the page's actual readable text.
    var sourceWithoutActiveContent = source.replaceAll(
      RegExp(
        r'<(script|style|noscript|svg|iframe|object|template|nav|footer|aside|form|button|select|textarea|dialog)\b[^>]*>[\s\S]*?</\1\s*>',
        caseSensitive: false,
      ),
      ' ',
    );
    sourceWithoutActiveContent = sourceWithoutActiveContent.replaceAll(
      RegExp(
        r'<(script|style|noscript|svg|iframe|object|template|nav|footer|aside|form|button|select|textarea|dialog)\b[^>]*>[\s\S]*$',
        caseSensitive: false,
      ),
      ' ',
    );
    sourceWithoutActiveContent = sourceWithoutActiveContent
        .replaceAll(RegExp(r'<!--[\s\S]*?-->'), ' ')
        .replaceAll(RegExp(r'<!--[\s\S]*$'), ' ');

    // Prefer semantic article/main containers after removing embedded
    // active content and navigation chrome. This remains a lightweight
    // fallback, not a full readability engine.
    final article = _extractFirstBalancedElementContents(
      sourceWithoutActiveContent,
      'article',
    );
    final main = _extractFirstBalancedElementContents(
      sourceWithoutActiveContent,
      'main',
    );
    text = article ?? main ?? sourceWithoutActiveContent;

    // Remove remaining navigation chrome and any unclosed active blocks.
    text = text.replaceAll(
      RegExp(
        r'<(script|style|noscript|svg|iframe|object|template|nav|footer|aside|form|button|select|textarea|dialog)\b[^>]*>[\s\S]*?</\1\s*>',
        caseSensitive: false,
      ),
      ' ',
    );
    text = text.replaceAll(
      RegExp(
        r'<(script|style|noscript|svg|iframe|object|template|nav|footer|aside|form|button|select|textarea|dialog)\b[^>]*>[\s\S]*$',
        caseSensitive: false,
      ),
      ' ',
    );
    text = text.replaceAll(RegExp(r'<!--[\s\S]*?-->'), ' ');
    text = text.replaceAll(RegExp(r'<!--[\s\S]*$'), ' ');
    text = text.replaceAll(
      RegExp(
        r'<br\s*/?>|</(p|div|article|section|h[1-6]|li|tr)\s*>',
        caseSensitive: false,
      ),
      '\n',
    );
    text = text.replaceAll(RegExp(r'<[^>]{0,2048}>'), ' ');
  }

  // Decode numeric references before named references so escaped ampersands
  // are not recursively decoded in the same sanitizer pass.
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

  const entities = <String, String>{
    '&amp;': '&',
    '&lt;': '<',
    '&gt;': '>',
    '&quot;': '"',
    '&apos;': "'",
    '&nbsp;': ' ',
    '&mdash;': '—',
    '&ndash;': '–',
    '&hellip;': '…',
    '&copy;': '©',
    '&reg;': '®',
    '&trade;': '™',
    '&euro;': '€',
    '&lsquo;': '‘',
    '&rsquo;': '’',
    '&ldquo;': '“',
    '&rdquo;': '”',
    '&bull;': '•',
    '&middot;': '·',
    '&deg;': '°',
    '&laquo;': '«',
    '&raquo;': '»',
    '&times;': '×',
    '&divide;': '÷',
    '&plusmn;': '±',
    '&cent;': '¢',
    '&pound;': '£',
    '&yen;': '¥',
    '&sect;': '§',
    '&para;': '¶',
  };
  text = text.replaceAllMapped(
    RegExp(
      r'&(?:amp|lt|gt|quot|apos|nbsp|mdash|ndash|hellip|copy|reg|trade|euro|lsquo|rsquo|ldquo|rdquo|bull|middot|deg|laquo|raquo|times|divide|plusmn|cent|pound|yen|sect|para);',
      caseSensitive: false,
    ),
    (match) => entities[match[0]!.toLowerCase()] ?? match[0]!,
  );
  // Remove non-printing control bytes; keep tabs and line separators for the
  // following whitespace normalization, and preserve meaningful Unicode.
  text = text.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), ' ');
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
  // Keep URL validation ahead of every transport path, including test seams,
  // so an injected transport cannot accidentally mask invalid-input behavior.
  if (parseArticleReaderUrl(url) == null) {
    return Future<ArticleReaderResult>.value(
      const ArticleReaderResult(state: ArticleReaderState.invalidUrl),
    );
  }
  final testLoader = articleReaderLoaderForTesting;
  if (testLoader != null) return testLoader(url, timeout);
  return platform.loadArticleForReader(url, timeout: timeout);
}
