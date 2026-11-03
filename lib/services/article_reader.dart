import 'package:flutter/foundation.dart' show visibleForTesting;

import 'article_reader_core.dart';
import 'article_reader_stub.dart'
    if (dart.library.io) 'article_reader_io.dart'
    if (dart.library.js_interop) 'article_reader_web.dart' as platform;

export 'article_reader_core.dart';

/// Test seam for deterministic reader UI tests. Production leaves this unset.
@visibleForTesting
Future<ArticleReaderResult> Function(String url, Duration timeout)?
    articleReaderLoaderForTesting;

/// Called only from an explicit reader action. The result is transient and is
/// never written to LibraryRepository or included in backups.
Future<ArticleReaderResult> loadArticleForReader(
  String url, {
  Duration timeout = defaultArticleReaderTimeout,
}) {
  // Keep URL validation ahead of every transport path, including test seams,
  // so an injected transport cannot accidentally mask invalid-input behavior.
  if (parseArticleReaderUrl(url) == null) {
    return Future<ArticleReaderResult>.value(
      const ArticleReaderResult(state: ArticleReaderState.invalidUrl),
    );
  }
  final testLoader = articleReaderLoaderForTesting;
  if (testLoader != null) return testLoader(url, timeout);
  return platform.loadArticleForReader(url, timeout: timeout);
}
