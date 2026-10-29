import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stashhive/screens/article_reader_page.dart';

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
    expect(find.text('This saved URL is not a valid HTTP or HTTPS address.'),
        findsOneWidget);
    expect(find.text('Open in browser'), findsOneWidget);
  });
}
