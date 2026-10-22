import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:stashhive/data/library_repository.dart';
import 'package:stashhive/models/saved_item.dart';
import 'package:stashhive/main.dart' as app;

double _contrastRatio(Color first, Color second) {
  final a = first.computeLuminance();
  final b = second.computeLuminance();
  return (a > b ? a + 0.05 : b + 0.05) /
      (a > b ? b + 0.05 : a + 0.05);
}

void main() {
  testWidgets('muted text meets contrast on light surfaces', (tester) async {
    late Color muted;
    late Color canvas;
    late Color field;
    await tester.pumpWidget(
      MaterialApp(
        theme: app.buildLightTheme(),
        home: Builder(
          builder: (context) {
            muted = app.mutedTextColor(context);
            canvas = Theme.of(context).scaffoldBackgroundColor;
            field = Theme.of(context).inputDecorationTheme.fillColor!;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(_contrastRatio(muted, Colors.white), greaterThanOrEqualTo(4.5));
    expect(_contrastRatio(muted, canvas), greaterThanOrEqualTo(4.5));
    expect(_contrastRatio(muted, field), greaterThanOrEqualTo(4.5));
  });

  testWidgets('muted text meets contrast on dark surfaces', (tester) async {
    late Color muted;
    late Color canvas;
    late Color field;
    await tester.pumpWidget(
      MaterialApp(
        theme: app.buildLightTheme(),
        darkTheme: app.buildDarkTheme(),
        themeMode: ThemeMode.dark,
        home: Builder(
          builder: (context) {
            muted = app.mutedTextColor(context);
            canvas = Theme.of(context).scaffoldBackgroundColor;
            field = Theme.of(context).inputDecorationTheme.fillColor!;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(_contrastRatio(muted, canvas), greaterThanOrEqualTo(4.5));
    expect(_contrastRatio(muted, field), greaterThanOrEqualTo(4.5));
  });

  late Directory testDirectory;
  late LibraryRepository repository;

  setUp(() async {
    testDirectory = await Directory.systemTemp.createTemp('stashhive_a11y_test_');
    Hive.init(testDirectory.path);
    repository = await LibraryRepository.openInitializedForTesting();
  });

  tearDown(() async {
    repository.dispose();
    await Hive.close();
    await testDirectory.delete(recursive: true);
  });

  testWidgets('Library search teaser exposes and handles semantic activation', (tester) async {
    final semantics = tester.ensureSemantics();
    addTearDown(semantics.dispose);
    var openedSearch = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: app.LibraryPage(
            repository: repository,
            onAdd: (_) {},
            onSearch: (_) => openedSearch = true,
            onOpenItem: (_) {},
          ),
        ),
      ),
    );

    final search = find.bySemanticsLabel('Search your library');
    expect(search, findsOneWidget);
    final node = tester.getSemantics(search);
    expect(node.hasAction(SemanticsAction.tap), isTrue);
    node.performAction(SemanticsAction.tap);
    expect(openedSearch, isTrue);
  });

  testWidgets('Search result count is exposed as a live status', (tester) async {
    final semantics = tester.ensureSemantics();
    addTearDown(semantics.dispose);
    const item = SavedItem(
      id: 'searchable-link',
      kind: ItemKind.link,
      title: 'Accessible Flutter guide',
      content: 'Guide',
      url: 'https://flutter.dev',
      tags: ['Accessibility'],
      collection: null,
      isFavorite: false,
      createdAtMs: 1,
      updatedAtMs: 2,
    );
    await repository.save(item);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: app.SearchPage(
            repository: repository,
            initialQuery: 'Accessible',
            onOpenItem: (_) {},
          ),
        ),
      ),
    );

    final matchCount = find.bySemanticsLabel('1 result');
    expect(matchCount, findsOneWidget);
    expect(
      tester.getSemantics(matchCount).hasFlag(SemanticsFlag.isLiveRegion),
      isTrue,
    );

    await tester.enterText(find.byType(TextField), 'does-not-match');
    await tester.pump();

    final emptyCount = find.bySemanticsLabel('0 results');
    expect(emptyCount, findsOneWidget);
    expect(
      tester.getSemantics(emptyCount).hasFlag(SemanticsFlag.isLiveRegion),
      isTrue,
    );
  });

  testWidgets('Saved-item action menu is contextual and runs its commands', (tester) async {
    const item = SavedItem(
      id: 'actions-link',
      kind: ItemKind.link,
      title: 'Accessible Flutter guide',
      content: 'Guide',
      url: 'https://flutter.dev',
      tags: ['Accessibility'],
      collection: null,
      isFavorite: false,
      createdAtMs: 1,
      updatedAtMs: 2,
    );
    var openedDetails = false;
    await repository.save(item);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: app.SavedItemTile(
            item: item,
            repository: repository,
            onTap: () => openedDetails = true,
          ),
        ),
      ),
    );

    final actions = find.byTooltip('Actions for Accessible Flutter guide');
    expect(actions, findsOneWidget);
    await tester.tap(actions);
    await tester.pumpAndSettle();

    expect(find.text('Add to favorites'), findsOneWidget);
    expect(find.text('View details'), findsOneWidget);

    await tester.tap(find.text('View details'));
    await tester.pumpAndSettle();
    expect(openedDetails, isTrue);

    await tester.tap(actions);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add to favorites'));
    await tester.pumpAndSettle();

    expect(repository.items.value.single.isFavorite, isTrue);
  });

  testWidgets('favorite state is exposed with a meaningful semantic label', (tester) async {
    final semantics = tester.ensureSemantics();
    addTearDown(semantics.dispose);
    const item = SavedItem(
      id: 'favorite-link',
      kind: ItemKind.link,
      title: 'Accessible Flutter guide',
      content: 'Guide',
      url: 'https://flutter.dev',
      tags: ['Accessibility'],
      collection: null,
      isFavorite: true,
      createdAtMs: 1,
      updatedAtMs: 2,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: app.SavedItemTile(
            item: item,
            repository: repository,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Saved as a favorite'), findsOneWidget);
  });
}
