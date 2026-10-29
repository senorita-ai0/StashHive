import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stashhive/services/article_reader.dart';

void main() {
  tearDown(() {
    articleReaderDnsResolverForTesting = null;
    articleReaderTransportForTesting = null;
    articleReaderLoaderForTesting = null;
  });

  group('native article reader transport policy', () {
    setUp(() {
      articleReaderDnsResolverForTesting = (host) async => <String>['93.184.216.34'];
    });

    test('extracts a real title instead of title-looking script or comment text', () async {
      articleReaderTransportForTesting = (uri, addresses, timeout) async =>
          ArticleReaderTransportResponse(
            statusCode: 200,
            contentType: 'text/html; charset=utf-8',
            body: utf8.encode(
              '<script>const template = "<title>Fake script title</title>";</script>'
              '<!-- <title>Fake comment title</title> -->'
              '<title>Actual &amp; useful title</title>'
              '<article><p>Actual article body.</p></article>',
            ),
          );

      final result = await loadArticleForReader('https://example.com/title');

      expect(result.state, ArticleReaderState.success);
      expect(result.title, 'Actual & useful title');
      expect(result.text, contains('Actual article body.'));
    });

    test('loads HTML through the injected transport and sanitizes its contents', () async {
      Uri? requestedUri;
      List<String>? vettedAddresses;
      articleReaderTransportForTesting = (uri, addresses, timeout) async {
        requestedUri = uri;
        vettedAddresses = addresses;
        return ArticleReaderTransportResponse(
          statusCode: 200,
          contentType: 'text/html; charset=utf-8',
          body: utf8.encode(
            '<title>Reader title</title>'
            '<nav>Menu</nav><article><h1>Useful &amp; safe</h1>'
            '<script>doNotRun()</script><p>Readable paragraph.</p></article>',
          ),
        );
      };

      final result = await loadArticleForReader(
        'https://example.com/path?q=1',
      );

      expect(result.state, ArticleReaderState.success);
      expect(result.title, 'Reader title');
      expect(result.text, contains('Useful & safe'));
      expect(result.text, contains('Readable paragraph.'));
      expect(result.text, isNot(contains('doNotRun')));
      expect(result.text, isNot(contains('Menu')));
      expect(requestedUri?.path, '/path');
      expect(requestedUri?.queryParameters['q'], '1');
      expect(vettedAddresses, ['93.184.216.34']);
    });

    test('rejects a redirect without returning its response body', () async {
      articleReaderTransportForTesting = (uri, addresses, timeout) async =>
          ArticleReaderTransportResponse(
            statusCode: 302,
            contentType: 'text/html',
            body: utf8.encode('<article>redirect body must not show</article>'),
          );

      final result = await loadArticleForReader('https://example.com/path');

      expect(result.state, ArticleReaderState.networkError);
      expect(result.text, isEmpty);
      expect(result.message, contains('redirects'));
    });

    test('rejects non-HTML response content types', () async {
      articleReaderTransportForTesting = (uri, addresses, timeout) async =>
          ArticleReaderTransportResponse(
            statusCode: 200,
            contentType: 'application/pdf',
            body: <int>[37, 80, 68, 70],
          );

      final result = await loadArticleForReader('https://example.com/file.pdf');

      expect(result.state, ArticleReaderState.unsupportedContent);
      expect(result.text, isEmpty);
    });

    test('strips a leading UTF-8 BOM from reader text', () async {
      articleReaderTransportForTesting = (uri, addresses, timeout) async =>
          ArticleReaderTransportResponse(
            statusCode: 200,
            contentType: 'text/plain; charset=utf-8',
            body: <int>[
              0xEF,
              0xBB,
              0xBF,
              ...utf8.encode('BOM-free article'),
            ],
          );

      final result = await loadArticleForReader('https://example.com/bom');

      expect(result.state, ArticleReaderState.success);
      expect(result.text, 'BOM-free article');
      expect(result.text.codeUnitAt(0), isNot(0xFEFF));
    });

    test('decodes Windows-1252 punctuation and the euro sign', () async {
      articleReaderTransportForTesting = (uri, addresses, timeout) async =>
          ArticleReaderTransportResponse(
            statusCode: 200,
            contentType: 'text/plain; charset="windows-1252"',
            body: <int>[
              0x80, 0x20, 0x93, 0x68, 0x65, 0x6c, 0x6c, 0x6f, 0x94,
              0x20, 0x97, 0x20, 0x31, 0x30, 0x30, 0x20, 0x80,
            ],
          );

      final result = await loadArticleForReader('https://example.com/legacy');

      expect(result.state, ArticleReaderState.success);
      expect(result.text, '€ “hello” — 100 €');
    });

    test('supports the cp1252 alias without changing Latin-1 decoding', () async {
      articleReaderTransportForTesting = (uri, addresses, timeout) async =>
          ArticleReaderTransportResponse(
            statusCode: 200,
            contentType: uri.path == '/cp1252'
                ? 'text/plain; charset=cp1252'
                : 'text/plain; charset=latin1',
            body: <int>[0x80],
          );

      final windows = await loadArticleForReader(
        'https://example.com/cp1252',
      );
      final latin = await loadArticleForReader(
        'https://example.com/latin1',
      );

      expect(windows.text, '€');
      expect(latin.text.codeUnitAt(0), 0x80);
    });

    test('enforces the response byte cap even with an injected response', () async {
      articleReaderTransportForTesting = (uri, addresses, timeout) async =>
          ArticleReaderTransportResponse(
            statusCode: 200,
            contentType: 'text/plain; charset=utf-8',
            body: List<int>.filled(maxArticleResponseBytes + 1, 97),
          );

      final result = await loadArticleForReader('https://example.com/large');

      expect(result.state, ArticleReaderState.tooLarge);
      expect(result.text, isEmpty);
    });

    test('enforces the display text cap after sanitizing', () async {
      articleReaderTransportForTesting = (uri, addresses, timeout) async =>
          ArticleReaderTransportResponse(
            statusCode: 200,
            contentType: 'text/plain',
            body: utf8.encode(List<String>.filled(12000, 'safe text').join(' ')),
          );

      final result = await loadArticleForReader('https://example.com/long');

      expect(result.state, ArticleReaderState.success);
      expect(result.text.length, maxArticleTextCharacters);
    });

    test('does not split a supplementary Unicode character at the text cap', () async {
      final prefix = List<String>.filled(
        maxArticleTextCharacters - 1,
        'a',
      ).join();
      articleReaderTransportForTesting = (uri, addresses, timeout) async =>
          ArticleReaderTransportResponse(
            statusCode: 200,
            contentType: 'text/plain; charset=utf-8',
            body: utf8.encode('${prefix}🙂tail'),
          );

      final result = await loadArticleForReader(
        'https://example.com/unicode-boundary',
      );

      expect(result.state, ArticleReaderState.success);
      expect(result.text.length, maxArticleTextCharacters - 1);
      expect(result.text, prefix);
      expect(
        result.text.codeUnits.any(
          (unit) => unit >= 0xD800 && unit <= 0xDFFF,
        ),
        isFalse,
      );
    });

    test('blocks private DNS answers before transport is called', () async {
      articleReaderDnsResolverForTesting = (host) async => <String>['127.0.0.1'];
      var transportCalled = false;
      articleReaderTransportForTesting = (uri, addresses, timeout) async {
        transportCalled = true;
        return ArticleReaderTransportResponse(
          statusCode: 200,
          contentType: 'text/plain',
          body: utf8.encode('should not load'),
        );
      };

      final result = await loadArticleForReader('https://example.com/private');

      expect(result.state, ArticleReaderState.blockedAddress);
      expect(transportCalled, isFalse);
    });

    test('blocks a DNS answer set containing both public and private IPv4', () async {
      articleReaderDnsResolverForTesting =
          (host) async => <String>['93.184.216.34', '10.0.0.8'];
      var transportCalled = false;
      articleReaderTransportForTesting = (uri, addresses, timeout) async {
        transportCalled = true;
        return ArticleReaderTransportResponse(
          statusCode: 200,
          contentType: 'text/plain',
          body: utf8.encode('should not load'),
        );
      };

      final result = await loadArticleForReader('https://example.com/mixed-dns');

      expect(result.state, ArticleReaderState.blockedAddress);
      expect(transportCalled, isFalse);
    });

    test('blocks reserved IPv4 destination ranges before transport', () async {
      const blockedAddresses = <String>[
        '0.1.2.3',
        '10.0.0.8',
        '100.64.0.1',
        '127.0.0.1',
        '169.254.1.1',
        '172.16.0.1',
        '192.0.0.1',
        '192.0.2.1',
        '192.168.1.1',
        '192.88.99.1',
        '198.18.0.1',
        '198.51.100.1',
        '203.0.113.1',
        '224.0.0.1',
        '240.0.0.1',
      ];

      for (final address in blockedAddresses) {
        articleReaderDnsResolverForTesting = (host) async => <String>[address];
        var transportCalled = false;
        articleReaderTransportForTesting = (uri, addresses, timeout) async {
          transportCalled = true;
          return ArticleReaderTransportResponse(
            statusCode: 200,
            contentType: 'text/plain',
            body: utf8.encode('must not be loaded'),
          );
        };

        final result = await loadArticleForReader('https://example.com/article');

        expect(
          result.state,
          ArticleReaderState.blockedAddress,
          reason: 'Blocked address should be rejected: $address',
        );
        expect(transportCalled, isFalse, reason: address);
      }
    });

    test('maps DNS resolution timeout to the reader timeout state', () async {
      articleReaderDnsResolverForTesting =
          (host) => Completer<List<String>>().future;

      final result = await loadArticleForReader(
        'https://example.com/slow-dns',
        timeout: const Duration(milliseconds: 1),
      );

      expect(result.state, ArticleReaderState.timedOut);
    });

    test('does not expose content from unsuccessful HTTP responses', () async {
      articleReaderTransportForTesting = (uri, addresses, timeout) async =>
          ArticleReaderTransportResponse(
            statusCode: 503,
            contentType: 'text/plain',
            body: utf8.encode('private server diagnostic details'),
          );

      final result = await loadArticleForReader('https://example.com/unavailable');

      expect(result.state, ArticleReaderState.networkError);
      expect(result.text, isEmpty);
      expect(result.message, isNot(contains('diagnostic details')));
    });

    test('maps a transport timeout to a recoverable reader state', () async {
      var transportCalled = false;
      articleReaderTransportForTesting = (uri, addresses, timeout) {
        transportCalled = true;
        return Completer<ArticleReaderTransportResponse>().future;
      };

      final result = await loadArticleForReader(
        'https://example.com/slow',
        timeout: const Duration(milliseconds: 100),
      );

      expect(transportCalled, isTrue);
      expect(result.state, ArticleReaderState.timedOut);
    });
  });

  group('parseArticleReaderUrl', () {
    test('invalid URLs are rejected before even an injected loader runs', () async {
      var loaderCalled = false;
      articleReaderLoaderForTesting = (url, timeout) async {
        loaderCalled = true;
        return const ArticleReaderResult(state: ArticleReaderState.success);
      };

      final result = await loadArticleForReader('javascript:alert(1)');

      expect(result.state, ArticleReaderState.invalidUrl);
      expect(loaderCalled, isFalse);
    });

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

    test('rejects non-web schemes, credentials, and unsupported ports', () {
      for (final value in <String>[
        'javascript:alert(1)',
        'file:///etc/passwd',
        'ftp://example.com/article',
        'https://user:password@example.com/',
        'http://example.com:8080/',
        'https://example.com:8443/',
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

  test('replaces non-printing control characters without damaging Unicode', () {
    expect(
      sanitizeArticleMarkup('hello\u0000world\u0001\u007F سلام', isHtml: false),
      'hello world سلام',
    );
  });

  test('decodes common named entities without recursively unescaping text', () {
    final text = sanitizeArticleMarkup(
      'A &copy; &REG; &trade; &euro; &lsquo;hello&rsquo; '
      '&ldquo;world&rdquo; &bull; &amp;#169; &amp;lt;tag&amp;gt; &#x1F642;',
      isHtml: false,
    );

    expect(
      text,
      'A © ® ™ € ‘hello’ “world” • &#169; &lt;tag&gt; 🙂',
    );
  });

  test('ignores fake article containers inside scripts and comments', () {
    final text = sanitizeArticleMarkup(
      '<script>const template = "<article>fake script article</article>";</script>'
      '<!-- <article>fake commented article</article> -->'
      '<nav><article>fake navigation article</article>Navigation</nav>'
      '<article><p>The actual article body.</p></article>',
    );

    expect(text, contains('The actual article body.'));
    expect(text, isNot(contains('fake script article')));
    expect(text, isNot(contains('fake commented article')));
    expect(text, isNot(contains('fake navigation article')));
    expect(text, isNot(contains('Navigation')));
  });

  test('malformed unclosed active markup does not leak its tail into reader text', () {
    final openScript = sanitizeArticleMarkup(
      '<p>Readable paragraph.</p><script>secretCode()</script never-closed',
    );
    final openComment = sanitizeArticleMarkup(
      '<p>Visible paragraph.</p><!-- private hidden tail',
    );

    expect(openScript, contains('Readable paragraph.'));
    expect(openScript, isNot(contains('secretCode')));
    expect(openScript, isNot(contains('never-closed')));
    expect(openComment, contains('Visible paragraph.'));
    expect(openComment, isNot(contains('private hidden tail')));
  });
}
