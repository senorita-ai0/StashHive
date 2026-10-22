import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stashhive/services/attachment_bytes.dart';
import 'package:stashhive/services/bounded_bytes_reader.dart';
import 'package:stashhive/services/backup_codec.dart';

class _OversizedByteList extends ListBase<int> {
  _OversizedByteList(this._length);

  final int _length;

  @override
  int get length => _length;

  @override
  set length(int value) => throw UnsupportedError('length is fixed');

  @override
  int operator [](int index) => 0;

  @override
  void operator []=(int index, int value) {
    throw UnsupportedError('read-only test list');
  }
}

void main() {
  group('readBoundedByteStream', () {
    test('joins chunks that remain within the attachment cap', () async {
      final bytes = await readBoundedByteStream(
        Stream<List<int>>.fromIterable([
          [1, 2],
          [3, 4, 5],
        ]),
        maxBytes: 5,
        limitMessage: 'too large',
      );

      expect(bytes, orderedEquals([1, 2, 3, 4, 5]));
    });

    test('stops reading as soon as the stream exceeds the cap', () async {
      var producedChunks = 0;
      Stream<List<int>> chunks() async* {
        producedChunks++;
        yield [1, 2, 3];
        producedChunks++;
        yield [4, 5, 6];
        producedChunks++;
        yield [7];
      }

      await expectLater(
        readBoundedByteStream(
          chunks(),
          maxBytes: 5,
          limitMessage: 'Shared files must be 15 MB or smaller.',
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'Shared files must be 15 MB or smaller.',
          ),
        ),
      );
      expect(
        producedChunks,
        2,
        reason: 'The reader must cancel instead of consuming later chunks.',
      );
    });
  });

  group('isValidAttachmentByteList', () {
    test('accepts non-empty byte lists within the cap', () {
      expect(isValidAttachmentByteList([0, 1, 127, 255]), isTrue);
      expect(isValidAttachmentByteList(Uint8List.fromList([8, 9, 10])), isTrue);
    });

    test('rejects null, empty and invalid byte values', () {
      expect(isValidAttachmentByteList(null), isFalse);
      expect(isValidAttachmentByteList(<int>[]), isFalse);
      expect(isValidAttachmentByteList([1, -1, 2]), isFalse);
      expect(isValidAttachmentByteList([1, 256]), isFalse);
      expect(isValidAttachmentByteList(<Object?>[1, 'invalid', 2]), isFalse);
    });

    test('rejects an oversized list before iterating its elements', () {
      final oversized = _OversizedByteList(
        BackupCodec.maxAttachmentBytes + 1,
      );

      expect(isValidAttachmentByteList(oversized), isFalse);
    });
  });
}
