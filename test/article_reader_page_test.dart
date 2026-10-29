import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stashhive/screens/article_reader_page.dart';
import 'package:stashhive/services/article_reader.dart';

void main() {
  testWidgets('invalid URL shows a recoverable state without a request',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ArticleReaderPage(
          url: 'javascript:alert(1)',
          savedTitle: 'Saved title',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Article preview unavailable'), findsOneWidget);
    expect(
      find.text('This saved URL is not a valid HTTP or HTTPS address.'),
      findsOneWidget,
    );
    expect(find.text('Open in browser'), findsOneWidget);
  });

  testWidgets('selected passage can be saved with bounded context and offsets',
      (tester) async {
    articleReaderLoaderForTesting = (url, timeout) async =>
        const ArticleReaderResult(
          state: ArticleReaderState.success,
          title: 'Sample article',
          text:
              'The river flows through the quiet green valley, carrying stories from the old town.',
        );
    addTearDown(() {
      articleReaderLoaderForTesting = null;
    });

    String? savedQuote;
    int? savedStart;
    int? savedEnd;
    String? savedBefore;
    String? savedAfter;

    await tester.pumpWidget(
      MaterialApp(
        home: ArticleReaderPage(
          url: 'https://example.com/article',
          savedTitle: 'Saved title',
          onSaveQuote: (quote, start, end, before, after) async {
            savedQuote = quote;
            savedStart = start;
            savedEnd = end;
            savedBefore = before;
            savedAfter = after;
            return true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final articleText = find.byKey(const ValueKey('article-reader-text'));
    await tester.longPress(articleText);
    await tester.pumpAndSettle();

    expect(find.text('SELECTED PASSAGE'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('save-reader-highlight')));
    await tester.pumpAndSettle();

    expect(savedQuote, isNotNull);
    expect(savedQuote, isNotEmpty);
    expect(savedStart, isNotNull);
    expect(savedEnd! - savedStart!, savedQuote!.length);
    expect(savedBefore!.length, lessThanOrEqualTo(200));
    expect(savedAfter!.length, lessThanOrEqualTo(200));
  });
}
