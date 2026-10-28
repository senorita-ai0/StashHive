import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:cross_file/cross_file.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../models/saved_item.dart';
import 'backup_codec.dart';
import 'mime_types.dart';
import 'web_url.dart';
import 'bounded_bytes_reader.dart';

const int maxIncomingAttachmentBytes = BackupCodec.maxAttachmentBytes;
const int maxIncomingUrlCharacters = maxSavedItemUrlCharacters;
const int maxIncomingTextCharacters = 1000000;
const int maxIncomingProviderPathCharacters = 4096;

/// Maximum number of entries reviewed from one operating-system share batch.
/// Larger selections are truncated with a user-facing warning before queuing.
const int maxIncomingShareBatchItems = 100;

/// Maximum waiting batches accepted while the user is reviewing earlier shares.
/// The active batch is tracked separately from this waiting queue.
const int maxPendingIncomingShareBatches = 8;

/// Bound the amount of provider/error guidance inspected for one summary.
const int maxShareReviewHintCandidates = 16;
const int maxShareReviewHintCharacters = 160;

bool hasCapacityForIncomingShareBatch(int pendingBatchCount) =>
    pendingBatchCount < maxPendingIncomingShareBatches;

/// Builds one bounded, user-facing summary after queued share review finishes.
/// Hints are app-defined validation guidance, not raw plugin exceptions.
String? buildShareReviewSummary({
  required int unsupportedItemCount,
  required int invalidItemCount,
  required int omittedItemCount,
  Iterable<String> validationHints = const <String>[],
}) {
  final parts = <String>[];
  if (unsupportedItemCount > 0) {
    parts.add(
      unsupportedItemCount == 1
          ? '1 unsupported item was skipped'
          : '$unsupportedItemCount unsupported items were skipped',
    );
  }
  if (invalidItemCount > 0) {
    parts.add(
      invalidItemCount == 1
          ? '1 item could not be prepared'
          : '$invalidItemCount items could not be prepared',
    );
  }
  if (omittedItemCount > 0) {
    parts.add(
      omittedItemCount == 1
          ? '1 additional item was omitted because each share batch is limited to 100 items'
          : '$omittedItemCount additional items were omitted because each share batch is limited to 100 items',
    );
  }
  if (parts.isEmpty) return null;

  final safeHints = <String>[];
  var inspectedHints = 0;
  for (final rawHint in validationHints) {
    if (inspectedHints >= maxShareReviewHintCandidates) break;
    inspectedHints++;
    // A caller can construct this helper directly; avoid making a second,
    // trimmed copy of arbitrary-size text just to display a short summary.
    if (rawHint.length > maxShareReviewHintCharacters) continue;
    final hint = rawHint.trim();
    if (hint.isEmpty || safeHints.contains(hint)) continue;
    safeHints.add(hint);
    if (safeHints.length == 3) break;
  }
  final details = safeHints.isEmpty
      ? ''
      : ' Details: ${safeHints.join('; ')}';
  return 'Share review complete. ${parts.join('; ')}.$details '
      'You can add skipped items manually.';
}

/// Bound the input copied into a single de-duplication fingerprint. Oversized
/// payloads go to normal validation without creating a large JSON/UTF-8 copy.
const int _maxShareFingerprintCharacters =
    maxIncomingTextCharacters + maxIncomingShareBatchItems * maxIncomingUrlCharacters;

final RegExp _nonWhitespacePattern = RegExp(r'\S');

/// Reads and acknowledges a launch-time share before waiting for interactive
/// review. Quick Save can remain open while the user reviews a batch; delaying
/// [resetInitialMedia] until then can leave the consumed OS intent pending if
/// the app is stopped in the middle of that review.
Future<void> consumeInitialSharedMedia({
  required Future<List<SharedMediaFile>> Function() readInitialMedia,
  required Future<void> Function() resetInitialMedia,
  required Future<void> Function(List<SharedMediaFile>) enqueue,
}) async {
  final media = await readInitialMedia();

  // A failed acknowledgement must not discard a share we have already read.
  // The item is still queued; a later app launch could replay it if the plugin
  // could not clear the stored intent.
  try {
    await resetInitialMedia();
  } catch (_) {
    // Best-effort acknowledgement; continue with the media already received.
  }

  if (media.isNotEmpty) await enqueue(media);
}

