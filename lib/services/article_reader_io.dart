import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'article_reader.dart';

Future<ArticleReaderResult> loadArticleForReader(
  String url, {
  required Duration timeout,
}) async {
  final uri = parseArticleReaderUrl(url);
  if (uri == null) {
    return const ArticleReaderResult(state: ArticleReaderState.invalidUrl);
  }
  final boundedTimeout = timeout <= Duration.zero ||
          timeout > const Duration(seconds: 15)
      ? defaultArticleReaderTimeout
      : timeout;
  final deadline = DateTime.now().add(boundedTimeout);
  final host = uri.host.toLowerCase();
  if (host == 'localhost' ||
      host.endsWith('.localhost') ||
      host.endsWith('.local') ||
      host.endsWith('.internal') ||
      (InternetAddress.tryParse(host) == null && !host.contains('.'))) {
    return const ArticleReaderResult(state: ArticleReaderState.blockedAddress);
  }

  late final List<InternetAddress> addresses;
  try {
    final resolver = articleReaderDnsResolverForTesting;
    final resolved = resolver == null
        ? (await InternetAddress.lookup(host).timeout(_remaining(deadline)))
            .map((address) => address.address)
            .toList(growable: false)
        : await resolver(host).timeout(_remaining(deadline));
    if (resolved.isEmpty) {
      return const ArticleReaderResult(state: ArticleReaderState.networkError);
    }

    final parsedAddresses = <InternetAddress>[];
    for (final value in resolved) {
      final address = InternetAddress.tryParse(value);
      if (address == null) {
        return const ArticleReaderResult(state: ArticleReaderState.networkError);
      }
      // Any resolved private/reserved IPv4 answer blocks the hostname. IPv6
      // is conservatively ignored; only vetted IPv4 addresses are connected.
      if (address.type == InternetAddressType.IPv4) {
        if (!_isPublicAddress(address)) {
          return const ArticleReaderResult(
            state: ArticleReaderState.blockedAddress,
          );
        }
        parsedAddresses.add(address);
      }
    }
    if (parsedAddresses.isEmpty) {
      return const ArticleReaderResult(state: ArticleReaderState.blockedAddress);
    }
    addresses = List<InternetAddress>.unmodifiable(parsedAddresses);
  } on TimeoutException {
    return const ArticleReaderResult(state: ArticleReaderState.timedOut);
  } catch (_) {
    return const ArticleReaderResult(state: ArticleReaderState.networkError);
  }

  try {
    final testTransport = articleReaderTransportForTesting;
    final response = testTransport == null
        ? await _fetchNativeResponse(uri, host, addresses, deadline)
        : await testTransport(
            uri,
            addresses.map((address) => address.address).toList(growable: false),
            _remaining(deadline),
          ).timeout(_remaining(deadline));
    return _parseResponse(response);
  } on _ArticleResponseTooLarge {
    return const ArticleReaderResult(state: ArticleReaderState.tooLarge);
  } on TimeoutException {
    return const ArticleReaderResult(state: ArticleReaderState.timedOut);
  } on SocketException {
    return const ArticleReaderResult(state: ArticleReaderState.networkError);
  } on HttpException {
    return const ArticleReaderResult(state: ArticleReaderState.networkError);
  } catch (_) {
    return const ArticleReaderResult(state: ArticleReaderState.networkError);
  }
}

Future<ArticleReaderTransportResponse> _fetchNativeResponse(
  Uri uri,
  String host,
  List<InternetAddress> addresses,
  DateTime deadline,
) async {
  final client = HttpClient()
    ..connectionTimeout = _remaining(deadline)
    ..idleTimeout = _remaining(deadline)
    ..userAgent = 'StashHive-Reader'
    ..maxConnectionsPerHost = 1
    ..findProxy = (_) => 'DIRECT'
    ..connectionFactory = (requestedUri, proxyHost, proxyPort) {
      if (proxyHost != null ||
          proxyPort != null ||
          requestedUri.host.toLowerCase() != host) {
        return Future<ConnectionTask<Socket>>.error(
          const SocketException('Unsupported connection route.'),
        );
      }
      final port = requestedUri.hasPort
          ? requestedUri.port
          : requestedUri.scheme.toLowerCase() == 'https'
              ? 443
              : 80;
      return Socket.startConnect(addresses.first, port);
    };

  try {
    final request = await client.getUrl(uri).timeout(_remaining(deadline));
    // Never automatically follow a redirect: it could target a local/private
    // service or a different host that was never checked.
    request.followRedirects = false;
    request.maxRedirects = 0;
    request.headers
      ..set(HttpHeaders.acceptHeader, 'text/html, text/plain;q=0.9')
      ..set(HttpHeaders.acceptEncodingHeader, 'identity')
      ..set(HttpHeaders.cacheControlHeader, 'no-cache');
    final response = await request.close().timeout(_remaining(deadline));
    if (response.contentLength > maxArticleResponseBytes) {
      throw const _ArticleResponseTooLarge();
    }
    final body = await _readBoundedResponse(response, deadline);
    return ArticleReaderTransportResponse(
      statusCode: response.statusCode,
      contentType: response.headers.value(HttpHeaders.contentTypeHeader) ?? '',
      body: body,
    );
  } finally {
    client.close(force: true);
  }
}

