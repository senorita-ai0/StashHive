import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stashhive/main.dart' as app;
import 'package:stashhive/models/saved_item.dart';
import 'package:stashhive/services/library_stats.dart';

SavedItem _item(
  String id, {
  ItemKind kind = ItemKind.link,
  bool favorite = false,
  ReadingStatus status = ReadingStatus.unread,
  int createdAtMs = 1000,
}) =>
    SavedItem(
      id: id,
      kind: kind,
      title: id,
      content: '',
      url: kind == ItemKind.link ? 'https://example.com/$id' : null,
      tags: const <String>[],
      collection: null,
      isFavorite: favorite,
      readingStatus: status,
      createdAtMs: createdAtMs,
      updatedAtMs: createdAtMs,
    );

void main() {
  group('LibraryStats', () {
    test('empty library reports zero everywhere', () {
      final stats = LibraryStats.compute(const <SavedItem>[]);
      expect(stats.isEmpty, isTrue);
      expect(stats.total, 0);
      for (final kind in ItemKind.values) {
        expect(stats.countFor(kind), 0);
      }
    });

    test('counts totals, favorites, progress and kinds', () {
      final now = DateTime.fromMillisecondsSinceEpoch(
        1000 + const Duration(days: 30).inMilliseconds,
      );
      final stats = LibraryStats.compute(
        [
          _item('a', favorite: true),
          _item('b', kind: ItemKind.note, status: ReadingStatus.inProgress),
          _item('c', kind: ItemKind.image, status: ReadingStatus.completed),
          // Created "now": too recent for Rediscover.
          _item('d', createdAtMs: now.millisecondsSinceEpoch),
        ],
        now: now,
      );

      expect(stats.total, 4);
      expect(stats.favorites, 1);
      expect(stats.inProgress, 1);
      // a and b are old and unfinished; c is completed; d is too new.
      expect(stats.toRevisit, 2);
      expect(stats.countFor(ItemKind.link), 2);
      expect(stats.countFor(ItemKind.note), 1);
      expect(stats.countFor(ItemKind.image), 1);
      expect(stats.countFor(ItemKind.document), 0);
    });

    test('byKind cannot be mutated by callers', () {
      final stats = LibraryStats.compute([_item('a')]);
      expect(() => stats.byKind[ItemKind.link] = 9, throwsUnsupportedError);
    });
  });

  group('LibrarySummaryCard', () {
    testWidgets('shows labelled figures and per-type counts', (tester) async {
      final stats = LibraryStats.compute([
        _item('a', favorite: true),
        _item('b', kind: ItemKind.note),
        _item('c', kind: ItemKind.note),
      ]);
      await tester.pumpWidget(
        MaterialApp(
          theme: app.buildLightTheme(),
          home: Scaffold(body: app.LibrarySummaryCard(stats: stats)),
        ),
      );

      expect(find.text('Saved'), findsOneWidget);
      expect(find.text('Starred'), findsOneWidget);
      expect(find.text('Reading'), findsOneWidget);
      expect(find.text('To revisit'), findsOneWidget);
      expect(find.text('1 link'), findsOneWidget);
      expect(find.text('2 notes'), findsOneWidget);
      expect(find.text('1 image'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('exposes one summary label to screen readers',
        (tester) async {
      final semantics = tester.ensureSemantics();
      addTearDown(semantics.dispose);
      final stats = LibraryStats.compute([_item('a', favorite: true)]);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: app.LibrarySummaryCard(stats: stats)),
        ),
      );

      expect(
        find.bySemanticsLabel(
          'Library summary: 1 saved, 1 starred, 0 in progress, 0 to revisit',
        ),
        findsOneWidget,
      );
    });

    testWidgets('fits a narrow screen with large text without overflow',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final stats = LibraryStats.compute([
        for (final kind in ItemKind.values) _item(kind.name, kind: kind),
      ]);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(280, 800),
              textScaler: TextScaler.linear(2),
            ),
            child: Scaffold(
              body: SingleChildScrollView(
                child: app.LibrarySummaryCard(stats: stats),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
