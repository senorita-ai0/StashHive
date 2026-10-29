import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'pdf_text_probe.dart';

void main() {
  runApp(const PdfTextProbeApp());
}

class PdfTextProbeApp extends StatelessWidget {
  const PdfTextProbeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StashHive PDF Text Probe',
      theme: ThemeData(colorSchemeSeed: const Color(0xFF5265D9), useMaterial3: true),
      home: const PdfTextProbeHome(),
    );
  }
}

class PdfTextProbeHome extends StatefulWidget {
  const PdfTextProbeHome({super.key});

  @override
  State<PdfTextProbeHome> createState() => _PdfTextProbeHomeState();
}

class _PdfTextProbeHomeState extends State<PdfTextProbeHome> {
  final TextEditingController _expectedPhrasesController = TextEditingController();
  PdfTextProbeResult? _result;
  String? _fileName;
  String? _message;
  bool _busy = false;

  @override
  void dispose() {
    _expectedPhrasesController.dispose();
    super.dispose();
  }

  Future<Uint8List> _readBoundedFile(Stream<List<int>> stream) async {
    final builder = BytesBuilder(copy: false);
    var total = 0;
    await for (final chunk in stream) {
      if (chunk.length > maxPdfTextProbeInputBytes - total) {
        throw const FormatException('PDF samples must be 15 MB or smaller.');
      }
      total += chunk.length;
      builder.add(chunk);
    }
    return builder.takeBytes();
  }

  Future<void> _pickAndProbe() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
      _result = null;
      _fileName = null;
    });

    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
      );
      if (!mounted || file == null) return;

      final declaredSize = await file.length();
      if (!mounted) return;
      if (declaredSize <= 0) {
        setState(() => _message = 'The selected PDF is empty or unreadable.');
        return;
      }
      if (declaredSize > maxPdfTextProbeInputBytes) {
        setState(() => _message = 'PDF samples must be 15 MB or smaller.');
        return;
      }

      final bytes = await _readBoundedFile(file.readAsByteStream());
      if (!mounted) return;
      final result = await probePdfBytes(bytes);
      if (!mounted) return;
      setState(() {
        _fileName = file.name;
        _result = result;
      });
    } on FormatException catch (error) {
      if (mounted) setState(() => _message = error.message.toString());
    } catch (_) {
      if (mounted) {
        setState(() => _message = 'Could not read this PDF sample. Choose another file and try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  List<String> get _expectedPhrases => _expectedPhrasesController.text
      .split('\n')
      .map((phrase) => phrase.trim())
      .where((phrase) => phrase.isNotEmpty)
      .toList(growable: false);

  int get _matchedPhrases {
    final text = _result?.text.toLowerCase() ?? '';
    return _expectedPhrases
        .where((phrase) => text.contains(phrase.toLowerCase()))
        .length;
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return Scaffold(
      appBar: AppBar(title: const Text('StashHive PDF text feasibility')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Isolated proof of concept',
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tests text already embedded in PDFs. Scanned/image PDFs require OCR and are not evaluated by this screen.',
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy ? null : _pickAndProbe,
            icon: _busy
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf_outlined),
            label: Text(_busy ? 'Extracting text…' : 'Choose local PDF sample'),
          ),
          if (_message != null) ...[
            const SizedBox(height: 12),
            Text(_message!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          if (result != null) ...[
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_fileName ?? 'Selected PDF', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text('Status: ${result.status.label}'),
                    Text('Input: ${result.inputBytes} bytes'),
                    Text('Pages: ${result.pageCount}'),
                    Text('Extracted characters: ${result.characterCount}'),
                    Text('Elapsed: ${result.elapsed.inMilliseconds} ms (includes first-use initialization when cold)'),
                    if (_expectedPhrases.isNotEmpty)
                      Text('Expected phrases found: $_matchedPhrases / ${_expectedPhrases.length}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _expectedPhrasesController,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Expected phrases (one per line)',
                helperText: 'Enter known text from this sample to measure simple phrase recall.',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            Text('Extracted text', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (result.text.isEmpty)
              const Text('No extracted text to display.')
            else
              SelectableText(
                result.text.length > 4000
                    ? '${result.text.substring(0, 4000)}\n… preview truncated …'
                    : result.text,
              ),
          ],
          const SizedBox(height: 20),
          const Text(
            'Privacy: processing occurs locally in this probe. The PDF is not saved by the probe and neither PDF bytes nor extracted text are uploaded. This package is not yet a production StashHive dependency.',
          ),
        ],
      ),
    );
  }
}
