import '../models/saved_item.dart';
import 'article_reader.dart';

const int maxAnnotationAnchorCandidates = 8;
const int minAnnotationContextMatchCharacters = 12;

enum AnnotationAnchorStatus {
  invalidInput,
  notFound,
  uniqueQuote,
  contextualMatch,
  ambiguous,
}

class AnnotationAnchorCandidate {
  const AnnotationAnchorCandidate({
    required this.startOffset,
    required this.endOffset,
    required this.matchedBeforeCharacters,
    required this.matchedAfterCharacters,
  });

  final int startOffset;
  final int endOffset;
  final int matchedBeforeCharacters;
  final int matchedAfterCharacters;

  int get contextMatchScore =>
      matchedBeforeCharacters + matchedAfterCharacters;
}

class AnnotationAnchorResult {
  const AnnotationAnchorResult({
    required this.status,
    required this.totalMatches,
    required this.candidates,
    this.recommended,
  });

  final AnnotationAnchorStatus status;
  final int totalMatches;
  final List<AnnotationAnchorCandidate> candidates;

  /// Present only when the quote is unique or context identifies one
  /// unambiguous candidate with enough exact surrounding evidence.
  final AnnotationAnchorCandidate? recommended;

  bool get hasSafeSuggestion => recommended != null;
}

/// Finds occurrences of a saved quote in a newly fetched, temporary article.
///
/// Stored source offsets are deliberately ignored: after a page changes they
/// describe the old extraction, not necessarily the current one. Exact quote
/// occurrences are ranked using the contiguous suffix/prefix overlap with the
/// saved surrounding context. The result is a suggestion only; callers must
/// ask the user before persisting a new position.
AnnotationAnchorResult findSavedAnnotationAnchor({
  required String articleText,
  required SavedAnnotation annotation,
}) {
  final quote = annotation.quote;
  if (quote.trim().isEmpty ||
      quote.length > maxSavedAnnotationQuoteCharacters ||
      articleText.length > maxArticleTextCharacters ||
      quote.length > articleText.length) {
    return const AnnotationAnchorResult(
      status: AnnotationAnchorStatus.invalidInput,
      totalMatches: 0,
      candidates: <AnnotationAnchorCandidate>[],
    );
  }

  final candidates = <AnnotationAnchorCandidate>[];
  var totalMatches = 0;
  var searchFrom = 0;
  while (searchFrom <= articleText.length - quote.length) {
    final start = articleText.indexOf(quote, searchFrom);
    if (start < 0) break;
    totalMatches++;
    final end = start + quote.length;
    final candidate = AnnotationAnchorCandidate(
      startOffset: start,
      endOffset: end,
      matchedBeforeCharacters: _matchingContextSuffix(
        articleText,
        start,
        annotation.contextBefore,
      ),
      matchedAfterCharacters: _matchingContextPrefix(
        articleText,
        end,
        annotation.contextAfter,
      ),
    );
    candidates.add(candidate);
    searchFrom = start + 1; // Keep overlapping occurrences visible.
  }

  if (totalMatches == 0) {
    return const AnnotationAnchorResult(
      status: AnnotationAnchorStatus.notFound,
      totalMatches: 0,
      candidates: <AnnotationAnchorCandidate>[],
    );
  }

  candidates.sort((a, b) {
    final byContext = b.contextMatchScore.compareTo(a.contextMatchScore);
    return byContext != 0 ? byContext : a.startOffset.compareTo(b.startOffset);
  });
  final visibleCandidates = List<AnnotationAnchorCandidate>.unmodifiable(
    candidates.take(maxAnnotationAnchorCandidates),
  );

  if (totalMatches == 1) {
    return AnnotationAnchorResult(
      status: AnnotationAnchorStatus.uniqueQuote,
      totalMatches: 1,
      candidates: visibleCandidates,
      recommended: visibleCandidates.first,
    );
  }

  final best = candidates[0];
  final secondScore = candidates[1].contextMatchScore;
  if (best.contextMatchScore >= minAnnotationContextMatchCharacters &&
      best.contextMatchScore > secondScore) {
    return AnnotationAnchorResult(
      status: AnnotationAnchorStatus.contextualMatch,
      totalMatches: totalMatches,
      candidates: visibleCandidates,
      recommended: best,
    );
  }

  return AnnotationAnchorResult(
    status: AnnotationAnchorStatus.ambiguous,
    totalMatches: totalMatches,
    candidates: visibleCandidates,
  );
}

int _matchingContextSuffix(String text, int quoteStart, String context) {
  var matched = 0;
  while (matched < context.length && matched < quoteStart) {
    if (context.codeUnitAt(context.length - matched - 1) !=
        text.codeUnitAt(quoteStart - matched - 1)) {
      break;
    }
    matched++;
  }
  return matched;
}

int _matchingContextPrefix(String text, int quoteEnd, String context) {
  var matched = 0;
  while (matched < context.length && quoteEnd + matched < text.length) {
    if (context.codeUnitAt(matched) != text.codeUnitAt(quoteEnd + matched)) {
      break;
    }
    matched++;
  }
  return matched;
}
