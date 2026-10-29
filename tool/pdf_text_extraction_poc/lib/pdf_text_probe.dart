import 'dart:typed_data';

import 'package:pdfrx/pdfrx.dart';

const int maxPdfTextProbeInputBytes = 15 * 1024 * 1024;
const int maxPdfTextProbePages = 250;
const int maxPdfTextProbeCharacters = 1000000;

enum PdfTextProbeStatus {
  textFound,
  noSelectableText,
  inputEmpty,
  inputTooLarge,
  pageLimitExceeded,
  extractedTextTooLarge,
  encrypted,
  failed;

  String get label => switch (this) {
        PdfTextProbeStatus.textFound => 'Selectable text extracted',
        PdfTextProbeStatus.noSelectableText => 'No selectable text found',
        PdfTextProbeStatus.inputEmpty => 'Empty PDF',
        PdfTextProbeStatus.inputTooLarge => 'PDF exceeds the probe size limit',
        PdfTextProbeStatus.pageLimitExceeded => 'PDF exceeds the probe page limit',
        PdfTextProbeStatus.extractedTextTooLarge =>
          'Extracted text exceeds the probe output limit',
        PdfTextProbeStatus.encrypted => 'Encrypted PDF',
        PdfTextProbeStatus.failed => 'Could not read this PDF',
      };
}

class PdfTextProbeResult {
  const PdfTextProbeResult({
    required this.status,
    required this.text,
    required this.pageCount,
    required this.inputBytes,
    required this.elapsed,
  });

  final PdfTextProbeStatus status;
  final String text;
  final int pageCount;
  final int inputBytes;
  final Duration elapsed;

  int get characterCount => text.length;

  bool get hasSelectableText =>
      status == PdfTextProbeStatus.textFound && text.trim().isNotEmpty;
}

/// Performs an isolated, local-only probe of text that is already selectable
/// in a PDF. This does not run OCR and does not send bytes or text over a
/// network. It is deliberately not wired into the production StashHive app.
///
/// The probe bounds input bytes, page count and extracted characters so test
/// samples cannot allocate unbounded extraction output. Runtime measurements
/// and platform suitability must be verified before moving this into the app.
Future<PdfTextProbeResult> probePdfBytes(Uint8List bytes) async {
  if (bytes.isEmpty) {
    return PdfTextProbeResult(
      status: PdfTextProbeStatus.inputEmpty,
      text: '',
      pageCount: 0,
      inputBytes: 0,
      elapsed: Duration.zero,
    );
  }
  if (bytes.length > maxPdfTextProbeInputBytes) {
    return PdfTextProbeResult(
      status: PdfTextProbeStatus.inputTooLarge,
      text: '',
      pageCount: 0,
      inputBytes: bytes.length,
      elapsed: Duration.zero,
    );
  }

  final stopwatch = Stopwatch()..start();
  PdfDocument? document;
  var pageCount = 0;
  var extractedText = '';
  var status = PdfTextProbeStatus.failed;

  try {
    await pdfrxFlutterInitialize();
    document = await PdfDocument.openData(
      bytes,
      sourceName: 'memory:stashhive-pdf-text-probe',
    );

    pageCount = document.pages.length;
    if (document.isEncrypted) {
      status = PdfTextProbeStatus.encrypted;
    } else if (pageCount > maxPdfTextProbePages) {
      status = PdfTextProbeStatus.pageLimitExceeded;
    } else {
      final output = StringBuffer();
      status = PdfTextProbeStatus.noSelectableText;

      for (final page in document.pages) {
        final rawText = await page.loadText();
        final pageText = rawText?.fullText ?? '';
        if (pageText.isEmpty) continue;

        final separatorLength = output.isEmpty ? 0 : 1;
        if (output.length + separatorLength + pageText.length >
            maxPdfTextProbeCharacters) {
          status = PdfTextProbeStatus.extractedTextTooLarge;
          break;
        }

        if (separatorLength != 0) output.write('\n');
        output.write(pageText);
        status = PdfTextProbeStatus.textFound;
      }

      if (status == PdfTextProbeStatus.textFound) {
        extractedText = output.toString();
        if (extractedText.trim().isEmpty) {
          extractedText = '';
          status = PdfTextProbeStatus.noSelectableText;
        }
      }
    }
  } catch (_) {
    // Do not expose PDFium/plugin internals or file content in the UI.
    status = PdfTextProbeStatus.failed;
    extractedText = '';
  } finally {
    if (document != null) {
      try {
        await document.dispose();
      } catch (_) {
        // Preserve the bounded probe result; disposal details are not user data.
      }
    }
    stopwatch.stop();
  }

  return PdfTextProbeResult(
    status: status,
    text: extractedText,
    pageCount: pageCount,
    inputBytes: bytes.length,
    elapsed: stopwatch.elapsed,
  );
}
