import 'package:flutter_test/flutter_test.dart';
import 'package:stashhive/models/link_health_record.dart';
import 'package:stashhive/services/link_health_checker.dart';

void main() {
  group('linkHealthStateForStatusCode', () {
    test('classifies common response codes without calling them all healthy', () {
      expect(linkHealthStateForStatusCode(200), LinkHealthState.healthy);
      expect(linkHealthStateForStatusCode(299), LinkHealthState.healthy);
      expect(linkHealthStateForStatusCode(301), LinkHealthState.redirect);
      expect(linkHealthStateForStatusCode(405), LinkHealthState.methodUnsupported);
      expect(linkHealthStateForStatusCode(501), LinkHealthState.methodUnsupported);
      expect(linkHealthStateForStatusCode(404), LinkHealthState.notFound);
      expect(linkHealthStateForStatusCode(410), LinkHealthState.gone);
      expect(linkHealthStateForStatusCode(401), LinkHealthState.restricted);
      expect(linkHealthStateForStatusCode(403), LinkHealthState.restricted);
      expect(linkHealthStateForStatusCode(429), LinkHealthState.httpError);
      expect(linkHealthStateForStatusCode(503), LinkHealthState.serverError);
    });

    test('rejects status codes outside the HTTP range', () {
      expect(() => linkHealthStateForStatusCode(99), throwsA(isA<FormatException>()));
      expect(() => linkHealthStateForStatusCode(600), throwsFormatException);
    });
  });

  group('LinkHealthRecord', () {
    test('round-trips only bounded local result metadata', () {
      final original = LinkHealthRecord(
        itemId: 'saved-link',
        checkedUrl: 'https://example.com/article',
        state: LinkHealthState.notFound,
        checkedAtMs: DateTime.now().millisecondsSinceEpoch,
        httpStatusCode: 404,
      );

      final restored = LinkHealthRecord.fromMap(original.toMap());

      expect(restored.itemId, original.itemId);
      expect(restored.checkedUrl, original.checkedUrl);
      expect(restored.state, LinkHealthState.notFound);
      expect(restored.httpStatusCode, 404);
      expect(restored.checkedAtMs, original.checkedAtMs);
    });

    test('rejects invalid stored status and status code', () {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      expect(
        () => LinkHealthRecord.fromMap(<String, Object?>{
          'itemId': 'item',
          'checkedUrl': 'https://example.com',
          'state': 'made-up',
          'checkedAtMs': timestamp,
          'httpStatusCode': 200,
        }),
        throwsFormatException,
      );
      expect(
        () => LinkHealthRecord(
          itemId: 'item',
          checkedUrl: 'https://example.com',
          state: LinkHealthState.healthy,
          checkedAtMs: timestamp,
          httpStatusCode: 700,
        ).toMap(),
        throwsFormatException,
      );
    });
  });

  group('checkLinkHealth', () {
    test('rejects invalid web addresses without making a request', () async {
      final result = await checkLinkHealth(
        itemId: 'legacy-link',
        url: 'javascript:alert(1)',
      );

      expect(result.state, LinkHealthState.invalidUrl);
      expect(result.httpStatusCode, isNull);
    });

    test('does not send requests to loopback or local hostnames', () async {
      for (final url in <String>[
        'http://127.0.0.1:8080/admin',
        'http://localhost/',
        'http://printer/',
      ]) {
        final result = await checkLinkHealth(itemId: 'saved-link', url: url);
        expect(
          result.state,
          LinkHealthState.blockedAddress,
          reason: 'Unsafe local destination should be blocked: $url',
        );
      }
    });
  });
}
