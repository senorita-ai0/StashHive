import 'dart:io';

import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:stashhive/data/library_repository.dart';
import 'package:stashhive/main.dart' as app;
import 'package:stashhive/models/saved_item.dart';
import 'package:stashhive/services/library_stats.dart';
import 'package:stashhive/services/reading_time.dart';

String _words(int count) => List<String>.filled(count, 'word').join(' ');

SavedItem _item(
  String id, {
  List<String> tags = const <String>[],
  String content = '',
  String? url,
  ItemKind kind = ItemKind.note,
}) =>
    SavedItem(
      id: id,
      kind: kind,
      title: 'Title $id',
      content: content,
      url: url,
      tags: tags,
      isFavorite: false,
      createdAtMs: 1000,
      updatedAtMs: 2000,
    );

void main() {
  group('reading time', () {
    test('short or empty text has no estimate', () {
      expect(estimatedReadingMinutes(''), isNull);
      expect(estimatedReadingMinutes(_words(399)), isNull);
      expect(readingTimeLabel(_words(10)), isNull);
      expect(estimatedReadingMinutes(' ' * 5000), isNull);
    });

    test('rounds up at 200 words per minute', () {
      expect(estimatedReadingMinutes(_words(400)), 2);
      expect(estimatedReadingMinutes(_words(401)), 3);
      expect(estimatedReadingMinutes(_words(1000)), 5);
      expect(readingTimeLabel(_words(1000)), '5 min read');
    });

    test('counts whitespace-separated words in non-Latin text', () {
      expect(estimatedReadingMinutes(List.filled(400, 'سلام').join(' ')), 2);
    });

    test('caps very large texts', () {
      expect(
        estimatedReadingMinutes(_words(300000)),
        readingTimeMaximumMinutes,
      );
    });
  });

  group('top tags', () {
    test('ranks by count with case-insensitive grouping', () {
      final stats = LibraryStats.compute([
        _item('a', tags: ['Flutter', 'dart']),
        _item('b', tags: ['flutter', 'Dart', 'dart']),
        _item('c', tags: ['Flutter', 'misc']),
        _item('d', tags: ['rare']),
      ]);

      expect(stats.topTags.map((t) => t.tag).toList(), ['Flutter', 'dart', 'misc']);
      expect(stats.topTags.map((t) => t.count).toList(), [3, 2, 1]);
    });

    test('ignores blank tags and has none for untagged libraries', () {
      expect(LibraryStats.compute([_item('a')]).topTags, isEmpty);
      expect(
        LibraryStats.compute([_item('a', tags: ['  ', ''])]).topTags,
        isEmpty,
      );
    });

    test('result cannot be mutated', () {
      final stats = LibraryStats.compute([_item('a', tags: ['x'])]);
      expect(
        () => stats.topTags.add(const TagCount('y', 1)),
        throwsUnsupportedError,
      );
    });

    testWidgets('summary card shows top tags and announces them',
        (tester) async {
      final semantics = tester.ensureSemantics();
      addTearDown(semantics.dispose);
      final stats = LibraryStats.compute([
        _item('a', tags: ['Flutter']),
        _item('b', tags: ['flutter', 'dart']),
      ]);
      await tester.pumpWidget(
        MaterialApp(
          theme: app.buildLightTheme(),
          home: Scaffold(body: app.LibrarySummaryCard(stats: stats)),
        ),
      );

      expect(find.text('Flutter · 2'), findsOneWidget);
      expect(find.text('dart · 1'), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp('top tags: Flutter 2, dart 1')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('item tile', () {
    late Directory directory;
    late LibraryRepository repository;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('stashhive_pack_');
      Hive.init(directory.path);
      repository = await LibraryRepository.openInitializedForTesting();
    });

    tearDown(() async {
      repository.dispose();
      await Hive.close();
      await directory.delete(recursive: true);
    });

    Future<void> pumpTile(WidgetTester tester, SavedItem item) {
      return tester.pumpWidget(
        MaterialApp(
          theme: app.buildLightTheme(),
          home: Scaffold(
            body: app.SavedItemTile(
              item: item,
              repository: repository,
              onTap: () {},
            ),
          ),
        ),
      );
    }

    testWidgets('long text shows a reading-time estimate', (tester) async {
      await pumpTile(tester, _item('long', content: _words(600)));
      expect(find.textContaining('3 min read'), findsOneWidget);
    });

    testWidgets('short text shows no reading-time estimate', (tester) async {
      await pumpTile(tester, _item('short', content: 'a few words'));
      expect(find.textContaining('min read'), findsNothing);
    });

    testWidgets('Copy link puts the URL on the clipboard', (tester) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));

      await pumpTile(
        tester,
        _item('link', kind: ItemKind.link, url: 'https://example.com/a'),
      );
      await tester.tap(find.byTooltip('Actions for Title link'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Copy link'));
      await tester.pumpAndSettle();

      expect(copied, 'https://example.com/a');
      expect(find.text('Link copied.'), findsOneWidget);
    });

    testWidgets('Copy link reports a clipboard failure safely',
        (tester) async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            throw PlatformException(code: 'unavailable');
          }
          return null;
        },
      );
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));

      await pumpTile(
        tester,
        _item('link2', kind: ItemKind.link, url: 'https://example.com/b'),
      );
      await tester.tap(find.byTooltip('Actions for Title link2'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Copy link'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Could not copy the link'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('items without a URL offer no Copy link action',
        (tester) async {
      await pumpTile(tester, _item('note'));
      await tester.tap(find.byTooltip('Actions for Title note'));
      await tester.pumpAndSettle();
      expect(find.text('Copy link'), findsNothing);
      expect(find.text('View details'), findsOneWidget);
    });
  });

  group('Ctrl/Cmd+K shortcut', () {
    late Directory directory;
    late LibraryRepository repository;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('stashhive_keys_');
      Hive.init(directory.path);
      repository = await LibraryRepository.openInitializedForTesting();
    });

    tearDown(() async {
      repository.dispose();
      await Hive.close();
      await directory.delete(recursive: true);
    });

    Future<void> pumpShell(WidgetTester tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      await tester.pumpWidget(
        MaterialApp(
          home: app.HomeShell(
            repository: repository,
            darkMode: false,
            onDarkModeChanged: (_) {},
            textScaleMultiplier: 1,
            onTextScaleChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    int selectedTab(WidgetTester tester) =>
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex;

    Future<void> chord(WidgetTester tester, LogicalKeyboardKey modifier) async {
      await tester.sendKeyDownEvent(modifier);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyK);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyK);
      await tester.sendKeyUpEvent(modifier);
      await tester.pumpAndSettle();
    }

    testWidgets('Ctrl+K opens Search', (tester) async {
      await pumpShell(tester);
      expect(selectedTab(tester), 0);
      await chord(tester, LogicalKeyboardKey.controlLeft);
      expect(selectedTab(tester), 1);
    });

    testWidgets('Cmd+K opens Search', (tester) async {
      await pumpShell(tester);
      await chord(tester, LogicalKeyboardKey.metaLeft);
      expect(selectedTab(tester), 1);
    });

    testWidgets('K alone does not change the tab', (tester) async {
      await pumpShell(tester);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyK);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyK);
      await tester.pumpAndSettle();
      expect(selectedTab(tester), 0);
    });

    testWidgets('does nothing while another page is on top', (tester) async {
      await pumpShell(tester);
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('covering page')),
        ),
      );
      await tester.pumpAndSettle();

      await chord(tester, LogicalKeyboardKey.controlLeft);
      navigator.pop();
      await tester.pumpAndSettle();

      expect(selectedTab(tester), 0);
    });
  });
}