/// A user-selected or OS-shared item ready to prefill StashHive's save form.
class IncomingShare {
  const IncomingShare({
    required this.kind,
    this.title = '',
    this.url,
    this.content = '',
    this.bytes,
    this.fileName,
    this.mimeType,
    this.sharePosition = 1,
    this.shareTotal = 1,
  });

  final ItemKind kind;
  final String title;
  final String? url;
  final String content;
  final Uint8List? bytes;
  final String? fileName;
  final String? mimeType;
  final int sharePosition;
  final int shareTotal;

  IncomingShare withShareProgress({
    required int position,
    required int total,
  }) {
    final safeTotal = total < 1 ? 1 : total;
    final safePosition = position < 1
        ? 1
        : position > safeTotal
            ? safeTotal
            : position;
    return IncomingShare(
      kind: kind,
      title: title,
      url: url,
      content: content,
      bytes: bytes,
      fileName: fileName,
      mimeType: mimeType,
      sharePosition: safePosition,
      shareTotal: safeTotal,
    );
  }
}

/// A share batch limited to the number of entries StashHive will review.
class BoundedShareBatch {
  const BoundedShareBatch({
    required this.media,
    required this.skippedCount,
  });

  final List<SharedMediaFile> media;
  final int skippedCount;
}

/// Keeps only the first [maxIncomingShareBatchItems] entries from a very
/// large OS share selection. The caller must explain any skipped entries.
BoundedShareBatch boundIncomingShareBatch(List<SharedMediaFile> media) {
  final retainedCount = media.length > maxIncomingShareBatchItems
      ? maxIncomingShareBatchItems
      : media.length;
  return BoundedShareBatch(
    media: List<SharedMediaFile>.unmodifiable(media.take(retainedCount)),
    skippedCount: media.length - retainedCount,
  );
}

/// Filters only near-simultaneous duplicate deliveries from the initial intent
/// API and the broadcast stream. A later deliberate share of the same URL is
/// accepted after the short de-duplication window.
class ShareEventDeduplicator {
  ShareEventDeduplicator({
    this.window = const Duration(seconds: 3),
    this.maxEntries = 64,
  })  : assert(window > Duration.zero),
        assert(maxEntries > 0);

  final Duration window;
  final int maxEntries;
  final Map<String, DateTime> _seen = <String, DateTime>{};

  bool _canFingerprint(List<SharedMediaFile> media) {
    if (media.length > maxIncomingShareBatchItems) return false;

    // First pass is length-only: do not trim/normalize a large message just
    // to decide whether the aggregate batch is safe to fingerprint. Count all
    // raw text path/message fields conservatively; unused provider metadata
    // may make a legitimate event bypass de-duplication, but it will still
    // reach the normal input validation path without unbounded copies.
    var totalCharacters = 0;
    for (final item in media) {
      final pathLength = item.path.length;
      final messageLength = item.message?.length ?? 0;
      final mimeLength = item.mimeType?.length ?? 0;
      var charactersForItem = 0;

      switch (item.type) {
        case SharedMediaType.text:
          if (messageLength > maxIncomingTextCharacters ||
              pathLength > maxIncomingTextCharacters) {
            return false;
          }
          charactersForItem = messageLength + pathLength;
          break;
        case SharedMediaType.url:
          if (pathLength > maxIncomingUrlCharacters ||
              messageLength > maxIncomingTextCharacters) {
            return false;
          }
          charactersForItem = pathLength + messageLength;
          break;
        case SharedMediaType.image:
        case SharedMediaType.file:
        case SharedMediaType.video:
          if (pathLength > maxIncomingProviderPathCharacters ||
              mimeLength > 128) {
            return false;
          }
          charactersForItem = pathLength + mimeLength;
          break;
      }

      totalCharacters += charactersForItem;
      if (totalCharacters > _maxShareFingerprintCharacters) return false;
    }
    return true;
  }

