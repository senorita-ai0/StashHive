# StashHive — Local PDF text extraction probe

This is an **isolated feasibility tool**, not part of the production StashHive dependency graph. It tests direct extraction from digital/text-bearing PDFs. It does **not** perform OCR, does not modify StashHive's saved items, and does not upload PDF bytes or extracted text.

## Why it is isolated

The main app must stay lean until runtime testing shows that this dependency is reliable on the target platforms. The probe currently targets `pdfrx 2.10.1`; package requirements list Flutter 3.47 / Dart 3.13 or later, matching the project's declared baseline. The engine documents `PdfDocument.openData`, page text loading via `PdfPage.loadText()`, and disposal of opened documents. Check the current upstream references before future version changes:

- [pdfrx package and platform/build requirements](https://pub.dev/packages/pdfrx)
- [PdfDocument API](https://pub.dev/documentation/pdfrx/latest/pdfrx/PdfDocument-class.html)
- [PdfPage.loadText API](https://pub.dev/documentation/pdfrx_engine/latest/pdfrx_engine/PdfPage-class.html)
- [pdfrxFlutterInitialize API](https://pub.dev/documentation/pdfrx/latest/pdfrx/pdfrxFlutterInitialize.html)

## Run the isolated probe

Use the project's pinned Flutter 3.47.2 / Dart 3.13.2 toolchain.

```bash
cd tool/pdf_text_extraction_poc
flutter pub get
flutter test
flutter run -d chrome
```

If platform runners are absent, generate only the runners needed for the target device/browser first:

```bash
flutter create --project-name stashhive_pdf_text_extraction_poc --platforms=android,web .
flutter pub get
```

Do not add `pdfrx` to the production `pubspec.yaml` based on the test fixture alone. A successful widget/unit run is necessary but not sufficient for integration. This project is intentionally outside the root manual workflow; it is not run automatically by source commits.

## Sample protocol

Use synthetic or permissively licensed PDFs only. Do not commit private/copyrighted sample documents.

1. Run the probe against at least 10 small/large digital PDFs with known selectable phrases, including multiline and multicolumn pages.
2. Add expected phrases one per line, record phrase hits/total, extracted character count, page count, elapsed milliseconds, and input byte size in the feasibility report.
3. Test on a real Android device and a supported browser. Repeat each sample at least once cold and once warm; the app screen reports end-to-end elapsed time, with first-use initialization included in the cold measurement.
4. Test an image-only/scanned PDF and a blank PDF. They should report no selectable text; this is not an OCR failure because this probe does not include OCR.
5. Test malformed, encrypted, oversized, and high-page-count samples. Record memory/peak RSS using platform tools, Android APK size delta, web output size delta, offline behavior, and console/network inspection.
6. Try English, Urdu-script and Roman Urdu samples, but treat text extracted from PDF text layers separately from OCR accuracy. Text encoding/font mapping can still produce poor results.

## Limits and statuses

- Input: 15 MiB maximum, aligned with StashHive's imported-attachment limit.
- Pages: 250 maximum.
- Extracted text: 1,000,000 characters maximum.
- Extraction statuses distinguish selectable text, no selectable text, empty input, size/page/output limits, encrypted documents, and generic unreadable/unsupported PDFs.
- The tool deliberately avoids exposing raw PDFium exceptions that may contain path or diagnostic details.

## Acceptance gate before production integration

- All clean digital PDF samples yield every predeclared target phrase; text order/line breaks are reviewed manually.
- Unsupported, encrypted, malformed and textless PDFs fail or report no text without crashing or storing partial content as if successful.
- Native runtime succeeds on target Android and browser runtime works offline after installation, where supported.
- Record measured APK/web size delta, elapsed time and peak memory before adopting it.
- No network request occurs and PDF bytes/text are absent from logs.
- Only after the results are recorded should we consider indexing the extracted text. OCR remains a separate study and should not be promised for Urdu/Nastaleeq without measured accuracy.

**Current status:** Code scaffold and synthetic regression source are committed as an isolated spike. The tests and device/browser measurements have not been run; SH-005 remains blocked on runtime evidence.
