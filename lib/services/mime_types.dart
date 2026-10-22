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
