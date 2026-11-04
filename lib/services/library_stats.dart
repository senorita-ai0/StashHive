import '../models/saved_item.dart';
import 'rediscovery.dart';

/// A tag and how many saved items carry it.
class TagCount {
  const TagCount(this.tag, this.count);

  final String tag;
  final int count;
}

/// Local, read-only summary of the library shown on the Library tab.
///
/// Pure computation: no storage, network or logging, and no item content is
/// retained beyond the counts.
class LibraryStats {
  const LibraryStats({
    required this.total,
    required this.favorites,
    required this.inProgress,
    required this.toRevisit,
    required this.byKind,
    this.topTags = const <TagCount>[],
  });

  final int total;
  final int favorites;
  final int inProgress;

  /// Items old and unfinished enough to appear in the Rediscover filter.
  final int toRevisit;
  final Map<ItemKind, int> byKind;

  /// Most-used tags, most frequent first. Tags that differ only by case are
  /// counted together and shown with the casing first seen.
  final List<TagCount> topTags;

  bool get isEmpty => total == 0;

  int countFor(ItemKind kind) => byKind[kind] ?? 0;

  static LibraryStats compute(Iterable<SavedItem> items, {DateTime? now}) {
    final list = items.toList(growable: false);
    final byKind = <ItemKind, int>{for (final kind in ItemKind.values) kind: 0};
    var favorites = 0;
    var inProgress = 0;
    final tagCounts = <String, int>{};
    final tagDisplay = <String, String>{};
    for (final item in list) {
      // Count each tag once per item even if the item repeats it.
      final seenForItem = <String>{};
      for (final raw in item.tags) {
        final tag = raw.trim();
        if (tag.isEmpty) continue;
        final key = tag.toLowerCase();
        if (!seenForItem.add(key)) continue;
        tagCounts[key] = (tagCounts[key] ?? 0) + 1;
        tagDisplay.putIfAbsent(key, () => tag);
      }
      byKind[item.kind] = (byKind[item.kind] ?? 0) + 1;
      if (item.isFavorite) favorites++;
      if (item.readingStatus == ReadingStatus.inProgress) inProgress++;
    }
    return LibraryStats(
      total: list.length,
      favorites: favorites,
      inProgress: inProgress,
      toRevisit: filterRediscoverItems(list, now: now).length,
      byKind: Map<ItemKind, int>.unmodifiable(byKind),
      topTags: _rankTags(tagCounts, tagDisplay),
    );
  }

  static List<TagCount> _rankTags(
    Map<String, int> counts,
    Map<String, String> display, {
    int limit = 3,
  }) {
    final keys = counts.keys.toList()
      ..sort((a, b) {
        final byCount = counts[b]!.compareTo(counts[a]!);
        return byCount != 0 ? byCount : a.compareTo(b);
      });
    return List<TagCount>.unmodifiable([
      for (final key in keys.take(limit)) TagCount(display[key]!, counts[key]!),
    ]);
  }
}