ArticleReaderResult _parseResponse(ArticleReaderTransportResponse response) {
  if (response.statusCode >= 300 && response.statusCode < 400) {
    return const ArticleReaderResult(
      state: ArticleReaderState.networkError,
      message:
          'This page redirects to another address. Open it in your browser instead.',
    );
  }
  if (response.statusCode < 200 || response.statusCode >= 300) {
    return const ArticleReaderResult(
      state: ArticleReaderState.networkError,
      message: 'The website did not provide a readable page.',
    );
  }
  if (response.body.length > maxArticleResponseBytes) {
    return const ArticleReaderResult(state: ArticleReaderState.tooLarge);
  }

  final contentTypeParts = response.contentType.split(';');
  final mime = contentTypeParts.first.trim().toLowerCase();
  if (mime != 'text/html' && mime != 'text/plain') {
    return const ArticleReaderResult(
      state: ArticleReaderState.unsupportedContent,
      message: 'This website did not return HTML or plain text.',
    );
  }
  final html = mime == 'text/html';
  final charset = _charsetFromContentType(response.contentType) ??
      (html ? _charsetFromHtmlMeta(response.body) : null);
  final decoded = _decodeText(response.body, charset);
  final title = html ? _extractTitle(decoded) : null;
  final text = sanitizeArticleMarkup(decoded, isHtml: html);
  if (text.trim().isEmpty) {
    return const ArticleReaderResult(
      state: ArticleReaderState.unsupportedContent,
      message: 'No readable text was found on this page.',
    );
  }
  return ArticleReaderResult(
    state: ArticleReaderState.success,
    title: title,
    text: _truncateAtUnicodeBoundary(text, maxArticleTextCharacters),
  );
}

String _truncateAtUnicodeBoundary(String value, int maxLength) {
  if (value.length <= maxLength) return value;
  var end = maxLength;
  if (end > 0 && end < value.length) {
    final previous = value.codeUnitAt(end - 1);
    final next = value.codeUnitAt(end);
    // Dart strings are UTF-16 indexed. Do not leave an isolated high
    // surrogate when the display limit falls between an emoji's code units.
    if (previous >= 0xD800 &&
        previous <= 0xDBFF &&
        next >= 0xDC00 &&
        next <= 0xDFFF) {
      end -= 1;
    }
  }
  return value.substring(0, end);
}

String? _charsetFromContentType(String contentType) {
  final match = RegExp(
    r'(?:^|;)\s*charset\s*=\s*["\x27]?([^;\s"\x27]+)',
    caseSensitive: false,
  ).firstMatch(contentType);
  return match?.group(1);
}

String? _charsetFromHtmlMeta(List<int> bytes) {
  // The HTML encoding prescan is deliberately bounded to the first 1024
  // bytes. Latin-1 preserves the ASCII markup even when the document body
  // uses a legacy encoding that UTF-8 would decode incorrectly.
  final scanLength = bytes.length < 1024 ? bytes.length : 1024;
  final prefix = latin1.decode(bytes.sublist(0, scanLength), allowInvalid: true);
  final metaTags = RegExp(
    r'<meta\b[^>]{0,1024}>',
    caseSensitive: false,
  ).allMatches(prefix);

  for (final match in metaTags) {
    final tag = match[0]!;
    // This catches both the direct charset attribute and the legacy
    // http-equiv content attribute, while not matching data-charset.
    final charset = RegExp(
      r'(?:^|[\s;])charset\s*=\s*["\x27]?([^;\s"\x27/>]+)',
      caseSensitive: false,
    ).firstMatch(tag);
    final value = charset?.group(1)?.trim();
    if (value != null && value.isNotEmpty) return value;
  }
  return null;
}
Duration _remaining(DateTime deadline) {
  final remaining = deadline.difference(DateTime.now());
  if (remaining <= Duration.zero) {
    throw TimeoutException('Article reader request deadline exceeded.');
  }
  return remaining;
}

class _ArticleResponseTooLarge implements Exception {
  const _ArticleResponseTooLarge();
}

