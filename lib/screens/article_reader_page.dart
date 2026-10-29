import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/saved_item.dart';
import '../services/article_reader.dart';
import '../services/web_url.dart';

typedef SaveArticleReaderSelection = Future<bool> Function(
  String quote,
  int startOffset,
  int endOffset,
  String contextBefore,
  String contextAfter,
);

class ArticleReaderPage extends StatefulWidget {
  const ArticleReaderPage({
    required this.url,
    required this.savedTitle,
    this.onSaveQuote,
    super.key,
  });

  final String url;
  final String savedTitle;
  final SaveArticleReaderSelection? onSaveQuote;

  @override
  State<ArticleReaderPage> createState() => _ArticleReaderPageState();
}

class _ArticleReaderPageState extends State<ArticleReaderPage> {
  late Future<ArticleReaderResult> _request;
  String? _selectedQuote;
  int? _selectionStart;
  int? _selectionEnd;
  bool _savingQuote = false;

  @override
  void initState() {
    super.initState();
    // This route is only pushed by an explicit user tap. There is no automatic
    // request from save, search, background refresh or item details loading.
    _request = loadArticleForReader(widget.url);
  }

  void _retry() {
    setState(() => _request = loadArticleForReader(widget.url));
  }

  void _onTextSelectionChanged(String text, TextSelection selection) {
    if (!selection.isValid ||
        selection.isCollapsed ||
        selection.start < 0 ||
        selection.end > text.length) {
      if (_selectedQuote != null) {
        setState(() {
          _selectedQuote = null;
          _selectionStart = null;
          _selectionEnd = null;
        });
      }
      return;
    }
    final start = selection.start;
    final end = selection.end;
    final quote = text.substring(start, end);
    setState(() {
      _selectedQuote = quote.trim().isEmpty ? null : quote;
      _selectionStart = quote.trim().isEmpty ? null : start;
      _selectionEnd = quote.trim().isEmpty ? null : end;
    });
  }

  Future<void> _saveSelectedQuote(String text) async {
    final save = widget.onSaveQuote;
    final quote = _selectedQuote;
    final start = _selectionStart;
    final end = _selectionEnd;
    if (save == null ||
        quote == null ||
        start == null ||
        end == null ||
        quote.trim().isEmpty ||
        quote.length > maxSavedAnnotationQuoteCharacters ||
        _savingQuote) {
      return;
    }
    final beforeStart = (start - 80).clamp(0, start).toInt();
    final afterEnd = (end + 80).clamp(end, text.length).toInt();
    setState(() => _savingQuote = true);
    try {
      final saved = await save(
        quote,
        start,
        end,
        text.substring(beforeStart, start),
        text.substring(end, afterEnd),
      );
      if (saved && mounted) {
        setState(() {
          _selectedQuote = null;
          _selectionStart = null;
          _selectionEnd = null;
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save this highlight. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _savingQuote = false);
    }
  }

  Future<void> _openExternal() async {
    // External navigation is a separate explicit user action; it may open a
    // local site that the in-app network reader deliberately refuses to fetch.
    final uri = parseHttpUrl(widget.url);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This is not a valid HTTP or HTTPS URL.')),
      );
      return;
    }
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No app could open this link.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open this link externally.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reader'),
        actions: [
          IconButton(
            tooltip: 'Open in browser',
            onPressed: _openExternal,
            icon: const Icon(Icons.open_in_new_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: FutureBuilder<ArticleReaderResult>(
              future: _request,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Loading this page only because you asked to read it…'),
                        ],
                      ),
                    ),
                  );
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return _ReaderMessage(
                    icon: Icons.cloud_off_outlined,
                    title: 'Reader could not load this page',
                    message: 'Your saved bookmark is unchanged. You can retry or open it in your browser.',
                    onRetry: _retry,
                    onOpenExternal: _openExternal,
                  );
                }
                final result = snapshot.data!;
                if (!result.isSuccess) {
                  final message = switch (result.state) {
                    ArticleReaderState.invalidUrl =>
                      'This saved URL is not a valid HTTP or HTTPS address.',
                    ArticleReaderState.blockedAddress =>
                      'This address is local or reserved, so StashHive will not request it.',
                    ArticleReaderState.unsupportedContent =>
                      result.message ?? 'This page does not contain supported readable text.',
                    ArticleReaderState.tooLarge =>
                      'This page exceeds the 1 MB reader download limit. Your bookmark is unchanged.',
                    ArticleReaderState.timedOut =>
                      'The website took too long to respond. Try again or open it in your browser.',
                    ArticleReaderState.unavailableInBrowser =>
                      result.message ?? 'Browser security prevents reading this site directly.',
                    ArticleReaderState.networkError =>
                      result.message ?? 'The page could not be loaded. It may be offline or may redirect.',
                    ArticleReaderState.success => '',
                  };
                  return _ReaderMessage(
                    icon: result.state == ArticleReaderState.blockedAddress
                        ? Icons.shield_outlined
                        : Icons.article_outlined,
                    title: 'Article preview unavailable',
                    message: message,
                    onRetry: result.state == ArticleReaderState.invalidUrl ||
                            result.state == ArticleReaderState.blockedAddress ||
                            result.state == ArticleReaderState.unavailableInBrowser
                        ? null
                        : _retry,
                    onOpenExternal: _openExternal,
                  );
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 36),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: .55),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Temporary online preview. StashHive does not save this page for offline use. The original bookmark and your library remain unchanged.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      (result.title?.trim().isNotEmpty ?? false)
                          ? result.title!
                          : widget.savedTitle,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      widget.url,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.primary),
                    ),
                    const SizedBox(height: 22),
                    SelectableText(
                      result.text,
                      key: const ValueKey('article-reader-text'),
                      onSelectionChanged: (selection, _) =>
                          _onTextSelectionChanged(result.text, selection),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.8),
                    ),
                    if (widget.onSaveQuote != null && _selectedQuote != null) ...[
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'SELECTED PASSAGE',
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _selectedQuote!,
                                maxLines: 5,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 10),
                              if (_selectedQuote!.length > maxSavedAnnotationQuoteCharacters)
                                Text(
                                  'Select a shorter passage (up to $maxSavedAnnotationQuoteCharacters characters).',
                                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                                ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: FilledButton.icon(
                                  key: const ValueKey('save-reader-highlight'),
                                  onPressed: _savingQuote ||
                                          _selectedQuote!.length > maxSavedAnnotationQuoteCharacters
                                      ? null
                                      : () => _saveSelectedQuote(result.text),
                                  icon: _savingQuote
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Icon(Icons.bookmark_add_outlined),
                                  label: Text(_savingQuote ? 'Saving…' : 'Save highlight'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    OutlinedButton.icon(
                      onPressed: _openExternal,
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: const Text('Open original website'),
                    ),
                    if (kIsWeb) ...[
                      const SizedBox(height: 8),
                      Text(
                        'The browser may limit access to some external sites.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ReaderMessage extends StatelessWidget {
  const _ReaderMessage({
    required this.icon,
    required this.title,
    required this.message,
    required this.onOpenExternal,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final VoidCallback onOpenExternal;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 46, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5)),
              const SizedBox(height: 20),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: [
                  if (onRetry != null)
                    OutlinedButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Try again'),
                    ),
                  FilledButton.icon(
                    onPressed: onOpenExternal,
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: const Text('Open in browser'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
