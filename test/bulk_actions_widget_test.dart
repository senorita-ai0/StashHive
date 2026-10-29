import 'dart:convert';
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
  String content = '',
}) =>
    SavedItem(
      id: id,
      kind: ItemKind.link,
      title: title,
      content: content,
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

  testWidgets('exports only selected items as a Markdown attachment',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1100, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    addTearDown(() => app.selectedItemsShareForTesting = null);

    await repository.save(
      buildBulkItem(
        id: 'one',
        title: 'First saved link',
        content: 'First item private notes',
      ),
    );
    await repository.save(
      buildBulkItem(
        id: 'two',
        title: 'Second saved link',
        content: 'Second item private notes',
      ),
    );

    String? exportedTitle;
    String? exportedName;
    String? exportedMimeType;
    String? exportedMarkdown;
    app.selectedItemsShareForTesting = (params) async {
      exportedTitle = params.title;
      final file = params.files!.single;
      exportedName = file.name;
      exportedMimeType = file.mimeType;
      exportedMarkdown = utf8.decode(await file.readAsBytes());
    };

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

    // Tapping a selected card while selection mode is active deselects it.
    await tester.tap(find.text('Second saved link'));
    await tester.pumpAndSettle();
    expect(find.text('1 selected'), findsOneWidget);

    await tester.tap(find.text('Export selected'));
    await tester.pumpAndSettle();

    expect(exportedTitle, 'StashHive selected items');
    expect(exportedName, matches(RegExp(r'^stashhive-selected-\d{4}-\d{2}-\d{2}\.md      (tester) async {
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
)));
    expect(exportedMimeType, 'text/markdown');
    expect(exportedMarkdown, contains('# StashHive selected items'));
    expect(exportedMarkdown, contains('## First saved link'));
    expect(exportedMarkdown, contains('https://example.com/one'));
    expect(exportedMarkdown, contains('First item private notes'));
    expect(exportedMarkdown, isNot(contains('Second saved link')));
    expect(exportedMarkdown, isNot(contains('Second item private notes')));
    expect(
      find.text(
        'Export list prepared. Attachment file contents are not included; use JSON backup for full recovery.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('reports a safe error if selected-item sharing fails',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1100, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    addTearDown(() => app.selectedItemsShareForTesting = null);
    await repository.save(buildBulkItem(id: 'one', title: 'First saved link'));

    app.selectedItemsShareForTesting = (_) async {
      throw StateError('private share diagnostic');
    };

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
    await tester.tap(find.text('Export selected'));
    await tester.pumpAndSettle();

    expect(find.text('Could not export the selected list. Try again.'), findsOneWidget);
    expect(find.textContaining('private share diagnostic'), findsNothing);
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
