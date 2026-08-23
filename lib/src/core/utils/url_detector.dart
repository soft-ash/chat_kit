/// Finds http(s) URLs inside message text. Deliberately requires an
/// explicit scheme — we never try to "guess" a bare domain into a link
/// (see doc section 17, URL security: only ever resolve http/https).
final RegExp _urlPattern = RegExp(
  r'((https?:\/\/)[^\s]+)',
  caseSensitive: false,
);

/// The first URL found in [text], or `null` if none.
String? extractFirstUrl(String? text) {
  if (text == null || text.isEmpty) return null;
  return _urlPattern.firstMatch(text)?.group(0);
}

/// Every URL found in [text], in order of appearance.
List<String> extractAllUrls(String? text) {
  if (text == null || text.isEmpty) return const [];
  return _urlPattern.allMatches(text).map((m) => m.group(0)!).toList();
}