  String _effectiveFileMime(SharedMediaFile item) {
    final rawPath = item.path.trim();
    final parsedPath = Uri.tryParse(rawPath);
    var localPath = rawPath;
    if (parsedPath?.scheme == 'file') {
      // A provider may supply a file URI whose authority/path cannot be
      // converted on this platform. Fingerprinting must remain best-effort;
      // actual intake will show a safe file-read failure if it is unusable.
      try {
        localPath = parsedPath!.toFilePath();
      } catch (_) {
        localPath = rawPath;
      }
    }
    final inferredByExtension = guessMimeTypeFromFilename(localPath);
    final sharedMime = item.mimeType?.trim().toLowerCase() ?? '';
    final inferred = inferredByExtension != defaultBinaryMimeType
        ? inferredByExtension
        : sharedMime.isEmpty || sharedMime == defaultBinaryMimeType
            ? defaultBinaryMimeType
            : sharedMime;

    if (item.type == SharedMediaType.image &&
        !inferred.startsWith('image/')) {
      return sharedMime.startsWith('image/')
          ? sharedMime
          : defaultBinaryMimeType;
    }
    return inferred;
  }

  List<Object?> _fileFingerprint(SharedMediaFile item, String path) {
    final mimeType = _effectiveFileMime(item);
    final category = item.type == SharedMediaType.image ||
            mimeType.startsWith('image/')
        ? 'image'
        : 'document';
    return <Object?>[category, path, mimeType];
  }

  List<Object?> _textItemFingerprint(SharedMediaFile item) {
    final message = item.message?.trim() ?? '';
    // When a provider has supplied the effective message, do not copy/trim an
    // unused path that may be very large. Text intake uses the path only when
    // the message field is empty.
    final path = message.isNotEmpty ? '' : item.path.trim();
    return _textFingerprint(path, message);
  }

  List<Object?> _textFingerprint(String path, String message) {
    final effectiveText = message.isNotEmpty ? message : path;
    final urlCandidate =
        ShareIntake._trimTrailingShareUrlPunctuation(effectiveText.trim());
    final uri = parseUserWebUrl(urlCandidate);
    if (uri != null) return <Object?>['web-url', uri.toString(), ''];
    return <Object?>['text', effectiveText];
  }

  List<Object?> _urlFingerprint(String path, String message) {
    final uri = parseUserWebUrl(path);
    return <Object?>[
      'web-url',
      uri?.toString() ?? path,
      message,
    ];
  }

  bool shouldAccept(
    List<SharedMediaFile> media, {
    DateTime? now,
  }) {
    if (media.isEmpty) return false;
    // Let the regular intake validator report oversized payloads without first
    // serializing an unbounded JSON representation just for de-duplication.
    if (!_canFingerprint(media)) return true;
    final timestamp = now ?? DateTime.now();
    _seen.removeWhere((_, seenAt) {
      final age = timestamp.difference(seenAt);
      return age.isNegative || age > window;
    });

    // Hash the canonical ordered fields so the bounded cache retains only a
    // fixed-size digest, not copies of potentially large shared text/paths.
    // Canonical JSON preserves field and batch boundaries before hashing.
    final canonical = jsonEncode(
      media.map((item) {
        return switch (item.type) {
          // Text intake uses only the message when present; keep unused provider
          // paths out of temporary string copies and out of the fingerprint.
          SharedMediaType.text => _textItemFingerprint(item),
          // URL and standalone-text URL shares should deduplicate when their
          // normalized web destination/context produces the same draft.
          SharedMediaType.url => _urlFingerprint(
              item.path.trim(),
              item.message?.trim() ?? '',
            ),
          // Image-intent and generic-file events can produce the same image
          // draft for the same path. Fingerprint that effective category rather
          // than the provider's raw type label.
          SharedMediaType.image ||
          SharedMediaType.file =>
            _fileFingerprint(item, item.path.trim()),
          // Videos are currently skipped by intake, but keep their events
          // distinct from supported image/document drafts.
          SharedMediaType.video => <Object?>[
              item.type.name,
              item.path.trim(),
              _effectiveFileMime(item),
            ],
        };
      }).toList(growable: false),
    );
    final fingerprint = sha256.convert(utf8.encode(canonical)).toString();
    final previous = _seen[fingerprint];
    if (previous != null && timestamp.difference(previous) <= window) {
      return false;
    }

    while (_seen.length >= maxEntries) {
      _seen.remove(_seen.keys.first);
    }
    _seen[fingerprint] = timestamp;
    return true;
  }
}

