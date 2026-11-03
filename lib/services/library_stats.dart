import '../models/saved_item.dart';
import 'rediscovery.dart';

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
  });

  final int total;
  final int favorites;
  final int inProgress;

  /// Items old and unfinished enough to appear in the Rediscover filter.
  final int toRevisit;
  final Map<ItemKind, int> byKind;

  bool get isEmpty => total == 0;

  int countFor(ItemKind kind) => byKind[kind] ?? 0;

  static LibraryStats compute(Iterable<SavedItem> items, {DateTime? now}) {
    final list = items.toList(growable: false);
    final byKind = <ItemKind, int>{for (final kind in ItemKind.values) kind: 0};
    var favorites = 0;
    var inProgress = 0;
    for (final item in list) {
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
    );
  }
}
