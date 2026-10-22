import 'dart:convert';
import 'dart:io';

import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:stashhive/data/library_repository.dart';

/// Produces a local, non-gating baseline for representative metadata-only
/// library sizes. Run deliberately with:
///   dart run tool/benchmark_library_repository.dart
///
/// Run after `flutter pub get`. Results are environment-specific; this tool
/// reports measurements and intentionally does not impose latency thresholds.
Future<void> main() async {
  final directory =
      await Directory.systemTemp.createTemp('stashhive_performance_');

  try {
    Hive.init(directory.path);
    final reports = <Map<String, Object>>[];

    for (final count in const [100, 1000, 10000]) {
      final itemsBox = await Hive.openBox<dynamic>('stashhive_items_v1');
      final attachmentsBox =
          await Hive.openBox<dynamic>('stashhive_attachments_v1');
      final preferencesBox =
          await Hive.openBox<dynamic>('stashhive_preferences_v1');

      await itemsBox.clear();
      await attachmentsBox.clear();
      await preferencesBox.clear();

      final records = <String, Object?>{};
      for (var index = 0; index < count; index++) {
        final id = 'benchmark-${index.toString().padLeft(5, '0')}';
        records[id] = <String, Object?>{
          'id': id,
          'kind': 'link',
          'title': index % 100 == 0
              ? 'Sentinel item $index'
              : 'Saved item $index',
          'content': 'Benchmark metadata for saved item $index',
          'url': 'https://example.com/items/$index',
          'tags': <String>['benchmark'],
          'collection': 'Benchmark',
          'isFavorite': index.isEven,
          'createdAtMs': 1700000000000 + index,
          'updatedAtMs': 1700000000000 + index,
          'attachmentKey': null,
          'attachmentName': null,
          'attachmentMimeType': null,
        };
      }

      final seedWatch = Stopwatch()..start();
      await itemsBox.putAll(records);
      seedWatch.stop();
      await Hive.close();

      final loadWatch = Stopwatch()..start();
      final repository = await LibraryRepository.openInitializedForTesting();
      loadWatch.stop();

      try {
        const repetitions = 25;
        var searchMatches = 0;
        final searchWatch = Stopwatch()..start();
        for (var pass = 0; pass < repetitions; pass++) {
          searchMatches = repository.items.value
              .where((item) => item.matchesQuery('sentinel'))
              .length;
        }
        searchWatch.stop();

        final favoritesWatch = Stopwatch()..start();
        var favoriteCount = 0;
        for (var pass = 0; pass < repetitions; pass++) {
          favoriteCount = repository.items.value
              .where((item) => item.isFavorite)
              .length;
        }
        favoritesWatch.stop();

        final editTarget = repository.findById('benchmark-00000');
        if (editTarget == null) {
          throw StateError('Benchmark fixture could not be loaded.');
        }
        final editWatch = Stopwatch()..start();
        await repository.save(
          editTarget.copyWith(
            title: '${editTarget.title} edited',
            updatedAtMs: DateTime.now().millisecondsSinceEpoch,
          ),
        );
        editWatch.stop();

        final backupWatch = Stopwatch()..start();
        final backup = await repository.createBackup();
        backupWatch.stop();

        reports.add(<String, Object>{
          'items': count,
          'bulkSeedMs': seedWatch.elapsedMilliseconds,
          'openAndValidateMs': loadWatch.elapsedMilliseconds,
          'searchSentinelMatches': searchMatches,
          'searchAverageMicroseconds':
              searchWatch.elapsedMicroseconds ~/ repetitions,
          'favoriteCount': favoriteCount,
          'favoriteFilterAverageMicroseconds':
              favoritesWatch.elapsedMicroseconds ~/ repetitions,
          'editExistingItemMs': editWatch.elapsedMilliseconds,
          'backupEncodeMs': backupWatch.elapsedMilliseconds,
          'backupCharacters': backup.length,
        });
      } finally {
        repository.dispose();
        await Hive.close();
      }
    }

    stdout.writeln(const JsonEncoder.withIndent('  ').convert(reports));
  } finally {
    await Hive.close();
    await directory.delete(recursive: true);
  }
}
