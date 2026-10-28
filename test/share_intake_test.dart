import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:stashhive/models/saved_item.dart';
import 'package:stashhive/services/share_intake.dart';

void main() {
  group('ShareIntake', () {
    test('acknowledges a launch-time share before review finishes', () async {
      final events = <String>[];
      final reviewGate = Completer<void>();
      final reviewEntered = Completer<void>();
      final media = <SharedMediaFile>[
        SharedMediaFile(
          path: 'https://example.com/launch-share',
          type: SharedMediaType.url,
          mimeType: 'text/uri-list',
        ),
      ];

      final consuming = consumeInitialSharedMedia(
        readInitialMedia: () async {
          events.add('read');
          return media;
        },
        resetInitialMedia: () async {
          events.add('reset');
        },
        enqueue: (received) async {
          expect(received, same(media));
          events.add('enqueue');
          reviewEntered.complete();
          await reviewGate.future;
        },
      );

      await reviewEntered.future;
      final orderBeforeReviewFinishes = List<String>.from(events);
      reviewGate.complete();
      await consuming;

      expect(orderBeforeReviewFinishes, ['read', 'reset', 'enqueue']);
    });

    test('still queues a launch-time share when plugin reset fails', () async {
      var queued = false;

      await consumeInitialSharedMedia(
        readInitialMedia: () async => <SharedMediaFile>[
          SharedMediaFile(
            path: 'https://example.com/reset-failure',
            type: SharedMediaType.url,
            mimeType: 'text/uri-list',
          ),
        ],
        resetInitialMedia: () async {
          throw StateError('simulated plugin acknowledgement failure');
        },
        enqueue: (received) async {
          queued = received.isNotEmpty;
        },
      );

      expect(queued, isTrue);
    });
    test('accepts the URL length supported by backup format', () async {
      const prefix = 'https://example.com/';
      final url = prefix +
          List<String>.filled(maxIncomingUrlCharacters - prefix.length, 'a').join();
      expect(url.length, maxIncomingUrlCharacters);

      final result = await ShareIntake.fromSharedMedia(
        SharedMediaFile(
          path: url,
          type: SharedMediaType.url,
          mimeType: 'text/uri-list',
        ),
      );

      expect(result, isNotNull);
      expect(result!.url!.length, maxIncomingUrlCharacters);
    });

    test('rejects shared URLs beyond backup-supported length', () async {
      const prefix = 'https://example.com/';
      final url = prefix +
          List<String>.filled(maxIncomingUrlCharacters + 1 - prefix.length, 'a').join();

      await expectLater(
        ShareIntake.fromSharedMedia(
          SharedMediaFile(
            path: url,
            type: SharedMediaType.url,
            mimeType: 'text/uri-list',
          ),
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('4,096 characters'),
          ),
        ),
      );
    });

    test('limits context attached to a typed URL share', () async {
      await expectLater(
        ShareIntake.fromSharedMedia(
          SharedMediaFile(
            path: 'https://example.com/',
            type: SharedMediaType.url,
            mimeType: 'text/uri-list',
            message: List<String>.filled(maxIncomingTextCharacters + 1, 'x').join(),
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

    test('uses the message when a text share has an empty provider path', () async {
      final result = await ShareIntake.fromSharedMedia(
        SharedMediaFile(
          path: '',
          message: 'Read this later',
          type: SharedMediaType.text,
          mimeType: 'text/plain',
        ),
      );

      expect(result, isNotNull);
      expect(result!.kind, ItemKind.note);
      expect(result.content, 'Read this later');
      expect(result.url, isNull);
    });

    test('uses effective text when an oversized provider path is unused', () async {
      final ignoredPath =
          List<String>.filled(maxIncomingTextCharacters + 1, 'x').join();
      final shared = SharedMediaFile(
        path: ignoredPath,
        message: 'Read this later',
        type: SharedMediaType.text,
        mimeType: 'text/plain',
      );

      // Deduplication should bypass fingerprint allocation for this provider
      // metadata, but the actual text field remains valid for normal intake.
      expect(ShareEventDeduplicator().shouldAccept([shared]), isTrue);
      final result = await ShareIntake.fromSharedMedia(shared);

      expect(result, isNotNull);
      expect(result!.kind, ItemKind.note);
      expect(result.content, 'Read this later');
      expect(result.url, isNull);
    });

    test('ignores an oversized whitespace-only message when path has content', () async {
      final unusedMessage = List<String>.filled(
        maxIncomingTextCharacters + 1,
        ' ',
      ).join();
      final result = await ShareIntake.fromSharedMedia(
        SharedMediaFile(
          path: 'Remember this shared note',
          message: unusedMessage,
          type: SharedMediaType.text,
          mimeType: 'text/plain',
        ),
      );

      expect(result, isNotNull);
      expect(result!.kind, ItemKind.note);
      expect(result.content, 'Remember this shared note');
      expect(result.url, isNull);
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

    test('builds one summary for unsupported, invalid and omitted share items', () {
      final message = buildShareReviewSummary(
        unsupportedItemCount: 1,
        invalidItemCount: 2,
        omittedItemCount: 101,
        validationHints: const [
          ' Invalid URL ',
          'Invalid URL',
          '',
          'File could not be read.',
          'Shared text is too long.',
          'This fourth detail should be excluded.',
        ],
      );

      expect(message, isNotNull);
      expect(message, contains('1 unsupported item was skipped'));
      expect(message, contains('2 items could not be prepared'));
      expect(
        message,
        contains(
          '101 additional items were omitted because each share batch is limited to 100 items',
        ),
      );
      expect(
        message,
        contains(
          'Details: Invalid URL File could not be read. Shared text is too long.',
        ),
      );
      expect(message, isNot(contains('This fourth detail should be excluded.')));
    });

    test('does not show a share summary when there is nothing to report', () {
      expect(
        buildShareReviewSummary(
          unsupportedItemCount: 0,
          invalidItemCount: 0,
          omittedItemCount: 0,
          validationHints: const ['Unused hint'],
        ),
        isNull,
      );
    });

    test('caps waiting share batches while the current batch is reviewed', () {
      expect(
        hasCapacityForIncomingShareBatch(maxPendingIncomingShareBatches - 1),
        isTrue,
      );
      expect(
        hasCapacityForIncomingShareBatch(maxPendingIncomingShareBatches),
        isFalse,
      );
      expect(
        hasCapacityForIncomingShareBatch(maxPendingIncomingShareBatches + 1),
        isFalse,
      );
    });

    test('bounds large share batches while preserving their original order', () {
      final media = List<SharedMediaFile>.generate(
        maxIncomingShareBatchItems + 3,
        (index) => SharedMediaFile(
          path: 'https://example.com/item-$index',
          type: SharedMediaType.url,
          mimeType: 'text/uri-list',
        ),
      );

      final bounded = boundIncomingShareBatch(media);

      expect(bounded.media, hasLength(maxIncomingShareBatchItems));
      expect(bounded.skippedCount, 3);
      expect(bounded.media.first.path, 'https://example.com/item-0');
      expect(
        bounded.media.last.path,
        'https://example.com/item-${maxIncomingShareBatchItems - 1}',
      );
      expect(media, hasLength(maxIncomingShareBatchItems + 3));
    });

    test('counts whitespace-only provider messages toward fingerprint budget', () {
      final deduplicator = ShareEventDeduplicator();
      final whitespace = List<String>.filled(900000, ' ').join();
      final shared = <SharedMediaFile>[
        SharedMediaFile(
          path: 'remember',
          message: whitespace,
          type: SharedMediaType.text,
          mimeType: 'text/plain',
        ),
        SharedMediaFile(
          path: 'later',
          message: whitespace,
          type: SharedMediaType.text,
          mimeType: 'text/plain',
        ),
      ];
      final start = DateTime.utc(2026, 10, 28, 18);

      expect(deduplicator.shouldAccept(shared, now: start), isTrue);
      expect(
        deduplicator.shouldAccept(
          shared,
          now: start.add(const Duration(milliseconds: 100)),
        ),
        isTrue,
        reason: 'Whitespace-only messages still incur trim/serialization work, so oversized aggregate input must bypass fingerprint caching.',
      );
    });

    test('does not fingerprint oversized text before normal validation', () async {
      final deduplicator = ShareEventDeduplicator();
      final oversizedText =
          List<String>.filled(maxIncomingTextCharacters + 1, 'x').join();
      final shared = <SharedMediaFile>[
        SharedMediaFile(
          path: 'provider-placeholder',
          message: oversizedText,
          type: SharedMediaType.text,
          mimeType: 'text/plain',
        ),
      ];
      final start = DateTime.utc(2026, 10, 28, 12);

      expect(deduplicator.shouldAccept(shared, now: start), isTrue);
      expect(
        deduplicator.shouldAccept(
          shared,
          now: start.add(const Duration(milliseconds: 100)),
        ),
        isTrue,
        reason: 'Oversized drafts bypass hashing so intake can reject them safely.',
      );
      await expectLater(
        ShareIntake.fromSharedMedia(shared.single),
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
        mimeType: 'application/octet-stream',
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
    test('deduplicates text events based on the effective draft text', () {
      final deduplicator = ShareEventDeduplicator();
      final start = DateTime.utc(2026, 10, 22, 16);
      final fromPath = SharedMediaFile(
        path: 'Read this later',
        type: SharedMediaType.text,
        mimeType: 'text/plain',
      );
      final fromMessage = SharedMediaFile(
        path: 'provider-placeholder',
        type: SharedMediaType.text,
        mimeType: 'text/html',
        message: ' Read this later ',
      );

      expect(deduplicator.shouldAccept([fromPath], now: start), isTrue);
      expect(
        deduplicator.shouldAccept(
          [fromMessage],
          now: start.add(const Duration(milliseconds: 100)),
        ),
        isFalse,
        reason: 'Both events produce the same text draft despite provider-field differences.',
      );
    });

    test('ignores unused message metadata for file share deduplication', () {
      final deduplicator = ShareEventDeduplicator();
      final start = DateTime.utc(2026, 10, 22, 17);
      SharedMediaFile fileWithMessage(String message) => SharedMediaFile(
            path: '/provider/cache/report.pdf',
            type: SharedMediaType.file,
            mimeType: 'application/pdf',
            message: message,
          );

      expect(deduplicator.shouldAccept([fileWithMessage('Original caption')], now: start), isTrue);
      expect(
        deduplicator.shouldAccept(
          [fileWithMessage('Different unused caption')],
          now: start.add(const Duration(milliseconds: 100)),
        ),
        isFalse,
        reason: 'The file draft ignores the shared message field.',
      );
    });

    test('deduplicates normalized URL shares across text and URL media types', () {
      final deduplicator = ShareEventDeduplicator();
      final start = DateTime.utc(2026, 10, 22, 19);
      final textUrl = SharedMediaFile(
        path: 'HTTPS://example.com/guide.',
        type: SharedMediaType.text,
        mimeType: 'text/plain',
      );
      final urlMedia = SharedMediaFile(
        path: 'https://example.com/guide',
        type: SharedMediaType.url,
        mimeType: 'text/uri-list',
      );

      expect(deduplicator.shouldAccept([textUrl], now: start), isTrue);
      expect(
        deduplicator.shouldAccept(
          [urlMedia],
          now: start.add(const Duration(milliseconds: 100)),
        ),
        isFalse,
        reason: 'Both providers resolve to the same normalized standalone URL draft.',
      );
    });

    test('deduplicates image intent and file intent for the same image draft', () {
      final deduplicator = ShareEventDeduplicator();
      final start = DateTime.utc(2026, 10, 22, 20);
      final genericFile = SharedMediaFile(
        path: '/provider/cache/reference.png',
        type: SharedMediaType.file,
        mimeType: 'text/plain',
      );
      final imageIntent = SharedMediaFile(
        path: '/provider/cache/reference.png',
        type: SharedMediaType.image,
        mimeType: 'image/png',
      );

      expect(deduplicator.shouldAccept([genericFile], now: start), isTrue);
      expect(
        deduplicator.shouldAccept(
          [imageIntent],
          now: start.add(const Duration(milliseconds: 100)),
        ),
        isFalse,
        reason: 'The file and image intents produce the same image draft.',
      );
    });

    test('fingerprints unusual file URIs without throwing', () {
      final deduplicator = ShareEventDeduplicator();
      final shared = <SharedMediaFile>[
        SharedMediaFile(
          path: 'file://remote-host/shared/reference.png',
          type: SharedMediaType.file,
          mimeType: 'application/octet-stream',
        ),
      ];

      expect(
        deduplicator.shouldAccept(
          shared,
          now: DateTime.utc(2026, 10, 28, 19),
        ),
        isTrue,
      );
    });

    test('deduplicates recognized files despite conflicting raw MIME headers', () {
      final deduplicator = ShareEventDeduplicator();
      final start = DateTime.utc(2026, 10, 22, 18);
      SharedMediaFile imageWithMime(String mimeType) => SharedMediaFile(
            path: '/provider/cache/reference.png',
            type: SharedMediaType.file,
            mimeType: mimeType,
          );

      expect(
        deduplicator.shouldAccept(
          [imageWithMime('text/plain')],
          now: start,
        ),
        isTrue,
      );
      expect(
        deduplicator.shouldAccept(
          [imageWithMime('image/png')],
          now: start.add(const Duration(milliseconds: 100)),
        ),
        isFalse,
        reason: 'The recognized .png extension determines both drafts’ MIME.',
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

    test('reads a supported document share into an attachment draft', () async {
      final directory =
          await Directory.systemTemp.createTemp('stashhive_share_file_test_');
      try {
        final file = File('${directory.path}/meeting-notes.txt');
        final bytes = [72, 101, 108, 108, 111, 10];
        await file.writeAsBytes(bytes);

        final result = await ShareIntake.fromSharedMedia(
          SharedMediaFile(
            path: file.path,
            type: SharedMediaType.file,
            mimeType: 'application/octet-stream',
          ),
        );

        expect(result, isNotNull);
        expect(result!.kind, ItemKind.document);
        expect(result.fileName, 'meeting-notes.txt');
        expect(result.mimeType, 'text/plain');
        expect(result.bytes, orderedEquals(bytes));
      } finally {
        await directory.delete(recursive: true);
      }
    });

    test('uses recognized file extension when shared MIME conflicts', () async {
      final directory =
          await Directory.systemTemp.createTemp('stashhive_share_mime_conflict_');
      try {
        final imageFile = File('${directory.path}/reference.png');
        final imageBytes = [137, 80, 78, 71];
        await imageFile.writeAsBytes(imageBytes);
        final image = await ShareIntake.fromSharedMedia(
          SharedMediaFile(
            path: imageFile.path,
            type: SharedMediaType.file,
            mimeType: 'text/plain',
          ),
        );

        final textFile = File('${directory.path}/notes.txt');
        final textBytes = [72, 105, 10];
        await textFile.writeAsBytes(textBytes);
        final document = await ShareIntake.fromSharedMedia(
          SharedMediaFile(
            path: textFile.path,
            type: SharedMediaType.file,
            mimeType: 'image/png',
          ),
        );

        expect(image?.kind, ItemKind.image);
        expect(image?.mimeType, 'image/png');
        expect(image?.bytes, orderedEquals(imageBytes));
        expect(document?.kind, ItemKind.document);
        expect(document?.mimeType, 'text/plain');
        expect(document?.bytes, orderedEquals(textBytes));
      } finally {
        await directory.delete(recursive: true);
      }
    });

    test('reads a supported image share into an image draft', () async {
      final directory =
          await Directory.systemTemp.createTemp('stashhive_share_image_test_');
      try {
        final file = File('${directory.path}/reference.png');
        final bytes = [137, 80, 78, 71];
        await file.writeAsBytes(bytes);

        final result = await ShareIntake.fromSharedMedia(
          SharedMediaFile(
            path: file.path,
            type: SharedMediaType.image,
            mimeType: 'image/png',
          ),
        );

        expect(result, isNotNull);
        expect(result!.kind, ItemKind.image);
        expect(result.fileName, 'reference.png');
        expect(result.mimeType, 'image/png');
        expect(result.bytes, orderedEquals(bytes));
      } finally {
        await directory.delete(recursive: true);
      }
    });

    test('forced image share does not keep a conflicting text MIME header', () async {
      final directory =
          await Directory.systemTemp.createTemp('stashhive_share_image_mime_');
      try {
        final file = File('${directory.path}/shared-content.bin');
        final bytes = [137, 80, 78, 71, 13, 10, 26, 10];
        await file.writeAsBytes(bytes);
        final result = await ShareIntake.fromSharedMedia(
          SharedMediaFile(
            path: file.path,
            type: SharedMediaType.image,
            mimeType: 'text/plain',
          ),
        );

        expect(result, isNotNull);
        expect(result!.kind, ItemKind.image);
        expect(result.mimeType, defaultBinaryMimeType);
        expect(result.bytes, orderedEquals(bytes));
      } finally {
        await directory.delete(recursive: true);
      }
    });

    test('uses the common MIME map for less common image extensions', () async {
      final directory =
          await Directory.systemTemp.createTemp('stashhive_share_tiff_test_');
      try {
        final file = File('${directory.path}/archive.TIFF');
        final bytes = [73, 73, 42, 0];
        await file.writeAsBytes(bytes);

        final result = await ShareIntake.fromSharedMedia(
          SharedMediaFile(
            path: file.path,
            type: SharedMediaType.file,
            mimeType: 'application/octet-stream',
          ),
        );

        expect(result, isNotNull);
        expect(result!.kind, ItemKind.image);
        expect(result.mimeType, 'image/tiff');
        expect(result.bytes, orderedEquals(bytes));
      } finally {
        await directory.delete(recursive: true);
      }
    });

    test('rejects an incoming filename beyond the metadata limit before IO', () async {
      final longName = '${List<String>.filled(256, 'x').join()}.txt';

      await expectLater(
        ShareIntake.fromSharedMedia(
          SharedMediaFile(
            path: '/tmp/$longName',
            type: SharedMediaType.file,
            mimeType: 'text/plain',
          ),
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('filename is too long'),
          ),
        ),
      );
    });

    test('rejects oversized MIME metadata before file IO', () async {
      final oversizedMime = 'image/' + List<String>.filled(130, 'x').join();

      await expectLater(
        ShareIntake.fromSharedMedia(
          SharedMediaFile(
            path: '/tmp/unknown-extension.bin',
            type: SharedMediaType.file,
            mimeType: oversizedMime,
          ),
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('file type metadata is too long'),
          ),
        ),
      );
    });

    test('rejects an unsupported shared file extension', () async {
      final directory =
          await Directory.systemTemp.createTemp('stashhive_share_unsupported_test_');
      try {
        final file = File('${directory.path}/installer.exe');
        await file.writeAsBytes([1, 2, 3]);

        await expectLater(
          ShareIntake.fromSharedMedia(
            SharedMediaFile(
              path: file.path,
              type: SharedMediaType.file,
              mimeType: 'application/octet-stream',
            ),
          ),
          throwsA(
            isA<FormatException>().having(
              (error) => error.message,
              'message',
              contains('currently accepts shared images'),
            ),
          ),
        );
      } finally {
        await directory.delete(recursive: true);
      }
    });

    test('rejects an oversized shared file before reading its bytes', () async {
      final directory =
          await Directory.systemTemp.createTemp('stashhive_share_oversize_test_');
      try {
        final file = File('${directory.path}/large.pdf');
        final handle = await file.open(mode: FileMode.write);
        await handle.setPosition(maxIncomingAttachmentBytes);
        await handle.writeByte(1);
        await handle.close();

        expect(await file.length(), maxIncomingAttachmentBytes + 1);
        await expectLater(
          ShareIntake.fromSharedMedia(
            SharedMediaFile(
              path: file.path,
              type: SharedMediaType.file,
              mimeType: 'application/pdf',
            ),
          ),
          throwsA(
            isA<FormatException>().having(
              (error) => error.message,
              'message',
              contains('15 MB or smaller'),
            ),
          ),
        );
      } finally {
        await directory.delete(recursive: true);
      }
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