/// Converts Android OS shares into draft values. It never saves automatically;
/// the user reviews and confirms the item in Quick Save.
class ShareIntake {
  ShareIntake._();

  static const Set<String> _imageExtensions = <String>{
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
    'bmp',
    'heic',
    'heif',
  };
  static const Set<String> _documentExtensions = <String>{
    'pdf',
    'txt',
    'doc',
    'docx',
    'rtf',
    'csv',
  };
  static const Set<String> _documentMimeTypes = <String>{
    'application/pdf',
    'text/plain',
    'text/csv',
    'application/msword',
    'application/rtf',
    'text/rtf',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  };

  static Future<IncomingShare?> fromSharedMedia(SharedMediaFile media) async {
    // Video shares are not supported yet, and do not need their path parsed.
    if (media.type == SharedMediaType.video) return null;

    if (media.type == SharedMediaType.text) {
      final rawMessage = media.message ?? '';
      final messageHasContent = _nonWhitespacePattern.hasMatch(rawMessage);
      if (rawMessage.length > maxIncomingTextCharacters &&
          messageHasContent) {
        throw const FormatException(
          'Shared text is over the 1,000,000-character limit.',
        );
      }
      if (rawMessage.length <= maxIncomingTextCharacters &&
          messageHasContent) {
        // Some providers place the effective text in message and leave path
        // empty or populate it with unused metadata. Do not require/copy path.
        return _fromText(rawMessage.trim());
      }
      // An oversized message made only of whitespace is not the effective
      // content. Ignore it and fall back to the provider path without trimming
      // or allocating a same-sized copy of the unused field.

      final rawText = media.path;
      if (rawText.length > maxIncomingTextCharacters) {
        throw const FormatException(
          'Shared text is over the 1,000,000-character limit.',
        );
      }
      final text = rawText.trim();
      if (text.isEmpty) {
        throw const FormatException('The shared text is empty.');
      }
      return _fromText(text);
    }

    if (media.type == SharedMediaType.url) {
      final rawPath = media.path;
      if (rawPath.length > maxIncomingUrlCharacters) {
        throw const FormatException(
          'Shared URLs must be 4,096 characters or shorter.',
        );
      }
      final path = rawPath.trim();
      if (path.isEmpty) {
        throw const FormatException(
          'The shared item did not contain any content.',
        );
      }

      final rawContext = media.message ?? '';
      if (rawContext.length > maxIncomingTextCharacters) {
        throw const FormatException(
          'Shared text is over the 1,000,000-character limit.',
        );
      }
      final sharedContext = rawContext.trim();
      final uri = _parseWebUrl(path);
      if (uri == null) {
        throw const FormatException('Only http and https links can be saved.');
      }
      if (uri.toString().length > maxIncomingUrlCharacters) {
        throw const FormatException(
          'Shared URLs must be 4,096 characters or shorter.',
        );
      }
      return IncomingShare(
        kind: ItemKind.link,
        title: uri.host,
        url: uri.toString(),
        content: sharedContext,
      );
    }

    final rawPath = media.path;
    if (rawPath.length > maxIncomingProviderPathCharacters) {
      throw const FormatException(
        'The shared file path is too long to read safely.',
      );
    }
    if (rawPath.trim().isEmpty) {
      throw const FormatException('The shared item did not contain any content.');
    }
    if (media.type == SharedMediaType.image) {
      return _fromFile(media, forceImage: true);
    }
    return _fromFile(media);
  }

