import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stashhive/services/attachment_bytes.dart';
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
