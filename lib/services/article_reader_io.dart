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
    final resolved =
        await InternetAddress.lookup(host).timeout(boundedTimeout);
    if (resolved.isEmpty || resolved.any((address) => !_isPublicAddress(address))) {
      return const ArticleReaderResult(state: ArticleReaderState.blockedAddress);
    }
    addresses = List<InternetAddress>.unmodifiable(resolved);
  } on TimeoutException {
    return const ArticleReaderResult(state: ArticleReaderState.timedOut);
  } catch (_) {
    return const ArticleReaderResult(state: ArticleReaderState.networkError);
  }

  final client = HttpClient()
    ..connectionTimeout = boundedTimeout
    ..idleTimeout = boundedTimeout
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
    final request = await client.getUrl(uri).timeout(boundedTimeout);
    request.followRedirects = false;
    request.maxRedirects = 0;
    request.headers
      ..set(HttpHeaders.acceptHeader, 'text/html, text/plain;q=0.9')
      ..set(HttpHeaders.acceptEncodingHeader, 'identity')
      ..set(HttpHeaders.cacheControlHeader, 'no-cache');
    final response = await request.close().timeout(boundedTimeout);

    if (response.isRedirect) {
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
    final contentType = response.headers.contentType;
    final mime = contentType?.mimeType.toLowerCase() ?? '';
    if (mime != 'text/html' && mime != 'text/plain') {
      return const ArticleReaderResult(
        state: ArticleReaderState.unsupportedContent,
        message: 'This website did not return HTML or plain text.',
      );
    }
    final declaredLength = response.contentLength;
    if (declaredLength > maxArticleResponseBytes) {
      return const ArticleReaderResult(state: ArticleReaderState.tooLarge);
    }

    final bytes = BytesBuilder(copy: false);
    var total = 0;
    await for (final chunk in response.timeout(boundedTimeout)) {
      total += chunk.length;
      if (total > maxArticleResponseBytes) {
        client.close(force: true);
        return const ArticleReaderResult(state: ArticleReaderState.tooLarge);
      }
      bytes.add(chunk);
    }
    final decoded = _decodeText(bytes.takeBytes(), contentType?.charset);
    final html = mime == 'text/html';
    final title = html ? _extractTitle(decoded) : null;
    final text = _plainText(decoded, isHtml: html);
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
  } on TimeoutException {
    return const ArticleReaderResult(state: ArticleReaderState.timedOut);
  } on SocketException {
    return const ArticleReaderResult(state: ArticleReaderState.networkError);
  } on HttpException {
    return const ArticleReaderResult(state: ArticleReaderState.networkError);
  } catch (_) {
    return const ArticleReaderResult(state: ArticleReaderState.networkError);
  } finally {
    client.close(force: true);
  }
}

String _decodeText(Uint8List bytes, String? charset) {
  if (charset != null && charset.toLowerCase() == 'latin1') {
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
  final title = _decodeEntities(_stripTags(match.group(1)!)).trim();
  return title.isEmpty ? null : title.substring(0, title.length.clamp(0, 300));
}

String _plainText(String source, {required bool isHtml}) {
  var text = source;
  if (isHtml) {
    text = text.replaceAll(
      RegExp(r'<(script|style|noscript|svg|iframe|object|template)\b[^>]*>[\s\S]*?</\1\s*>', caseSensitive: false),
      ' ',
    );
    text = text.replaceAll(RegExp(r'<!--([\s\S]*?)-->'), ' ');
    text = text.replaceAll(RegExp(r'<br\s*/?>|</(p|div|article|section|h[1-6]|li|tr)\s*>', caseSensitive: false), '\n');
    text = _stripTags(text);
  }
  text = _decodeEntities(text);
  text = text.replaceAll('\r', '\n').replaceAll(RegExp(r'[\t\f\v ]+'), ' ');
  text = text.replaceAll(RegExp(r' *\n *'), '\n');
  text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
  return text.trim();
}

String _stripTags(String value) => value.replaceAll(RegExp(r'<[^>]{0,2048}>'), ' ');

String _decodeEntities(String value) {
  const named = <String, String>{
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
  var result = value.replaceAllMapped(
    RegExp(r'&(?:amp|lt|gt|quot|apos|nbsp|mdash|ndash|hellip|#39);', caseSensitive: false),
    (match) => named[match[0]!.toLowerCase()] ?? match[0]!,
  );
  result = result.replaceAllMapped(RegExp(r'&#(\d{1,7});'), (match) {
    final code = int.tryParse(match.group(1)!);
    if (code == null || code < 1 || code > 0x10FFFF || (code >= 0xD800 && code <= 0xDFFF)) {
      return ' ';
    }
    return String.fromCharCode(code);
  });
  result = result.replaceAllMapped(RegExp(r'&#x([0-9a-f]{1,6});', caseSensitive: false), (match) {
    final code = int.tryParse(match.group(1)!, radix: 16);
    if (code == null || code < 1 || code > 0x10FFFF || (code >= 0xD800 && code <= 0xDFFF)) {
      return ' ';
    }
    return String.fromCharCode(code);
  });
  return result;
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
  if (address.type == InternetAddressType.IPv6 && bytes.length == 16) {
    final mapped = bytes.take(10).every((byte) => byte == 0) &&
        bytes[10] == 0xff && bytes[11] == 0xff;
    if (mapped) {
      return _isPublicAddress(InternetAddress.fromRawAddress(
        Uint8List.fromList(bytes.sublist(12)),
        type: InternetAddressType.IPv4,
      ));
    }
    return (bytes[0] & 0xe0) == 0x20 &&
        !(bytes[0] == 0x20 && bytes[1] == 0x01 &&
            bytes[2] == 0x0d && bytes[3] == 0xb8);
  }
  return false;
}