Future<Uint8List> _readBoundedResponse(
  HttpClientResponse response,
  DateTime deadline,
) async {
  final bytes = BytesBuilder(copy: false);
  await response.fold<int>(0, (total, chunk) {
    final nextTotal = total + chunk.length;
    if (nextTotal > maxArticleResponseBytes) {
      throw const _ArticleResponseTooLarge();
    }
    bytes.add(chunk);
    return nextTotal;
  }).timeout(_remaining(deadline));
  return bytes.takeBytes();
}

String _decodeText(List<int> bytes, String? charset) {
  // A leading UTF-8 BOM is an encoding signature, not article content. Strip
  // it before the declared-charset fallback so it never leaks into titles or
  // the first visible character of a plain-text preview.
  if (bytes.length >= 3 &&
      bytes[0] == 0xEF &&
      bytes[1] == 0xBB &&
      bytes[2] == 0xBF) {
    return utf8.decode(bytes.sublist(3), allowMalformed: true);
  }
  final normalizedCharset = charset?.trim().toLowerCase();
  if (normalizedCharset == 'windows-1252' ||
      normalizedCharset == 'cp1252') {
    // Latin-1 and Windows-1252 differ in the 0x80–0x9F range. Mapping these
    // bytes as Latin-1 would turn common punctuation and the euro sign into
    // invisible control characters in reader previews.
    const windows1252Specials = <int, int>{
      0x80: 0x20AC,
      0x82: 0x201A,
      0x83: 0x0192,
      0x84: 0x201E,
      0x85: 0x2026,
      0x86: 0x2020,
      0x87: 0x2021,
      0x88: 0x02C6,
      0x89: 0x2030,
      0x8A: 0x0160,
      0x8B: 0x2039,
      0x8C: 0x0152,
      0x8E: 0x017D,
      0x91: 0x2018,
      0x92: 0x2019,
      0x93: 0x201C,
      0x94: 0x201D,
      0x95: 0x2022,
      0x96: 0x2013,
      0x97: 0x2014,
      0x98: 0x02DC,
      0x99: 0x2122,
      0x9A: 0x0161,
      0x9B: 0x203A,
      0x9C: 0x0153,
      0x9E: 0x017E,
      0x9F: 0x0178,
    };
    return String.fromCharCodes(bytes.map(
      (byte) => windows1252Specials[byte] ?? byte,
    ));
  }
  if (normalizedCharset == 'latin1' ||
      normalizedCharset == 'iso-8859-1') {
    return latin1.decode(bytes, allowInvalid: true);
  }
  return utf8.decode(bytes, allowMalformed: true);
}

String? _extractTitle(String html) {
  // Ignore title-looking text from script strings or comments when choosing
  // the document title.
  var titleSource = html.replaceAll(
    RegExp(
      r'<(script|style|noscript|svg|iframe|object|template)\b[^>]*>[\s\S]*?</\1\s*>',
      caseSensitive: false,
    ),
    ' ',
  );
  titleSource = titleSource.replaceAll(
    RegExp(
      r'<(script|style|noscript|svg|iframe|object|template)\b[^>]*>[\s\S]*$',
      caseSensitive: false,
    ),
    ' ',
  );
  titleSource = titleSource
      .replaceAll(RegExp(r'<!--[\s\S]*?-->'), ' ')
      .replaceAll(RegExp(r'<!--[\s\S]*$'), ' ');

  final match = RegExp(
    r'<title\b[^>]*>([\s\S]*?)</title\s*>',
    caseSensitive: false,
  ).firstMatch(titleSource);
  if (match == null) return null;
  final title = sanitizeArticleMarkup(match.group(1)!, isHtml: true).trim();
  return title.isEmpty ? null : _truncateAtUnicodeBoundary(title, 300);
}

bool _isPublicAddress(InternetAddress address) {
  final bytes = address.rawAddress;
  if (address.type == InternetAddressType.IPv4 && bytes.length == 4) {
    final a = bytes[0], b = bytes[1], c = bytes[2];
    if (a == 0 || a == 10 || a == 127 || a >= 224 ||
        (a == 100 && b >= 64 && b <= 127) ||
        (a == 169 && b == 254) ||
        (a == 172 && b >= 16 && b <= 31) ||
        (a == 192 && b == 168) ||
        (a == 192 && b == 0 && (c == 0 || c == 2)) ||
        (a == 192 && b == 88 && c == 99) ||
        (a == 198 && (b == 18 || b == 19)) ||
        (a == 198 && b == 51 && c == 100) ||
        (a == 203 && b == 0 && c == 113)) {
      return false;
    }
    return true;
  }
  return false;
}
