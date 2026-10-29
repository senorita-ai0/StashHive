import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:stashhive/data/library_repository.dart';
import 'package:stashhive/main.dart' as app;
import 'package:stashhive/models/saved_item.dart';

late Directory testDirectory;
late LibraryRepository repository;

SavedItem buildBulkItem({
  required String id,
  required String title,
  String? collection,
  List<String> tags = const <String>['Reading'],
}) =>
    SavedItem(
      id: id,
      kind: ItemKind.link,
      title: title,
      content: '',
      url: 'https://example.com/$id',
      tags: tags,
      collection: collection,
      isFavorite: false,
      createdAtMs: 1000,
      updatedAtMs: 1000,
    );

void main() {
  setUp(() async {
    testDirectory = await Directory.systemTemp.createTemp('stashhive_bulk_test_');
    Hive.init(testDirectory.path);
    repository = await LibraryRepository.openInitializedForTesting();
  });

  tearDown(() async {
    repository.dispose();
    await Hive.close();
    await testDirectory.delete(recursive: true);
  });

  testWidgets('bulk actions favorite, move and edit tags for selected items',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1100, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await repository.addCollection('Work');
    await repository.save(buildBulkItem(id: 'one', title: 'First saved link'));
    await repository.save(buildBulkItem(id: 'two', title: 'Second saved link'));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: app.LibraryPage(
            repository: repository,
            onAdd: (_) {},
            onSearch: (_) {},
            onOpenItem: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Select items'));
    await tester.pumpAndSettle();
    expect(find.text('2 selected'), findsOneWidget);

    await tester.tap(find.text('Favorite'));
    await tester.pumpAndSettle();
    expect(repository.items.value.every((item) => item.isFavorite), isTrue);

    await tester.tap(find.text('Move'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Work').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Move items'));
    await tester.pumpAndSettle();
    expect(repository.items.value.every((item) => item.collection == 'Work'), isTrue);

    await tester.tap(find.text('Add tags'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Research, Reading');
    await tester.tap(find.text('Add tags').last);
    await tester.pumpAndSettle();
    expect(repository.items.value.every((item) => item.tags.contains('Research')), isTrue);
    expect(
      repository.items.value.every(
        (item) => item.tags.where((tag) => tag.toLowerCase() == 'reading').length == 1,
      ),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('bulk delete requires confirmation and can be cancelled',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1100, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await repository.save(buildBulkItem(id: 'one', title: 'First saved link'));
    await repository.save(buildBulkItem(id: 'two', title: 'Second saved link'));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: app.LibraryPage(
            repository: repository,
            onAdd: (_) {},
            onSearch: (_) {},
            onOpenItem: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Select items'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();

    expect(find.text('Delete 2 items?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(repository.items.value, hasLength(2));
    expect(find.text('First saved link'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
