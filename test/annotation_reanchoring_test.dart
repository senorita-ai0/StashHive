import 'package:flutter_test/flutter_test.dart';
import 'package:stashhive/models/saved_item.dart';
import 'package:stashhive/services/annotation_reanchoring.dart';

SavedAnnotation _annotation({
  String quote = 'target passage',
  String contextBefore = 'previous paragraph ends here before ',
  String contextAfter = ' and the next paragraph begins here.',
  int? oldStart = 500,
}) {
  return SavedAnnotation(
    id: 'saved-highlight',
    quote: quote,
    sourceStartOffset: oldStart,
    sourceEndOffset: oldStart == null ? null : oldStart + quote.length,
    contextBefore: contextBefore,
    contextAfter: contextAfter,
    createdAtMs: 1000,
  );
}

void main() {
  test('finds one exact quote without trusting its old offset', () {
    const article =
        'A refreshed introduction. The target passage appears in the new article.';
    final result = findSavedAnnotationAnchor(
      articleText: article,
      annotation: _annotation(),
    );

    expect(result.status, AnnotationAnchorStatus.uniqueQuote);
    expect(result.totalMatches, 1);
    expect(result.recommended, isNotNull);
    expect(
      result.recommended!.startOffset,
      article.indexOf('target passage'),
    );
    expect(result.recommended!.startOffset, isNot(500));
  });

  test('uses saved surrounding context to distinguish repeated quotes', () {
    const article =
        'An unrelated target passage appears here. '
        'A new section says previous paragraph ends here before target passage '
        'and the next paragraph begins here.';

    final result = findSavedAnnotationAnchor(
      articleText: article,
      annotation: _annotation(),
    );

    expect(result.status, AnnotationAnchorStatus.contextualMatch);
    expect(result.totalMatches, 2);
    expect(result.recommended, isNotNull);
    expect(
      result.recommended!.startOffset,
      article.lastIndexOf('target passage'),
    );
    expect(
      result.recommended!.contextMatchScore,
      greaterThanOrEqualTo(minAnnotationContextMatchCharacters),
    );
  });

  test('leaves equally supported repeated quotes ambiguous', () {
    const article =
        'before target passage after; before target passage after';
    final result = findSavedAnnotationAnchor(
      articleText: article,
      annotation: _annotation(
        quote: 'target passage',
        contextBefore: 'before ',
        contextAfter: ' after',
      ),
    );

    expect(result.status, AnnotationAnchorStatus.ambiguous);
    expect(result.totalMatches, 2);
    expect(result.recommended, isNull);
    expect(result.candidates, hasLength(2));
  });

  test('does not guess when repeated quotes have no saved context', () {
    final result = findSavedAnnotationAnchor(
      articleText: 'repeat passage then repeat passage',
      annotation: _annotation(
        quote: 'repeat passage',
        contextBefore: '',
        contextAfter: '',
      ),
    );

    expect(result.status, AnnotationAnchorStatus.ambiguous);
    expect(result.recommended, isNull);
  });

  test('returns not found when an edited article no longer contains the quote',
      () {
    final result = findSavedAnnotationAnchor(
      articleText: 'The publisher rewrote this article from top to bottom.',
      annotation: _annotation(),
    );

    expect(result.status, AnnotationAnchorStatus.notFound);
    expect(result.totalMatches, 0);
    expect(result.recommended, isNull);
  });

  test('rejects empty or oversized matching inputs', () {
    final empty = findSavedAnnotationAnchor(
      articleText: 'Any text',
      annotation: _annotation(quote: '  '),
    );
    final oversized = findSavedAnnotationAnchor(
      articleText: List<String>.filled(maxArticleTextCharacters + 1, 'a').join(),
      annotation: _annotation(quote: 'a'),
    );

    expect(empty.status, AnnotationAnchorStatus.invalidInput);
    expect(oversized.status, AnnotationAnchorStatus.invalidInput);
  });

  test('retains overlapping quote occurrences as ambiguous candidates', () {
    final result = findSavedAnnotationAnchor(
      articleText: 'aaaa',
      annotation: _annotation(
        quote: 'aa',
        contextBefore: '',
        contextAfter: '',
      ),
    );

    expect(result.status, AnnotationAnchorStatus.ambiguous);
    expect(result.totalMatches, 3);
    expect(result.candidates.map((candidate) => candidate.startOffset),
        [0, 1, 2]);
  });
}
