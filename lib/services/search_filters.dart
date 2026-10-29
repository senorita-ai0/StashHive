import '../models/saved_item.dart';

const List<String> supportedSearchKinds = <String>[
  'All',
  'Links',
  'Images',
  'Notes',
  'Files',
];

const List<String> supportedSearchSortOrders = <String>[
  'Recently saved',
  'Oldest first',
  'Title A–Z',
];

enum SavedSearchDateRange {
  anyTime,
  last7Days,
  last30Days,
  lastYear;

  String get label => switch (this) {
        SavedSearchDateRange.anyTime => 'Any time',
        SavedSearchDateRange.last7Days => 'Last 7 days',
        SavedSearchDateRange.last30Days => 'Last 30 days',
        SavedSearchDateRange.lastYear => 'Last year',
      };

  Duration? get duration => switch (this) {
        SavedSearchDateRange.anyTime => null,
        SavedSearchDateRange.last7Days => const Duration(days: 7),
        SavedSearchDateRange.last30Days => const Duration(days: 30),
        SavedSearchDateRange.lastYear => const Duration(days: 365),
      };
}

/// A serializable, local-only description of Search filters.
class SearchFilters {
  const SearchFilters({
    this.query = '',
    this.kindLabel = 'All',
    this.tag,
    this.collection,
    this.domain = '',
    this.favoritesOnly = false,
    this.dateRange = SavedSearchDateRange.anyTime,
    this.sortOrder = 'Recently saved',
  });

  final String query;
  final String kindLabel;
  final String? tag;
  final String? collection;
  final String domain;
  final bool favoritesOnly;
  final SavedSearchDateRange dateRange;
  final String sortOrder;

  bool get hasAdvancedFilters =>
      (tag?.isNotEmpty ?? false) ||
      (collection?.isNotEmpty ?? false) ||
      domain.isNotEmpty ||
      favoritesOnly ||
      dateRange != SavedSearchDateRange.anyTime;

  bool get hasAnyFilter =>
      query.trim().isNotEmpty ||
      kindLabel != 'All' ||
      hasAdvancedFilters;

