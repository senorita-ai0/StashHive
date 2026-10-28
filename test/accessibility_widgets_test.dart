import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:stashhive/data/library_repository.dart';
import 'package:stashhive/models/saved_item.dart';
import 'package:stashhive/main.dart' as app;

final class _FailingBackupLengthFile extends PlatformFile {
  _FailingBackupLengthFile();

  @override
  String get name => 'private-backup-provider.json';

  @override
  Future<int> length() async {
    throw StateError('private backup provider detail should not be shown');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _FailingBackupByteStreamFile extends PlatformFile {
  _FailingBackupByteStreamFile();

  @override
  String get name => 'private-backup-stream-provider.json';

  @override
  Future<int> length() async => 16;

  @override
  Stream<Uint8List> readAsByteStream() => Stream<Uint8List>.error(
        StateError('private backup byte stream location should not be shown'),
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

double _contrastRatio(Color first, Color second) {
  final a = first.computeLuminance();
  final b = second.computeLuminance();
  return (a > b ? a + 0.05 : b + 0.05) /
      (a > b ? b + 0.05 : a + 0.05);
}

void main() {
  test('backup share result messages distinguish confirmed, dismissed and unknown outcomes', () {
    final completed = app.backupShareResultMessage(ShareResultStatus.success);
    final dismissed = app.backupShareResultMessage(ShareResultStatus.dismissed);
    final unavailable = app.backupShareResultMessage(ShareResultStatus.unavailable);

    expect(completed, contains('Check the destination to confirm the file arrived'));
    expect(completed, isNot(contains('Backup shared.')));
    expect(dismissed, contains('share sheet was dismissed'));
    expect(dismissed, contains('create a backup again'));
    expect(unavailable, contains('could not confirm whether the backup was saved or shared'));
    expect(unavailable, contains('Downloads'));
    expect(unavailable, isNot(contains('Backup shared.')));
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

  testWidgets('Startup failure UI hides raw local storage diagnostics', (tester) async {
    await tester.pumpWidget(const app.StartupFailureApp());
    expect(find.text('StashHive could not open its local library'), findsOneWidget);
    expect(find.textContaining('Technical details are hidden'), findsOneWidget);
    expect(find.byType(SelectableText), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'keeps the local library usable when native share-stream setup fails',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      var initialReadAttempted = false;
      app.incomingShareStreamForTesting = () {
        throw StateError('private native share channel detail');
      };
      app.incomingInitialShareReaderForTesting = () async {
        initialReadAttempted = true;
        return <SharedMediaFile>[];
      };
      app.resetIncomingInitialShareForTesting = () async {};
      addTearDown(() {
        debugDefaultTargetPlatformOverride = null;
        app.incomingShareStreamForTesting = null;
        app.incomingInitialShareReaderForTesting = null;
        app.resetIncomingInitialShareForTesting = null;
      });

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

      expect(
        find.text(
          'Sharing is unavailable right now. You can still add items manually.',
        ),
        findsOneWidget,
      );
      expect(initialReadAttempted, isTrue);
      expect(
        find.textContaining('private native share channel detail'),
        findsNothing,
      );
      expect(find.bySemanticsLabel('Search your library'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Library header displays the StashHive brand', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: app.LibraryPage(
          repository: repository,
          onAdd: (_) {},
          onSearch: (_) {},
          onOpenItem: (_) {},
        ),
      ),
    );

    expect(find.text('StashHive'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Library reminder explains local storage and offers a backup action', (tester) async {
    var dismissed = false;
    var backupRequested = false;
    await tester.pumpWidget(
      MaterialApp(
        home: app.LibraryPage(
          repository: repository,
          onAdd: (_) {},
          onSearch: (_) {},
          onOpenItem: (_) {},
          showStorageReminder: true,
          onDismissStorageReminder: () => dismissed = true,
          onCreateBackup: () => backupRequested = true,
        ),
      ),
    );

    expect(find.text('Keep your library safe'), findsOneWidget);
    expect(find.textContaining('does not sync'), findsOneWidget);
    await tester.tap(find.text('Backup options'));
    expect(backupRequested, isTrue);
    await tester.tap(find.text('Got it'));
    expect(dismissed, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('HomeShell remembers dismissal of its first-launch reminder', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    await tester.pumpWidget(
      MaterialApp(
        home: app.HomeShell(
          repository: repository,
          darkMode: false,
          onDarkModeChanged: (_) {},
          textScaleMultiplier: repository.textScaleMultiplier,
          onTextScaleChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Keep your library safe'), findsOneWidget);
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(find.text('Keep your library safe'), findsNothing);
    expect(repository.hasSeenStorageReminder, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('HomeShell opens Backup & privacy from the first-launch reminder', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    await tester.pumpWidget(
      MaterialApp(
        home: app.HomeShell(
          repository: repository,
          darkMode: false,
          onDarkModeChanged: (_) {},
          textScaleMultiplier: repository.textScaleMultiplier,
          onTextScaleChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Backup options'));
    await tester.pumpAndSettle();

    expect(find.text('Backup & privacy'), findsOneWidget);
    expect(repository.hasSeenStorageReminder, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Dark-mode switch reverts when its preference cannot be saved', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    await tester.pumpWidget(
      app.StashHiveApp(repository: repository, initialDarkMode: false),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();
    final switchFinder = find.byType(Switch);
    expect(switchFinder, findsOneWidget);

    LibraryRepository.setDarkModeAfterWriteForTesting = () async {
      throw StateError('simulated dark-mode preference failure');
    };
    try {
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();
    } finally {
      LibraryRepository.setDarkModeAfterWriteForTesting = null;
    }

    expect(repository.darkMode, isFalse);
    expect(tester.widget<Switch>(switchFinder).value, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'an older dark-mode failure cannot revert the newest queued choice',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      await tester.pumpWidget(
        app.StashHiveApp(repository: repository, initialDarkMode: false),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Settings').last);
      await tester.pumpAndSettle();

      final switchFinder = find.byType(Switch);
      final firstWriteEntered = Completer<void>();
      final releaseFirstFailure = Completer<void>();
      final allWritesEntered = Completer<void>();
      var hookCalls = 0;
      LibraryRepository.setDarkModeAfterWriteForTesting = () async {
        hookCalls++;
        if (hookCalls == 1) {
          firstWriteEntered.complete();
          await releaseFirstFailure.future;
          throw StateError('simulated older theme write failure');
        }
        if (hookCalls == 3 && !allWritesEntered.isCompleted) {
          allWritesEntered.complete();
        }
      };

      try {
        await tester.tap(switchFinder);
        await tester.pump();
        await firstWriteEntered.future;
        await tester.pump();

        // Queue false and then true while the first true write is unresolved.
        await tester.tap(switchFinder);
        await tester.pump();
        await tester.tap(switchFinder);
        await tester.pump();
        expect(tester.widget<Switch>(switchFinder).value, isTrue);

        releaseFirstFailure.complete();
        await allWritesEntered.future;
        await tester.pumpAndSettle();
      } finally {
        if (!releaseFirstFailure.isCompleted) releaseFirstFailure.complete();
        LibraryRepository.setDarkModeAfterWriteForTesting = null;
      }

      expect(hookCalls, 3);
      expect(repository.darkMode, isTrue);
      expect(tester.widget<Switch>(switchFinder).value, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Text size preference increases app text and preserves platform scaling', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    await tester.pumpWidget(
      app.StashHiveApp(repository: repository, initialDarkMode: false),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();

    final before = MediaQuery.of(tester.element(find.text('Text size')))
        .textScaler
        .scale(10);
    final control = find.byType(DropdownButtonFormField<double>);
    expect(control, findsOneWidget);
    await tester.tap(control);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Large').last);
    await tester.pumpAndSettle();

    expect(repository.textScaleMultiplier, 1.15);
    final after = MediaQuery.of(tester.element(find.text('Text size')))
        .textScaler
        .scale(10);
    expect(after, closeTo(before * 1.15, 0.1));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'text-size dropdown visibly restores the persisted choice after a write fails',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      await tester.pumpWidget(
        app.StashHiveApp(repository: repository, initialDarkMode: false),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Settings').last);
      await tester.pumpAndSettle();

      LibraryRepository.setTextScaleMultiplierAfterWriteForTesting = () async {
        throw StateError('simulated text-size dropdown failure');
      };
      try {
        final control = find.byType(DropdownButtonFormField<double>);
        await tester.tap(control);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Large').last);
        await tester.pumpAndSettle();
      } finally {
        LibraryRepository.setTextScaleMultiplierAfterWriteForTesting = null;
      }

      expect(repository.textScaleMultiplier, 1.0);
      expect(
        tester.widget<DropdownButtonFormField<double>>(
          find.byType(DropdownButtonFormField<double>),
        ).initialValue,
        1.0,
      );
      expect(find.text('System default'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Text size preference supports Extra large and resets to system default', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    Future<void> openSettings() async {
      await tester.pumpWidget(
        app.StashHiveApp(repository: repository, initialDarkMode: false),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Settings').last);
      await tester.pumpAndSettle();
    }

    await openSettings();
    final control = find.byType(DropdownButtonFormField<double>);
    await tester.tap(control);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Extra large').last);
    await tester.pumpAndSettle();

    expect(repository.textScaleMultiplier, 1.3);
    expect(
      tester.widget<DropdownButtonFormField<double>>(control).initialValue,
      1.3,
    );

    // Recreate the app state to exercise persisted preference initialization.
    await tester.pumpWidget(const SizedBox.shrink());
    await openSettings();
    expect(repository.textScaleMultiplier, 1.3);
    expect(
      tester
          .widget<DropdownButtonFormField<double>>(
            find.byType(DropdownButtonFormField<double>),
          )
          .initialValue,
      1.3,
    );
    await tester.tap(find.byType(DropdownButtonFormField<double>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('System default').last);
    await tester.pumpAndSettle();

    expect(repository.textScaleMultiplier, 1.0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'an older text-size failure cannot revert the newest queued choice',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      await tester.pumpWidget(
        app.StashHiveApp(repository: repository, initialDarkMode: false),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Settings').last);
      await tester.pumpAndSettle();

      final control = find.byType(DropdownButtonFormField<double>);
      final firstWriteEntered = Completer<void>();
      final releaseFirstFailure = Completer<void>();
      final allWritesEntered = Completer<void>();
      var hookCalls = 0;
      LibraryRepository.setTextScaleMultiplierAfterWriteForTesting = () async {
        hookCalls++;
        if (hookCalls == 1) {
          firstWriteEntered.complete();
          await releaseFirstFailure.future;
          throw StateError('simulated older text-size write failure');
        }
        if (hookCalls == 2 && !allWritesEntered.isCompleted) {
          allWritesEntered.complete();
        }
      };

      try {
        await tester.tap(control);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Large').last);
        await tester.pump();
        await firstWriteEntered.future;
        await tester.pump();

        await tester.tap(control);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Extra large').last);
        await tester.pump();
        expect(
          tester.widget<DropdownButtonFormField<double>>(control).initialValue,
          1.3,
        );

        releaseFirstFailure.complete();
        await allWritesEntered.future;
        await tester.pumpAndSettle();
      } finally {
        if (!releaseFirstFailure.isCompleted) releaseFirstFailure.complete();
        LibraryRepository.setTextScaleMultiplierAfterWriteForTesting = null;
      }

      expect(hookCalls, 2);
      expect(repository.textScaleMultiplier, 1.3);
      expect(
        tester.widget<DropdownButtonFormField<double>>(control).initialValue,
        1.3,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'recovers from a backup size lookup failure and allows a retry',
    (tester) async {
      const item = SavedItem(
        id: 'backup-retry-source',
        kind: ItemKind.link,
        title: 'Backup retry source',
        content: 'A saved item for retry coverage.',
        url: 'https://example.com/backup-retry',
        tags: <String>['Backup'],
        collection: null,
        isFavorite: false,
        createdAtMs: 100,
        updatedAtMs: 101,
      );
      await repository.save(item);
      final backupBytes = Uint8List.fromList(
        utf8.encode(await repository.createBackup()),
      );
      var pickerAttempts = 0;
      app.backupFilePickerForTesting = () async {
        pickerAttempts++;
        if (pickerAttempts == 1) return _FailingBackupLengthFile();
        return PlatformFile(
          name: 'retry-backup.json',
          size: backupBytes.length,
          bytes: backupBytes,
        );
      };
      addTearDown(() {
        app.backupFilePickerForTesting = null;
      });

      await tester.pumpWidget(
        MaterialApp(
          home: app.BackupPrivacyPage(repository: repository),
        ),
      );
      await tester.ensureVisible(find.text('Choose backup file'));
      await tester.tap(find.text('Choose backup file'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Could not restore this backup. Check the selected file and try again.',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('private backup provider detail should not be shown'),
        findsNothing,
      );
      expect(find.text('Choosing backup…'), findsNothing);
      expect(repository.items.value, hasLength(1));
      expect(tester.takeException(), isNull);

      await tester.ensureVisible(find.text('Choose backup file'));
      await tester.tap(find.text('Choose backup file'));
      await tester.pumpAndSettle();

      expect(pickerAttempts, 2);
      expect(find.text('Merge this backup?'), findsOneWidget);
      await tester.tap(find.text('Merge backup'));
      await tester.pumpAndSettle();

      expect(find.text('Restored 1 item.'), findsOneWidget);
      expect(repository.items.value, hasLength(2));
      expect(
        repository.items.value.where((saved) => saved.title == item.title),
        hasLength(2),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'recovers from a backup byte-stream failure and allows a retry',
    (tester) async {
      const item = SavedItem(
        id: 'backup-stream-retry-source',
        kind: ItemKind.link,
        title: 'Backup stream retry source',
        content: 'A saved item for read-failure coverage.',
        url: 'https://example.com/backup-stream-retry',
        tags: <String>['Backup'],
        collection: null,
        isFavorite: false,
        createdAtMs: 200,
        updatedAtMs: 201,
      );
      await repository.save(item);
      final backupBytes = Uint8List.fromList(
        utf8.encode(await repository.createBackup()),
      );
      var pickerAttempts = 0;
      app.backupFilePickerForTesting = () async {
        pickerAttempts++;
        if (pickerAttempts == 1) return _FailingBackupByteStreamFile();
        return PlatformFile(
          name: 'retry-after-stream-error.json',
          size: backupBytes.length,
          bytes: backupBytes,
        );
      };
      addTearDown(() {
        app.backupFilePickerForTesting = null;
      });

      await tester.pumpWidget(
        MaterialApp(
          home: app.BackupPrivacyPage(repository: repository),
        ),
      );
      await tester.ensureVisible(find.text('Choose backup file'));
      await tester.tap(find.text('Choose backup file'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Could not restore this backup. Check the selected file and try again.',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('private backup byte stream location should not be shown'),
        findsNothing,
      );
      expect(find.text('Choosing backup…'), findsNothing);
      expect(repository.items.value, hasLength(1));
      expect(repository.findById(item.id), isNotNull);
      expect(tester.takeException(), isNull);

      await tester.ensureVisible(find.text('Choose backup file'));
      await tester.tap(find.text('Choose backup file'));
      await tester.pumpAndSettle();

      expect(pickerAttempts, 2);
      expect(find.text('Merge this backup?'), findsOneWidget);
      await tester.tap(find.text('Merge backup'));
      await tester.pumpAndSettle();

      expect(find.text('Restored 1 item.'), findsOneWidget);
      expect(repository.items.value, hasLength(2));
      expect(
        repository.items.value.where((saved) => saved.title == item.title),
        hasLength(2),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'blocks back navigation while a restore is committing',
    (tester) async {
      final semantics = tester.ensureSemantics();
      addTearDown(semantics.dispose);
      const item = SavedItem(
        id: 'restore-navigation-guard-source',
        kind: ItemKind.link,
        title: 'Restore navigation guard source',
        content: 'Existing library data',
        url: 'https://example.com/restore-navigation-guard',
        tags: <String>['Backup'],
        collection: null,
        isFavorite: false,
        createdAtMs: 300,
        updatedAtMs: 301,
      );
      await repository.save(item);
      final backupBytes = Uint8List.fromList(
        utf8.encode(await repository.createBackup()),
      );
      app.backupFilePickerForTesting = () async => PlatformFile(
            name: 'restore-navigation-guard.json',
            size: backupBytes.length,
            bytes: backupBytes,
          );
      addTearDown(() {
        app.backupFilePickerForTesting = null;
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            app.BackupPrivacyPage(repository: repository),
                      ),
                    );
                  },
                  child: const Text('Open backup screen'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open backup screen'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Choose backup file'));
      await tester.tap(find.text('Choose backup file'));
      await tester.pumpAndSettle();
      expect(find.text('Merge this backup?'), findsOneWidget);

      final restoreEntered = Completer<void>();
      final releaseRestore = Completer<void>();
      LibraryRepository.restoreBeforeCollectionsCommitForTesting = () async {
        restoreEntered.complete();
        await releaseRestore.future;
      };

      try {
        await tester.tap(find.text('Merge backup'));
        await tester.pump();
        await restoreEntered.future;
        await tester.pump();

        expect(find.text('Restoring…'), findsOneWidget);
        expect(find.text('Restore in progress…'), findsOneWidget);
        expect(
          tester
              .getSemantics(find.bySemanticsLabel('Restore in progress…'))
              .hasFlag(SemanticsFlag.isLiveRegion),
          isTrue,
        );
        final exportAction = find.ancestor(
          of: find.text('Restore in progress…'),
          matching: find.byType(FilledButton),
        );
        expect(exportAction, findsOneWidget);
        expect(tester.widget<FilledButton>(exportAction).onPressed, isNull);

        final backButton = tester.widget<IconButton>(
          find.descendant(
            of: find.byType(AppBar),
            matching: find.byType(IconButton),
          ).first,
        );
        expect(backButton.onPressed, isNull);

        await tester.binding.handlePopRoute();
        await tester.pump();

        expect(find.text('Backup & privacy'), findsOneWidget);
        expect(
          find.text('Restoring…'),
          findsOneWidget,
          reason: 'System back must not dismiss an active restore commit.',
        );
        expect(repository.items.value, hasLength(1));
      } finally {
        if (!releaseRestore.isCompleted) releaseRestore.complete();
        LibraryRepository.restoreBeforeCollectionsCommitForTesting = null;
      }

      await tester.pumpAndSettle();
      expect(find.text('Backup & privacy'), findsOneWidget);
      expect(find.text('Restored 1 item.'), findsOneWidget);
      expect(repository.items.value, hasLength(2));
      expect(repository.findById(item.id), isNotNull);
      final exportActionAfterRestore = find.ancestor(
        of: find.text('Create backup'),
        matching: find.byType(FilledButton),
      );
      expect(exportActionAfterRestore, findsOneWidget);
      expect(
        tester.widget<FilledButton>(exportActionAfterRestore).onPressed,
        isNotNull,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'releases the restore navigation guard after a failed restore',
    (tester) async {
      const item = SavedItem(
        id: 'restore-navigation-failure-source',
        kind: ItemKind.link,
        title: 'Existing item to preserve',
        content: 'Existing library data',
        url: 'https://example.com/restore-navigation-failure',
        tags: <String>['Backup'],
        collection: null,
        isFavorite: false,
        createdAtMs: 400,
        updatedAtMs: 401,
      );
      await repository.save(item);
      final backupBytes = Uint8List.fromList(
        utf8.encode(await repository.createBackup()),
      );
      app.backupFilePickerForTesting = () async => PlatformFile(
            name: 'restore-failure-guard.json',
            size: backupBytes.length,
            bytes: backupBytes,
          );
      addTearDown(() {
        app.backupFilePickerForTesting = null;
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            app.BackupPrivacyPage(repository: repository),
                      ),
                    );
                  },
                  child: const Text('Open backup screen'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open backup screen'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Choose backup file'));
      await tester.tap(find.text('Choose backup file'));
      await tester.pumpAndSettle();
      expect(find.text('Merge this backup?'), findsOneWidget);

      LibraryRepository.restoreBeforeCollectionsCommitForTesting = () async {
        throw StateError('private restore commit detail should not be shown');
      };

      try {
        await tester.tap(find.text('Merge backup'));
        await tester.pumpAndSettle();

        expect(
          find.text(
            'Could not restore this backup. Check the selected file and try again.',
          ),
          findsOneWidget,
        );
        expect(
          find.textContaining('private restore commit detail should not be shown'),
          findsNothing,
        );
        expect(find.text('Restoring…'), findsNothing);
        expect(repository.items.value, hasLength(1));
        expect(repository.findById(item.id), isNotNull);
        expect(tester.takeException(), isNull);

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();

        expect(find.text('Open backup screen'), findsOneWidget);
        expect(find.text('Backup & privacy'), findsNothing);
        expect(tester.takeException(), isNull);
      } finally {
        LibraryRepository.restoreBeforeCollectionsCommitForTesting = null;
      }
    },
  );

  testWidgets(
    'disables restore while backup preparation is in progress',
    (tester) async {
      final semantics = tester.ensureSemantics();
      addTearDown(semantics.dispose);
      final preparationEntered = Completer<void>();
      final releasePreparation = Completer<void>();
      var pickerCalls = 0;
      app.backupFilePickerForTesting = () async {
        pickerCalls++;
        return null;
      };
      LibraryRepository.backupPreparedAtAfterWriteForTesting = () async {
        preparationEntered.complete();
        await releasePreparation.future;
      };
      addTearDown(() {
        LibraryRepository.backupPreparedAtAfterWriteForTesting = null;
        app.backupFilePickerForTesting = null;
        if (!releasePreparation.isCompleted) {
          releasePreparation.complete();
        }
      });

      await tester.pumpWidget(
        MaterialApp(
          home: app.BackupPrivacyPage(repository: repository),
        ),
      );
      await tester.ensureVisible(find.text('Create backup'));
      await tester.tap(find.text('Create backup'));
      await tester.pump();
      await preparationEntered.future;
      await tester.pump();

      expect(find.text('Preparing…'), findsOneWidget);
      expect(find.text('Backup in progress…'), findsOneWidget);
      expect(
        tester
            .getSemantics(find.bySemanticsLabel('Backup in progress…'))
            .hasFlag(SemanticsFlag.isLiveRegion),
        isTrue,
      );
      final restoreAction = find.ancestor(
        of: find.text('Backup in progress…'),
        matching: find.byType(FilledButton),
      );
      expect(restoreAction, findsOneWidget);
      expect(tester.widget<FilledButton>(restoreAction).onPressed, isNull);

      // A second entry point must not start while the export owns the screen.
      await tester.tap(find.text('Backup in progress…'));
      await tester.pump();
      expect(pickerCalls, 0);
      expect(find.text('Choosing backup…'), findsNothing);

      LibraryRepository.backupPreparedAtAfterWriteForTesting = null;
      releasePreparation.complete();
      await tester.pumpAndSettle();

      expect(find.text('Preparing…'), findsNothing);
      final restoreActionAfterExport = find.ancestor(
        of: find.text('Choose backup file'),
        matching: find.byType(FilledButton),
      );
      expect(restoreActionAfterExport, findsOneWidget);
      expect(
        tester.widget<FilledButton>(restoreActionAfterExport).onPressed,
        isNotNull,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'disables backup export while the backup file picker is open',
    (tester) async {
      final semantics = tester.ensureSemantics();
      addTearDown(semantics.dispose);
      final pickerStarted = Completer<void>();
      final pendingPicker = Completer<PlatformFile?>();
      var preparationHookCalls = 0;
      app.backupFilePickerForTesting = () {
        pickerStarted.complete();
        return pendingPicker.future;
      };
      LibraryRepository.backupPreparedAtAfterWriteForTesting = () async {
        preparationHookCalls++;
      };
      addTearDown(() {
        app.backupFilePickerForTesting = null;
        LibraryRepository.backupPreparedAtAfterWriteForTesting = null;
        if (!pendingPicker.isCompleted) pendingPicker.complete(null);
      });

      await tester.pumpWidget(
        MaterialApp(
          home: app.BackupPrivacyPage(repository: repository),
        ),
      );
      await tester.ensureVisible(find.text('Choose backup file'));
      await tester.tap(find.text('Choose backup file'));
      await tester.pump();
      await pickerStarted.future;
      await tester.pump();

      expect(find.text('Choosing backup…'), findsOneWidget);
      expect(find.text('Backup selection in progress…'), findsOneWidget);
      expect(
        tester
            .getSemantics(
              find.bySemanticsLabel('Backup selection in progress…'),
            )
            .hasFlag(SemanticsFlag.isLiveRegion),
        isTrue,
      );
      final exportAction = find.ancestor(
        of: find.text('Backup selection in progress…'),
        matching: find.byType(FilledButton),
      );
      expect(exportAction, findsOneWidget);
      expect(tester.widget<FilledButton>(exportAction).onPressed, isNull);

      // Even a direct tap on the disabled-looking label must not start export.
      await tester.tap(find.text('Backup selection in progress…'));
      await tester.pump();
      expect(preparationHookCalls, 0);
      expect(find.text('Preparing…'), findsNothing);

      pendingPicker.complete(null);
      await tester.pumpAndSettle();

      expect(find.text('Choosing backup…'), findsNothing);
      expect(find.text('Backup selection in progress…'), findsNothing);
      final exportActionAfterCancel = find.ancestor(
        of: find.text('Create backup'),
        matching: find.byType(FilledButton),
      );
      expect(exportActionAfterCancel, findsOneWidget);
      expect(
        tester.widget<FilledButton>(exportActionAfterCancel).onPressed,
        isNotNull,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Backup & privacy shows backup preparation time without claiming destination save',
    (tester) async {
      final backupPage = () => MaterialApp(
            home: app.BackupPrivacyPage(repository: repository),
          );

      await tester.pumpWidget(backupPage());
      expect(find.text('Last backup prepared'), findsOneWidget);
      expect(find.text('Not prepared yet'), findsOneWidget);

      await repository.createBackup();
      final timestamp = repository.lastBackupPreparedAtMs;
      expect(timestamp, isNotNull);
      await tester.pumpWidget(backupPage());

      expect(find.text('Last backup prepared'), findsOneWidget);
      expect(find.text('Not prepared yet'), findsNothing);
      expect(
        find.textContaining(
          'This records when a backup file was generated, not whether the destination saved it.',
        ),
        findsOneWidget,
      );
      final localDate =
          DateTime.fromMillisecondsSinceEpoch(timestamp!).toLocal();
      final expectedDate = MaterialLocalizations.of(
        tester.element(find.text('Last backup prepared')),
      ).formatMediumDate(localDate);
      expect(find.textContaining(expectedDate), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Library and Search avoid layout exceptions at narrow width with large text', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await repository.save(
      const SavedItem(
        id: 'small-screen-long-title',
        kind: ItemKind.link,
        title: 'A deliberately long saved title for small screens',
        content: 'A longer summary that should wrap without breaking the card layout.',
        url: 'https://example.com/small-screen',
        tags: ['Responsive', 'Accessibility'],
        collection: null,
        isFavorite: false,
        createdAtMs: 1,
        updatedAtMs: 2,
      ),
    );

    Widget largeTextApp(Widget child) {
      return MaterialApp(
        builder: (context, appChild) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(2),
          ),
          child: appChild!,
        ),
        home: Scaffold(body: child),
      );
    }

    await tester.pumpWidget(
      largeTextApp(
        app.LibraryPage(
          repository: repository,
          onAdd: (_) {},
          onSearch: (_) {},
          onOpenItem: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      largeTextApp(
        app.SearchPage(
          repository: repository,
          initialQuery: 'small screens',
          onOpenItem: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('favorite star icon meets graphical contrast in both themes', (tester) async {
    late Color lightStar;
    late Color lightSurface;
    late Color lightCanvas;
    late Color darkStar;
    late Color darkSurface;
    late Color darkCanvas;
    late Color darkField;

    await tester.pumpWidget(
      MaterialApp(
        theme: app.buildLightTheme(),
        home: Builder(
          builder: (context) {
            lightStar = app.favoriteStarColor(context);
            lightSurface = Theme.of(context).colorScheme.surface;
            lightCanvas = Theme.of(context).scaffoldBackgroundColor;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: app.buildLightTheme(),
        darkTheme: app.buildDarkTheme(),
        themeMode: ThemeMode.dark,
        home: Builder(
          builder: (context) {
            darkStar = app.favoriteStarColor(context);
            darkSurface = Theme.of(context).colorScheme.surface;
            darkCanvas = Theme.of(context).scaffoldBackgroundColor;
            darkField = Theme.of(context).inputDecorationTheme.fillColor!;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(_contrastRatio(lightStar, Colors.white), greaterThanOrEqualTo(3));
    expect(_contrastRatio(lightStar, lightSurface), greaterThanOrEqualTo(3));
    expect(_contrastRatio(lightStar, lightCanvas), greaterThanOrEqualTo(3));
    expect(_contrastRatio(darkStar, darkSurface), greaterThanOrEqualTo(3));
    expect(_contrastRatio(darkStar, darkCanvas), greaterThanOrEqualTo(3));
    expect(_contrastRatio(darkStar, darkField), greaterThanOrEqualTo(3));
  });

  test('item-type labels and icons meet contrast on light and dark surfaces', () {
    const darkSurface = Color(0xFF202638);
    for (final kind in ItemKind.values) {
      expect(
        _contrastRatio(kind.readableTextAccent, Colors.white),
        greaterThanOrEqualTo(4.5),
        reason: '${kind.label} text must remain readable on a light surface.',
      );
      expect(
        _contrastRatio(kind.accent, Colors.white),
        greaterThanOrEqualTo(3),
        reason: '${kind.label} decorative icon must meet graphical contrast on light surfaces.',
      );
      expect(
        _contrastRatio(kind.readableTextAccent, kind.softAccent),
        greaterThanOrEqualTo(4.5),
        reason: '${kind.label} selected badge text must meet normal-text contrast.',
      );
      expect(
        _contrastRatio(kind.softAccent, darkSurface),
        greaterThanOrEqualTo(4.5),
        reason: '${kind.label} must remain readable when unselected on a dark surface.',
      );
    }
  });

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
    expect(
      _contrastRatio(muted, const Color(0xFFEEF0FF)),
      greaterThanOrEqualTo(4.5),
      reason: 'Muted chip labels must remain readable on the selected-chip fill.',
    );
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

  testWidgets('Backup page warns and confirms before partial export', (tester) async {
    await Hive.box<dynamic>('stashhive_items_v1').put(
      'unreadable-before-backup',
      <String, Object?>{
        'id': 'unreadable-before-backup',
        'kind': 'unknown-kind',
        'title': 'Unreadable legacy entry',
        'content': '',
        'tags': <String>[],
        'isFavorite': false,
        'createdAtMs': 1,
        'updatedAtMs': 2,
      },
    );
    await repository.save(
      const SavedItem(
        id: 'valid-before-backup',
        kind: ItemKind.link,
        title: 'Readable entry',
        content: '',
        url: 'https://example.com',
        tags: [],
        collection: null,
        isFavorite: false,
        createdAtMs: 1,
        updatedAtMs: 2,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: app.BackupPrivacyPage(repository: repository),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.skippedRecordCount.value, 1);
    expect(
      find.textContaining('Any backup will omit them'),
      findsOneWidget,
    );
    await tester.tap(find.text('Create backup'));
    await tester.pumpAndSettle();

    expect(find.text('This backup may be incomplete'), findsOneWidget);
    expect(
      find.textContaining('They will be omitted from this export'),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('This backup may be incomplete'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Library warns when malformed local records were skipped', (tester) async {
    await Hive.box<dynamic>('stashhive_items_v1').put(
      'unreadable-legacy-record',
      <String, Object?>{
        'id': 'unreadable-legacy-record',
        'kind': 'not-a-supported-kind',
        'title': 'Legacy record',
        'content': '',
        'tags': <String>[],
        'isFavorite': false,
        'createdAtMs': 1,
        'updatedAtMs': 2,
      },
    );
    await repository.save(
      const SavedItem(
        id: 'valid-after-corruption',
        kind: ItemKind.link,
        title: 'Valid saved link',
        content: '',
        url: 'https://example.com',
        tags: [],
        collection: null,
        isFavorite: false,
        createdAtMs: 1,
        updatedAtMs: 2,
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

    expect(repository.skippedRecordCount.value, 1);
    expect(find.textContaining('1 saved record could not be read.'), findsOneWidget);
    expect(
      find.textContaining('use a previous backup'),
      findsOneWidget,
      reason: 'The warning should tell the user how to recover skipped records.',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Library warning includes skipped legacy collection entries', (tester) async {
    await Hive.box<dynamic>('stashhive_preferences_v1').put(
      'collections',
      <Object?>['Research', 'research', '   '],
    );
    repository.dispose();
    repository = await LibraryRepository.openInitializedForTesting();

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

    expect(repository.skippedCollectionCount.value, 2);
    expect(
      find.textContaining('2 collection names or assignments were invalid'),
      findsOneWidget,
    );
    expect(
      find.textContaining('use a previous backup'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Backup confirms before omitting unexportable legacy items', (tester) async {
    const legacyId = 'unexportable-legacy-url-for-backup-dialog';
    final unsafeLegacyItem = SavedItem(
      id: legacyId,
      kind: ItemKind.link,
      title: 'Old unsafe link',
      content: '',
      url: 'javascript:alert(1)',
      tags: const [],
      collection: null,
      isFavorite: false,
      createdAtMs: 1,
      updatedAtMs: 2,
    );
    await Hive.box<dynamic>('stashhive_items_v1').put(
      legacyId,
      unsafeLegacyItem.toMap(),
    );
    await repository.save(
      const SavedItem(
        id: 'valid-next-to-unexportable',
        kind: ItemKind.link,
        title: 'Valid entry',
        content: '',
        url: 'https://example.com/valid',
        tags: [],
        collection: null,
        isFavorite: false,
        createdAtMs: 1,
        updatedAtMs: 3,
      ),
    );

    expect(repository.unexportableRecordCount, 1);
    await tester.pumpWidget(
      MaterialApp(
        home: app.BackupPrivacyPage(repository: repository),
      ),
    );
    await tester.pumpAndSettle();

    final exportButton = find.widgetWithText(FilledButton, 'Create backup');
    await tester.ensureVisible(exportButton);
    await tester.tap(exportButton);
    await tester.pumpAndSettle();

    expect(find.text('This backup may be incomplete'), findsOneWidget);
    expect(
      find.textContaining(
        '1 readable legacy item(s) cannot be represented within portable backup limits',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('This backup may be incomplete'), findsNothing);
    expect(repository.findById(legacyId), isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Backup page warns and asks before exporting skipped records and collections', (tester) async {
    await Hive.box<dynamic>('stashhive_items_v1').put(
      'unreadable-backup-warning-record',
      <String, Object?>{
        'id': 'unreadable-backup-warning-record',
        'kind': 'unsupported-legacy-kind',
        'title': 'Unreadable record',
        'content': '',
        'tags': <String>[],
        'isFavorite': false,
        'createdAtMs': 1,
        'updatedAtMs': 2,
      },
    );
    await Hive.box<dynamic>('stashhive_preferences_v1').put(
      'collections',
      <Object?>['Research', 'research', '   '],
    );
    repository.dispose();
    repository = await LibraryRepository.openInitializedForTesting();

    expect(repository.skippedRecordCount.value, 1);
    expect(repository.skippedCollectionCount.value, 2);

    await tester.pumpWidget(
      MaterialApp(
        home: app.BackupPrivacyPage(repository: repository),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('1 saved record(s) could not be read.'), findsOneWidget);
    expect(find.textContaining('2 collection names or assignments were invalid'), findsOneWidget);
    expect(find.textContaining('Move any item assignment that exceeds the cap'), findsOneWidget);

    final exportButton = find.widgetWithText(FilledButton, 'Create backup');
    await tester.ensureVisible(exportButton);
    await tester.tap(exportButton);
    await tester.pumpAndSettle();

    expect(find.text('This backup may be incomplete'), findsOneWidget);
    expect(
      find.textContaining('1 saved record(s) could not be read and will be omitted.'),
      findsOneWidget,
    );
    expect(
      find.textContaining('2 collection names or assignments were invalid'),
      findsOneWidget,
    );
    expect(find.textContaining('raw local entries will not be deleted'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('This backup may be incomplete'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Backup export blocks hidden collection assignments with repair guidance', (tester) async {
    await Hive.box<dynamic>('stashhive_preferences_v1').put(
      'collections',
      List<String>.generate(
        500,
        (index) => 'Portable collection $index',
      ),
    );
    final overflowItem = SavedItem(
      id: 'hidden-collection-assignment',
      kind: ItemKind.link,
      title: 'Assigned beyond the collection cap',
      content: '',
      url: 'https://example.com/overflow',
      tags: const [],
      collection: 'Unrepresented collection',
      isFavorite: false,
      createdAtMs: 1,
      updatedAtMs: 2,
    );
    await Hive.box<dynamic>('stashhive_items_v1')
        .put(overflowItem.id, overflowItem.toMap());
    repository.dispose();
    repository = await LibraryRepository.openInitializedForTesting();

    expect(repository.unrepresentedCollectionAssignmentCount, 1);

    await tester.pumpWidget(
      MaterialApp(
        home: app.BackupPrivacyPage(repository: repository),
      ),
    );
    await tester.pumpAndSettle();
    final exportButton = find.widgetWithText(FilledButton, 'Create backup');
    await tester.ensureVisible(exportButton);
    await tester.tap(exportButton);
    await tester.pumpAndSettle();

    expect(
      find.textContaining('1 saved item uses a collection name beyond the backup limit.'),
      findsOneWidget,
    );
    expect(
      find.textContaining('choose an available collection or No collection'),
      findsOneWidget,
    );
    expect(find.text('This backup may be incomplete'), findsNothing);
    expect(repository.findById(overflowItem.id), isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Quick Save attachment picker exposes a named accessible button', (tester) async {
    final semantics = tester.ensureSemantics();
    addTearDown(semantics.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: app.QuickSavePage(
          repository: repository,
          initialKind: ItemKind.image,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final picker = find.bySemanticsLabel('Choose an image');
    expect(picker, findsOneWidget);
    final node = tester.getSemantics(picker);
    expect(node.hasFlag(SemanticsFlag.isButton), isTrue);
    expect(node.hasAction(SemanticsAction.tap), isTrue);
    expect(node.getSemanticsData().hint, 'Select a file, up to 15 megabytes');

    const existingImage = SavedItem(
      id: 'existing-picker-image',
      kind: ItemKind.image,
      title: 'Existing image',
      content: '',
      tags: [],
      collection: null,
      isFavorite: false,
      createdAtMs: 1,
      updatedAtMs: 2,
      attachmentKey: 'existing-picker-image',
      attachmentName: 'reference.png',
      attachmentMimeType: 'image/png',
    );
    await repository.save(existingImage, attachmentBytes: const [1, 2, 3]);
    await tester.pumpWidget(
      MaterialApp(
        home: app.QuickSavePage(
          repository: repository,
          existingItem: existingImage,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final replacementPicker = find.bySemanticsLabel('reference.png');
    expect(replacementPicker, findsOneWidget);
    expect(
      tester.getSemantics(replacementPicker).getSemanticsData().hint,
      'Select a replacement file, up to 15 megabytes',
    );
  });

  testWidgets('Collection contents match assignments ignoring casing', (tester) async {
    repository.items.value = const [
      SavedItem(
        id: 'lowercase-collection-content',
        kind: ItemKind.link,
        title: 'Case-insensitive collection result',
        content: '',
        url: 'https://example.com/case',
        tags: [],
        collection: 'learning',
        isFavorite: false,
        createdAtMs: 1,
        updatedAtMs: 2,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: app.CollectionContentsPage(
          repository: repository,
          collection: 'Learning',
          onOpenItem: (_) {},
          onAdd: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Case-insensitive collection result'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('collection row counts legacy assignments case-insensitively', (tester) async {
    await repository.addCollection('Learning');
    repository.items.value = const [
      SavedItem(
        id: 'lowercase-collection-count',
        kind: ItemKind.link,
        title: 'Count this legacy item',
        content: '',
        url: 'https://example.com/collection-count',
        tags: [],
        collection: 'learning',
        isFavorite: false,
        createdAtMs: 1,
        updatedAtMs: 2,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: app.CollectionsPage(
            repository: repository,
            onOpenItem: (_) {},
            onAdd: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1 saved item'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Collection row actions have contextual tooltips', (tester) async {
    await repository.addCollection('Learning');
    await repository.save(
      const SavedItem(
        id: 'collection-tooltip-link',
        kind: ItemKind.link,
        title: 'Saved for learning',
        content: '',
        url: 'https://example.com/learning',
        tags: [],
        collection: 'Learning',
        isFavorite: false,
        createdAtMs: 1,
        updatedAtMs: 2,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: app.CollectionsPage(
            repository: repository,
            onOpenItem: (_) {},
            onAdd: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final actions = find.byTooltip('Actions for Learning collection');
    expect(actions, findsOneWidget);
    await tester.tap(actions);
    await tester.pumpAndSettle();
    expect(find.text('Rename'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
  });

  testWidgets('Collection deletion failure shows recovery feedback', (tester) async {
    await repository.addCollection('Learning');
    await repository.save(
      const SavedItem(
        id: 'collection-delete-failure',
        kind: ItemKind.link,
        title: 'Keep this item assigned',
        content: '',
        url: 'https://example.com/keep-collection',
        tags: [],
        collection: 'Learning',
        isFavorite: false,
        createdAtMs: 1,
        updatedAtMs: 2,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: app.CollectionsPage(
            repository: repository,
            onOpenItem: (_) {},
            onAdd: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    LibraryRepository.collectionBeforeItemWriteForTesting = (_) async {
      throw StateError('simulated collection delete failure');
    };
    try {
      await tester.tap(find.byTooltip('Actions for Learning collection'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete collection'));
      await tester.pumpAndSettle();
    } finally {
      LibraryRepository.collectionBeforeItemWriteForTesting = null;
    }

    expect(find.text('Could not delete the collection. Please try again.'), findsOneWidget);
    expect(find.textContaining('simulated collection delete failure'), findsNothing);
    expect(repository.collections.value, contains('Learning'));
    expect(repository.findById('collection-delete-failure')?.collection, 'Learning');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Item Details overflow menu has an accessible name', (tester) async {
    await repository.save(
      const SavedItem(
        id: 'details-menu-link',
        kind: ItemKind.link,
        title: 'Details action link',
        content: '',
        url: 'https://example.com/details',
        tags: [],
        collection: null,
        isFavorite: false,
        createdAtMs: 1,
        updatedAtMs: 2,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: app.ItemDetailsPage(
          repository: repository,
          itemId: 'details-menu-link',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Item actions'), findsOneWidget);
    await tester.tap(find.byTooltip('Item actions'));
    await tester.pumpAndSettle();
    expect(find.text('Edit item'), findsOneWidget);
    expect(find.text('Delete item'), findsOneWidget);
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

  testWidgets('Favorite update failure shows safe storage guidance', (tester) async {
    const item = SavedItem(
      id: 'favorite-write-failure',
      kind: ItemKind.link,
      title: 'Favorite write test',
      content: 'Useful note',
      url: 'https://example.com/favorite',
      tags: <String>[],
      collection: null,
      isFavorite: false,
      createdAtMs: 10,
      updatedAtMs: 11,
    );
    await repository.save(item);

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
    await tester.pumpAndSettle();

    LibraryRepository.saveAfterItemCommitForTesting = () async {
      throw StateError('simulated favorite storage diagnostic');
    };
    try {
      await tester.tap(find.byTooltip('Actions for Favorite write test'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add to favorites'));
      await tester.pumpAndSettle();
    } finally {
      LibraryRepository.saveAfterItemCommitForTesting = null;
    }

    expect(
      find.text(
        'Could not update this item. Check local storage and try again.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('simulated favorite storage diagnostic'), findsNothing);
    expect(repository.findById(item.id)?.isFavorite, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Item Details favorite update failure shows safe storage guidance',
    (tester) async {
      const item = SavedItem(
        id: 'details-favorite-write-failure',
        kind: ItemKind.link,
        title: 'Details favorite test',
        content: 'Useful note',
        url: 'https://example.com/details-favorite',
        tags: <String>[],
        collection: null,
        isFavorite: false,
        createdAtMs: 10,
        updatedAtMs: 11,
      );
      await repository.save(item);

      await tester.pumpWidget(
        MaterialApp(
          home: app.ItemDetailsPage(
            repository: repository,
            itemId: item.id,
          ),
        ),
      );
      await tester.pumpAndSettle();

      LibraryRepository.saveAfterItemCommitForTesting = () async {
        throw StateError('simulated details favorite storage diagnostic');
      };
      try {
        await tester.tap(find.text('Favorite'));
        await tester.pumpAndSettle();
      } finally {
        LibraryRepository.saveAfterItemCommitForTesting = null;
      }

      expect(
        find.text(
          'Could not update this item. Check local storage and try again.',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('Open Edit to review its saved details'),
        findsNothing,
      );
      expect(
        find.textContaining('simulated details favorite storage diagnostic'),
        findsNothing,
      );
      expect(repository.findById(item.id)?.isFavorite, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Item Details shows loading while attachment bytes await a save commit',
    (tester) async {
      const item = SavedItem(
        id: 'details-attachment-read-commit',
        kind: ItemKind.image,
        title: 'Image being replaced',
        content: '',
        tags: <String>[],
        collection: null,
        isFavorite: false,
        createdAtMs: 1,
        updatedAtMs: 2,
        attachmentKey: 'details-attachment-read-commit',
        attachmentName: 'sample.png',
        attachmentMimeType: 'image/png',
      );
      final originalBytes = Uint8List.fromList([1, 2, 3]);
      final replacementBytes = Uint8List.fromList([4, 5, 6]);
      await repository.save(item, attachmentBytes: originalBytes);

      final writeEntered = Completer<void>();
      final releaseWrite = Completer<void>();
      LibraryRepository.saveBeforeItemCommitForTesting = () async {
        writeEntered.complete();
        await releaseWrite.future;
      };
      final pendingSave = repository.save(
        item.copyWith(title: 'Replacement committed'),
        attachmentBytes: replacementBytes,
      );
      await writeEntered.future;

      try {
        await tester.pumpWidget(
          MaterialApp(
            home: app.ItemDetailsPage(
              repository: repository,
              itemId: item.id,
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Loading image…'), findsOneWidget);
        expect(find.text('The local image is missing.'), findsNothing);

        await tester.tap(find.text('View image'));
        await tester.pump();

        expect(
          find.text('Loading image…'),
          findsWidgets,
          reason: 'The page and image dialog should distinguish pending reads from missing bytes.',
        );
        expect(find.text('The local image is missing.'), findsNothing);
      } finally {
        if (!releaseWrite.isCompleted) releaseWrite.complete();
        try {
          await pendingSave;
        } finally {
          LibraryRepository.saveBeforeItemCommitForTesting = null;
        }
      }

      await tester.pumpAndSettle();
      expect(find.text('Loading image…'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'image thumbnails reuse their attachment read across parent rebuilds',
    (tester) async {
      const image = SavedItem(
        id: 'thumbnail-read-cache',
        kind: ItemKind.image,
        title: 'Thumbnail cache test',
        content: '',
        tags: <String>[],
        collection: null,
        isFavorite: false,
        createdAtMs: 1,
        updatedAtMs: 2,
        attachmentKey: 'thumbnail-read-cache',
        attachmentName: 'thumbnail.png',
        attachmentMimeType: 'image/png',
      );
      await repository.save(image, attachmentBytes: Uint8List.fromList([1, 2, 3]));

      var readCount = 0;
      LibraryRepository.readAttachmentBeforeReadForTesting = (_) async {
        readCount++;
      };

      try {
        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, rebuildParent) => app.LibraryPage(
                repository: repository,
                onAdd: (_) {},
                onSearch: (_) => rebuildParent(() {}),
                onOpenItem: (_) {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(readCount, 1);
        await tester.tap(find.bySemanticsLabel('Search your library'));
        await tester.pumpAndSettle();

        expect(
          readCount,
          1,
          reason: 'An unrelated parent rebuild should reuse the thumbnail future.',
        );
        expect(tester.takeException(), isNull);
      } finally {
        LibraryRepository.readAttachmentBeforeReadForTesting = null;
      }
    },
  );

  testWidgets('Item Details labels native attachment storage accurately', (tester) async {
    const item = SavedItem(
      id: 'attachment-storage-label',
      kind: ItemKind.image,
      title: 'Storage location sample',
      content: '',
      tags: [],
      collection: null,
      isFavorite: false,
      createdAtMs: 1,
      updatedAtMs: 2,
      attachmentKey: 'attachment-storage-label',
      attachmentName: 'sample.png',
      attachmentMimeType: 'image/png',
    );
    await repository.save(item, attachmentBytes: Uint8List.fromList([7, 8, 9]));
    await tester.pumpWidget(
      MaterialApp(
        home: app.ItemDetailsPage(repository: repository, itemId: item.id),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Stored inside StashHive on this device'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Search settings explain collection search and local scope', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: app.SettingsPage(
            repository: repository,
            darkMode: false,
            onDarkModeChanged: (_) {},
            textScaleMultiplier: repository.textScaleMultiplier,
            onTextScaleChanged: (_) {},
          ),
        ),
      ),
    );
    expect(find.text('What is searchable on this device'), findsOneWidget);
    await tester.tap(find.text('Search & saved content'));
    await tester.pumpAndSettle();
    expect(find.textContaining('collection names'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Item deletion failure keeps details open and reports an error', (tester) async {
    final bytes = Uint8List.fromList([1, 3, 3, 7]);
    const item = SavedItem(
      id: 'image-delete-failure',
      kind: ItemKind.image,
      title: 'Keep this image',
      content: '',
      tags: [],
      collection: null,
      isFavorite: false,
      createdAtMs: 1,
      updatedAtMs: 2,
      attachmentKey: 'image-delete-failure',
      attachmentName: 'reference.png',
      attachmentMimeType: 'image/png',
    );
    await repository.save(item, attachmentBytes: bytes);
    await tester.pumpWidget(
      MaterialApp(
        home: app.ItemDetailsPage(
          repository: repository,
          itemId: item.id,
        ),
      ),
    );
    await tester.pumpAndSettle();

    LibraryRepository.deleteAfterAttachmentDeleteForTesting = () async {
      throw StateError('simulated item delete failure');
    };
    try {
      await tester.tap(find.text('Delete saved item'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
    } finally {
      LibraryRepository.deleteAfterAttachmentDeleteForTesting = null;
    }

    expect(find.text('Item details'), findsOneWidget);
    expect(
      find.text('Could not delete this item. The item remains in your library. Please try again.'),
      findsOneWidget,
    );
    expect(find.textContaining('simulated item delete failure'), findsNothing);
    expect(repository.findById(item.id)?.title, item.title);
    expect(await repository.readAttachment(item.attachmentKey!), orderedEquals(bytes));
    expect(tester.takeException(), isNull);
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
  testWidgets('Search results support recency, oldest, and title sorting',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const items = <SavedItem>[
      SavedItem(
        id: 'search-sort-cedar',
        kind: ItemKind.link,
        title: 'Cedar',
        content: 'Cedar content',
        url: 'https://example.com/cedar',
        tags: [],
        collection: null,
        isFavorite: false,
        createdAtMs: 300,
        updatedAtMs: 300,
      ),
      SavedItem(
        id: 'search-sort-bravo',
        kind: ItemKind.link,
        title: 'Bravo',
        content: 'Bravo content',
        url: 'https://example.com/bravo',
        tags: [],
        collection: null,
        isFavorite: false,
        createdAtMs: 100,
        updatedAtMs: 200,
      ),
      SavedItem(
        id: 'search-sort-alpha',
        kind: ItemKind.link,
        title: 'Alpha',
        content: 'Alpha content',
        url: 'https://example.com/alpha',
        tags: [],
        collection: null,
        isFavorite: false,
        createdAtMs: 200,
        updatedAtMs: 100,
      ),
    ];
    for (final item in items) {
      await repository.save(item);
    }
    final metadataBefore = <String, List<Object>>{
      for (final saved in repository.items.value)
        saved.id: <Object>[
          saved.title,
          saved.createdAtMs,
          saved.updatedAtMs,
        ],
    };

    await tester.pumpWidget(
      MaterialApp(
        home: app.SearchPage(
          repository: repository,
          initialQuery: '',
          onOpenItem: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    double titleY(String title) => tester.getTopLeft(find.text(title)).dy;

    expect(titleY('Cedar'), lessThan(titleY('Bravo')));
    expect(titleY('Bravo'), lessThan(titleY('Alpha')));

    await tester.tap(find.byTooltip('Sort search results'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Title A–Z'));
    await tester.pumpAndSettle();

    expect(titleY('Alpha'), lessThan(titleY('Bravo')));
    expect(titleY('Bravo'), lessThan(titleY('Cedar')));

    await tester.tap(find.byTooltip('Sort search results'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Oldest first'));
    await tester.pumpAndSettle();

    expect(titleY('Bravo'), lessThan(titleY('Alpha')));
    expect(titleY('Alpha'), lessThan(titleY('Cedar')));

    await tester.tap(find.byTooltip('Sort search results'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Recently saved'));
    await tester.pumpAndSettle();

    expect(titleY('Cedar'), lessThan(titleY('Bravo')));
    expect(titleY('Bravo'), lessThan(titleY('Alpha')));

    final metadataAfter = <String, List<Object>>{
      for (final saved in repository.items.value)
        saved.id: <Object>[
          saved.title,
          saved.createdAtMs,
          saved.updatedAtMs,
        ],
    };
    expect(metadataAfter, metadataBefore);
  });



  testWidgets('Search hint lists all indexed metadata fields', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: app.SearchPage(
          repository: repository,
          initialQuery: '',
          onOpenItem: (_) {},
        ),
      ),
    );

    final searchField = find.byType(TextField).first;
    expect(
      tester.widget<TextField>(searchField).decoration?.hintText,
      'Search titles, URLs, notes, tags and collections',
    );
    expect(tester.takeException(), isNull);
  });


  testWidgets('rejects oversized search input before scanning saved items', (tester) async {
    const item = SavedItem(
      id: 'oversized-search-query-target',
      kind: ItemKind.note,
      title: 'Searchable target',
      content: 'This should not be scanned for an oversized query.',
      tags: <String>[],
      collection: null,
      isFavorite: false,
      createdAtMs: 100,
      updatedAtMs: 101,
    );
    await repository.save(item);
    final oversizedQuery = List<String>.filled(
      app.maxSearchQueryCharacters + 1,
      'x',
    ).join();

    await tester.pumpWidget(
      MaterialApp(
        home: app.SearchPage(
          repository: repository,
          initialQuery: oversizedQuery,
          onOpenItem: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Search text must be 4,096 characters or shorter.'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('0 results'), findsOneWidget);
    expect(find.text('Searchable target'), findsNothing);
    expect(find.text('No matches found'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Search empty state explains and clears an unmatched type filter', (
    tester,
  ) async {
    await repository.save(
      const SavedItem(
        id: 'search-filter-note',
        kind: ItemKind.note,
        title: 'Keep planning',
        content: 'Weekend ideas',
        tags: <String>[],
        collection: null,
        isFavorite: false,
        createdAtMs: 100,
        updatedAtMs: 101,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: app.SearchPage(
          repository: repository,
          initialQuery: '',
          onOpenItem: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Images'));
    await tester.pumpAndSettle();

    expect(find.text('No items in this filter'), findsOneWidget);
    expect(
      find.text(
        'Try another type or clear the filter to see all your saved items.',
      ),
      findsOneWidget,
    );
    expect(find.text('Clear filter'), findsOneWidget);

    await tester.tap(find.text('Clear filter'));
    await tester.pumpAndSettle();

    expect(find.text('No items in this filter'), findsNothing);
    expect(find.text('Keep planning'), findsOneWidget);
    expect(find.bySemanticsLabel('1 result'), findsOneWidget);

    // When a query and type filter both cause no results, the recovery action
    // must clear both controls so the saved item is reachable again.
    await tester.enterText(find.byType(TextField).first, 'missing phrase');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Images'));
    await tester.pumpAndSettle();

    expect(find.text('No matches found'), findsOneWidget);
    expect(find.text('Clear search and filter'), findsOneWidget);
    await tester.tap(find.text('Clear search and filter'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      isEmpty,
    );
    expect(find.text('Keep planning'), findsOneWidget);
    expect(find.bySemanticsLabel('1 result'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'retries an image preview after a transient attachment read failure',
    (tester) async {
      const item = SavedItem(
        id: 'details-image-preview-retry',
        kind: ItemKind.image,
        title: 'Preview retry sample',
        content: '',
        tags: <String>[],
        collection: null,
        isFavorite: false,
        createdAtMs: 10,
        updatedAtMs: 11,
        attachmentKey: 'details-image-preview-retry',
        attachmentName: 'sample.png',
        attachmentMimeType: 'image/png',
      );
      await repository.save(item, attachmentBytes: Uint8List.fromList([1, 2, 3]));

      var readAttempts = 0;
      LibraryRepository.readAttachmentBeforeReadForTesting = (_) async {
        readAttempts++;
        if (readAttempts == 1) {
          throw StateError('secret transient preview storage detail');
        }
      };
      addTearDown(() {
        LibraryRepository.readAttachmentBeforeReadForTesting = null;
      });

      await tester.pumpWidget(
        MaterialApp(
          home: app.ItemDetailsPage(
            repository: repository,
            itemId: item.id,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('View image'));
      await tester.pumpAndSettle();

      expect(find.text('Retry preview'), findsOneWidget);
      expect(
        tester
            .getSemantics(
              find.text(
                'Preview unavailable. The original attachment is still saved and can be shared.',
              ),
            )
            .hasFlag(SemanticsFlag.isLiveRegion),
        isTrue,
      );
      expect(
        find.textContaining('secret transient preview storage detail'),
        findsNothing,
      );

      await tester.tap(find.text('Retry preview'));
      await tester.pumpAndSettle();

      expect(readAttempts, 2);
      expect(find.text('Retry preview'), findsNothing);
      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Item Details reports attachment read failure without leaking storage details',
    (tester) async {
      final bytes = Uint8List.fromList([1, 2, 3, 4]);
      const item = SavedItem(
        id: 'details-attachment-read-failure',
        kind: ItemKind.document,
        title: 'Read failure document',
        content: '',
        tags: <String>[],
        collection: null,
        isFavorite: false,
        createdAtMs: 10,
        updatedAtMs: 11,
        attachmentKey: 'details-attachment-read-failure',
        attachmentName: 'report.pdf',
        attachmentMimeType: 'application/pdf',
      );
      await repository.save(item, attachmentBytes: bytes);

      await tester.pumpWidget(
        MaterialApp(
          home: app.ItemDetailsPage(
            repository: repository,
            itemId: item.id,
          ),
        ),
      );
      await tester.pumpAndSettle();

      LibraryRepository.readAttachmentBeforeReadForTesting = (_) async {
        throw StateError('secret local storage path');
      };
      try {
        await tester.tap(find.text('Open / share file'));
        await tester.pumpAndSettle();
      } finally {
        LibraryRepository.readAttachmentBeforeReadForTesting = null;
      }

      expect(
        find.text(
          'Could not read the saved file. Check local storage and try again.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('secret local storage path'), findsNothing);
      expect(repository.findById(item.id), isNotNull);
      expect(
        await repository.readAttachment(item.attachmentKey!),
        orderedEquals(bytes),
      );
      expect(tester.takeException(), isNull);
    },
  );

}
