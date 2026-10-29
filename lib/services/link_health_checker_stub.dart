import '../models/link_health_record.dart';

Future<LinkHealthRecord> checkLinkHealth({
  required String itemId,
  required String url,
  required Duration timeout,
}) async {
  return LinkHealthRecord(
    itemId: itemId,
    checkedUrl: url,
    state: LinkHealthState.unsupportedPlatform,
    checkedAtMs: DateTime.now().millisecondsSinceEpoch,
  );
}
