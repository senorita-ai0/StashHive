import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/saved_item.dart';
import '../services/annotation_reanchoring.dart';
import '../services/article_reader.dart';
import '../services/web_url.dart';

typedef SaveArticleReaderSelection = Future<bool> Function(
  String quote,
  int startOffset,
  int endOffset,
  String contextBefore,
  String contextAfter,
);

typedef UpdateArticleReaderAnchor = Future<bool> Function(
  String annotationId,
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
    this.annotationToLocate,
    this.onUpdateAnnotationAnchor,
    super.key,
  });

  final String url;
  final String savedTitle;
  final SaveArticleReaderSelection? onSaveQuote;
  final SavedAnnotation? annotationToLocate;
  final UpdateArticleReaderAnchor? onUpdateAnnotationAnchor;

  @override
  State<ArticleReaderPage> createState() => _ArticleReaderPageState();
}

class _ArticleReaderPageState extends State<ArticleReaderPage> {
  late Future<ArticleReaderResult> _request;
  String? _selectedQuote;
  int? _selectionStart;
  int? _selectionEnd;
  bool _savingQuote = false;
  bool _updatingAnchor = false;
  bool _anchorUpdated = false;

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
    final captured = !selection.isValid || selection.isCollapsed
        ? null
        : captureArticleReaderSelection(text, selection.start, selection.end);
    if (captured == null || captured.quote.trim().isEmpty) {
      if (_selectedQuote != null) {
        setState(() {
          _selectedQuote = null;
          _selectionStart = null;
          _selectionEnd = null;
        });
      }
      return;
    }
    setState(() {
      _selectedQuote = captured.quote;
      _selectionStart = captured.startOffset;
      _selectionEnd = captured.endOffset;
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
    final selection = captureArticleReaderSelection(text, start, end);
    if (selection == null || selection.quote != quote) return;
    setState(() => _savingQuote = true);
    try {
      final saved = await save(
        selection.quote,
        selection.startOffset,
        selection.endOffset,
        selection.contextBefore,
        selection.contextAfter,
      );
      if (!mounted) return;
      if (saved) {
        setState(() {
          _selectedQuote = null;
          _selectionStart = null;
          _selectionEnd = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Highlight saved to this item. It may not align if the article changes.',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Highlight was not saved. Check the item limit or local storage and try again.',
            ),
          ),
        );
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

  Future<void> _updateSavedAnchor(
    String text,
    AnnotationAnchorCandidate candidate,
  ) async {
    final annotation = widget.annotationToLocate;
    final update = widget.onUpdateAnnotationAnchor;
    if (annotation == null || update == null || _updatingAnchor || _anchorUpdated) {
      return;
    }
    final selection = captureArticleReaderSelection(
      text,
      candidate.startOffset,
      candidate.endOffset,
    );
    if (selection == null || selection.quote != annotation.quote) return;

    setState(() => _updatingAnchor = true);
    try {
      final saved = await update(
        annotation.id,
        selection.startOffset,
        selection.endOffset,
        selection.contextBefore,
        selection.contextAfter,
      );
      if (!mounted) return;
      if (saved) {
        setState(() => _anchorUpdated = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Saved highlight position updated. Its quote and note were kept unchanged.',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not update this highlight position. Please retry.'),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not update this highlight position. Please retry.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _updatingAnchor = false);
    }
  }

  Widget _anchorStatusCard(
    BuildContext context,
    AnnotationAnchorResult result,
    String text,
  ) {
    final recommended = result.recommended;
    final (title, message, icon) = switch (result.status) {
      AnnotationAnchorStatus.uniqueQuote => (
          'Saved quote found',
          'This exact quote appears once in the current article. Review the highlighted passage before updating its saved position.',
          Icons.check_circle_outline_rounded,
        ),
      AnnotationAnchorStatus.contextualMatch => (
          'Saved quote matched by context',
          'The quote appears \${result.totalMatches} times. Its surrounding text identifies one strongest match. Review the highlighted passage before updating its saved position.',
          Icons.manage_search_rounded,
        ),
      AnnotationAnchorStatus.ambiguous => (
          'Saved quote has multiple matches',
          '\${result.totalMatches} exact copies were found, but the saved context does not safely distinguish one. Nothing has been highlighted or moved.',
          Icons.help_outline_rounded,
        ),
      AnnotationAnchorStatus.notFound => (
          'Saved quote not found',
          'This exact quote was not found in the current article. The page may have changed; the saved annotation remains untouched.',
          Icons.search_off_rounded,
        ),
      AnnotationAnchorStatus.invalidInput => (
          'Saved quote cannot be located',
          'This annotation does not contain a supported quote for matching.',
          Icons.info_outline_rounded,
        ),
    };

    return Card(
      key: const ValueKey('annotation-anchor-status'),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(message),
            if (recommended != null && !_anchorUpdated) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                key: const ValueKey('update-annotation-anchor'),
                onPressed: _updatingAnchor
                    ? null
                    : () => _updateSavedAnchor(text, recommended),
                icon: _updatingAnchor
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.bookmark_add_outlined),
                label: Text(
                  _updatingAnchor ? 'Updating position…' : 'Update saved position',
                ),
              ),
            ],
            if (_anchorUpdated) ...[
              const SizedBox(height: 8),
              const Text('Saved position now points to this article version.'),
            ],
          ],
        ),
      ),
    );
  }

  TextSpan _articleTextSpan(
    BuildContext context,
    String text,
    AnnotationAnchorCandidate? candidate,
  ) {
    final style = Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.8);
    if (candidate == null) return TextSpan(text: text, style: style);
    final highlightStyle = style?.copyWith(
      backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
      color: Theme.of(context).colorScheme.onTertiaryContainer,
      fontWeight: FontWeight.w800,
    );
    return TextSpan(
      style: style,
      children: [
        TextSpan(text: text.substring(0, candidate.startOffset)),
        TextSpan(
          text: text.substring(candidate.startOffset, candidate.endOffset),
          style: highlightStyle,
        ),
        TextSpan(text: text.substring(candidate.endOffset)),
      ],
    );
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
                          CircularProgressIndicator(
                            semanticsLabel: 'Loading article text',
                          ),
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
                      'The reader supports only credential-free HTTP/HTTPS links on standard ports (80/443).',
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

                final anchorResult = widget.annotationToLocate == null
                    ? null
                    : findSavedAnnotationAnchor(
                        articleText: result.text,
                        annotation: widget.annotationToLocate!,
                      );
                final anchorCandidate = anchorResult?.recommended;
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
                    Semantics(
                      header: true,
                      child: Text(
                        (result.title?.trim().isNotEmpty ?? false)
                            ? result.title!
                            : widget.savedTitle,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      widget.url,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.primary),
                    ),
                    const SizedBox(height: 22),
                    if (anchorResult != null) ...[
                      _anchorStatusCard(context, anchorResult, result.text),
                      const SizedBox(height: 14),
                    ],
                    SelectableText.rich(
                      _articleTextSpan(context, result.text, anchorCandidate),
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
                                          child: CircularProgressIndicator(
                                            semanticsLabel: 'Saving highlight',
                                            strokeWidth: 2,
                                          ),
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
              Semantics(
                header: true,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
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
