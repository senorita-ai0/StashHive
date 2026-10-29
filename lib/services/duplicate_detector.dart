import '../models/saved_item.dart';

const Set<String> _trackingQueryParameters = <String>{
  'fbclid',
  'gclid',
  'dclid',
  'msclkid',
  'mc_cid',
  'mc_eid',
  'igshid',
  'vero_conv',
  'vero_id',
};

/// Returns a stable URL key for duplicate checks without changing the URL
/// stored or displayed to the user.
///
/// This intentionally performs conservative URL cleanup only: it ignores the
/// fragment, removes common analytics parameters, normalizes the scheme/host,
/// removes default HTTP(S) ports, normalizes dot segments, and trims trailing
/// path slashes. It does not fetch a page or assume that different paths are
/// equivalent. The key is local-only and is never sent to a service.
String? normalizeUrlForDuplicateCheck(String? rawUrl) {
  if (rawUrl == null || rawUrl.isEmpty || rawUrl.length > maxSavedItemUrlCharacters) {
    return null;
  }

  final parsed = Uri.tryParse(rawUrl.trim());
  if (parsed == null ||
      (parsed.scheme.toLowerCase() != 'http' &&
          parsed.scheme.toLowerCase() != 'https') ||
      parsed.host.isEmpty) {
    return null;
  }

  final scheme = parsed.scheme.toLowerCase();
  final port = parsed.hasPort ? parsed.port : null;
  final normalizedPort = port == 80 && scheme == 'http' ||
          port == 443 && scheme == 'https'
      ? null
      : port;

  var path = parsed.normalizePath().path;
  if (path.length > 1 && path.endsWith('/')) {
    path = path.replaceFirst(RegExp(r'/+$'), '');
    if (path.isEmpty) path = '/';
  }

  final queryParameters = <String, dynamic>{};
  for (final entry in parsed.queryParametersAll.entries) {
    final normalizedName = entry.key.toLowerCase();
    if (_trackingQueryParameters.contains(normalizedName) ||
        normalizedName.startsWith('utm_')) {
      continue;
    }
    queryParameters[entry.key] = entry.value;
  }

  final normalized = Uri(
    scheme: scheme,
    userInfo: parsed.userInfo,
    host: parsed.host.toLowerCase(),
    port: normalizedPort,
    path: path,
    queryParameters: queryParameters.isEmpty ? null : queryParameters,
  );
  return normalized.toString();
}

/// Returns existing links with the same conservative duplicate key.
///
/// Results preserve the library's current ordering. The candidate itself is
/// excluded by ID so editing a saved link never reports that item as its own
/// duplicate. Non-link items and invalid URLs are ignored.
List<SavedItem> findDuplicateLinks(
  SavedItem candidate,
  Iterable<SavedItem> library,
) {
  if (candidate.kind != ItemKind.link) return const <SavedItem>[];

  final candidateKey = normalizeUrlForDuplicateCheck(candidate.url);
  if (candidateKey == null) return const <SavedItem>[];

  final matches = <SavedItem>[];
  final seenIds = <String>{};
  for (final item in library) {
    if (item.id == candidate.id ||
        item.kind != ItemKind.link ||
        !seenIds.add(item.id)) {
      continue;
    }
    if (normalizeUrlForDuplicateCheck(item.url) == candidateKey) {
      matches.add(item);
    }
  }

  return List<SavedItem>.unmodifiable(matches);
}
