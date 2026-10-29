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

/// Validates a URL before any request is attempted. Network-address validation
/// is repeated by the native transport after DNS resolution.
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
  final host = uri.host.toLowerCase();
  if (host == 'localhost' ||
      host.endsWith('.localhost') ||
      host.endsWith('.local') ||
      host.endsWith('.internal') ||
      (Uri.tryParse('http://$host')?.host == null) ||
      (host.contains('%'))) {
    return null;
  }
  return uri;
}

/// Called only from an explicit reader action. The result is transient and is
/// never written to LibraryRepository or included in backups.
Future<ArticleReaderResult> loadArticleForReader(
  String url, {
  Duration timeout = defaultArticleReaderTimeout,
}) {
  return platform.loadArticleForReader(url, timeout: timeout);
}
