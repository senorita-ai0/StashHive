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
