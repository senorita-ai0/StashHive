import 'package:flutter_test/flutter_test.dart';
import 'package:stashhive/services/article_reader.dart';

void main() {
  group('parseArticleReaderUrl', () {
    test('accepts HTTP and HTTPS public-looking URLs', () {
      expect(parseArticleReaderUrl('https://example.com/article')?.scheme, 'https');
      expect(parseArticleReaderUrl('http://news.example.org')?.host, 'news.example.org');
    });

    test('rejects non-web schemes and credential-bearing URLs', () {
      for (final value in <String>[
        'javascript:alert(1)',
        'file:///etc/passwd',
        'ftp://example.com/article',
        'https://user:password@example.com/',
      ]) {
        expect(parseArticleReaderUrl(value), isNull, reason: value);
      }
    });

    test('rejects localhost, local suffixes, and malformed values', () {
      for (final value in <String>[
        'http://localhost/',
        'http://service.local/',
        'http://router.internal/',
        'not a URL',
        '',
      ]) {
        expect(parseArticleReaderUrl(value), isNull, reason: value);
      }
    });
  });

  test('reader result exposes success without persisting content', () {
    const result = ArticleReaderResult(
      state: ArticleReaderState.success,
      title: 'Article title',
      text: 'Temporary page text',
    );
    expect(result.isSuccess, isTrue);
    expect(result.text, 'Temporary page text');
  });
}
