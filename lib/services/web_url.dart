/// Parsing helpers for links that may be opened outside StashHive.
///
/// Never pass a URL from persisted or imported data directly to a platform
/// launcher. Older local records can predate current save/restore validation.
Uri? parseHttpUrl(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty || text.contains(RegExp(r'\s'))) return null;
  final uri = Uri.tryParse(text);
  if (uri == null || uri.host.isEmpty) return null;

  final scheme = uri.scheme.toLowerCase();
  if (scheme != 'http' && scheme != 'https') return null;
  return uri.replace(scheme: scheme);
}
