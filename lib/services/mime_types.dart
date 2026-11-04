/// MIME type helpers shared by file-picker and OS share intake.
const String defaultBinaryMimeType = 'application/octet-stream';

String guessMimeTypeFromExtension(String extension) {
  return switch (extension.toLowerCase()) {
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'gif' => 'image/gif',
    'webp' => 'image/webp',
    'bmp' => 'image/bmp',
    'heic' => 'image/heic',
    'heif' => 'image/heif',
    'tif' || 'tiff' => 'image/tiff',
    'pdf' => 'application/pdf',
    'txt' => 'text/plain',
    'csv' => 'text/csv',
    'doc' => 'application/msword',
    'docx' =>
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'rtf' => 'application/rtf',
    _ => defaultBinaryMimeType,
  };
}

String guessMimeTypeFromFilename(String fileName) {
  final normalized = fileName.replaceAll('\\', '/');
  final basename = normalized.split('/').last;
  final dot = basename.lastIndexOf('.');
  if (dot <= 0 || dot == basename.length - 1) {
    return defaultBinaryMimeType;
  }
  return guessMimeTypeFromExtension(basename.substring(dot + 1));
}

/// Short, uppercase file-type label (for example `PDF`) for a document
/// preview, or `null` when the name has no usable extension.
///
/// Only the extension is read; the file name itself is never returned, so a
/// preview can show the type without repeating a private file name.
String? fileExtensionBadge(String? fileName) {
  if (fileName == null) return null;
  final basename = fileName.replaceAll('\\', '/').split('/').last.trim();
  final dot = basename.lastIndexOf('.');
  if (dot <= 0 || dot == basename.length - 1) return null;
  final extension = basename.substring(dot + 1);
  // Real extensions are short and alphanumeric; anything else would be noise.
  if (extension.length > 5 || !RegExp(r'^[A-Za-z0-9]+$').hasMatch(extension)) {
    return null;
  }
  return extension.toUpperCase();
}
