import 'package:flutter_test/flutter_test.dart';
import 'package:stashhive/models/saved_item.dart';
import 'package:stashhive/services/library_csv_export.dart';

SavedItem csvItem({
  String id = 'one',
  String title = 'Saved article',
  String content = 'line one\nline two',
  String? url = 'https://example.com/?a=1&b=2',
  List<String> tags = const <String>['Reading', 'Research'],
  String? collection = 'Learning',
  bool favorite = true,
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
      createdAtMs: 1000,
      updatedAtMs: 2000,
      attachmentKey: attachmentName == null ? null : 'attachment-$id',
      attachmentName: attachmentName,
      attachmentMimeType: attachmentName == null ? null : 'application/pdf',
    );

void main() {
  group('buildLibraryCsv', () {
    test('escapes commas, quotes and newlines and includes library metadata', () {
      final csv = buildLibraryCsv(<SavedItem>[
        csvItem(title: 'A "quoted", title'),
      ]);
      expect(csv.split('\n').first, contains('is_favorite'));
      expect(csv, contains('"A ""quoted"", title"'));
      expect(csv, contains('"line one\nline two"'));
      expect(csv, contains('https://example.com/?a=1&b=2'));
      expect(csv, contains('Reading|Research'));
      expect(csv, contains('Learning'));
      expect(csv, contains(',true,1000,2000,'));
    });

    test('rejects oversized item counts and generated output', () {
      final tooMany = List<SavedItem>.generate(
        maxLibraryCsvItems + 1,
        (index) => csvItem(id: 'item-$index', content: '', tags: const []),
      );
      expect(() => buildLibraryCsv(tooMany), throwsFormatException);

      final huge = csvItem(content: List<String>.filled(1000000, 'x').join());
      expect(
        () => buildLibraryCsv(<SavedItem>[huge, huge, huge, huge, huge, huge]),
        throwsFormatException,
      );
    });

    test('does not include attachment bytes or keys', () {
      final csv = buildLibraryCsv(<SavedItem>[
        csvItem(attachmentName: 'guide.pdf', url: null, content: ''),
      ]);
      expect(csv, contains('guide.pdf'));
      expect(csv, isNot(contains('attachment-one')));
    });
  });
}
