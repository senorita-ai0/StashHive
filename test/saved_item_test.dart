import 'package:flutter_test/flutter_test.dart';
import 'package:stashhive/models/saved_item.dart';

SavedItem makeItem({
  ItemKind kind = ItemKind.link,
  String title = 'Flutter docs',
  String? url = 'https://flutter.dev',
  String content = 'A useful page',
  List<String> tags = const ['Flutter', 'Reading'],
  String? collection = 'Learning',
  String? attachmentKey,
}) {
  return SavedItem(
    id: 'item-1',
    kind: kind,
    title: title,
    content: content,
    url: url,
    tags: tags,
    collection: collection,
    isFavorite: false,
    createdAtMs: 1000,
    updatedAtMs: 2000,
    attachmentKey: attachmentKey,
    attachmentName: attachmentKey == null ? null : 'sample.png',
    attachmentMimeType: attachmentKey == null ? null : 'image/png',
  );
}

void main() {
  group('SavedItem', () {
    test('serializes and deserializes without losing saved metadata', () {
      final original = makeItem();
      final restored = SavedItem.fromMap(original.toMap());

      expect(restored.id, original.id);
      expect(restored.kind, ItemKind.link);
      expect(restored.title, original.title);
      expect(restored.url, original.url);
      expect(restored.tags, original.tags);
      expect(restored.collection, original.collection);
      expect(restored.createdAtMs, original.createdAtMs);
    });

    test('searches titles, URLs, notes, tags and collections case-insensitively', () {
      final item = makeItem(content: 'Research local storage');
      expect(item.matchesQuery('FLUTTER'), isTrue);
      expect(item.matchesQuery('flutter.dev'), isTrue);
      expect(item.matchesQuery('LOCAL STORAGE'), isTrue);
      expect(item.matchesQuery('reading'), isTrue);
      expect(item.matchesQuery('learning'), isTrue);
      expect(item.matchesQuery('not present'), isFalse);
      expect(item.matchesQuery('  '), isTrue);
    });

    test('preserves Unicode text in note content and search', () {
      final item = makeItem(
        kind: ItemKind.note,
        title: 'Urdu note',
        url: null,
        content: 'قابلِ تلاش متن — Roman Urdu: mera khayal',
        tags: const ['اردو', 'Roman Urdu'],
        collection: null,
      );
      final restored = SavedItem.fromMap(item.toMap());

      expect(restored.content, contains('قابلِ تلاش متن'));
      expect(restored.matchesQuery('roman urdu'), isTrue);
      expect(restored.matchesQuery('اردو'), isTrue);
    });

    test('clears optional references explicitly through copyWith', () {
      final updated = makeItem(attachmentKey: 'local-file').copyWith(
        clearCollection: true,
        clearUrl: true,
        clearAttachment: true,
      );

      expect(updated.collection, isNull);
      expect(updated.url, isNull);
      expect(updated.attachmentKey, isNull);
      expect(updated.attachmentName, isNull);
    });
  });
}
