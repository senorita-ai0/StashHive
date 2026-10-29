import 'package:flutter_test/flutter_test.dart';
import 'package:stashhive/services/article_reader.dart';

void main() {
  group('parseArticleReaderUrl', () {
    test('accepts HTTP and HTTPS public-looking URLs', () {
      expect(
        parseArticleReaderUrl('https://example.com/article')?.scheme,
        'https',
      );
      expect(
        parseArticleReaderUrl('http://news.example.org')?.host,
        'news.example.org',
      );
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

    test('rejects localhost, local suffixes, private literals and malformed values', () {
      for (final value in <String>[
        'http://localhost/',
        'http://service.local/',
        'http://router.internal/',
        'http://127.0.0.1/',
        'http://192.168.1.20/',
        'http://[::1]/',
        'not a URL',
        '',
      ]) {
        expect(parseArticleReaderUrl(value), isNull, reason: value);
      }
    });
  });

  test('reader result exposes success without involving repository storage', () {
    const result = ArticleReaderResult(
      state: ArticleReaderState.success,
      title: 'Article title',
      text: 'Temporary page text',
    );
    expect(result.isSuccess, isTrue);
    expect(result.text, 'Temporary page text');
  });

  test('sanitizes hostile HTML to readable plain text', () {
    final text = sanitizeArticleMarkup(
      '<nav>Navigation links</nav>'
      '<article><h1>News &amp; updates</h1>'
      '<script>stealCookies()</script>'
      '<style>.hidden{display:none}</style>'
      '<p>Useful &lt;safe&gt; text</p>'
      '<iframe src="https://evil.example">frame secret</iframe></article>'
      '<footer>Footer links</footer>',
    );

    expect(text, contains('News & updates'));
    expect(text, contains('Useful <safe> text'));
    expect(text, isNot(contains('stealCookies')));
    expect(text, isNot(contains('frame secret')));
    expect(text, isNot(contains('Navigation links')));
    expect(text, isNot(contains('Footer links')));
    expect(text, isNot(contains('<script')));
  });

  test('plain text normalization preserves Unicode and line breaks', () {
    expect(
      sanitizeArticleMarkup('  سلام  \r\n  hello  ', isHtml: false),
      'سلام\nhello',
    );
  });
}
