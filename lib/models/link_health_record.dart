const int maxLinkHealthHistoryRecords = 1000;

/// A manually-triggered, local-only link check result.
/// This is stored separately from saved items and is not included in backup v1.
enum LinkHealthState {
  healthy,
  redirect,
  notFound,
  gone,
  restricted,
  httpError,
  serverError,
  networkError,
  timedOut,
  tlsError,
  blockedAddress,
  invalidUrl,
  unavailableInBrowser,
  unsupportedPlatform;

  String get label => switch (this) {
        LinkHealthState.healthy => 'Responded successfully',
        LinkHealthState.redirect => 'Redirect response',
        LinkHealthState.notFound => 'Not found (404)',
        LinkHealthState.gone => 'No longer available (410)',
        LinkHealthState.restricted => 'Access restricted',
        LinkHealthState.httpError => 'HTTP error response',
        LinkHealthState.serverError => 'Server error',
        LinkHealthState.networkError => 'Network or DNS error',
        LinkHealthState.timedOut => 'Request timed out',
        LinkHealthState.tlsError => 'Secure connection failed',
        LinkHealthState.blockedAddress => 'Blocked for safety',
        LinkHealthState.invalidUrl => 'Invalid web address',
        LinkHealthState.unavailableInBrowser => 'Cannot verify in this browser',
        LinkHealthState.unsupportedPlatform => 'Checking unavailable on this platform',
      };

  String get explanation => switch (this) {
        LinkHealthState.healthy =>
          'The destination responded successfully when checked.',
        LinkHealthState.redirect =>
          'The server returned a redirect. This check does not follow it; open the link in your browser to inspect the destination.',
        LinkHealthState.notFound =>
          'The destination returned 404. The page may have moved or been removed.',
        LinkHealthState.gone =>
          'The destination returned 410, which indicates the resource is no longer available.',
        LinkHealthState.restricted =>
          'The site denied or restricted this request. A browser login, bot protection or permissions may be required.',
        LinkHealthState.httpError =>
          'The site returned an HTTP error. This does not by itself prove the URL is permanently broken.',
        LinkHealthState.serverError =>
          'The website returned a server-side error. Try again later before treating the link as broken.',
        LinkHealthState.networkError =>
          'The device could not resolve or connect to the destination. Check your connection and try again.',
        LinkHealthState.timedOut =>
          'The request timed out. The site may be slow or temporarily unreachable.',
        LinkHealthState.tlsError =>
          'A secure connection could not be established. Certificate or network configuration may be responsible.',
        LinkHealthState.blockedAddress =>
          'This address is local, private, or otherwise reserved, so StashHive did not send a request.',
        LinkHealthState.invalidUrl =>
          'The saved value is not a valid HTTP or HTTPS web address.',
        LinkHealthState.unavailableInBrowser =>
          'Browsers block reliable status inspection for many external sites. StashHive did not contact the destination; use Open link to inspect it in your browser.',
        LinkHealthState.unsupportedPlatform =>
          'This platform does not support direct link checks. No request was sent.',
      };

  static LinkHealthState fromWire(Object? value) {
    if (value is! String || value.length > 32) {
      throw const FormatException('Unknown link health result.');
    }
    for (final state in LinkHealthState.values) {
      if (state.name == value) return state;
    }
    throw const FormatException('Unknown link health result.');
  }
}

/// The latest explicit status check for one saved URL. Original saved-item
/// metadata and timestamps are not changed by checking a link.
class LinkHealthRecord {
  const LinkHealthRecord({
    required this.itemId,
    required this.checkedUrl,
    required this.state,
    required this.checkedAtMs,
    this.httpStatusCode,
  });

  final String itemId;
  final String checkedUrl;
  final LinkHealthState state;
  final int checkedAtMs;
  final int? httpStatusCode;

  bool matchesUrl(String? url) => url != null && checkedUrl == url;

  Map<String, dynamic> toMap() {
    if (itemId.trim().isEmpty ||
        itemId.length > 128 ||
        checkedUrl.length > 4096 ||
        checkedAtMs < -8640000000000000 ||
        checkedAtMs > 8640000000000000 ||
        (httpStatusCode != null &&
            (httpStatusCode! < 100 || httpStatusCode! > 599))) {
      throw const FormatException('A link health record is invalid.');
    }
    final latestPlausible =
        DateTime.now().millisecondsSinceEpoch + const Duration(minutes: 5).inMilliseconds;
    if (checkedAtMs <= 0 || checkedAtMs > latestPlausible) {
      throw const FormatException('The link check timestamp is invalid.');
    }
    return <String, dynamic>{
      'itemId': itemId,
      'checkedUrl': checkedUrl,
      'state': state.name,
      'checkedAtMs': checkedAtMs,
      'httpStatusCode': httpStatusCode,
    };
  }

  factory LinkHealthRecord.fromMap(Map<dynamic, dynamic> raw) {
    final itemId = raw['itemId'];
    final checkedUrl = raw['checkedUrl'];
    final checkedAtMs = raw['checkedAtMs'];
    final statusCode = raw['httpStatusCode'];
    if (itemId is! String ||
        checkedUrl is! String ||
        checkedAtMs is! int ||
        (statusCode != null && statusCode is! int) ||
        checkedUrl.length > 4096 ||
        (statusCode is int && (statusCode < 100 || statusCode > 599))) {
      throw const FormatException('A link health record contains invalid fields.');
    }
    final record = LinkHealthRecord(
      itemId: itemId,
      checkedUrl: checkedUrl,
      state: LinkHealthState.fromWire(raw['state']),
      checkedAtMs: checkedAtMs,
      httpStatusCode: statusCode as int?,
    );
    record.toMap();
    return record;
  }
}

/// Converts an HTTP response code to the user-facing status category.
LinkHealthState linkHealthStateForStatusCode(int statusCode) {
  if (statusCode < 100 || statusCode > 599) {
    throw const FormatException('The HTTP status code is outside the supported range.');
  }
  if (statusCode >= 200 && statusCode < 300) return LinkHealthState.healthy;
  if (statusCode >= 300 && statusCode < 400) return LinkHealthState.redirect;
  if (statusCode == 404) return LinkHealthState.notFound;
  if (statusCode == 410) return LinkHealthState.gone;
  if (statusCode == 401 || statusCode == 403) return LinkHealthState.restricted;
  if (statusCode >= 500) return LinkHealthState.serverError;
  return LinkHealthState.httpError;
}
