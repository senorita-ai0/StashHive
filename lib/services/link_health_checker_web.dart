import '../models/link_health_record.dart';

/// Browsers generally cannot inspect cross-origin HTTP response status without
/// the destination granting CORS access. Do not use a proxy or silently fetch
/// page content just to produce a status label.
Future<LinkHealthRecord> checkLinkHealth({
  required String itemId,
  required String url,
  required Duration timeout,
}) async {
  return LinkHealthRecord(
    itemId: itemId,
    checkedUrl: url,
    state: LinkHealthState.unavailableInBrowser,
    checkedAtMs: DateTime.now().millisecondsSinceEpoch,
  );
}