  SearchFilters copyWith({
    String? query,
    String? kindLabel,
    String? tag,
    bool clearTag = false,
    String? collection,
    bool clearCollection = false,
    String? domain,
    bool? favoritesOnly,
    SavedSearchDateRange? dateRange,
    String? sortOrder,
  }) {
    return SearchFilters(
      query: query ?? this.query,
      kindLabel: kindLabel ?? this.kindLabel,
      tag: clearTag ? null : tag ?? this.tag,
      collection: clearCollection ? null : collection ?? this.collection,
      domain: domain ?? this.domain,
      favoritesOnly: favoritesOnly ?? this.favoritesOnly,
      dateRange: dateRange ?? this.dateRange,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, Object?> toMap() => <String, Object?>{
        'query': query,
        'kindLabel': kindLabel,
        'tag': tag,
        'collection': collection,
        'domain': domain,
        'favoritesOnly': favoritesOnly,
        'dateRange': dateRange.name,
        'sortOrder': sortOrder,
      };

  factory SearchFilters.fromMap(Map<dynamic, dynamic> raw) {
    final query = raw['query'] ?? '';
    final kindLabel = raw['kindLabel'] ?? 'All';
    final tag = raw['tag'];
    final collection = raw['collection'];
    final domainValue = raw['domain'] ?? '';
    final favoritesOnly = raw['favoritesOnly'] ?? false;
    final dateRangeValue = raw['dateRange'] ?? 'anyTime';
    final sortOrder = raw['sortOrder'] ?? 'Recently saved';

    if (query is! String ||
        query.length > maxSearchQueryCharacters ||
        kindLabel is! String ||
        !supportedSearchKinds.contains(kindLabel) ||
        (tag != null && (tag is! String || tag.length > 100)) ||
        (collection != null && (collection is! String || collection.length > 80)) ||
        domainValue is! String ||
        domainValue.length > 253 ||
        favoritesOnly is! bool ||
        dateRangeValue is! String ||
        sortOrder is! String ||
        !supportedSearchSortOrders.contains(sortOrder)) {
      throw const FormatException('The saved search filter is invalid.');
    }

    SavedSearchDateRange? dateRange;
    for (final value in SavedSearchDateRange.values) {
      if (value.name == dateRangeValue) {
        dateRange = value;
        break;
      }
    }
    if (dateRange == null) {
      throw const FormatException('The saved search date range is invalid.');
    }

    final normalizedDomain = normalizeDomainFilter(domainValue);
    if (normalizedDomain == null) {
      throw const FormatException('The saved search domain is invalid.');
    }

    return SearchFilters(
      query: query,
      kindLabel: kindLabel,
      tag: tag as String?,
      collection: collection as String?,
      domain: normalizedDomain,
      favoritesOnly: favoritesOnly,
      dateRange: dateRange,
      sortOrder: sortOrder,
    );
  }
}

class SavedSearchPreset {
  const SavedSearchPreset({
    required this.name,
    required this.filters,
  });

  static const int maxNameCharacters = 40;

  final String name;
  final SearchFilters filters;

  Map<String, Object?> toMap() => <String, Object?>{
        'name': name,
        'filters': filters.toMap(),
      };

  factory SavedSearchPreset.create({
    required String name,
    required SearchFilters filters,
  }) {
    final cleaned = name.trim();
    if (cleaned.isEmpty || cleaned.length > maxNameCharacters) {
      throw const FormatException(
        'Saved search names must be between 1 and 40 characters.',
      );
    }
    // Validate the nested filter through the same boundary used by storage
    // reads, so directly constructed values cannot persist invalid settings.
    final validatedFilters = SearchFilters.fromMap(filters.toMap());
    return SavedSearchPreset(name: cleaned, filters: validatedFilters);
  }

  factory SavedSearchPreset.fromMap(Map<dynamic, dynamic> raw) {
    final name = raw['name'];
    final filterValue = raw['filters'];
    if (name is! String ||
        name.trim().isEmpty ||
        name.length > maxNameCharacters ||
        filterValue is! Map) {
      throw const FormatException('The saved search preset is invalid.');
    }
    return SavedSearchPreset.create(
      name: name,
      filters: SearchFilters.fromMap(filterValue),
    );
  }
}

/// Normalizes an optional domain filter without network access.
/// Accepts a hostname or a full HTTP(S) URL and returns its hostname.
String? normalizeDomainFilter(String raw) {
  if (raw.length > 512) return null;
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '';
  final candidate = trimmed.contains('://') ? trimmed : 'https://$trimmed';
  final uri = Uri.tryParse(candidate);
  if (uri == null ||
      (uri.scheme != 'http' && uri.scheme != 'https') ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty) {
    return null;
  }
  var host = uri.host.toLowerCase();
  if (host.startsWith('www.')) host = host.substring(4);
  if (host.length > 253 ||
      host.startsWith('.') ||
      host.endsWith('.') ||
      host.contains('..') ||
      host.contains(' ')) {
    return null;
  }
  return host;
}

String? _normalizedItemHost(SavedItem item) {
  if (item.kind != ItemKind.link || item.url == null) return null;
  final uri = Uri.tryParse(item.url!);
  if (uri == null ||
      (uri.scheme.toLowerCase() != 'http' &&
          uri.scheme.toLowerCase() != 'https') ||
      uri.host.isEmpty) {
    return null;
  }
  var host = uri.host.toLowerCase();
  if (host.startsWith('www.')) host = host.substring(4);
  return host;
}

bool _domainMatches(SavedItem item, String domain) {
  if (domain.isEmpty) return true;
  final host = _normalizedItemHost(item);
  return host != null && (host == domain || host.endsWith('.$domain'));
}

/// Applies every Search filter locally and returns a deterministically sorted
/// result list. [now] can be supplied by tests; date filtering uses saved time.
List<SavedItem> filterSavedItems(
  Iterable<SavedItem> items,
  SearchFilters filters, {
  DateTime? now,
}) {
  if (filters.query.length > maxSearchQueryCharacters) {
    return const <SavedItem>[];
  }
  final query = filters.query.trim().toLowerCase();
  final normalizedTag = filters.tag?.toLowerCase();
  final normalizedCollection = filters.collection?.toLowerCase();
  final domain = normalizeDomainFilter(filters.domain);
  if (domain == null) return const <SavedItem>[];

  final cutoff = filters.dateRange.duration == null
      ? null
      : (now ?? DateTime.now()).subtract(filters.dateRange.duration!).millisecondsSinceEpoch;

  final results = items.where((item) {
    if (filters.kindLabel != 'All' &&
        item.kind.pluralLabel != filters.kindLabel) {
      return false;
    }
    if (!item.matchesNormalizedQuery(query)) return false;
    if (normalizedTag != null &&
        !item.tags.any((tag) => tag.toLowerCase() == normalizedTag)) {
      return false;
    }
    if (normalizedCollection != null &&
        item.collection?.toLowerCase() != normalizedCollection) {
      return false;
    }
    if (!_domainMatches(item, domain)) return false;
    if (filters.favoritesOnly && !item.isFavorite) return false;
    if (cutoff != null && item.createdAtMs < cutoff) return false;
    return true;
  }).toList();

  final sort = switch (filters.sortOrder) {
    'Title A–Z' => SavedItemSort.titleAZ,
    'Oldest first' => SavedItemSort.oldestFirst,
    _ => SavedItemSort.recentlySaved,
  };
  results.sort((a, b) => compareSavedItemsForSort(a, b, sort));
  return results;
}
