import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:stashhive/data/library_repository.dart';
import 'package:stashhive/main.dart' as app;

late Directory testDirectory;
late LibraryRepository repository;

void main() {
  setUp(() async {
    testDirectory = await Directory.systemTemp.createTemp(
      'stashhive_smart_tag_rules_widget_test_',
    );
    Hive.init(testDirectory.path);
    repository = await LibraryRepository.openInitializedForTesting();
  });

  tearDown(() async {
    repository.dispose();
    await Hive.close();
    await testDirectory.delete(recursive: true);
  });

  testWidgets('creates and deletes a local smart tag rule', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: app.SmartTagRulesPage(repository: repository),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No smart rules yet'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('add-smart-tag-rule')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('smart-tag-match-text')),
      ' design ',
    );
    await tester.enterText(
      find.byKey(const ValueKey('smart-tag-suggested-tag')),
      ' Design ',
    );
    await tester.tap(find.text('Save rule'));
    await tester.pumpAndSettle();

    expect(repository.smartTagRules, hasLength(1));
    expect(repository.smartTagRules.single.matchText, 'design');
    expect(repository.smartTagRules.single.suggestedTag, 'Design');
    expect(find.text('Suggest “Design”'), findsOneWidget);
    expect(
      find.text('When title, URL or notes contain “design”'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Delete rule for design'));
    await tester.pumpAndSettle();
    expect(find.text('Delete smart tag rule?'), findsOneWidget);
    await tester.tap(find.text('Delete rule'));
    await tester.pumpAndSettle();

    expect(repository.smartTagRules, isEmpty);
    expect(find.text('No smart rules yet'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rejects an empty smart tag rule without saving', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: app.SmartTagRulesPage(repository: repository),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('add-smart-tag-rule')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save rule'));
    await tester.pumpAndSettle();

    expect(
      find.text('Match text must be between 1 and 120 characters.'),
      findsOneWidget,
    );
    expect(repository.smartTagRules, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
