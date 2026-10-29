import 'package:flutter_test/flutter_test.dart';
import 'package:stashhive/models/saved_item.dart';
import 'package:stashhive/services/duplicate_detector.dart';

SavedItem makeItem({
  String id = 'item-1',
  ItemKind kind = ItemKind.link,
  String? url = 'https://flutter.dev',
  String title = 'Flutter documentation',
}) {
  return SavedItem(
    id: id,
    kind: kind,
    title: title,
    content: '',
    url: url,
    tags: const <String>[],
    collection: null,
    isFavorite: false,
    createdAtMs: 1000,
    updatedAtMs: 1000,
  );
}

void main() {
  group('normalizeUrlForDuplicateCheck', () {
    test('normalizes scheme/host, default port, fragment and trailing slash', () {
      expect(
        normalizeUrlForDuplicateCheck(
          'HTTPS://Flutter.Dev:443/docs/?utm_source=newsletter#install',
        ),
        'https://flutter.dev/docs',
      );
    });

    test('ignores common tracking parameters but preserves useful query values', () {
      expect(
        normalizeUrlForDuplicateCheck(
          'https://example.com/article?utm_medium=email&id=42&fbclid=click',
        ),
        'https://example.com/article?id=42',
      );
    });

    test('treats an empty root path and a single slash as the same URL', () {
      expect(
        normalizeUrlForDuplicateCheck('https://example.com'),
        normalizeUrlForDuplicateCheck('https://example.com/'),
      );
    });

    test('preserves meaningful query parameters and path case', () {
      expect(
        normalizeUrlForDuplicateCheck('https://example.com/Article?id=42'),
        'https://example.com/Article?id=42',
      );
      expect(
        normalizeUrlForDuplicateCheck('https://example.com/article?id=43'),
        isNot(normalizeUrlForDuplicateCheck(
          'https://example.com/article?id=42',
        )),
      );
    });

    test('rejects missing, oversized and non-web URLs', () {
      expect(normalizeUrlForDuplicateCheck(null), isNull);
      expect(normalizeUrlForDuplicateCheck(''), isNull);
      expect(normalizeUrlForDuplicateCheck('file:///tmp/notes.txt'), isNull);
      expect(
        normalizeUrlForDuplicateCheck(
          'https://example.com/${List<String>.filled(maxSavedItemUrlCharacters + 1, 'x').join()}',
        ),
        isNull,
      );
    });
  });

  group('findDuplicateLinks', () {
    test('returns normalized URL matches and excludes self and non-links', () {
      final candidate = makeItem(
        id: 'new',
        url: 'https://flutter.dev/docs#install',
      );
      final exactDuplicate = makeItem(
        id: 'saved',
        url: 'https://FLUTTER.dev:443/docs/?utm_source=home',
        title: 'Existing Flutter docs',
      );
      final noteWithSameUrl = makeItem(
        id: 'note',
        kind: ItemKind.note,
        url: 'https://flutter.dev/docs',
      );
      final differentQuery = makeItem(
        id: 'different',
        url: 'https://flutter.dev/docs?version=2',
      );
      final sameCandidateId = makeItem(
        id: 'new',
        url: 'https://flutter.dev/docs',
      );

      expect(
        findDuplicateLinks(
          candidate,
          <SavedItem>[
            exactDuplicate,
            noteWithSameUrl,
            differentQuery,
            sameCandidateId,
          ],
        ),
        <SavedItem>[exactDuplicate],
      );
    });

    test('does not compare notes or invalid candidate URLs', () {
      expect(
        findDuplicateLinks(
          makeItem(kind: ItemKind.note, url: null),
          <SavedItem>[makeItem()],
        ),
        isEmpty,
      );
      expect(
        findDuplicateLinks(
          makeItem(url: 'not a URL'),
          <SavedItem>[makeItem(url: 'not a URL', id: 'saved')],
        ),
        isEmpty,
      );
    });

    test('deduplicates repeated library references by item ID', () {
      final saved = makeItem(id: 'saved');
      expect(
        findDuplicateLinks(makeItem(id: 'new'), <SavedItem>[saved, saved]),
        <SavedItem>[saved],
      );
    });
  });
}
