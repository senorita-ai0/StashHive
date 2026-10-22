import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:stashhive/data/library_repository.dart';
import 'package:stashhive/main.dart' as app;
import 'package:stashhive/models/saved_item.dart';

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
                Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
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
                Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
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
          app.maxSavedItemUrlCharacters,
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
