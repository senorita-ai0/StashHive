import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stashhive/screens/article_reader_page.dart';
import 'package:stashhive/services/article_reader.dart';

void main() {
  testWidgets('loading reader exposes an accessible progress label',
      (tester) async {
    final pending = Completer<ArticleReaderResult>();
    articleReaderLoaderForTesting = (url, timeout) => pending.future;
    addTearDown(() {
      articleReaderLoaderForTesting = null;
    });
    final semanticsHandle = tester.ensureSemantics();
    addTearDown(semanticsHandle.dispose);

    await tester.pumpWidget(
      const MaterialApp(
        home: ArticleReaderPage(
          url: 'https://example.com/article',
          savedTitle: 'Saved title',
        ),
      ),
    );
    await tester.pump();

    expect(find.bySemanticsLabel('Loading article text'), findsOneWidget);

    pending.complete(
      const ArticleReaderResult(
        state: ArticleReaderState.success,
        title: 'Loaded article',
        text: 'Synthetic article text',
      ),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('saving a highlight exposes an accessible progress label',
      (tester) async {
    articleReaderLoaderForTesting = (url, timeout) async =>
        const ArticleReaderResult(
          state: ArticleReaderState.success,
          title: 'Sample article',
          text: 'A selected passage while the save operation is pending.',
        );
    addTearDown(() {
      articleReaderLoaderForTesting = null;
    });
    final pendingSave = Completer<bool>();
    final semanticsHandle = tester.ensureSemantics();
    addTearDown(semanticsHandle.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: ArticleReaderPage(
          url: 'https://example.com/article',
          savedTitle: 'Saved title',
          onSaveQuote: (quote, start, end, before, after) =>
              pendingSave.future,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.byKey(const ValueKey('article-reader-text')));
    await tester.pumpAndSettle();
    expect(find.text('SELECTED PASSAGE'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('save-reader-highlight')));
    await tester.pump();

    expect(find.bySemanticsLabel('Saving highlight'), findsOneWidget);

    pendingSave.complete(true);
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Highlight saved to this item. It may not align if the article changes.',
      ),
      findsOneWidget,
    );
  });

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
      find.text('The reader supports only credential-free HTTP/HTTPS links on standard ports (80/443).'),
      findsOneWidget,
    );
    expect(find.text('Open in browser'), findsOneWidget);
  });

  testWidgets('failed highlight save remains visible and can be retried',
      (tester) async {
    articleReaderLoaderForTesting = (url, timeout) async =>
        const ArticleReaderResult(
          state: ArticleReaderState.success,
          title: 'Sample article',
          text: 'A selected passage that may need another save attempt.',
        );
    addTearDown(() {
      articleReaderLoaderForTesting = null;
    });

    var attempts = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: ArticleReaderPage(
          url: 'https://example.com/article',
          savedTitle: 'Saved title',
          onSaveQuote: (quote, start, end, before, after) async {
            attempts++;
            return false;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.byKey(const ValueKey('article-reader-text')));
    await tester.pumpAndSettle();
    expect(find.text('SELECTED PASSAGE'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('save-reader-highlight')));
    await tester.pumpAndSettle();

    expect(attempts, 1);
    expect(
      find.text(
        'Highlight was not saved. Check the item limit or local storage and try again.',
      ),
      findsOneWidget,
    );
    expect(find.text('SELECTED PASSAGE'), findsOneWidget);
    expect(find.byKey(const ValueKey('save-reader-highlight')), findsOneWidget);
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
