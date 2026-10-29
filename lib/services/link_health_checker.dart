import '../models/link_health_record.dart';
import 'link_health_checker_stub.dart'
    if (dart.library.io) 'link_health_checker_io.dart'
    if (dart.library.js_interop) 'link_health_checker_web.dart' as platform;

export '../models/link_health_record.dart';

const Duration defaultLinkHealthTimeout = Duration(seconds: 8);

/// Checks only after a user action. Implementations must never run in the
/// background or send library content, notes, tags or attachment data.
Future<LinkHealthRecord> checkLinkHealth({
  required String itemId,
  required String url,
  Duration timeout = defaultLinkHealthTimeout,
}) {
  return platform.checkLinkHealth(
    itemId: itemId,
    url: url,
    timeout: timeout,
  );
}
