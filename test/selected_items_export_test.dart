import 'package:flutter_test/flutter_test.dart';
import 'package:stashhive/models/saved_item.dart';
import 'package:stashhive/services/selected_items_export.dart';

SavedItem makeExportItem({
  String id = 'one',
  String title = 'Saved article',
  String? url = 'https://example.com/article',
  String content = 'Useful notes',
  List<String> tags = const <String>['Reading'],
  String? collection = 'Learning',
  bool favorite = true,
  ReadingStatus readingStatus = ReadingStatus.unread,
  int readingProgress = 0,
  String? attachmentName,
}) =>
    SavedItem(
      id: id,
      kind: attachmentName == null ? ItemKind.link : ItemKind.document,
      title: title,
      content: content,
      url: url,
      tags: tags,
      collection: collection,
      isFavorite: favorite,
      readingStatus: readingStatus,
      readingProgress: readingProgress,
      createdAtMs: 1000,
      updatedAtMs: 1000,
      attachmentKey: attachmentName == null ? null : 'attachment-$id',
      attachmentName: attachmentName,
      attachmentMimeType: attachmentName == null ? null : 'application/pdf',
    );

void main() {
  group('buildSelectedItemsMarkdown', () {
    test('exports selected metadata and user text without attachment bytes', () {
      final markdown = buildSelectedItemsMarkdown(<SavedItem>[
        makeExportItem(
          title: 'A title\ncontinued',
          readingStatus: ReadingStatus.inProgress,
          readingProgress: 45,
          attachmentName: 'guide.pdf',
          url: null,
        ),
      ]);

      expect(markdown, contains('# StashHive selected items'));
      expect(markdown, contains('## A title continued'));
      expect(markdown, contains('- Type: Document'));
      expect(markdown, contains('- Collection: Learning'));
      expect(markdown, contains('- Tags: Reading'));
      expect(markdown, contains('- Favorite: yes'));
      expect(markdown, contains('- Reading status: In progress'));
      expect(markdown, contains('- Reading progress: 45%'));
      expect(markdown, contains('- Attachment: guide.pdf'));
      expect(markdown, contains('Useful notes'));
      expect(markdown, isNot(contains('attachment-one')));
    });

    test('exports quotes and notes as Markdown blockquotes', () {
      final markdown = buildSelectedItemsMarkdown(<SavedItem>[
        makeExportItem().copyWith(
          annotations: <SavedAnnotation>[
            SavedAnnotation(
              id: 'annotation-1',
              quote: 'A copied passage\ncontinues here.',
              note: 'Review this claim later.',
              createdAtMs: 2000,
            ),
          ],
        ),
      ]);

      expect(markdown, contains('### Highlights & annotations'));
      expect(markdown, contains('> A copied passage'));
      expect(markdown, contains('> continues here.'));
      expect(markdown, contains('**Note:**'));
      expect(markdown, contains('> Review this claim later.'));
    });

    test('rejects empty selections and oversized item counts', () {
      expect(
        () => buildSelectedItemsMarkdown(const <SavedItem>[]),
        throwsFormatException,
      );
      final items = List<SavedItem>.generate(
        maxSelectedMarkdownExportItems + 1,
        (index) => makeExportItem(id: 'item-$index', content: '', tags: const []),
      );
      expect(() => buildSelectedItemsMarkdown(items), throwsFormatException);
    });

    test('bounds the generated export size', () {
      final huge = makeExportItem(
        content: List<String>.filled(1000000, 'x').join(),
      );
      expect(
        () => buildSelectedItemsMarkdown(<SavedItem>[huge, huge, huge]),
        throwsFormatException,
      );
    });
  });
}
