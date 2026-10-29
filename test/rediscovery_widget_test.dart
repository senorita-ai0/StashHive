import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:stashhive/data/library_repository.dart';
import 'package:stashhive/main.dart' as app;
import 'package:stashhive/models/saved_item.dart';

late Directory testDirectory;
late LibraryRepository repository;

SavedItem makeLibraryRediscoveryItem({
  required String id,
  required String title,
  required int ageInDays,
  ReadingStatus status = ReadingStatus.unread,
}) {
  final now = DateTime.now().toUtc();
  final createdAtMs = now
      .subtract(Duration(days: ageInDays))
      .millisecondsSinceEpoch;
  return SavedItem(
    id: id,
    kind: ItemKind.link,
    title: title,
    content: '',
    url: 'https://example.com/$id',
    tags: const <String>[],
    collection: null,
    isFavorite: false,
    readingStatus: status,
    createdAtMs: createdAtMs,
    updatedAtMs: now.millisecondsSinceEpoch,
  );
}

void main() {
  setUp(() async {
    testDirectory =
        await Directory.systemTemp.createTemp('stashhive_rediscovery_test_');
    Hive.init(testDirectory.path);
    repository = await LibraryRepository.openInitializedForTesting();
  });

  tearDown(() async {
    repository.dispose();
    await Hive.close();
    await testDirectory.delete(recursive: true);
  });

  testWidgets(
    'Rediscover shows older unfinished items and excludes recent/completed items',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await repository.save(
        makeLibraryRediscoveryItem(
          id: 'older-unread',
          title: 'Older unfinished item',
          ageInDays: 35,
        ),
      );
      await repository.save(
        makeLibraryRediscoveryItem(
          id: 'old-in-progress',
          title: 'Older in-progress item',
          ageInDays: 21,
          status: ReadingStatus.inProgress,
        ),
      );
      await repository.save(
        makeLibraryRediscoveryItem(
          id: 'old-completed',
          title: 'Already completed item',
          ageInDays: 40,
          status: ReadingStatus.completed,
        ),
      );
      await repository.save(
        makeLibraryRediscoveryItem(
          id: 'recent-unread',
          title: 'Recently saved item',
          ageInDays: 2,
        ),
      );

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

      final rediscoverChip = find.widgetWithText(ChoiceChip, 'Rediscover');
      await tester.ensureVisible(rediscoverChip);
      await tester.tap(rediscoverChip);
      await tester.pumpAndSettle();

      expect(find.text('Rediscover'), findsWidgets);
      expect(
        find.text(
          'Saved at least 14 days ago and not marked Completed. Oldest items appear first.',
        ),
        findsOneWidget,
      );
      expect(find.text('Older unfinished item'), findsOneWidget);
      expect(find.text('Older in-progress item'), findsOneWidget);
      expect(find.text('Already completed item'), findsNothing);
      expect(find.text('Recently saved item'), findsNothing);
      expect(find.text('Oldest first'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
