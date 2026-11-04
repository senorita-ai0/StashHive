/// Local reading-time estimate for saved text.
///
/// Pure computation over text already stored in the library; it performs no
/// network access and keeps nothing.

/// Average silent reading speed used for the estimate.
const int readingWordsPerMinute = 200;

/// Texts shorter than this are quick reads and show no estimate.
const int readingTimeMinimumWords = 400;

/// Upper bound so an unusually large note cannot show an absurd figure.
const int readingTimeMaximumMinutes = 999;

final RegExp _wordPattern = RegExp(r'\S+');

/// Estimated minutes to read [text], or `null` for short or empty text.
///
/// Words are whitespace-separated runs, which fits Latin scripts and Urdu.
/// Languages written without spaces (for example Chinese) are undercounted,
/// so the estimate is a hint, not a promise.
int? estimatedReadingMinutes(String text) {
  // Fewer characters than this cannot hold the minimum number of words
  // (each word needs a character plus a separator), so skip the scan.
  if (text.length < readingTimeMinimumWords * 2 - 1) return null;
  final words = _wordPattern.allMatches(text).length;
  if (words < readingTimeMinimumWords) return null;
  final minutes = (words + readingWordsPerMinute - 1) ~/ readingWordsPerMinute;
  return minutes > readingTimeMaximumMinutes
      ? readingTimeMaximumMinutes
      : minutes;
}

/// Short label such as `3 min read`, or `null` when there is no estimate.
String? readingTimeLabel(String text) {
  final minutes = estimatedReadingMinutes(text);
  return minutes == null ? null : '$minutes min read';
}
