# SH-005 — Local PDF text extraction and OCR feasibility

**Date:** 2026-10-29  
**Status (2026-10-29):** Desk research and an isolated source-level PDF text probe are committed. The probe has not been run. No PDF/OCR dependency has been added to the production app; no runtime, app-size, memory, offline, or accuracy claim is made.

## Goal

Let users search text inside saved PDFs and screenshots/images while keeping content local, offline-capable, and private. A digital PDF that already contains selectable text is a different problem from a scanned PDF/image that needs OCR. Evaluate them separately rather than applying OCR to every document.

## Executive recommendation

**Stage this feature rather than introduce one OCR stack for every platform immediately.**

1. Prototype direct text extraction from local, text-bearing PDFs first. `pdfrx`/`pdfrx_engine` is the leading candidate because its published API exposes page text and its package targets Android, iOS, desktop platforms, and web. Validate the exact API, PDF size/memory behavior, and license in a minimal spike before integrating it into StashHive. Sources: [pdfrx on pub.dev](https://pub.dev/packages/pdfrx), [PdfPageText API](https://pub.dev/documentation/pdfrx_engine/latest/pdfrx_engine/PdfPageText-class.html).
2. Evaluate local image/scanned-PDF OCR separately. Tesseract has an official Urdu trained-data file and a fast model set intended to trade some accuracy for speed. The `tesseract_ocr` Flutter plugin documents Android/iOS support and trained-data assets including `urd.traineddata`; this makes it a candidate to test, not proof of Urdu/Nastaleeq accuracy. Sources: [tesseract_ocr package](https://pub.dev/packages/tesseract_ocr), [official Tesseract model documentation](https://tesseract-ocr.github.io/tessdoc/Data-Files).
3. Do not select Google ML Kit as the universal OCR path: its documented Android script models include Latin, Chinese, Devanagari, Japanese, and Korean, not Urdu/Nastaleeq. Its bundled models add about 4 MB per script per architecture; unbundled models are smaller but may need a model download before first use. Source: [ML Kit text recognition for Android](https://developers.google.com/ml-kit/vision/text-recognition/v2/android).
4. Do not use Syncfusion PDF as the default until licensing is decided: it offers cross-platform text extraction, but the package requires a commercial license or a qualifying free Community license. Source: [Syncfusion Flutter PDF](https://pub.dev/packages/syncfusion_flutter_pdf).
5. Do not treat web OCR as offline-ready just because a package lists web support. The `flutter_tesseract_ocr` web instructions show Tesseract.js loaded from an external CDN. A compliant StashHive implementation must bundle the JS/WASM and model assets locally or clearly report that OCR is unavailable; verify it works after network is disabled. Source: [flutter_tesseract_ocr package](https://pub.dev/packages/flutter_tesseract_ocr).

## Candidate matrix

| Candidate | Platform evidence | Strength | Main risk / gap | Decision |
|---|---|---|---|---|
| `pdfrx` / `pdfrx_engine` | Android, iOS, Linux, macOS, Windows, web; API provides page text | Direct extraction from PDFs that already contain text; no OCR model needed for this case | Must validate memory, malformed/encrypted PDF behavior, web bytes input, and exact engine dependency/licensing | **Prototype first for text PDFs** |
| `tesseract_ocr` | Android and iOS | Local OCR with language data; Urdu data is available to test | Language assets increase installed size; speed/accuracy unknown for StashHive samples; no documented web target in this package | Candidate for mobile OCR after size/accuracy spike |
| `flutter_tesseract_ocr` | Android, iOS, web listed | One package advertises multiple platforms | Web instructions load Tesseract.js from CDN; local bundling and offline behavior are not demonstrated by the basic example | Do not adopt until an offline web spike proves it |
| Google ML Kit Text Recognition | On-device Android API; bundled/unbundled variants | Fast native OCR for documented scripts | Urdu/Nastaleeq is not among the documented Android script modules; bundled model size is material, unbundled may download on first use | Not the cross-platform or Urdu solution |
| Syncfusion Flutter PDF | Android, iOS, desktop, web | Direct PDF text extraction | Commercial package; license eligibility must be confirmed | Consider only after license review |
| `pdf_text` / `flutter_pdf_text` | Android and iOS | Direct text from digital PDFs with a simple API | No web support listed, so it would need a separate implementation | Mobile fallback only |

## Required proof of concept

### Sample set

Use synthetic or permissively licensed samples only; do not check private user documents into Git.

- 10 digital PDFs with known selectable text, including short/long documents, multi-column pages, mixed English/Urdu text, and malformed/encrypted cases.
- 10 scanned PDFs/images with clear printed English.
- At least 10 Urdu-script/Nastaleeq samples spanning clean print, screenshots, compression, small text, and mixed-language content.
- Include blank/no-text images and poor-quality samples to check failure handling.
- Keep a machine-readable expected phrase/keyword manifest separate from copyrighted/private source content.

### Measure and record

For each candidate and each sample, record:

- Platform and runtime (Android device/emulator and supported web browser).
- Text presence and language; count of searchable expected phrases found after Unicode normalization.
- Character/token error notes, separately for English and Urdu/Nastaleeq.
- Cold/warm latency, peak memory where measurable, timeout behavior, and app/web bundle-size delta.
- Whether extraction succeeds in airplane mode / offline browser mode.
- Whether source bytes or extracted text appear in logs or network requests.
- Behavior on encrypted, empty, malformed, oversized, and unsupported documents.

### Proposed gates before integration

- Digital-PDF extraction must find all expected target phrases in the clean text-PDF set, with graceful handling of unsupported/encrypted/malformed PDFs.
- For OCR, publish English and Urdu/Nastaleeq results separately. Do not promise a language unless at least 80% of the predeclared search phrases are found in the clean printed sample set; report degraded/noisy samples honestly.
- Set an explicit app-size budget before selecting model assets. Compare fast vs best Tesseract models rather than guessing their size/performance.
- No paid API, server upload, hidden network fetch, or required first-use model download.
- Extraction status must distinguish not requested, completed with text, completed with no usable text, unsupported, and failed.
- Extracted text must be bounded and treated as rebuildable derived data, not as a replacement for the original attachment. Search must continue to work if extraction is unavailable.
- Do not OCR every file automatically on import. Start with an explicit user action or bounded queue after file save, with progress, cancellation, and retry.
- Run the manual validation checkpoint before promoting this from a proof of concept to a release feature.

## Isolated probe scaffold (source only; not yet executed)

A separate, non-production Flutter package now lives in [`tool/pdf_text_extraction_poc`](../../tool/pdf_text_extraction_poc/README.md). It targets `pdfrx 2.10.1`, bounds local input to 15 MiB, caps processing at 250 pages and 1,000,000 extracted characters, reports text/no-text/limit/failure statuses, and includes a manual phrase-recall screen plus synthetic PDF test source.

Current API references were rechecked on 29 October 2026:
- `pdfrx 2.10.1` requires Flutter 3.47 / Dart 3.13 or later and lists Android, iOS, desktop, and Web support. These are upstream platform claims, not proof that StashHive's own builds will succeed. See [pdfrx package documentation](https://pub.dev/documentation/pdfrx/latest/).
- `PdfDocument.openData` accepts in-memory PDF bytes and `sourceName`; `PdfDocument.isEncrypted` and `dispose()` are documented. See [PdfDocument API](https://pub.dev/documentation/pdfrx/latest/pdfrx/PdfDocument-class.html).
- `PdfPage.loadText()` returns raw selectable text through `PdfPageRawText.fullText`. This is text-layer extraction, not OCR. See [PdfPage API](https://pub.dev/documentation/pdfrx_engine/latest/pdfrx_engine/PdfPage-class.html) and [PdfPageRawText API](https://pub.dev/documentation/pdfrx_engine/latest/pdfrx_engine/PdfPageRawText-class.html).

The probe deliberately remains outside the production dependency graph and root CI workflow. The scaffold, synthetic fixture, and test code are **not yet verified**. At the manual validation checkpoint, run the isolated package's tests and platform builds, profile Android APK/web bundle size and peak memory, check offline operation, and record results for the sample protocol below. Do not integrate the dependency into StashHive unless those results meet the acceptance gates.

## Scope decision

SH-005 remains **BLOCKED on runtime feasibility evidence**, not on code availability. The immediate engineering slice should be digital PDF text extraction first, then evaluate OCR. No OCR dependency or model has been added to the production `pubspec.yaml`. The isolated probe has its own `pubspec.yaml`; its package resolution and runtime behavior have not been verified.
