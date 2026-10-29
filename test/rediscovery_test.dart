import 'package:flutter_test/flutter_test.dart';
import 'package:stashhive/models/saved_item.dart';
import 'package:stashhive/services/rediscovery.dart';

SavedItem makeRediscoveryItem({
  required String id,
  required int createdAtMs,
  int? updatedAtMs,
  ItemKind kind = ItemKind.link,
  ReadingStatus readingStatus = ReadingStatus.unread,
}) =>
    SavedItem(
      id: id,
      kind: kind,
      title: id,
      content: '',
      url: kind == ItemKind.link ? 'https://example.com/$id' : null,
      tags: const <String>[],
      collection: null,
      isFavorite: false,
      readingStatus: readingStatus,
      createdAtMs: createdAtMs,
      updatedAtMs: updatedAtMs ?? createdAtMs,
    );

void main() {
  group('filterRediscoverItems', () {
    final now = DateTime.utc(2026, 10, 29);
    final cutoff = now.subtract(rediscoveryMinimumAge).millisecondsSinceEpoch;

    test('selects unfinished items at least 14 days old and orders oldest first', () {
      final olderLink = makeRediscoveryItem(
        id: 'older-link',
        createdAtMs: DateTime.utc(2026, 9, 1).millisecondsSinceEpoch,
      );
      final oldNote = makeRediscoveryItem(
        id: 'old-note',
        kind: ItemKind.note,
        readingStatus: ReadingStatus.inProgress,
        createdAtMs: DateTime.utc(2026, 10, 1).millisecondsSinceEpoch,
      );
      final atCutoff = makeRediscoveryItem(
        id: 'at-cutoff',
        createdAtMs: cutoff,
      );
      final recentItem = makeRediscoveryItem(
        id: 'recent-item',
        createdAtMs: DateTime.utc(2026, 10, 20).millisecondsSinceEpoch,
      );
      final completedItem = makeRediscoveryItem(
        id: 'completed-item',
        readingStatus: ReadingStatus.completed,
        createdAtMs: DateTime.utc(2026, 8, 1).millisecondsSinceEpoch,
      );
      final futureItem = makeRediscoveryItem(
        id: 'future-item',
        createdAtMs: DateTime.utc(2026, 11, 2).millisecondsSinceEpoch,
      );

      final results = filterRediscoverItems(
        <SavedItem>[
          futureItem,
          atCutoff,
          completedItem,
          recentItem,
          oldNote,
          olderLink,
        ],
        now: now,
      );

      expect(
        results.map((item) => item.id).toList(),
        <String>['older-link', 'old-note', 'at-cutoff'],
      );
      expect(
        () => results.clear(),
        throwsUnsupportedError,
      );
    });

    test('uses creation time rather than a recent edit time', () {
      final oldButRecentlyEdited = makeRediscoveryItem(
        id: 'old-recently-edited',
        createdAtMs: DateTime.utc(2026, 9, 1).millisecondsSinceEpoch,
        updatedAtMs: now.millisecondsSinceEpoch,
      );

      expect(
        filterRediscoverItems(
          <SavedItem>[oldButRecentlyEdited],
          now: now,
        ).map((item) => item.id),
        <String>['old-recently-edited'],
      );
    });

    test('returns an empty result for only recent or completed items', () {
      expect(
        filterRediscoverItems(
          <SavedItem>[
            makeRediscoveryItem(
              id: 'recent',
              createdAtMs: DateTime.utc(2026, 10, 25).millisecondsSinceEpoch,
            ),
            makeRediscoveryItem(
              id: 'done',
              readingStatus: ReadingStatus.completed,
              createdAtMs: DateTime.utc(2026, 8, 1).millisecondsSinceEpoch,
            ),
          ],
          now: now,
        ),
        isEmpty,
      );
    });
  });
}
