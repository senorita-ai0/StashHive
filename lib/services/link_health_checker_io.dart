import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

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

  // Clamp caller-supplied values so this service remains a short, manual
  // check even if another caller passes an accidental extreme timeout.
  final requestTimeout = timeout <= Duration.zero ||
          timeout > const Duration(seconds: 15)
      ? const Duration(seconds: 8)
      : timeout;

  late final List<InternetAddress> publicAddresses;
  try {
    final resolved =
        await InternetAddress.lookup(host).timeout(requestTimeout);
    if (resolved.isEmpty || resolved.any((address) => !_isPublicAddress(address))) {
      return result(LinkHealthState.blockedAddress);
    }
    publicAddresses = List<InternetAddress>.unmodifiable(resolved);
  } on TimeoutException {
    return result(LinkHealthState.timedOut);
  } on SocketException {
    return result(LinkHealthState.networkError);
  } catch (_) {
    return result(LinkHealthState.networkError);
  }

  // Pin the socket to an address from the exact DNS result that passed the
  // public-address policy. Otherwise HttpClient could resolve the hostname
  // a second time and a changing DNS answer could bypass the preflight check.
  final client = HttpClient()
    ..connectionTimeout = requestTimeout
    ..idleTimeout = requestTimeout
    ..userAgent = 'StashHive-LinkCheck'
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
      return Socket.startConnect(publicAddresses.first, requestedUri.port);
    };

  try {
    final response = await _sendRequest(client, uri, requestTimeout);
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
  Duration timeout,
) async {
  final request = await client.headUrl(uri).timeout(timeout);
  // Do not follow a redirect automatically: a public website could redirect
  // to a local/private address. Report the redirect instead of probing a second host.
  request.followRedirects = false;
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
        (a == 192 && b == 0 && c == 0) ||
        (a == 192 && b == 0 && c == 2) ||
        (a == 198 && (b == 18 || b == 19)) ||
        (a == 198 && b == 51 && c == 100) ||
        (a == 192 && b == 88 && c == 99) ||
        (a == 203 && b == 0 && c == 113)) {
      return false;
    }
    return true;
  }

  if (address.type == InternetAddressType.IPv6 && bytes.length == 16) {
    final ipv4Mapped = bytes.take(10).every((byte) => byte == 0) &&
        bytes[10] == 0xFF &&
        bytes[11] == 0xFF;
    if (ipv4Mapped) {
      return _isPublicAddress(
        InternetAddress.fromRawAddress(
          Uint8List.fromList(bytes.sublist(12)),
          type: InternetAddressType.IPv4,
        ),
      );
    }

    // Only global-unicast IPv6 (2000::/3) is accepted. This also excludes
    // unspecified/loopback, ULA, link-local, site-local, multicast and
    // IPv4-translation ranges instead of trying to enumerate each range.
    final globalUnicast = (bytes[0] & 0xE0) == 0x20;
    final documentation = bytes[0] == 0x20 &&
        bytes[1] == 0x01 &&
        bytes[2] == 0x0D &&
        bytes[3] == 0xB8;
    final documentationRange = bytes[0] == 0x3F &&
        bytes[1] == 0xFF &&
        (bytes[2] & 0xF0) == 0;
    final specialPurpose2001 = bytes[0] == 0x20 &&
        bytes[1] == 0x01 &&
        bytes[2] == 0 &&
        bytes[3] <= 1;
    if (!globalUnicast ||
        documentation ||
        documentationRange ||
        specialPurpose2001) {
      return false;
    }
    return true;
  }

  // Unknown address types are not safe destinations for an HTTP URL check.
  return false;
}
