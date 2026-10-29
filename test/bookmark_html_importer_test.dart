import 'package:flutter_test/flutter_test.dart';
import 'package:stashhive/services/bookmark_html_importer.dart';

void main() {
  group('parseBookmarkHtml', () {
    test('parses links, decodes entities and maps nested folders to collections', () {
      const html = '''
<!DOCTYPE NETSCAPE-Bookmark-file-1>
<DL><p>
  <DT><H3>Reading &amp; Research</H3>
  <DL><p>
    <DT><A HREF="https://example.com/a?x=1&amp;y=2" ADD_DATE="1">A &amp; B</A>
    <DT><H3>Nested</H3>
    <DL><p>
      <DT><A HREF='https://example.org/'>Nested page</A>
    </DL><p>
  </DL><p>
  <DT><A HREF="https://example.net/">Unfiled</A>
</DL><p>
''';
      final result = parseBookmarkHtml(html);

      expect(result.entries, hasLength(3));
      expect(result.entries[0].title, 'A & B');
      expect(result.entries[0].url, 'https://example.com/a?x=1&y=2');
      expect(result.entries[0].collection, 'Reading & Research');
      expect(result.entries[1].collection, 'Nested');
      expect(result.entries[2].collection, isNull);
      expect(result.collections.toSet(), <String>{'Reading & Research', 'Nested'});
      expect(result.invalidCount, 0);
      expect(result.duplicateCount, 0);
    });

    test('ignores non-web links and de-duplicates tracking variants', () {
      const html = '''
<DL>
<A HREF="mailto:hello@example.com">Email</A>
<A HREF="https://example.com/page?utm_source=one#top">First</A>
<A HREF="https://EXAMPLE.com/page/?utm_source=two">Duplicate</A>
</DL>
''';
      final result = parseBookmarkHtml(html);
      expect(result.entries, hasLength(1));
      expect(result.entries.single.title, 'First');
      expect(result.invalidCount, 1);
      expect(result.duplicateCount, 1);
    });

    test('rejects empty, oversized and non-bookmark content', () {
      expect(() => parseBookmarkHtml(''), throwsFormatException);
      expect(
        () => parseBookmarkHtml(List<String>.filled(maxBookmarkHtmlBytes + 1, 'x').join()),
        throwsFormatException,
      );
      expect(() => parseBookmarkHtml('<html><body>No links</body></html>'), throwsFormatException);
    });

    test('rejects unsupported schemes and falls back to host for blank titles', () {
      final result = parseBookmarkHtml(
        '<DL><A HREF="javascript:alert(1)">Bad</A>'
        '<A HREF="https://example.com/"><b></b></A></DL>',
      );
      expect(result.entries, hasLength(1));
      expect(result.entries.single.title, 'example.com');
      expect(result.invalidCount, 1);
    });
  });
}
