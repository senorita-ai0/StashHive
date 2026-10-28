import 'package:flutter_test/flutter_test.dart';
import 'package:stashhive/services/web_url.dart';

void main() {
  group('parseUserWebUrl', () {  test('rejects oversized URL input before normalization', () {
    final oversized = List<String>.filled(100000, ' ').join();
    expect(parseUserWebUrl(oversized), isNull);
    expect(parseHttpUrl(oversized), isNull);
  });


    test('accepts explicit web schemes and bare domains', () {
      expect(parseUserWebUrl('HTTPS://EXAMPLE.COM/Guide')?.toString(),
          'https://EXAMPLE.COM/Guide');
      expect(parseUserWebUrl('example.com/guide')?.toString(),
          'https://example.com/guide');
      expect(parseUserWebUrl('example.com:8443/guide')?.toString(),
          'https://example.com:8443/guide');
      expect(parseUserWebUrl('localhost:8080')?.toString(),
          'https://localhost:8080');
    });

    test('does not reinterpret explicit non-web schemes as hostnames', () {
      expect(parseUserWebUrl('javascript:alert(1)'), isNull);
      expect(parseUserWebUrl('javascript://example.com/alert(1)'), isNull);
      expect(parseUserWebUrl('http:example.com'), isNull);
      expect(parseUserWebUrl('file:///etc/passwd'), isNull);
      expect(parseUserWebUrl('mailto:hello@example.com'), isNull);
      expect(parseUserWebUrl('example.com:bad'), isNull);
    });

    test('does not turn arbitrary words into URLs', () {
      expect(parseUserWebUrl('remember'), isNull);
      expect(parseUserWebUrl('notes'), isNull);
      expect(parseUserWebUrl(''), isNull);
      expect(parseUserWebUrl('https://example.com/a b'), isNull);
    });
  });

  group('parseHttpUrl', () {
    test('accepts HTTP and HTTPS and normalizes scheme casing', () {
      expect(
        parseHttpUrl('HTTP://Example.com/path')?.toString(),
        'http://Example.com/path',
      );
      expect(
        parseHttpUrl('HTTPS://example.com/guide')?.toString(),
        'https://example.com/guide',
      );
    });

    test('rejects non-web schemes and hostless URLs', () {
      expect(parseHttpUrl('javascript:alert(1)'), isNull);
      expect(parseHttpUrl('file:///etc/passwd'), isNull);
      expect(parseHttpUrl('mailto:hello@example.com'), isNull);
      expect(parseHttpUrl('https:///missing-host'), isNull);
      expect(parseHttpUrl('https://user:password@example.com/secret'), isNull);
    });

    test('rejects empty, whitespace-bearing and invalid input', () {
      expect(parseHttpUrl(null), isNull);
      expect(parseHttpUrl(''), isNull);
      expect(parseHttpUrl('   '), isNull);
      expect(parseHttpUrl('https://example.com/a b'), isNull);
      expect(parseHttpUrl('not a URL'), isNull);
    });

    test('does not trim a dangerous scheme into an allowed one', () {
      expect(parseHttpUrl('javascript://example.com/alert(1)'), isNull);
      expect(parseHttpUrl('file://example.com/https://safe.example'), isNull);
    });
  });
}
