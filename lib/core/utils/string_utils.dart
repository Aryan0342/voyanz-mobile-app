String stripHtml(String html) =>
    html.replaceAll(RegExp(r'<[^>]*>'), '').trim();

/// Turns a backend slug (`intuitive_empath`) into a readable label
/// (`Intuitive Empath`). Values that already read as prose — anything
/// containing a space, or already capitalised — are returned untouched, so
/// French labels like `Voyance Generale` survive unchanged.
String humanizeSlug(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return value;
  final looksLikeSlug =
      !value.contains(' ') &&
      (value.contains('_') ||
          value.contains('-') ||
          value == value.toLowerCase());
  if (!looksLikeSlug) return value;
  return value
      .split(RegExp(r'[_\-\s]+'))
      .where((word) => word.isNotEmpty)
      .map((word) => word[0].toUpperCase() + word.substring(1))
      .join(' ');
}
