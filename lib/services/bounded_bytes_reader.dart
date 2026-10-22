import 'dart:typed_data';

/// Reads a byte stream without ever accumulating more than [maxBytes].
///
/// [limitMessage] is used for the recoverable error shown to the caller.
Future<Uint8List> readBoundedByteStream(
  Stream<List<int>> chunks, {
  required int maxBytes,
  required String limitMessage,
}) async {
  if (maxBytes <= 0) {
    throw ArgumentError.value(maxBytes, 'maxBytes', 'Must be positive.');
  }

  final builder = BytesBuilder(copy: false);
  var totalBytes = 0;
  await for (final chunk in chunks) {
    if (chunk.length > maxBytes - totalBytes) {
      throw FormatException(limitMessage);
    }
    totalBytes += chunk.length;
    builder.add(chunk);
  }
  return builder.takeBytes();
}
