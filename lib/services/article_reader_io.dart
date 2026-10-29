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
  final charset = _charsetFromContentType(response.contentType);
  final decoded = _decodeText(response.body, charset);
  final html = mime == 'text/html';
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
    text: text.length > maxArticleTextCharacters
        ? text.substring(0, maxArticleTextCharacters)
        : text,
  );
}

String? _charsetFromContentType(String contentType) {
  final match = RegExp(
    r'(?:^|;)\s*charset\s*=\s*["\x27]?([^;\s"\x27]+)',
    caseSensitive: false,
  ).firstMatch(contentType);
  return match?.group(1);
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
  if (charset != null &&
      (charset.toLowerCase() == 'latin1' ||
          charset.toLowerCase() == 'iso-8859-1' ||
          charset.toLowerCase() == 'windows-1252')) {
    return latin1.decode(bytes, allowInvalid: true);
  }
  return utf8.decode(bytes, allowMalformed: true);
}

String? _extractTitle(String html) {
  final match = RegExp(
    r'<title\b[^>]*>([\s\S]*?)</title\s*>',
    caseSensitive: false,
  ).firstMatch(html);
  if (match == null) return null;
  final title = sanitizeArticleMarkup(match.group(1)!, isHtml: true).trim();
  return title.isEmpty ? null : (title.length > 300 ? title.substring(0, 300) : title);
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
