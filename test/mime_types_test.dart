import 'package:flutter_test/flutter_test.dart';
import 'package:stashhive/services/mime_types.dart';

void main() {
  group('guessMimeTypeFromExtension', () {
    test('recognizes supported image extensions consistently', () {
      expect(guessMimeTypeFromExtension('JPG'), 'image/jpeg');
      expect(guessMimeTypeFromExtension('jpeg'), 'image/jpeg');
      expect(guessMimeTypeFromExtension('png'), 'image/png');
      expect(guessMimeTypeFromExtension('bmp'), 'image/bmp');
      expect(guessMimeTypeFromExtension('heic'), 'image/heic');
      expect(guessMimeTypeFromExtension('heif'), 'image/heif');
      expect(guessMimeTypeFromExtension('tif'), 'image/tiff');
      expect(guessMimeTypeFromExtension('tiff'), 'image/tiff');
    });

    test('recognizes supported document extensions', () {
      expect(guessMimeTypeFromExtension('pdf'), 'application/pdf');
      expect(guessMimeTypeFromExtension('txt'), 'text/plain');
      expect(guessMimeTypeFromExtension('csv'), 'text/csv');
      expect(guessMimeTypeFromExtension('doc'), 'application/msword');
      expect(
        guessMimeTypeFromExtension('docx'),
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      );
      expect(guessMimeTypeFromExtension('rtf'), 'application/rtf');
    });

    test('uses generic MIME for unknown extensions', () {
      expect(guessMimeTypeFromExtension('exe'), defaultBinaryMimeType);
      expect(guessMimeTypeFromExtension(''), defaultBinaryMimeType);
    });
  });

  group('guessMimeTypeFromFilename', () {
    test('handles paths, mixed case and Windows separators', () {
      expect(
        guessMimeTypeFromFilename(r'C:\Users\me\PHOTO.HEIC'),
        'image/heic',
      );
      expect(guessMimeTypeFromFilename('/tmp/report.PDF'), 'application/pdf');
      expect(guessMimeTypeFromFilename('README'), defaultBinaryMimeType);
      expect(guessMimeTypeFromFilename('.hidden'), defaultBinaryMimeType);
      expect(guessMimeTypeFromFilename('file.'), defaultBinaryMimeType);
    });
  });
}
