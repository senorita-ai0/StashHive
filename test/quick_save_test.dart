import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:stashhive/data/library_repository.dart';
import 'package:stashhive/main.dart' as app;
import 'package:stashhive/models/saved_item.dart';
import 'package:stashhive/services/share_intake.dart';

late Directory testDirectory;
late LibraryRepository repository;

SavedItem buildImage({
  required String id,
  required String attachmentKey,
}) {
  return SavedItem(
    id: id,
    kind: ItemKind.image,
    title: 'Shared reference',
    content: '',
    tags: const ['Reference'],
    collection: null,
    isFavorite: false,
    createdAtMs: 1000,
    updatedAtMs: 2000,
    attachmentKey: attachmentKey,
    attachmentName: 'reference.png',
    attachmentMimeType: 'image/png',
  );
}

Future<void> openEditor(WidgetTester tester, SavedItem item) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              key: const ValueKey('open-editor'),
              onPressed: () {
                Navigator.of(context).push<bool>(
                  MaterialPageRoute<bool>(
                    builder: (_) => app.QuickSavePage(
                      repository: repository,
                      existingItem: item,
                    ),
                  ),
                );
              },
              child: const Text('Open editor'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.byKey(const ValueKey('open-editor')));
  await tester.pumpAndSettle();
}

Future<void> openNewLink(
  WidgetTester tester, {
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      ),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              key: const ValueKey('open-new-link'),
              onPressed: () {
                Navigator.of(context).push<bool>(
                  MaterialPageRoute<bool>(
                    builder: (_) => app.QuickSavePage(
                      repository: repository,
                      initialKind: ItemKind.link,
                    ),
                  ),
                );
              },
              child: const Text('Add link'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.byKey(const ValueKey('open-new-link')));
  await tester.pumpAndSettle();
}

Future<void> openNewKind(WidgetTester tester, ItemKind kind) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              key: const ValueKey('open-new-kind'),
              onPressed: () {
                Navigator.of(context).push<bool>(
                  MaterialPageRoute<bool>(
                    builder: (_) => app.QuickSavePage(
                      repository: repository,
                      initialKind: kind,
                    ),
                  ),
                );
              },
              child: Text('Open ${kind.label} draft'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.byKey(const ValueKey('open-new-kind')));
  await tester.pumpAndSettle();
}

final class _DelayedPlatformFile extends PlatformFile {
  _DelayedPlatformFile(this._name);

  final String _name;

  @override
  String get name => _name;

  var lengthCalls = 0;

  @override
  Future<int> length() async {
    lengthCalls++;
    return 1;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() async {
    testDirectory =
        await Directory.systemTemp.createTemp('stashhive_quick_save_test_');
    Hive.init(testDirectory.path);
    repository = await LibraryRepository.openInitializedForTesting();
  });

  tearDown(() async {
    repository.dispose();
    await Hive.close();
    await testDirectory.delete(recursive: true);
  });

