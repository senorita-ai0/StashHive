import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:stashhive/data/library_repository.dart';
import 'package:stashhive/main.dart' as app;
import 'package:stashhive/models/saved_item.dart';
import 'package:stashhive/services/mime_types.dart';

SavedItem _item(ItemKind kind, {String? attachmentName}) => SavedItem(
      id: 'badge-${kind.name}',
      kind: kind,
      title: 'Badge test ${kind.name}',
      content: '',
      tags: const <String>[],
      isFavorite: false,
      createdAtMs: 1,
      updatedAtMs: 2,
      attachmentName: attachmentName,
    );

void main() {
  group('fileExtensionBadge', () {
    test('returns an uppercase extension', () {
      expect(fileExtensionBadge('report.pdf'), 'PDF');
      expect(fileExtensionBadge('Notes.Final.docx'), 'DOCX');
      expect(fileExtensionBadge(r'C:\files\sheet.csv'), 'CSV');
      expect(fileExtensionBadge('folder/readme.txt'), 'TXT');
    });

    test('returns null when there is no usable extension', () {
      expect(fileExtensionBadge(null), isNull);
      expect(fileExtensionBadge(''), isNull);
      expect(fileExtensionBadge('README'), isNull);
      expect(fileExtensionBadge('.hidden'), isNull);
      expect(fileExtensionBadge('trailingdot.'), isNull);
      expect(fileExtensionBadge('archive.toolongext'), isNull);
      expect(fileExtensionBadge('weird.p d'), isNull);
    });

    test('never returns any part of the file name', () {
      expect(fileExtensionBadge('private-tax-return.pdf'), isNot(contains('TAX')));
    });
  });

  group('document thumbnail badge', () {
    late Directory directory;
    late LibraryRepository repository;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('stashhive_badge_');
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

    testWidgets('document with an extension shows its type label',
        (tester) async {
      await pumpTile(tester, _item(ItemKind.document, attachmentName: 'q3.pdf'));
      expect(find.text('PDF'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('document without an extension shows no badge',
        (tester) async {
      await pumpTile(tester, _item(ItemKind.document, attachmentName: 'q3'));
      expect(find.text('PDF'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('non-document items never show a badge', (tester) async {
      await pumpTile(tester, _item(ItemKind.note, attachmentName: 'x.pdf'));
      expect(find.text('PDF'), findsNothing);
    });

    testWidgets('badge fits with large text scaling', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: app.buildLightTheme(),
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Scaffold(
              body: app.SavedItemTile(
                item: _item(ItemKind.document, attachmentName: 'a.docx'),
                repository: repository,
                onTap: () {},
              ),
            ),
          ),
        ),
      );
      expect(find.text('DOCX'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