  static IncomingShare _fromText(String text) {
    if (text.trim().isEmpty) {
      throw const FormatException('The shared text is empty.');
    }
    if (text.length > maxIncomingTextCharacters) {
      throw const FormatException('Shared text is over the 1,000,000-character limit.');
    }

    final standaloneText =
        _trimTrailingShareUrlPunctuation(text.trim());
    final standalone = _parseWebUrl(standaloneText);
    if (standalone != null) {
      if (standalone.toString().length > maxIncomingUrlCharacters) {
        throw const FormatException(
          'Shared URLs must be 4,096 characters or shorter.',
        );
      }
      return IncomingShare(
        kind: ItemKind.link,
        title: standalone.host,
        url: standalone.toString(),
      );
    }

    final match = RegExp(
      r'''https?://[^\s<>"']+''',
      caseSensitive: false,
    ).firstMatch(text);
    if (match != null) {
      final rawUrl = _trimTrailingShareUrlPunctuation(match.group(0) ?? '');
      if (rawUrl.length > maxIncomingUrlCharacters) {
        throw const FormatException(
          'Shared URLs must be 4,096 characters or shorter.',
        );
      }
      final uri = _parseWebUrl(rawUrl);
      if (uri != null) {
        final before = text.substring(0, match.start).trim();
        final after = text.substring(match.end).trim();
        final beforeLines = before
            .split(RegExp(r'[\r\n]+'))
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty)
            .toList(growable: false);
        final titleLine =
            beforeLines.isEmpty ? uri.host : beforeLines.first;
        final additionalBefore = beforeLines.length <= 1
            ? ''
            : beforeLines.skip(1).join('\n').trim();
        final noteParts = <String>[
          if (additionalBefore.isNotEmpty) additionalBefore,
          if (after.isNotEmpty) after,
        ];
        final title =
            titleLine.length > 500 ? titleLine.substring(0, 500) : titleLine;
        return IncomingShare(
          kind: ItemKind.link,
          title: title,
          url: uri.toString(),
          content: noteParts.join('\n'),
        );
      }
    }

