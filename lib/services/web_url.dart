/// Parsing helpers for links that may be opened outside StashHive.
///
/// Never pass a URL from persisted or imported data directly to a platform
/// launcher. Older local records can predate current save/restore validation.
/// Parses a URL field or shared text token, permitting a bare domain by
/// assuming HTTPS but never rewriting an explicit non-web scheme.
Uri? parseUserWebUrl(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty || text.contains(RegExp(r'\s'))) return null;

  final lower = text.toLowerCase();
  if (lower.startsWith('http://') || lower.startsWith('https://')) {
    return parseHttpUrl(text);
  }

  // A colon can introduce either a bare-domain port or a URI scheme. Accept
  // only numeric host ports; otherwise do not turn "javascript:..." or
  // "http:example.com" into an HTTPS hostname by prepending a scheme.
  final bareHostPort = RegExp(
    r'^([a-zA-Z0-9.-]+):[0-9]+(?=[/?#]|$)',
  ).firstMatch(text);
  final explicitScheme =
      RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*:').hasMatch(text);
  if (explicitScheme && bareHostPort == null) return null;

  final uri = parseHttpUrl('https://$text');
  if (uri == null ||
      (uri.host.toLowerCase() != 'localhost' && !uri.host.contains('.'))) {
    return null;
  }
  return uri;
}

Uri? parseHttpUrl(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty || text.contains(RegExp(r'\s'))) return null;
  final uri = Uri.tryParse(text);
  if (uri == null || uri.host.isEmpty || uri.userInfo.isNotEmpty) {
    return null;
  }

  final scheme = uri.scheme.toLowerCase();
  if (scheme != 'http' && scheme != 'https') return null;
  return uri.replace(scheme: scheme);
}
