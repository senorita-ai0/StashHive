import 'dart:async';
import 'dart:io';

import '../models/link_health_record.dart';

Future<LinkHealthRecord> checkLinkHealth({
  required String itemId,
  required String url,
  required Duration timeout,
}) async {
  LinkHealthRecord result(LinkHealthState state, [int? statusCode]) =>
      LinkHealthRecord(
        itemId: itemId,
        checkedUrl: url,
        state: state,
        checkedAtMs: DateTime.now().millisecondsSinceEpoch,
        httpStatusCode: statusCode,
      );

  final uri = Uri.tryParse(url.trim());
  if (uri == null ||
      (uri.scheme.toLowerCase() != 'http' &&
          uri.scheme.toLowerCase() != 'https') ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty) {
    return result(LinkHealthState.invalidUrl);
  }

  final host = uri.host.toLowerCase();
  final literalAddress = InternetAddress.tryParse(host);
  if (host == 'localhost' ||
      host.endsWith('.localhost') ||
      host.endsWith('.local') ||
      host.endsWith('.internal') ||
      (literalAddress == null && !host.contains('.'))) {
    return result(LinkHealthState.blockedAddress);
  }

  try {
    final resolved = await InternetAddress.lookup(host).timeout(timeout);
    if (resolved.isEmpty || resolved.any((address) => !_isPublicAddress(address))) {
      return result(LinkHealthState.blockedAddress);
    }
  } on TimeoutException {
    return result(LinkHealthState.timedOut);
  } on SocketException {
    return result(LinkHealthState.networkError);
  } catch (_) {
    return result(LinkHealthState.networkError);
  }

  final client = HttpClient()
    ..connectionTimeout = timeout
    ..idleTimeout = timeout
    ..userAgent = 'StashHive-LinkCheck'
    ..maxConnectionsPerHost = 2;

  try {
    final headResponse = await _sendRequest(
      client,
      uri,
      'HEAD',
      timeout,
    );
    var response = headResponse;
    if (headResponse.statusCode == HttpStatus.methodNotAllowed ||
        headResponse.statusCode == HttpStatus.notImplemented) {
      // Some sites do not implement HEAD. Retry with GET and close the client
      // immediately after reading response headers so the page body is not
      // downloaded or stored.
      response = await _sendRequest(client, uri, 'GET', timeout);
    }
    return result(
      linkHealthStateForStatusCode(response.statusCode),
      response.statusCode,
    );
  } on TimeoutException {
    return result(LinkHealthState.timedOut);
  } on HandshakeException {
    return result(LinkHealthState.tlsError);
  } on TlsException {
    return result(LinkHealthState.tlsError);
  } on SocketException {
    return result(LinkHealthState.networkError);
  } on HttpException {
    return result(LinkHealthState.networkError);
  } catch (_) {
    return result(LinkHealthState.networkError);
  } finally {
    // force:true closes connections even when the response stream was not
    // consumed. Only response headers/status codes are needed for this feature.
    client.close(force: true);
  }
}

Future<HttpClientResponse> _sendRequest(
  HttpClient client,
  Uri uri,
  String method,
  Duration timeout,
) async {
  final request = method == 'HEAD'
      ? await client.headUrl(uri).timeout(timeout)
      : await client.getUrl(uri).timeout(timeout);
  // Do not follow a redirect automatically: a public website could redirect
  // to a local/private address. Report the redirect instead of probing a second host.
  request.headers.set(HttpHeaders.acceptHeader, '*/*');
  request.headers.set(HttpHeaders.cacheControlHeader, 'no-cache');
  return request.close().timeout(timeout);
}

bool _isPublicAddress(InternetAddress address) {
  final bytes = address.rawAddress;
  if (address.type == InternetAddressType.IPv4 && bytes.length == 4) {
    final a = bytes[0];
    final b = bytes[1];
    final c = bytes[2];
    if (a == 0 ||
        a == 10 ||
        a == 127 ||
        a >= 224 ||
        (a == 100 && b >= 64 && b <= 127) ||
        (a == 169 && b == 254) ||
        (a == 172 && b >= 16 && b <= 31) ||
        (a == 192 && b == 168) ||
        (a == 192 && b == 0) ||
        (a == 192 && b == 2) ||
        (a == 198 && (b == 18 || b == 19)) ||
        (a == 198 && b == 51 && c == 100) ||
        (a == 192 && b == 88 && c == 99) ||
        (a == 203 && b == 0 && c == 113)) {
      return false;
    }
    return true;
  }

  if (address.type == InternetAddressType.IPv6 && bytes.length == 16) {
    final allZeroPrefix = bytes.take(15).every((byte) => byte == 0);
    final unspecified = allZeroPrefix && bytes[15] == 0;
    final loopback = allZeroPrefix && bytes[15] == 1;
    final uniqueLocal = (bytes[0] & 0xFE) == 0xFC;
    final linkLocal = bytes[0] == 0xFE && (bytes[1] & 0xC0) == 0x80;
    final multicast = bytes[0] == 0xFF;
    final documentation = bytes[0] == 0x20 &&
        bytes[1] == 0x01 &&
        bytes[2] == 0x0D &&
        bytes[3] == 0xB8;
    final ipv4Mapped = bytes.take(10).every((byte) => byte == 0) &&
        bytes[10] == 0xFF &&
        bytes[11] == 0xFF;
    if (unspecified ||
        loopback ||
        uniqueLocal ||
        linkLocal ||
        multicast ||
        documentation) {
      return false;
    }
    if (ipv4Mapped) {
      return _isPublicAddress(
        InternetAddress.fromRawAddress(bytes.sublist(12), type: InternetAddressType.IPv4),
      );
    }
    return true;
  }

  // Unknown address types are not safe destinations for an HTTP URL check.
  return false;
}
