import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:stashhive/data/library_repository.dart';
import 'package:stashhive/main.dart' as app;
import 'package:stashhive/models/saved_item.dart';

late Directory testDirectory;
late LibraryRepository repository;

SavedItem buildSearchItem({
  required String id,
  required String title,
  required String url,
  required bool favorite,
  List<String> tags = const <String>['Reading'],
  String? collection = 'Learning',
}) =>
    SavedItem(
      id: id,
      kind: ItemKind.link,
      title: title,
      content: 'A saved local note',
      url: url,
      tags: tags,
      collection: collection,
      isFavorite: favorite,
      createdAtMs: 1000,
      updatedAtMs: 1000,
    );

void main() {
  setUp(() async {
    testDirectory = await Directory.systemTemp.createTemp(
      'stashhive_search_filters_test_',
    );
    Hive.init(testDirectory.path);
    repository = await LibraryRepository.openInitializedForTesting();
  });

  tearDown(() async {
    repository.dispose();
    await Hive.close();
    await testDirectory.delete(recursive: true);
  });

  testWidgets(
    'advanced filters combine domain and favorite and can be saved and reused',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await repository.addCollection('Learning');
      await repository.addCollection('Work');
      await repository.save(
        buildSearchItem(
          id: 'favorite-target',
          title: 'Favorite target',
          url: 'https://www.example.com/article',
          favorite: true,
          collection: 'Learning',
        ),
      );
      await repository.save(
        buildSearchItem(
          id: 'ordinary-domain',
          title: 'Ordinary domain',
          url: 'https://blog.example.com/other',
          favorite: false,
          collection: 'Work',
        ),
      );
      await repository.save(
        buildSearchItem(
          id: 'other-domain',
          title: 'Other domain',
          url: 'https://unrelated.test/page',
          favorite: true,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: app.SearchPage(
              repository: repository,
              initialQuery: '',
              onOpenItem: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Favorite target'), findsOneWidget);
      expect(find.text('Ordinary domain'), findsOneWidget);
      expect(find.text('Other domain'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('advanced-search-filters')));
      await tester.pumpAndSettle();

      final domainField = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.labelText == 'Website domain',
      );
      expect(domainField, findsOneWidget);
      await tester.enterText(domainField, 'example.com');
      await tester.tap(find.text('Favorites only'));
      await tester.tap(find.text('Apply filters'));
      await tester.pumpAndSettle();

      expect(find.text('Favorite target'), findsOneWidget);
      expect(find.text('Ordinary domain'), findsNothing);
      expect(find.text('Other domain'), findsNothing);
      expect(find.text('Domain: example.com'), findsOneWidget);
      expect(find.text('Favorites'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('save-search-preset')));
      await tester.pumpAndSettle();
      final presetName = find.byType(TextField).last;
      await tester.enterText(presetName, 'Favorite example');
      await tester.tap(find.text('Save filter'));
      await tester.pumpAndSettle();

      expect(repository.savedSearchPresets, hasLength(1));
      expect(repository.savedSearchPresets.single.name, 'Favorite example');
      expect(repository.savedSearchPresets.single.filters.domain, 'example.com');
      expect(repository.savedSearchPresets.single.filters.favoritesOnly, isTrue);
      expect(find.text('Favorite example'), findsOneWidget);

      await tester.tap(find.text('Clear all'));
      await tester.pumpAndSettle();
      expect(find.text('Ordinary domain'), findsOneWidget);

      await tester.tap(find.widgetWithText(InputChip, 'Favorite example'));
      await tester.pumpAndSettle();
      expect(find.text('Favorite target'), findsOneWidget);
      expect(find.text('Ordinary domain'), findsNothing);
      expect(find.text('Other domain'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
