import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:stashhive/data/library_repository.dart';
import 'package:stashhive/main.dart' as app;
import 'package:stashhive/models/saved_item.dart';

late Directory testDirectory;
late LibraryRepository repository;

SavedItem buildLink() => SavedItem(
      id: 'annotation-link',
      kind: ItemKind.link,
      title: 'Useful article',
      content: 'A short user-entered summary.',
      url: 'https://example.com/article',
      tags: const <String>['Reading'],
      collection: null,
      isFavorite: false,
      createdAtMs: 1000,
      updatedAtMs: 1000,
    );

void main() {
  setUp(() async {
    testDirectory = await Directory.systemTemp.createTemp(
      'stashhive_annotations_widget_test_',
    );
    Hive.init(testDirectory.path);
    repository = await LibraryRepository.openInitializedForTesting();
    await repository.save(buildLink());
  });

  tearDown(() async {
    repository.dispose();
    await Hive.close();
    await testDirectory.delete(recursive: true);
  });

  testWidgets('saves, displays, and deletes a personal quote annotation', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: app.ItemDetailsPage(
          repository: repository,
          itemId: 'annotation-link',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const ValueKey('add-annotation')));
    await tester.tap(find.byKey(const ValueKey('add-annotation')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save annotation'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a quote or a personal note.'), findsOneWidget);
    expect(repository.findById('annotation-link')!.annotations, isEmpty);

    await tester.enterText(
      find.byKey(const ValueKey('annotation-quote')),
      'Local-first tools protect personal data.',
    );
    await tester.enterText(
      find.byKey(const ValueKey('annotation-note')),
      'Keep this principle in the product review.',
    );
    await tester.tap(find.text('Save annotation'));
    await tester.pumpAndSettle();

    final saved = repository.findById('annotation-link')!;
    expect(saved.annotations, hasLength(1));
    expect(saved.annotations.single.quote, 'Local-first tools protect personal data.');
    expect(saved.annotations.single.note, 'Keep this principle in the product review.');
    expect(find.text('“Local-first tools protect personal data.”'), findsOneWidget);
    expect(find.text('Keep this principle in the product review.'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final annotationId = saved.annotations.single.id;
    await tester.ensureVisible(
      find.byKey(ValueKey('delete-annotation-$annotationId')),
    );
    await tester.tap(find.byKey(ValueKey('delete-annotation-$annotationId')));
    await tester.pumpAndSettle();
    expect(find.text('Delete annotation?'), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(repository.findById('annotation-link')!.annotations, isEmpty);
    expect(find.text('“Local-first tools protect personal data.”'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
