import 'package:flutter_test/flutter_test.dart';
import 'package:stashhive/services/web_url.dart';

void main() {
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
