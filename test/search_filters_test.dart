import 'package:flutter_test/flutter_test.dart';
import 'package:stashhive/models/saved_item.dart';
import 'package:stashhive/services/search_filters.dart';

SavedItem item({
  String id = 'one',
  ItemKind kind = ItemKind.link,
  String title = 'A useful article',
  String? url = 'https://www.example.com/article',
  String content = 'Research notes',
  List<String> tags = const <String>['Reading'],
  String? collection = 'Learning',
  bool favorite = false,
  int createdAtMs = 1000,
  int updatedAtMs = 1000,
}) =>
    SavedItem(
      id: id,
      kind: kind,
      title: title,
      content: content,
      url: url,
      tags: tags,
      collection: collection,
      isFavorite: favorite,
      createdAtMs: createdAtMs,
      updatedAtMs: updatedAtMs,
    );

void main() {
  group('SearchFilters serialization', () {
    test('round trips all filter settings', () {
      const filters = SearchFilters(
        query: 'read',
        kindLabel: 'Links',
        tag: 'Reading',
        collection: 'Learning',
        domain: 'WWW.Example.com',
        favoritesOnly: true,
        dateRange: SavedSearchDateRange.last30Days,
        sortOrder: 'Title A–Z',
      );
      final restored = SearchFilters.fromMap(filters.toMap());

      expect(restored.query, filters.query);
      expect(restored.kindLabel, filters.kindLabel);
      expect(restored.tag, filters.tag);
      expect(restored.collection, filters.collection);
      expect(restored.domain, 'example.com');
      expect(restored.favoritesOnly, isTrue);
      expect(restored.dateRange, SavedSearchDateRange.last30Days);
      expect(restored.sortOrder, filters.sortOrder);
    });

    test('rejects unsupported or oversized saved filter values', () {
      expect(
        () => SearchFilters.fromMap(<String, Object?>{
          'kindLabel': 'Unknown kind',
        }),
        throwsFormatException,
      );
      expect(
        () => SearchFilters.fromMap(<String, Object?>{
          'query': List<String>.filled(maxSearchQueryCharacters + 1, 'x').join(),
        }),
        throwsFormatException,
      );
      expect(
        () => SearchFilters.fromMap(<String, Object?>{
          'domain': 'javascript:alert(1)',
        }),
        throwsFormatException,
      );
    });

    test('validates, trims and bounds saved preset names', () {
      final preset = SavedSearchPreset.create(
        name: '  Favorite reading  ',
        filters: const SearchFilters(favoritesOnly: true),
      );
      expect(preset.name, 'Favorite reading');
      expect(
        SavedSearchPreset.fromMap(preset.toMap()).filters.favoritesOnly,
        isTrue,
      );
      expect(
        () => SavedSearchPreset.create(
          name: ' ',
          filters: const SearchFilters(),
        ),
        throwsFormatException,
      );
      expect(
        () => SavedSearchPreset.create(
          name: List<String>.filled(41, 'x').join(),
          filters: const SearchFilters(),
        ),
        throwsFormatException,
      );
    });
  });

  group('normalizeDomainFilter', () {
    test('accepts hostnames and HTTP(S) URLs without paths', () {
      expect(normalizeDomainFilter(' WWW.Example.COM '), 'example.com');
      expect(
        normalizeDomainFilter('https://blog.example.com/category/reading'),
        'blog.example.com',
      );
      expect(normalizeDomainFilter(''), '');
    });

    test('rejects malformed non-web URLs and oversized input', () {
      expect(normalizeDomainFilter('javascript:alert(1)'), isNull);
      expect(normalizeDomainFilter('https://'), isNull);
      expect(normalizeDomainFilter(List<String>.filled(513, 'x').join()), isNull);
    });
  });

  group('filterSavedItems', () {
    final saved = <SavedItem>[
      item(
        id: 'favorite-example',
        title: 'Favorite research',
        url: 'https://www.example.com/article',
        tags: const <String>['Reading', 'Work'],
        collection: 'Learning',
        favorite: true,
        createdAtMs: 950000000000,
        updatedAtMs: 950000000000,
      ),
      item(
        id: 'ordinary-example',
        title: 'Other example page',
        url: 'https://blog.example.com/notes',
        tags: const <String>['Reading'],
        collection: 'Work',
        favorite: false,
        createdAtMs: 950000000000,
        updatedAtMs: 950000000000,
      ),
      item(
        id: 'other-domain',
        title: 'Other domain',
        url: 'https://unrelated.test/page',
        tags: const <String>['Work'],
        collection: 'Learning',
        favorite: true,
        createdAtMs: 950000000000,
        updatedAtMs: 950000000000,
      ),
      item(
        id: 'old-link',
        title: 'Old article',
        url: 'https://example.com/old',
        tags: const <String>['Reading'],
        collection: 'Learning',
        favorite: true,
        createdAtMs: 900000000000,
        updatedAtMs: 900000000000,
      ),
      item(
        id: 'note',
        kind: ItemKind.note,
        title: 'Local note',
        url: null,
        tags: const <String>['Reading'],
        collection: 'Learning',
        favorite: true,
        createdAtMs: 950000000000,
        updatedAtMs: 950000000000,
      ),
    ];

    test('combines type, query, tag, collection, domain and favorite filters', () {
      final results = filterSavedItems(
        saved,
        const SearchFilters(
          query: 'FAVORITE',
          kindLabel: 'Links',
          tag: 'reading',
          collection: 'learning',
          domain: 'example.com',
          favoritesOnly: true,
        ),
        now: DateTime.fromMillisecondsSinceEpoch(950000000000),
      );
      expect(results.map((savedItem) => savedItem.id), <String>[
        'favorite-example',
      ]);
    });

    test('domain filter includes subdomains but not unrelated hosts', () {
      final results = filterSavedItems(
        saved,
        const SearchFilters(domain: 'example.com'),
        now: DateTime.fromMillisecondsSinceEpoch(950000000000),
      );
      expect(
        results.map((savedItem) => savedItem.id).toSet(),
        <String>{'favorite-example', 'ordinary-example', 'old-link'},
      );
    });

    test('date range filters by saved time', () {
      final results = filterSavedItems(
        saved,
        const SearchFilters(dateRange: SavedSearchDateRange.last30Days),
        now: DateTime.fromMillisecondsSinceEpoch(950000000000 + 10 * 86400000),
      );
      expect(results.map((savedItem) => savedItem.id).toSet(), <String>{
        'favorite-example',
        'ordinary-example',
        'other-domain',
        'note',
      });
    });

    test('collection/tag/favorite filters can each be cleared', () {
      const original = SearchFilters(
        tag: 'Reading',
        collection: 'Learning',
        domain: 'example.com',
        favoritesOnly: true,
      );
      final cleared = original.copyWith(
        clearTag: true,
        clearCollection: true,
        domain: '',
        favoritesOnly: false,
      );
      expect(cleared.tag, isNull);
      expect(cleared.collection, isNull);
      expect(cleared.domain, isEmpty);
      expect(cleared.favoritesOnly, isFalse);
      expect(cleared.hasAdvancedFilters, isFalse);
    });

    test('keeps deterministic title sorting when filters match all items', () {
      final results = filterSavedItems(
        saved,
        const SearchFilters(sortOrder: 'Title A–Z'),
        now: DateTime.fromMillisecondsSinceEpoch(950000000000),
      );
      expect(results.first.title, 'Favorite research');
      expect(results.last.title, 'Other example page');
    });
  });
}
