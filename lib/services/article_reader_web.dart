import 'article_reader.dart';

/// Cross-origin browser fetches are blocked unless the destination opts into
/// CORS. Do not add a hosted proxy or send saved content to another service.
Future<ArticleReaderResult> loadArticleForReader(
  String url, {
  required Duration timeout,
}) async {
  if (parseArticleReaderUrl(url) == null) {
    return const ArticleReaderResult(state: ArticleReaderState.invalidUrl);
  }
  return const ArticleReaderResult(
    state: ArticleReaderState.unavailableInBrowser,
    message:
        'Your browser blocks reading many external websites directly. Open the link in your browser instead; StashHive does not use a proxy.',
  );
}
