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

    test('does not split a supplementary Unicode character at the title cap', () async {
      final prefix = List<String>.filled(299, 'a').join();
      articleReaderTransportForTesting = (uri, addresses, timeout) async =>
          ArticleReaderTransportResponse(
            statusCode: 200,
            contentType: 'text/html; charset=utf-8',
            body: utf8.encode(
              '<title>${prefix}🙂tail</title><article>Readable body</article>',
            ),
          );

      final result = await loadArticleForReader(
        'https://example.com/unicode-title',
      );

      expect(result.state, ArticleReaderState.success);
      expect(result.title, prefix);
      expect(
        result.title!.codeUnits.any(
          (unit) => unit >= 0xD800 && unit <= 0xDFFF,
        ),
        isFalse,
      );
      expect(result.text, contains('Readable body'));
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

    test('ignores charset-looking tags inside scripts and comments', () async {
      final prefix =
          '<html><head><!-- <meta charset="windows-1252"> -->'
          '<script>const tag = "<meta charset=windows-1252>";</script>'
          '</head><body><article>Price: ';
      const suffix = '</article></body></html>';
      articleReaderTransportForTesting = (uri, addresses, timeout) async =>
          ArticleReaderTransportResponse(
            statusCode: 200,
            contentType: 'text/html',
            body: <int>[
              ...utf8.encode(prefix),
              0x80,
              ...utf8.encode(suffix),
            ],
          );

      final result = await loadArticleForReader('https://example.com/fake-meta');

      expect(result.state, ArticleReaderState.success);
      expect(result.text, contains('Price: \uFFFD'));
      expect(result.text, isNot(contains('€')));
    });
    test('uses an early HTML meta charset when the response omits charset', () async {
      final prefix =
          '<html><head><meta charset="windows-1252"></head><body>'
          '<article>Price: ';
      const suffix = '</article></body></html>';
      articleReaderTransportForTesting = (uri, addresses, timeout) async =>
          ArticleReaderTransportResponse(
            statusCode: 200,
            contentType: 'text/html',
            body: <int>[
              ...utf8.encode(prefix),
              0x80,
              ...utf8.encode(suffix),
            ],
          );

      final result = await loadArticleForReader('https://example.com/meta-charset');

      expect(result.state, ArticleReaderState.success);
      expect(result.text, 'Price: €');
    });

    test('reads legacy charset from an early http-equiv meta tag', () async {
      final prefix =
          '<html><head><meta http-equiv="Content-Type" '
          'content="text/html; charset=windows-1252"></head><body>'
          '<article>Price: ';
      const suffix = '</article></body></html>';
      articleReaderTransportForTesting = (uri, addresses, timeout) async =>
          ArticleReaderTransportResponse(
            statusCode: 200,
            contentType: 'text/html',
            body: <int>[
              ...utf8.encode(prefix),
              0x80,
              ...utf8.encode(suffix),
            ],
          );

      final result = await loadArticleForReader('https://example.com/legacy-meta');

      expect(result.state, ArticleReaderState.success);
      expect(result.text, 'Price: €');
    });

    test('ignores charset-like text in unrelated meta attributes', () async {
      const prefix =
          '<html><head><meta name="description" '
          'content="This page mentions charset=windows-1252">'
          '<meta name="keywords" '
          'content="encoding; charset=windows-1252"></head><body>'
          '<article>Price: ';
      const suffix = '</article></body></html>';
      articleReaderTransportForTesting = (uri, addresses, timeout) async =>
          ArticleReaderTransportResponse(
            statusCode: 200,
            contentType: 'text/html',
            body: <int>[
              ...utf8.encode(prefix),
              0x80,
              ...utf8.encode(suffix),
            ],
          );

      final result = await loadArticleForReader(
        'https://example.com/unrelated-meta-charset',
      );

      expect(result.state, ArticleReaderState.success);
      expect(result.text, 'Price: \uFFFD');
      expect(result.text, isNot(contains('€')));
    });

    test('continues scanning after unrelated meta content to find a real charset', () async {
      const prefix =
          '<html><head><meta name="description" '
          'content="This page mentions charset=utf-8">'
          '<meta charset="windows-1252"></head><body><article>Price: ';
      const suffix = '</article></body></html>';
      articleReaderTransportForTesting = (uri, addresses, timeout) async =>
          ArticleReaderTransportResponse(
            statusCode: 200,
            contentType: 'text/html',
            body: <int>[
              ...utf8.encode(prefix),
              0x80,
              ...utf8.encode(suffix),
            ],
          );

      final result = await loadArticleForReader(
        'https://example.com/real-meta-after-description',
      );

      expect(result.state, ArticleReaderState.success);
      expect(result.text, 'Price: €');
    });

    test('prefers the HTTP charset over an HTML meta charset', () async {
      const prefix =
          '<html><head><meta charset="utf-8"></head><body>'
          '<article>Price: ';
      const suffix = '</article></body></html>';
      articleReaderTransportForTesting = (uri, addresses, timeout) async =>
          ArticleReaderTransportResponse(
            statusCode: 200,
            contentType: 'text/html; charset=windows-1252',
            body: <int>[
              ...utf8.encode(prefix),
              0x80,
              ...utf8.encode(suffix),
            ],
          );

      final result = await loadArticleForReader(
        'https://example.com/http-charset-precedence',
      );

      expect(result.state, ArticleReaderState.success);
      expect(result.text, 'Price: €');
    });

    test('ignores HTML meta charset declarations beyond the 1024-byte prescan', () async {
      final prefix = List<int>.filled(1024, 0x20);
      articleReaderTransportForTesting = (uri, addresses, timeout) async =>
          ArticleReaderTransportResponse(
            statusCode: 200,
            contentType: 'text/html',
            body: <int>[
              ...prefix,
              ...utf8.encode(
                '<meta charset="windows-1252"><article>Price: ',
              ),
              0x80,
              ...utf8.encode('</article>'),
            ],
          );

      final result = await loadArticleForReader(
        'https://example.com/late-meta-charset',
      );

      expect(result.state, ArticleReaderState.success);
      expect(result.text, 'Price: \uFFFD');
      expect(result.text, isNot(contains('€')));
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

  test('expands selection edges that split a supplementary Unicode character', () {
    const text = 'A🙂B';

    final selectedAfterHighSurrogate =
        captureArticleReaderSelection(text, 2, 3);
    expect(selectedAfterHighSurrogate, isNotNull);
    expect(selectedAfterHighSurrogate!.quote, '🙂');
    expect(selectedAfterHighSurrogate.startOffset, 1);
    expect(selectedAfterHighSurrogate.endOffset, 3);
    expect(selectedAfterHighSurrogate.contextBefore, 'A');
    expect(selectedAfterHighSurrogate.contextAfter, 'B');

    final selectedBeforeLowSurrogate =
        captureArticleReaderSelection(text, 0, 2);
    expect(selectedBeforeLowSurrogate, isNotNull);
    expect(selectedBeforeLowSurrogate!.quote, 'A🙂');
    expect(selectedBeforeLowSurrogate.endOffset, 3);
  });

  test('keeps context window edges outside supplementary Unicode characters', () {
    final beforeText = '🙂${List<String>.filled(79, 'a').join()}X';
    final beforeSelection = captureArticleReaderSelection(
      beforeText,
      81,
      82,
    );
    expect(beforeSelection, isNotNull);
    expect(beforeSelection!.quote, 'X');
    expect(beforeSelection.contextBefore, startsWith('🙂'));
    expect(beforeSelection.contextBefore.length, 81);
    expect(
      beforeSelection.contextBefore.codeUnitAt(0),
      inInclusiveRange(0xD800, 0xDBFF),
    );
    expect(
      beforeSelection.contextBefore.codeUnitAt(1),
      inInclusiveRange(0xDC00, 0xDFFF),
    );

    final afterText = 'X${List<String>.filled(79, 'a').join()}🙂Z';
    final afterSelection = captureArticleReaderSelection(afterText, 0, 1);
    expect(afterSelection, isNotNull);
    expect(afterSelection!.quote, 'X');
    expect(afterSelection.contextAfter, endsWith('🙂'));
    expect(afterSelection.contextAfter.length, 81);
    expect(
      afterSelection.contextAfter.codeUnitAt(79),
      inInclusiveRange(0xD800, 0xDBFF),
    );
    expect(
      afterSelection.contextAfter.codeUnitAt(80),
      inInclusiveRange(0xDC00, 0xDFFF),
    );
  });

  test('rejects collapsed or out-of-range Reader selections', () {
    expect(captureArticleReaderSelection('article', 2, 2), isNull);
    expect(captureArticleReaderSelection('article', -1, 2), isNull);
    expect(captureArticleReaderSelection('article', 2, 99), isNull);
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

  test('removes closed forms and interactive widgets but preserves article text', () {
    final text = sanitizeArticleMarkup(
      '<form><label>Newsletter address</label>'
      '<button>Subscribe to updates</button></form>'
      '<article><h1>Actual article headline</h1>'
      '<p>The useful story remains readable.</p>'
      '<form><label>Comment form secret</label></form>'
      '<select><option>Hidden category option</option></select>'
      '<textarea>Unsubmitted comment draft</textarea>'
      '<button>Share this story</button>'
      '<dialog>Sign in to continue</dialog>'
      '<p>Final article paragraph.</p></article>',
    );

    expect(text, contains('Actual article headline'));
    expect(text, contains('The useful story remains readable.'));
    expect(text, contains('Final article paragraph.'));
    expect(text, isNot(contains('Newsletter address')));
    expect(text, isNot(contains('Subscribe to updates')));
    expect(text, isNot(contains('Comment form secret')));
    expect(text, isNot(contains('Hidden category option')));
    expect(text, isNot(contains('Unsubmitted comment draft')));
    expect(text, isNot(contains('Share this story')));
    expect(text, isNot(contains('Sign in to continue')));
  });

  test('does not leak the tail of an unclosed form or interactive widget', () {
    final unclosedForm = sanitizeArticleMarkup(
      '<article><p>Readable before the broken form.</p>'
      '<form><label>Private form tail',
    );
    final unclosedButton = sanitizeArticleMarkup(
      '<article><p>Readable before the broken widget.</p>'
      '<button>Private widget tail',
    );

    expect(unclosedForm, contains('Readable before the broken form.'));
    expect(unclosedForm, isNot(contains('Private form tail')));
    expect(unclosedButton, contains('Readable before the broken widget.'));
    expect(unclosedButton, isNot(contains('Private widget tail')));
  });

  test('keeps the complete outer article when article elements are nested', () {
    final text = sanitizeArticleMarkup(
      '<div data-template="<article>not a container</article>">'
      '<article data-label="quoted > character">'
      '<h1>Outer article introduction.</h1>'
      '<article class="related"><p>Nested article text.</p></article>'
      '<p>Outer article continuation.</p>'
      '</article></div>'
      '<article><p>Sibling article text.</p></article>',
    );

    expect(text, contains('Outer article introduction.'));
    expect(text, contains('Nested article text.'));
    expect(text, contains('Outer article continuation.'));
    expect(text, isNot(contains('not a container')));
    expect(text, isNot(contains('Sibling article text')));
  });

  test('keeps the complete main container when main elements are nested', () {
    final text = sanitizeArticleMarkup(
      '<header>Page masthead outside main.</header>'
      '<main data-label="quoted > character">'
      '<h1>Main introduction.</h1>'
      '<main class="content"><p>Nested main content.</p></main>'
      '<p>Main continuation.</p>'
      '</main>',
    );

    expect(text, contains('Main introduction.'));
    expect(text, contains('Nested main content.'));
    expect(text, contains('Main continuation.'));
    expect(text, isNot(contains('Page masthead outside main')));
  });

  test('preserves block boundaries for quotes, figures, lists and table cells', () {
    final text = sanitizeArticleMarkup(
      '<article><h1>Reader headline</h1>'
      '<p>Opening paragraph.</p>'
      '<blockquote><p>Quoted first line.</p>'
      '<p>Quoted second line.</p></blockquote>'
      '<figure><figcaption>Photo caption.</figcaption></figure>'
      '<ul><li>First list item.</li><li>Second list item.</li></ul>'
      '<table><tbody><tr><th>Year</th><th>Value</th></tr>'
      '<tr><td>2026</td><td>Readable result.</td></tr></tbody></table>'
      '<hr><p>Closing paragraph.</p></article>',
    );

    expect(text, contains('Reader headline'));
    expect(text, contains('Opening paragraph.'));
    expect(text, contains('Quoted first line.'));
    expect(text, contains('Quoted second line.'));
    expect(text, contains('Photo caption.'));
    expect(text, contains('First list item.'));
    expect(text, contains('Second list item.'));
    expect(text, contains('Year'));
    expect(text, contains('Value'));
    expect(text, contains('2026'));
    expect(text, contains('Readable result.'));
    expect(text, contains('Closing paragraph.'));

    expect(text.indexOf('Opening paragraph.'),
        lessThan(text.indexOf('Quoted first line.')));
    expect(text.indexOf('Quoted second line.'),
        lessThan(text.indexOf('Photo caption.')));
    expect(text.indexOf('Photo caption.'),
        lessThan(text.indexOf('First list item.')));
    expect(text.indexOf('First list item.'),
        lessThan(text.indexOf('Second list item.')));
    expect(text.indexOf('Year'), lessThan(text.indexOf('Value')));
    expect(text.indexOf('Value'), lessThan(text.indexOf('2026')));
    expect(text.indexOf('2026'),
        lessThan(text.indexOf('Readable result.')));
    expect(text, contains('Opening paragraph.\n'));
    expect(text, contains('Quoted first line.\n'));
    expect(text, contains('First list item.\n'));
    expect(text, contains('Year\n'));
  });

  test('does not leak quoted attribute text while stripping block and inline tags', () {
    final text = sanitizeArticleMarkup(
      '<article>'
      '<p data-label="hidden-before > hidden-after">First paragraph.</p>'
      '<p>Second paragraph.</p>'
      '<span title="inline-hidden-before > inline-hidden-after">kept inline</span>'
      '<strong> words together.</strong>'
      '</article>',
    );

    expect(text, contains('First paragraph.'));
    expect(text, contains('Second paragraph.'));
    expect(text, contains('kept inline words together.'));
    expect(text, contains('First paragraph.\n'));
    expect(text, isNot(contains('hidden-before')));
    expect(text, isNot(contains('hidden-after')));
    expect(text, isNot(contains('inline-hidden')));
  });

  test('drops the tail after an unterminated double-quoted tag attribute', () {
    final text = sanitizeArticleMarkup(
      '<article><p>Readable text before malformed markup.</p>'
      '<span title="unfinished > private attribute tail '
      'and text that must not be exposed',
    );

    expect(text, contains('Readable text before malformed markup.'));
    expect(text, isNot(contains('unfinished')));
    expect(text, isNot(contains('private attribute tail')));
    expect(text, isNot(contains('must not be exposed')));
  });

  test('drops the tail after an unterminated single-quoted tag attribute', () {
    final text = sanitizeArticleMarkup(
      '<article><p>Keep this complete paragraph.</p>'
      '<em data-note=\'unfinished > secret attribute tail '
      'and remaining malformed page content',
    );

    expect(text, contains('Keep this complete paragraph.'));
    expect(text, isNot(contains('unfinished')));
    expect(text, isNot(contains('secret attribute tail')));
    expect(text, isNot(contains('remaining malformed page content')));
  });

  test('does not expose document declarations when no semantic container exists', () {
    final text = sanitizeArticleMarkup(
      '<!DOCTYPE html>'
      '<?xml version="1.0" encoding="UTF-8"?>'
      '<html><body><p>Readable page text.</p></body></html>',
    );

    expect(text, contains('Readable page text.'));
    expect(text, isNot(contains('DOCTYPE')));
    expect(text, isNot(contains('xml version')));
    expect(text, isNot(contains('<?')));
  });
}
