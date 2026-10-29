import '../models/saved_item.dart';

/// Minimum age before an unfinished saved item is offered for rediscovery.
/// Use the item's creation time, not its edit time, so adding a note or changing
/// reading progress does not make an old item appear newly saved.
const Duration rediscoveryMinimumAge = Duration(days: 14);

/// Selects older, unfinished items for a local rediscovery queue.
///
/// The queue includes every saved-item type, excludes items marked Completed,
/// and sorts oldest first with deterministic tie-breaking through the existing
/// [compareSavedItemsForSort] helper. It performs no network or storage access.
List<SavedItem> filterRediscoverItems(
  Iterable<SavedItem> items, {
  DateTime? now,
}) {
  final cutoffMs = (now ?? DateTime.now())
      .subtract(rediscoveryMinimumAge)
      .millisecondsSinceEpoch;
  final results = items
      .where(
        (item) =>
            item.readingStatus != ReadingStatus.completed &&
            item.createdAtMs <= cutoffMs,
      )
      .toList();

  results.sort(
    (a, b) => compareSavedItemsForSort(
      a,
      b,
      SavedItemSort.oldestFirst,
    ),
  );
  return List<SavedItem>.unmodifiable(results);
}
