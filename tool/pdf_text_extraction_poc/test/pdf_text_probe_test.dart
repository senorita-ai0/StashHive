import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stashhive_pdf_text_extraction_poc/pdf_text_probe.dart';

Uint8List _buildMinimalPdf(String contentStream) {
  final buffer = StringBuffer('%PDF-1.4\n');
  final offsets = <int>[0];

  void writeObject(int number, String body) {
    offsets.add(buffer.length);
    buffer.write('$number 0 obj\n$body\nendobj\n');
  }

  writeObject(1, '<< /Type /Catalog /Pages 2 0 R >>');
  writeObject(2, '<< /Type /Pages /Kids [3 0 R] /Count 1 >>');
  writeObject(
    3,
    '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] '
    '/Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>',
  );
  writeObject(4, '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>');
  writeObject(
    5,
    '<< /Length ${utf8.encode(contentStream).length} >>\n'
    'stream\n$contentStream\nendstream',
  );

  final xrefOffset = buffer.length;
  buffer.write('xref\n0 6\n0000000000 65535 f \n');
  for (final offset in offsets.skip(1)) {
    buffer.write('${offset.toString().padLeft(10, '0')} 00000 n \n');
  }
  buffer.write(
    'trailer\n<< /Size 6 /Root 1 0 R >>\n'
    'startxref\n$xrefOffset\n%%EOF\n',
  );
  return Uint8List.fromList(utf8.encode(buffer.toString()));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('extracts selectable text from an in-memory PDF', () async {
    final pdfBytes = _buildMinimalPdf(
      'BT /F1 18 Tf 72 720 Td (StashHive searchable phrase 123) Tj ET',
    );

    final result = await probePdfBytes(pdfBytes);

    expect(result.status, PdfTextProbeStatus.textFound);
    expect(result.pageCount, 1);
    expect(result.inputBytes, pdfBytes.length);
    expect(result.text, contains('StashHive searchable phrase 123'));
    expect(result.characterCount, greaterThan(0));
    expect(result.elapsed.inMilliseconds, greaterThanOrEqualTo(0));
  });

  test('reports textless PDF separately from a successful text extraction',
      () async {
    final result = await probePdfBytes(
      _buildMinimalPdf('q 72 720 80 20 re f Q'),
    );

    expect(result.status, PdfTextProbeStatus.noSelectableText);
    expect(result.text, isEmpty);
    expect(result.pageCount, 1);
  });

  test('rejects empty and oversized bytes before opening PDFium', () async {
    final empty = await probePdfBytes(Uint8List(0));
    expect(empty.status, PdfTextProbeStatus.inputEmpty);

    final oversized = await probePdfBytes(
      Uint8List(maxPdfTextProbeInputBytes + 1),
    );
    expect(oversized.status, PdfTextProbeStatus.inputTooLarge);
    expect(oversized.elapsed, Duration.zero);
  });

  test('returns a safe failure result for malformed PDF input', () async {
    final result = await probePdfBytes(
      Uint8List.fromList(utf8.encode('this is not a PDF')),
    );

    expect(result.status, PdfTextProbeStatus.failed);
    expect(result.text, isEmpty);
  });
}
