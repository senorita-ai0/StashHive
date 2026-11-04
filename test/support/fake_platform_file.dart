import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';

/// In-memory [PlatformFile] for tests.
///
/// file_picker 12 made [PlatformFile] an abstract base class and removed the
/// old `PlatformFile(name:, size:, bytes:)` constructor, so tests that need a
/// picked file build one from these bytes instead.
final class FakePlatformFile extends PlatformFile {
  FakePlatformFile({required this.name, required Uint8List bytes})
      : _bytes = bytes;

  @override
  final String name;

  final Uint8List _bytes;

  @override
  Uri get uri => Uri(scheme: 'memory', path: '/$name');

  @override
  XFile get xFile => XFile.fromData(_bytes, name: name);

  @override
  int? lengthSync() => _bytes.length;

  @override
  Future<int> length() async => _bytes.length;

  @override
  Future<Uint8List> readAsBytes() async => _bytes;

  @override
  Stream<Uint8List> readAsByteStream() => Stream<Uint8List>.value(_bytes);
}
