import 'article_reader.dart';

Future<ArticleReaderResult> loadArticleForReader(
  String url, {
  required Duration timeout,
}) async =>
    const ArticleReaderResult(
      state: ArticleReaderState.networkError,
      message: 'Article reader is unavailable on this platform.',
    );