    return IncomingShare(
      kind: ItemKind.note,
      content: text,
    );
  }

  static Future<IncomingShare> _fromFile(
    SharedMediaFile media, {
    bool forceImage = false,
  }) async {
    final rawPath = media.path.trim();
    final parsedPath = Uri.tryParse(rawPath);
    var localPath = rawPath;
    if (parsedPath?.scheme == 'file') {
      try {
        localPath = parsedPath!.toFilePath();
      } catch (_) {
        // Provider file URIs may contain a non-local authority or invalid
        // path escaping. Hide the raw URI and use stable recovery guidance.
        throw const FormatException(
          'The shared file path could not be read safely.',
        );
      }
    }
    final fileName = _basename(localPath);
    final extension = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : '';
    final rawSharedMime = media.mimeType ?? '';
    if (rawSharedMime.length > 128) {
      throw const FormatException(
        'The shared file type metadata is too long to validate safely.',
      );
    }
    final sharedMime = rawSharedMime.trim().toLowerCase();
    final guessedMime = guessMimeTypeFromExtension(extension);
    final hasRecognizedExtension =
        guessedMime != defaultBinaryMimeType;
    // Known supported extensions determine the stored type when the share
    // source provides a conflicting MIME header. Otherwise an incorrect header
    // can classify a text file as an image (or vice versa).
    final inferredMime = hasRecognizedExtension
        ? guessedMime
        : sharedMime.isEmpty || sharedMime == defaultBinaryMimeType
            ? guessedMime
            : sharedMime;
    // Some source apps identify the intent as an image while attaching a
    // generic/text MIME header. Keep the image classification from the intent,
    // but never persist that contradictory non-image MIME metadata.
    final mimeType = forceImage && !inferredMime.startsWith('image/')
        ? sharedMime.startsWith('image/')
            ? sharedMime
            : defaultBinaryMimeType
        : inferredMime;

    final isImage = forceImage ||
        mimeType.startsWith('image/') ||
        _imageExtensions.contains(extension);
    if (!isImage &&
        !_documentExtensions.contains(extension) &&
        !_documentMimeTypes.contains(mimeType)) {
      throw const FormatException(
        'StashHive currently accepts shared images and PDF, TXT, DOC/DOCX, RTF or CSV files.',
      );
    }
    if (fileName.length > 255) {
      throw const FormatException(
        'The shared filename is too long (maximum 255 characters).',
      );
    }
    if (mimeType.length > 128) {
      throw const FormatException(
        'The shared file type metadata is too long to validate safely.',
      );
    }
    final attachmentName = fileName.isEmpty
        ? (isImage ? 'shared-image' : 'shared-document')
        : fileName;

    final file = XFile(localPath, mimeType: mimeType);
    final length = await file.length();
    if (length > maxIncomingAttachmentBytes) {
      throw const FormatException('Shared files must be 15 MB or smaller.');
    }
    // File providers may report stale/unknown lengths. Enforce the cap while
    // chunks arrive so a bad length response cannot trigger an unbounded
    // allocation through XFile.readAsBytes().
    final bytes = await _readBoundedBytes(file);
    if (bytes.isEmpty) {
      throw const FormatException('The shared file is empty or unavailable.');
    }

    return IncomingShare(
      kind: isImage ? ItemKind.image : ItemKind.document,
      title: fileName.isEmpty
          ? (isImage ? 'Shared image' : 'Shared document')
          : fileName,
      content: '',
      bytes: bytes,
      fileName: attachmentName,
      mimeType: mimeType,
    );
  }

  static Future<Uint8List> _readBoundedBytes(XFile file) =>
      readBoundedByteStream(
        file.openRead(),
        maxBytes: maxIncomingAttachmentBytes,
        limitMessage: 'Shared files must be 15 MB or smaller.',
      );

  /// Removes punctuation that surrounds a shared URL without removing
  /// balanced parentheses/brackets that are legitimately part of its path.
  static String _trimTrailingShareUrlPunctuation(String value) {
    var end = value.length;
    const trailingPunctuation = '.,;:!?';
    while (end > 0 && trailingPunctuation.contains(value[end - 1])) {
      end--;
    }
    final result = value.substring(0, end);
    const pairs = <String, String>{')': '(', ']': '[', '}': '{'};
    final openCounts = <String, int>{'(': 0, '[': 0, '{': 0};
    final closeCounts = <String, int>{')': 0, ']': 0, '}': 0};
    for (var index = 0; index < result.length; index++) {
      final character = result[index];
      if (openCounts.containsKey(character)) {
        openCounts[character] = openCounts[character]! + 1;
      }
      if (closeCounts.containsKey(character)) {
        closeCounts[character] = closeCounts[character]! + 1;
      }
    }
    end = result.length;
    while (end > 0) {
      final closing = result[end - 1];
      final opening = pairs[closing];
      if (opening == null || closeCounts[closing]! <= openCounts[opening]!) {
        break;
      }
      closeCounts[closing] = closeCounts[closing]! - 1;
      end--;
    }
    return result.substring(0, end);
  }

  static Uri? _parseWebUrl(String value) => parseUserWebUrl(value);

  static String _basename(String path) {
    final normalized = path.replaceAll('\\', '/');
    final parts = normalized.split('/').where((part) => part.isNotEmpty);
    return parts.isEmpty ? '' : parts.last;
  }


}
