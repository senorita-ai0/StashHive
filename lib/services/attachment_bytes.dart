import 'dart:typed_data';

import 'backup_codec.dart';

/// Returns true only when [value] is a non-empty byte list within the
/// attachment cap. Check length before iterating so an oversized legacy list
/// can be rejected without inspecting every element.
bool isValidAttachmentByteList(Object? value) {
  if (value is Uint8List) {
    // Typed byte buffers can only contain values in 0..255, so their length
    // check is enough and avoids scanning every byte during repeated preflight.
    return value.isNotEmpty && value.length <= BackupCodec.maxAttachmentBytes;
  }
  if (value is! List ||
      value.isEmpty ||
      value.length > BackupCodec.maxAttachmentBytes) {
    return false;
  }
  for (final byte in value) {
    if (byte is! int || byte < 0 || byte > 255) return false;
  }
  return true;
}
