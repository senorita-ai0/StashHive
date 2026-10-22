import 'package:flutter_test/flutter_test.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:stashhive/models/saved_item.dart';
import 'package:stashhive/services/share_intake.dart';

void main() {
  group('ShareIntake', () {
    test('normalizes a shared URL into an editable link draft', () async {
      final result = await ShareIntake.fromSharedMedia(
        SharedMediaFile(
          path: 'https://example.com/guide',
          type: SharedMediaType.url,
          mimeType: 'text/uri-list',
        ),
      );

      expect(result, isNotNull);
      expect(result!.kind, ItemKind.link);
      expect(result.url, 'https://example.com/guide');
      expect(result.title, 'example.com');
    });

    test('trims wrapping punctuation but retains balanced URL parentheses', () async {
      final wrapped = await ShareIntake.fromSharedMedia(
        SharedMediaFile(
          path: 'Read this (https://example.com/articles/readme_(v2)).',
          type: SharedMediaType.text,
          mimeType: 'text/plain',
        ),
      );
      final standalone = await ShareIntake.fromSharedMedia(
        SharedMediaFile(
          path: 'https://en.wikipedia.org/wiki/Function_(mathematics)',
          type: SharedMediaType.text,
          mimeType: 'text/plain',
        ),
      );

      expect(wrapped?.url, 'https://example.com/articles/readme_(v2)');
      expect(
        standalone?.url,
        'https://en.wikipedia.org/wiki/Function_(mathematics)',
      );
    });
    test('trims sentence punctuation from a standalone shared URL', () async {
      final result = await ShareIntake.fromSharedMedia(
        SharedMediaFile(
          path: 'https://example.com/guide.',
          type: SharedMediaType.text,
          mimeType: 'text/plain',
        ),
      );

      expect(result, isNotNull);
      expect(result!.kind, ItemKind.link);
      expect(result.url, 'https://example.com/guide');
    });

    test('keeps a single shared word as a note instead of inventing a URL', () async {
      final result = await ShareIntake.fromSharedMedia(
        SharedMediaFile(
          path: 'remember',
          type: SharedMediaType.text,
          mimeType: 'text/plain',
        ),
      );

      expect(result, isNotNull);
      expect(result!.kind, ItemKind.note);
      expect(result.content, 'remember');
      expect(result.url, isNull);
    });

    test('preserves a port on a bare domain', () async {
      final result = await ShareIntake.fromSharedMedia(
        SharedMediaFile(
          path: 'example.com:8443/guide',
          type: SharedMediaType.text,
          mimeType: 'text/plain',
        ),
      );

      expect(result, isNotNull);
      expect(result!.kind, ItemKind.link);
      expect(result.url, 'https://example.com:8443/guide');
    });
    test('normalizes a bare domain into a link draft', () async {
      final result = await ShareIntake.fromSharedMedia(
        SharedMediaFile(
          path: 'example.com/guide',
          type: SharedMediaType.text,
          mimeType: 'text/plain',
        ),
      );

      expect(result, isNotNull);
      expect(result!.kind, ItemKind.link);
      expect(result.url, 'https://example.com/guide');
    });
    test('recognizes a URL inside shared title and text', () async {
      final result = await ShareIntake.fromSharedMedia(
        SharedMediaFile(
          path: 'Read this later\nhttps://example.com/article.',
          type: SharedMediaType.text,
          mimeType: 'text/plain',
        ),
      );

      expect(result, isNotNull);
      expect(result!.kind, ItemKind.link);
      expect(result.title, 'Read this later');
      expect(result.url, 'https://example.com/article');
      expect(result.content, '');
    });

    test('keeps the full URL when its path contains the letter s', () async {
      final result = await ShareIntake.fromSharedMedia(
        SharedMediaFile(
          path: 'Save this: https://example.com/stories/space-station?source=share.',
          type: SharedMediaType.text,
          mimeType: 'text/plain',
        ),
      );

      expect(result, isNotNull);
      expect(result!.kind, ItemKind.link);
      expect(result.url, 'https://example.com/stories/space-station?source=share');
      expect(result.content, '');
    });

    test('accepts shared text at the documented character limit', () async {
      final firstHalf = List<String>.filled(
        maxIncomingTextCharacters ~/ 2,
        'x',
      ).join();
      final secondHalf = List<String>.filled(
        maxIncomingTextCharacters ~/ 2 - 1,
        'y',
      ).join();
      final sharedText = '$firstHalf $secondHalf';

      expect(sharedText.length, maxIncomingTextCharacters);
      final result = await ShareIntake.fromSharedMedia(
        SharedMediaFile(
          path: sharedText,
          type: SharedMediaType.text,
          mimeType: 'text/plain',
        ),
      );

      expect(result, isNotNull);
      expect(result!.kind, ItemKind.note);
      expect(result.content.length, maxIncomingTextCharacters);
    });
    test('rejects shared text beyond the documented character limit', () async {
      await expectLater(
        ShareIntake.fromSharedMedia(
          SharedMediaFile(
            path: List<String>.filled(maxIncomingTextCharacters + 1, 'x').join(),
            type: SharedMediaType.text,
            mimeType: 'text/plain',
          ),
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('1,000,000-character'),
          ),
        ),
      );
    });

    test('retains batch progress when cloning a shared draft', () {
      final incoming = IncomingShare(
        kind: ItemKind.note,
        title: 'A note',
        content: 'Remember this',
        fileName: 'remember.txt',
        mimeType: 'text/plain',
      );

      final prepared = incoming.withShareProgress(position: 2, total: 4);

      expect(prepared.sharePosition, 2);
      expect(prepared.shareTotal, 4);
      expect(prepared.kind, ItemKind.note);
      expect(prepared.title, 'A note');
      expect(prepared.content, 'Remember this');
      expect(prepared.fileName, 'remember.txt');
      expect(prepared.mimeType, 'text/plain');
    });

    test('clamps shared batch progress into a valid range', () {
      final incoming = IncomingShare(kind: ItemKind.note);

      expect(
        incoming.withShareProgress(position: 0, total: 3).sharePosition,
        1,
      );
      expect(
        incoming.withShareProgress(position: 8, total: 3).sharePosition,
        3,
      );
      final invalidTotal = incoming.withShareProgress(position: 8, total: 0);
      expect(invalidTotal.sharePosition, 1);
      expect(invalidTotal.shareTotal, 1);
    });

    test('preserves ordinary Unicode share text as a note draft', () async {
      const sharedText = 'قابلِ تلاش متن — Roman Urdu: mera khayal';
      final result = await ShareIntake.fromSharedMedia(
        SharedMediaFile(
          path: sharedText,
          type: SharedMediaType.text,
          mimeType: 'text/plain',
        ),
      );

      expect(result, isNotNull);
      expect(result!.kind, ItemKind.note);
      expect(result.content, sharedText);
      expect(result.url, isNull);
    });

    test('does not accept executable URL schemes', () async {
      await expectLater(
        ShareIntake.fromSharedMedia(
          SharedMediaFile(
            path: 'javascript:alert(1)',
            type: SharedMediaType.url,
            mimeType: 'text/uri-list',
          ),
        ),
        throwsFormatException,
      );
    });

    test('suppresses immediate initial/stream duplicates but accepts later repeats', () {
      final deduplicator = ShareEventDeduplicator(
        window: const Duration(seconds: 3),
      );
      final shared = [
        SharedMediaFile(
          path: 'https://example.com/repeat',
          type: SharedMediaType.url,
          mimeType: 'text/uri-list',
        ),
      ];
      final start = DateTime.utc(2026, 10, 21, 12);

      expect(deduplicator.shouldAccept(shared, now: start), isTrue);
      expect(
        deduplicator.shouldAccept(
          shared,
          now: start.add(const Duration(milliseconds: 250)),
        ),
        isFalse,
      );
      expect(
        deduplicator.shouldAccept(
          shared,
          now: start.add(const Duration(seconds: 4)),
        ),
        isTrue,
      );
      expect(deduplicator.shouldAccept(const [], now: start), isFalse);
    });

    test('treats distinct shared messages as different events', () {
      final deduplicator = ShareEventDeduplicator();
      final start = DateTime.utc(2026, 10, 22, 14);
      SharedMediaFile shared(String message) => SharedMediaFile(
            path: 'https://example.com/same',
            type: SharedMediaType.url,
            mimeType: 'text/uri-list',
            message: message,
          );

      expect(
        deduplicator.shouldAccept([shared('First note')], now: start),
        isTrue,
      );
      expect(
        deduplicator.shouldAccept(
          [shared('Second note')],
          now: start.add(const Duration(milliseconds: 100)),
        ),
        isTrue,
        reason: 'The same URL can be intentionally shared with different context.',
      );
      expect(
        deduplicator.shouldAccept(
          [shared('Second note')],
          now: start.add(const Duration(milliseconds: 200)),
        ),
        isFalse,
        reason: 'An identical event is still suppressed inside the window.',
      );
    });

    test('normalizes harmless metadata differences before deduplication', () {
      final deduplicator = ShareEventDeduplicator();
      final start = DateTime.utc(2026, 10, 22, 15);
      final first = SharedMediaFile(
        path: ' https://example.com/space ',
        type: SharedMediaType.url,
        mimeType: 'TEXT/URI-LIST',
        message: ' Saved context ',
      );
      final normalized = SharedMediaFile(
        path: 'https://example.com/space',
        type: SharedMediaType.url,
        mimeType: 'text/uri-list',
        message: 'Saved context',
      );

      expect(deduplicator.shouldAccept([first], now: start), isTrue);
      expect(
        deduplicator.shouldAccept(
          [normalized],
          now: start.add(const Duration(milliseconds: 150)),
        ),
        isFalse,
        reason: 'Normalization yields the same user-visible share draft.',
      );
    });
    test('distinguishes batch order and respects the bounded fingerprint cache', () {
      final deduplicator = ShareEventDeduplicator(
        window: const Duration(seconds: 3),
        maxEntries: 1,
      );
      final first = SharedMediaFile(
        path: 'https://example.com/first',
        type: SharedMediaType.url,
        mimeType: 'text/uri-list',
      );
      final second = SharedMediaFile(
        path: 'https://example.com/second',
        type: SharedMediaType.url,
        mimeType: 'text/uri-list',
      );
      final start = DateTime.utc(2026, 10, 22, 12);

      expect(deduplicator.shouldAccept([first, second], now: start), isTrue);
      expect(
        deduplicator.shouldAccept([second, first], now: start),
        isTrue,
        reason: 'A differently ordered batch is a distinct share event.',
      );
      expect(
        deduplicator.shouldAccept([second, first], now: start),
        isFalse,
        reason: 'The exact recent batch should still be deduplicated.',
      );
      expect(
        deduplicator.shouldAccept([first], now: start),
        isTrue,
        reason: 'The bounded cache evicts its oldest fingerprint when full.',
      );
    });

    test('uses an unambiguous fingerprint for share batch contents', () {
      final deduplicator = ShareEventDeduplicator();
      final start = DateTime.utc(2026, 10, 22, 13);
      SharedMediaFile shared(String path) => SharedMediaFile(
            path: path,
            type: SharedMediaType.text,
            mimeType: 'text/plain',
          );

      expect(
        deduplicator.shouldAccept(
          [shared('a|b'), shared('c')],
          now: start,
        ),
        isTrue,
      );
      expect(
        deduplicator.shouldAccept(
          [shared('a'), shared('b|c')],
          now: start,
        ),
        isTrue,
        reason: 'Different batch contents must not alias through a delimiter.',
      );
    });

    test('returns unsupported for shared video instead of mislabeling it', () async {
      final result = await ShareIntake.fromSharedMedia(
        SharedMediaFile(
          path: '/tmp/clip.mp4',
          type: SharedMediaType.video,
          mimeType: 'video/mp4',
        ),
      );

      expect(result, isNull);
    });
  });
}
