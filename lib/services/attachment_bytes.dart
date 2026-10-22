import '../services/backup_codec.dart';

/// Returns true only when [value] is a non-empty byte list within the
/// attachment cap. Check length before iterating so an oversized legacy list
/// can be rejected without inspecting every element.
bool isValidAttachmentByteList(Object? value) {
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