  testWidgets(
    'invalidates a picker result after switching away and back to its original type',
    (tester) async {
      final semantics = tester.ensureSemantics();
      addTearDown(semantics.dispose);
      final pickerStarted = Completer<ItemKind>();
      final pendingPicker = Completer<PlatformFile?>();
      final delayedFile = _DelayedPlatformFile('stale-image.png');
      app.quickSaveAttachmentPickerForTesting = (kind) {
        pickerStarted.complete(kind);
        return pendingPicker.future;
      };
      addTearDown(() {
        app.quickSaveAttachmentPickerForTesting = null;
      });

      await openNewKind(tester, ItemKind.image);
      await tester.ensureVisible(find.text('Choose an image'));
      await tester.tap(find.text('Choose an image'));
      await tester.pump();
      expect(await pickerStarted.future, ItemKind.image);

      tester.getSemantics(find.bySemanticsLabel('Document'))
          .performAction(SemanticsAction.tap);
      await tester.pumpAndSettle();
      tester.getSemantics(find.bySemanticsLabel('Image'))
          .performAction(SemanticsAction.tap);
      await tester.pumpAndSettle();

      pendingPicker.complete(delayedFile);
      await tester.pumpAndSettle();

      expect(
        delayedFile.lengthCalls,
        0,
        reason: 'Switching back must not revive an earlier picker request.',
      );
      expect(find.text('Choose an image'), findsOneWidget);
      await tester.ensureVisible(find.text('Save to StashHive'));
      await tester.tap(find.text('Save to StashHive'));
      await tester.pumpAndSettle();

      expect(find.text('Choose a file before saving.'), findsOneWidget);
      expect(repository.items.value, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'discards a delayed file selection after the draft type changes',
    (tester) async {
      final semantics = tester.ensureSemantics();
      addTearDown(semantics.dispose);
      final pickerStarted = Completer<ItemKind>();
      final pendingPicker = Completer<PlatformFile?>();
      final delayedFile = _DelayedPlatformFile('stale-image.png');
      app.quickSaveAttachmentPickerForTesting = (kind) {
        pickerStarted.complete(kind);
        return pendingPicker.future;
      };
      addTearDown(() {
        app.quickSaveAttachmentPickerForTesting = null;
      });

      await openNewKind(tester, ItemKind.image);
      await tester.ensureVisible(find.text('Choose an image'));
      await tester.tap(find.text('Choose an image'));
      await tester.pump();

      expect(await pickerStarted.future, ItemKind.image);

      tester.getSemantics(find.bySemanticsLabel('Document'))
          .performAction(SemanticsAction.tap);
      await tester.pumpAndSettle();

      pendingPicker.complete(delayedFile);
      await tester.pumpAndSettle();

      expect(
        delayedFile.lengthCalls,
        0,
        reason: 'A stale picker result must be discarded before file IO.',
      );
      expect(find.text('Choose a document'), findsOneWidget);

      await tester.ensureVisible(find.text('Save to StashHive'));
      await tester.tap(find.text('Save to StashHive'));
      await tester.pumpAndSettle();

      expect(find.text('Choose a file before saving.'), findsOneWidget);
      expect(repository.items.value, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('locks Quick Save controls while an item is being saved', (tester) async {
    final semantics = tester.ensureSemantics();
    addTearDown(semantics.dispose);
    await openNewLink(tester);
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'https://example.com/safe-draft',
    );
    await tester.enterText(
      find.byType(TextFormField).at(2),
      'Keep the snapshot consistent.',
    );

    final saveHookEntered = Completer<void>();
    final releaseSaveHook = Completer<void>();
    LibraryRepository.saveAfterItemCommitForTesting = () async {
      saveHookEntered.complete();
      await releaseSaveHook.future;
    };

    try {
      await tester.ensureVisible(find.text('Save to StashHive'));
      await tester.tap(find.text('Save to StashHive'));
      await tester.pump();
      await saveHookEntered.future;
      await tester.pump();

      expect(find.text('Saving…'), findsOneWidget);
      expect(
        tester.widgetList<TextFormField>(find.byType(TextFormField))
            .every((field) => field.enabled == false),
        isTrue,
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Note'))
            .hasAction(SemanticsAction.tap),
        isFalse,
      );
      final backButton = tester.widget<IconButton>(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.byType(IconButton),
        ).first,
      );
      expect(backButton.onPressed, isNull);

      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(
        find.text('Saving…'),
        findsOneWidget,
        reason: 'A system back action must not dismiss an in-progress save.',
      );
    } finally {
      if (!releaseSaveHook.isCompleted) releaseSaveHook.complete();
      LibraryRepository.saveAfterItemCommitForTesting = null;
    }

    await tester.pumpAndSettle();
    expect(repository.items.value, hasLength(1));
    expect(repository.items.value.single.kind, ItemKind.link);
    expect(repository.items.value.single.url, 'https://example.com/safe-draft');
    expect(
      repository.items.value.single.content,
      'Keep the snapshot consistent.',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'unlocks Quick Save and preserves the draft after a delayed save failure',
    (tester) async {
      await openNewLink(tester);
      const url = 'https://example.com/retry-safe-draft';
      const note = 'Keep this content available for retry.';
      await tester.enterText(find.byType(TextFormField).at(0), url);
      await tester.enterText(find.byType(TextFormField).at(2), note);

      final writeEntered = Completer<void>();
      final releaseFailure = Completer<void>();
      LibraryRepository.saveAfterItemCommitForTesting = () async {
        writeEntered.complete();
        await releaseFailure.future;
        LibraryRepository.saveAfterItemCommitForTesting = null;
        throw StateError('simulated delayed save failure');
      };

      try {
        await tester.ensureVisible(find.text('Save to StashHive'));
        await tester.tap(find.text('Save to StashHive'));
        await tester.pump();
        await writeEntered.future;
        await tester.pump();

        expect(find.text('Saving…'), findsOneWidget);
        expect(
          tester.widgetList<TextFormField>(find.byType(TextFormField))
              .every((field) => field.enabled == false),
          isTrue,
        );
        expect(repository.items.value, isEmpty);
      } finally {
        if (!releaseFailure.isCompleted) releaseFailure.complete();
      }

      await tester.pumpAndSettle();
      expect(repository.items.value, isEmpty);
      expect(
        tester.widgetList<TextFormField>(find.byType(TextFormField))
            .every((field) => field.enabled == true),
        isTrue,
      );
      expect(
        tester.widget<TextFormField>(find.byType(TextFormField).at(0))
            .controller!.text,
        url,
      );
      expect(
        tester.widget<TextFormField>(find.byType(TextFormField).at(2))
            .controller!.text,
        note,
      );
      expect(find.text('Save to StashHive'), findsOneWidget);

      await tester.ensureVisible(find.text('Save to StashHive'));
      await tester.tap(find.text('Save to StashHive'));
      await tester.pumpAndSettle();

      expect(repository.items.value, hasLength(1));
      expect(repository.items.value.single.url, url);
      expect(repository.items.value.single.content, note);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('item-kind options wrap for enlarged text', (tester) async {
    await openNewLink(tester, textScale: 2);
    final linkChoice = find.bySemanticsLabel('Link');
    final noteChoice = find.bySemanticsLabel('Note');
    final imageChoice = find.bySemanticsLabel('Image');
    final documentChoice = find.bySemanticsLabel('Document');

    expect(linkChoice, findsOneWidget);
    expect(noteChoice, findsOneWidget);
    expect(imageChoice, findsOneWidget);
    expect(documentChoice, findsOneWidget);
    expect(
      tester.getTopLeft(imageChoice).dy,
      greaterThan(tester.getTopLeft(noteChoice).dy),
      reason: 'The image/document options should wrap below the first row.',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('item-kind choices expose selected state semantically', (tester) async {
    final semantics = tester.ensureSemantics();
    addTearDown(semantics.dispose);

    await openNewLink(tester);
    final linkChoice = find.bySemanticsLabel('Link');
    final noteChoice = find.bySemanticsLabel('Note');

    expect(linkChoice, findsOneWidget);
    expect(noteChoice, findsOneWidget);
    expect(tester.getSemantics(linkChoice).hasAction(SemanticsAction.tap), isTrue);
    expect(tester.getSemantics(linkChoice).hasFlag(SemanticsFlag.isButton), isTrue);
    expect(tester.getSemantics(linkChoice).hasFlag(SemanticsFlag.isSelected), isTrue);
    expect(tester.getSemantics(noteChoice).hasFlag(SemanticsFlag.isSelected), isFalse);

    tester.getSemantics(noteChoice).performAction(SemanticsAction.tap);
    await tester.pumpAndSettle();

    expect(tester.getSemantics(noteChoice).hasFlag(SemanticsFlag.isSelected), isTrue);
    expect(tester.getSemantics(linkChoice).hasFlag(SemanticsFlag.isSelected), isFalse);
  });

  testWidgets('reselecting a shared image kind keeps its attachment', (tester) async {
    final semantics = tester.ensureSemantics();
    addTearDown(semantics.dispose);
    final bytes = Uint8List.fromList([4, 8, 15, 16, 23, 42]);
    final share = IncomingShare(
      kind: ItemKind.image,
      title: 'Shared image draft',
      bytes: bytes,
      fileName: 'shared.png',
      mimeType: 'image/png',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                key: const ValueKey('open-shared-image'),
                onPressed: () {
                  Navigator.of(context).push<bool>(
                    MaterialPageRoute<bool>(
                      builder: (_) => app.QuickSavePage(
                        repository: repository,
                        initialShare: share,
                      ),
                    ),
                  );
                },
                child: const Text('Open shared image'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('open-shared-image')));
    await tester.pumpAndSettle();

    tester.getSemantics(find.bySemanticsLabel('Image'))
        .performAction(SemanticsAction.tap);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save to StashHive'));
    await tester.tap(find.text('Save to StashHive'));
    await tester.pumpAndSettle();

    expect(repository.items.value, hasLength(1));
    expect(repository.items.value.single.kind, ItemKind.image);
    expect(repository.items.value.single.attachmentName, 'shared.png');
    expect(
      await repository.readAttachment(
        repository.items.value.single.attachmentKey!,
      ),
      orderedEquals(bytes),
    );
  });

  testWidgets('changing item kind preserves shared note content', (tester) async {
    final semantics = tester.ensureSemantics();
    addTearDown(semantics.dispose);
    await openNewLink(tester);

    final noteChoice = find.bySemanticsLabel('Note');
    final linkChoice = find.bySemanticsLabel('Link');
    tester.getSemantics(noteChoice).performAction(SemanticsAction.tap);
    await tester.pumpAndSettle();

    final noteContent = find.byType(TextFormField).at(1);
    await tester.enterText(noteContent, 'Keep this note while changing types.');

    tester.getSemantics(linkChoice).performAction(SemanticsAction.tap);
    await tester.pumpAndSettle();
    tester.getSemantics(noteChoice).performAction(SemanticsAction.tap);
    await tester.pumpAndSettle();

    expect(
      tester.widget<TextFormField>(find.byType(TextFormField).at(1))
          .controller!
          .text,
      'Keep this note while changing types.',
    );
    expect(repository.items.value, isEmpty);
  });

  testWidgets('normalizes uppercase URL schemes before saving', (tester) async {
    await openNewLink(tester);
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'HTTPS://EXAMPLE.COM/Guide',
    );
    await tester.ensureVisible(find.text('Save to StashHive'));
    await tester.tap(find.text('Save to StashHive'));
    await tester.pumpAndSettle();

    expect(repository.items.value, hasLength(1));
    expect(Uri.parse(repository.items.value.single.url!).scheme, 'https');
  });

  testWidgets('shows an inline error for overlong URLs', (tester) async {
    await openNewLink(tester);
    final url = 'https://example.com/' +
        List<String>.filled(
          maxSavedItemUrlCharacters,
          'a',
        ).join();
    await tester.enterText(find.byType(TextFormField).at(0), url);
    await tester.ensureVisible(find.text('Save to StashHive'));
    await tester.tap(find.text('Save to StashHive'));
    await tester.pumpAndSettle();

    expect(
      find.text('Website URLs must be 4,096 characters or shorter.'),
      findsOneWidget,
    );
    expect(repository.items.value, isEmpty);
  });

  testWidgets('rejects an explicit non-web scheme in URL input', (tester) async {
    await openNewLink(tester);
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'javascript:alert(1)',
    );
    await tester.ensureVisible(find.text('Save to StashHive'));
    await tester.tap(find.text('Save to StashHive'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid http or https URL.'), findsOneWidget);
    expect(repository.items.value, isEmpty);
  });

  testWidgets('shows a clear error when too many tags are entered', (tester) async {
    await openNewLink(tester);
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'https://example.com/',
    );
    await tester.enterText(
      find.byType(TextFormField).at(3),
      List<String>.generate(101, (index) => 'tag$index').join(', '),
    );
    await tester.ensureVisible(find.text('Save to StashHive'));
    await tester.tap(find.text('Save to StashHive'));
    await tester.pumpAndSettle();

    expect(find.text('Use 100 tags or fewer for each saved item.'), findsOneWidget);
    expect(repository.items.value, isEmpty);
  });

  testWidgets('shows a clear error when a tag exceeds 100 characters', (tester) async {
    await openNewLink(tester);
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'https://example.com/',
    );
    await tester.enterText(
      find.byType(TextFormField).at(3),
      List<String>.filled(101, 'x').join(),
    );
    await tester.ensureVisible(find.text('Save to StashHive'));
    await tester.tap(find.text('Save to StashHive'));
    await tester.pumpAndSettle();

    expect(find.text('Tags must be 100 characters or shorter.'), findsOneWidget);
    expect(repository.items.value, isEmpty);
  });

  testWidgets('metadata-only edit preserves a shared attachment key', (tester) async {
    const sharedKey = 'shared-reference-bytes';
    final bytes = Uint8List.fromList([8, 6, 7, 5, 3, 0, 9]);
    final owner = buildImage(id: 'owner-image', attachmentKey: sharedKey);
    final edited = buildImage(id: 'edited-image', attachmentKey: sharedKey);
    await repository.save(owner, attachmentBytes: bytes);
    await repository.save(edited);

    await openEditor(tester, edited);
    await tester.ensureVisible(find.text('Save changes'));
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(repository.findById(edited.id)?.attachmentKey, sharedKey);
    expect(
      await repository.readAttachment(sharedKey),
      orderedEquals(bytes),
    );
    expect(repository.findById(edited.id)?.title, edited.title);
  });


}
