import 'package:flutter_test/flutter_test.dart';
import 'package:stashhive/models/saved_item.dart';

SavedItem makeItem({
  ItemKind kind = ItemKind.link,
  String title = 'Flutter docs',
  String? url = 'https://flutter.dev',
  String content = 'A useful page',
  List<String> tags = const ['Flutter', 'Reading'],
  String? collection = 'Learning',
  String? attachmentKey,
}) {
  return SavedItem(
    id: 'item-1',
    kind: kind,
    title: title,
    content: content,
    url: url,
    tags: tags,
    collection: collection,
    isFavorite: false,
    createdAtMs: 1000,
    updatedAtMs: 2000,
    attachmentKey: attachmentKey,
    attachmentName: attachmentKey == null ? null : 'sample.png',
    attachmentMimeType: attachmentKey == null ? null : 'image/png',
  );
}

void main() {
  group('SavedItem', () {
    test('serializes and deserializes without losing saved metadata', () {
      final original = makeItem();
      final restored = SavedItem.fromMap(original.toMap());

      expect(restored.id, original.id);
      expect(restored.kind, ItemKind.link);
      expect(restored.title, original.title);
      expect(restored.url, original.url);
      expect(restored.tags, original.tags);
      expect(restored.collection, original.collection);
      expect(restored.createdAtMs, original.createdAtMs);
    });

    test('does not echo oversized or unknown item kinds in errors', () {
      final oversizedKind = List<String>.filled(100000, 'x').join();

      for (final value in <Object?>[
        oversizedKind,
        'unknown-kind',
        <String>['not', 'a', 'kind'],
      ]) {
        expect(
          () => ItemKind.fromWire(value),
          throwsA(
            isA<FormatException>().having(
              (error) => error.message,
              'message',
              'Unknown saved-item type.',
            ),
          ),
        );
      }
    });

    test('preflights oversized raw fields before trimming or copying them', () {
      final oversizedWhitespace = List<String>.filled(100000, ' ').join();
      final oversizedTitle = <String, Object?>{
        ...makeItem().toMap(),
        'title': oversizedWhitespace,
      };
      expect(
        () => SavedItem.fromMap(oversizedTitle),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'A saved item contains fields beyond supported storage limits.',
          ),
        ),
      );

      final oversizedTag = <String, Object?>{
        ...makeItem().toMap(),
        'tags': <String>[oversizedWhitespace],
      };
      expect(
        () => SavedItem.fromMap(oversizedTag),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'A saved item contains an invalid or oversized tag list.',
          ),
        ),
      );
    });

    test('preflights direct model serialization before copying fields and tags', () {
      final oversizedWhitespace = List<String>.filled(100000, ' ').join();
      final oversizedTitle = makeItem(title: oversizedWhitespace);
      expect(
        () => oversizedTitle.toMap(),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'A saved item contains fields beyond supported storage limits.',
          ),
        ),
      );

      final oversizedTag = makeItem(tags: [oversizedWhitespace]);
      expect(
        () => oversizedTag.toMap(),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'A saved item contains an invalid or oversized tag list.',
          ),
        ),
      );

      final excessiveTags = makeItem(
        tags: List<String>.generate(101, (index) => 'tag$index'),
      );
      expect(
        () => excessiveTags.toMap(),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'A saved item contains an invalid or oversized tag list.',
          ),
        ),
      );

      expect(makeItem().toMap()['title'], 'Flutter docs');
    });

    test('searches titles, URLs, notes, tags and collections case-insensitively', () {
      final item = makeItem(content: 'Research local storage');
      expect(item.matchesQuery('FLUTTER'), isTrue);
      expect(item.matchesQuery('flutter.dev'), isTrue);
      expect(item.matchesQuery('LOCAL STORAGE'), isTrue);
      expect(item.matchesQuery('reading'), isTrue);
      expect(item.matchesQuery('learning'), isTrue);
      expect(item.matchesQuery('not present'), isFalse);
      expect(item.matchesQuery('  '), isTrue);
    });

    test('matches pre-normalized queries for reuse across items', () {
      final item = makeItem(content: 'Research local storage');

      expect(item.matchesNormalizedQuery('local storage'), isTrue);
      expect(item.matchesNormalizedQuery('reading'), isTrue);
      expect(item.matchesNormalizedQuery('missing'), isFalse);
      expect(item.matchesNormalizedQuery(''), isTrue);
    });

    test('rejects oversized search queries before normalization', () {
      final item = makeItem();
      final oversizedQuery =
          List<String>.filled(maxSearchQueryCharacters + 1, ' ').join();

      expect(item.matchesQuery(oversizedQuery), isFalse);
      expect(item.matchesNormalizedQuery(oversizedQuery), isFalse);
      expect(item.matchesQuery('flutter'), isTrue);
    });

    test('trims padded legacy metadata without changing note content', () {
      final raw = makeItem(attachmentKey: 'sample-key').toMap();
      raw['title'] = '  A saved title  ';
      raw['url'] = '  https://example.com/guide  ';
      raw['attachmentName'] = '  sample.png  ';
      raw['attachmentMimeType'] = ' IMAGE/PNG ';

      final restored = SavedItem.fromMap(raw);

      expect(restored.title, 'A saved title');
      expect(restored.url, 'https://example.com/guide');
      expect(restored.attachmentName, 'sample.png');
      expect(restored.attachmentMimeType, 'image/png');
    });

    test('normalizes duplicate tags without regard to case', () {
      final legacy = makeItem(tags: const [
        'Reading',
        'reading',
        'Work',
        'Reading ',
        '',
      ]);
      final restored = SavedItem.fromMap(legacy.toMap());

      expect(restored.tags, ['Reading', 'Work']);
    });

    test('trims legacy collection names and treats whitespace-only as unassigned', () {
      final padded = SavedItem.fromMap(
        makeItem(collection: '  Research  ').toMap(),
      );
      final blank = SavedItem.fromMap(
        makeItem(collection: '   ').toMap(),
      );

      expect(padded.collection, 'Research');
      expect(blank.collection, isNull);
    });

    test('sort comparators use deterministic tie-breakers', () {
      SavedItem sortable({
        required String id,
        required String title,
        required int createdAtMs,
        required int updatedAtMs,
      }) =>
          SavedItem(
            id: id,
            kind: ItemKind.link,
            title: title,
            content: '',
            url: 'https://example.com/$id',
            tags: const [],
            collection: null,
            isFavorite: false,
            createdAtMs: createdAtMs,
            updatedAtMs: updatedAtMs,
          );

      final idZ = sortable(
        id: 'item-z',
        title: 'Twin',
        createdAtMs: 10,
        updatedAtMs: 100,
      );
      final idA = sortable(
        id: 'item-a',
        title: 'Twin',
        createdAtMs: 10,
        updatedAtMs: 100,
      );
      final newerCreated = sortable(
        id: 'item-newer-created',
        title: 'Zulu',
        createdAtMs: 20,
        updatedAtMs: 100,
      );
      final olderUpdated = sortable(
        id: 'item-older-updated',
        title: 'Alpha',
        createdAtMs: 1,
        updatedAtMs: 50,
      );

      final recentlySaved = [idZ, idA, olderUpdated, newerCreated]
        ..sort((a, b) => compareSavedItemsForSort(
              a,
              b,
              SavedItemSort.recentlySaved,
            ));
      expect(
        recentlySaved.map((item) => item.id),
        ['item-newer-created', 'item-a', 'item-z', 'item-older-updated'],
      );

      final oldestFirst = [newerCreated, idZ, olderUpdated, idA]
        ..sort((a, b) => compareSavedItemsForSort(
              a,
              b,
              SavedItemSort.oldestFirst,
            ));
      expect(
        oldestFirst.map((item) => item.id),
        ['item-older-updated', 'item-a', 'item-z', 'item-newer-created'],
      );

      final titleAZ = [idZ, newerCreated, idA, olderUpdated]
        ..sort((a, b) => compareSavedItemsForSort(
              a,
              b,
              SavedItemSort.titleAZ,
            ));
      expect(
        titleAZ.map((item) => item.id),
        ['item-older-updated', 'item-a', 'item-z', 'item-newer-created'],
      );
    });

    test('preserves Unicode text in note content and search', () {
      final item = makeItem(
        kind: ItemKind.note,
        title: 'Urdu note',
        url: null,
        content: 'قابلِ تلاش متن — Roman Urdu: mera khayal',
        tags: const ['اردو', 'Roman Urdu'],
        collection: null,
      );
      final restored = SavedItem.fromMap(item.toMap());

      expect(restored.content, contains('قابلِ تلاش متن'));
      expect(restored.matchesQuery('roman urdu'), isTrue);
      expect(restored.matchesQuery('اردو'), isTrue);
    });


    test('searches emoji, accented text, and punctuation without corruption', () {
      final item = makeItem(
        kind: ItemKind.note,
        title: 'Café plans: déjà-vu #42 🚀',
        url: null,
        content: 'Résumé notes; keep [draft] (v2). Launch 🚀!',
        tags: const ['release#42', '🚀Launch'],
        collection: 'Équipe',
      );

      expect(item.matchesQuery('CAFÉ'), isTrue);
      expect(item.matchesQuery('DÉJÀ-VU'), isTrue);
      expect(item.matchesQuery('résumé'), isTrue);
      expect(item.matchesQuery('🚀'), isTrue);
      expect(item.matchesQuery('#42'), isTrue);
      expect(item.matchesQuery('[draft]'), isTrue);
      expect(item.matchesQuery('équipe'), isTrue);

      // Search is substring-based: punctuation that is actually present is
      // searchable, while a different string is not silently rewritten.
      expect(item.matchesQuery('release#42'), isTrue);
      expect(item.matchesQuery('release 42'), isFalse);
    });

    test('clears optional references explicitly through copyWith', () {
      final updated = makeItem(attachmentKey: 'local-file').copyWith(
        clearCollection: true,
        clearUrl: true,
        clearAttachment: true,
      );

      expect(updated.collection, isNull);
      expect(updated.url, isNull);
      expect(updated.attachmentKey, isNull);
      expect(updated.attachmentName, isNull);
    });
  });
}
