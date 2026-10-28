import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform, visibleForTesting;
import 'package:flutter/material.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'data/library_repository.dart';
import 'models/saved_item.dart';
import 'services/bounded_bytes_reader.dart';
import 'services/share_intake.dart';
import 'services/mime_types.dart';
import 'services/backup_codec.dart';
import 'services/web_url.dart';
import 'ui/layout_metrics.dart';

const Color kBrand = Color(0xFF5B5CE2);
const Color kInk = Color(0xFF1B2340);
const Color kMutedLight = Color(0xFF646C82);
const Color kMutedDark = Color(0xFFAAB2C5);

Color mutedTextColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark ? kMutedDark : kMutedLight;

Color favoriteStarColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFE1A52B)
        : const Color(0xFF996400);

/// Preserve app-defined validation guidance without exposing raw plugin or
/// storage exception details in normal user-facing messages.
String _messageForOperationError(
  Object error, {
  required String fallback,
}) {
  if (error is FormatException) return error.message.toString();
  return fallback;
}

/// Combines the platform accessibility scaler with StashHive's optional
/// extra text-size preference without lowering platform-provided scaling.
class _PreferenceTextScaler extends TextScaler {
  const _PreferenceTextScaler({
    required this.system,
    required this.multiplier,
  });

  final TextScaler system;
  final double multiplier;

  @override
  double scale(double fontSize) => system.scale(fontSize) * multiplier;

  @override
  bool operator ==(Object other) =>
      other is _PreferenceTextScaler &&
      other.system == system &&
      other.multiplier == multiplier;

  @override
  int get hashCode => Object.hash(system, multiplier);
}

const Color kCanvas = Color(0xFFF8F9FD);
const Color kBorder = Color(0xFFE7E9F2);
const int kMaxAttachmentBytes = BackupCodec.maxAttachmentBytes;

/// Test hook for resolving delayed file-picker requests without invoking a
/// platform picker. Production leaves this unset.
@visibleForTesting
Future<PlatformFile?> Function(ItemKind kind)? quickSaveAttachmentPickerForTesting;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final repository = await LibraryRepository.open();
    runApp(StashHiveApp(
      repository: repository,
      initialDarkMode: repository.darkMode,
    ));
  } catch (_) {
    runApp(const StartupFailureApp());
  }
}

class StartupFailureApp extends StatelessWidget {
  const StartupFailureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.hive_rounded, size: 52, color: kBrand),
                  const SizedBox(height: 18),
                  Text('StashHive could not open its local library',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  Text(
                    kIsWeb
                        ? 'Your existing data was not intentionally reset. Check this browser profile’s storage, reload the page and try again. Technical details are hidden because they may include local paths.'
                        : 'Your existing data was not intentionally reset. Check available device storage, restart StashHive and try again. Technical details are hidden because they may include local paths.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class StashHiveApp extends StatefulWidget {
  const StashHiveApp({
    required this.repository,
    required this.initialDarkMode,
    super.key,
  });

  final LibraryRepository repository;
  final bool initialDarkMode;

  @override
  State<StashHiveApp> createState() => _StashHiveAppState();
}

class _StashHiveAppState extends State<StashHiveApp> {
  late bool _darkMode = widget.initialDarkMode;
  late double _textScaleMultiplier = widget.repository.textScaleMultiplier;

  Future<void> _setTextScaleMultiplier(double value) async {
    setState(() => _textScaleMultiplier = value);
    try {
      await widget.repository.setTextScaleMultiplier(value);
    } catch (_) {
      if (mounted) {
        setState(() {
          _textScaleMultiplier = widget.repository.textScaleMultiplier;
        });
      }
    }
  }

  Future<void> _setDarkMode(bool value) async {
    setState(() => _darkMode = value);
    try {
      await widget.repository.setDarkMode(value);
    } catch (_) {
      // The repository attempts to roll back a failed preference write. Keep
      // the visible theme aligned with whatever value remains persisted, and
      // do not leak an unhandled async exception from the Switch callback.
      if (mounted) {
        setState(() => _darkMode = widget.repository.darkMode);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StashHive',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: _darkMode ? ThemeMode.dark : ThemeMode.light,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: _PreferenceTextScaler(
              system: mediaQuery.textScaler,
              multiplier: _textScaleMultiplier,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: HomeShell(
        repository: widget.repository,
        darkMode: _darkMode,
        onDarkModeChanged: _setDarkMode,
        textScaleMultiplier: _textScaleMultiplier,
        onTextScaleChanged: _setTextScaleMultiplier,
      ),
    );
  }
}

ThemeData buildLightTheme() {
  final colors = ColorScheme.fromSeed(
    seedColor: kBrand,
    brightness: Brightness.light,
  ).copyWith(
    primary: kBrand,
    onPrimary: Colors.white,
    surface: Colors.white,
    onSurface: kInk,
    outline: kBorder,
    error: const Color(0xFFC74A5B),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: colors,
    scaffoldBackgroundColor: kCanvas,
    dividerColor: kBorder,
    appBarTheme: const AppBarTheme(
      backgroundColor: kCanvas,
      foregroundColor: kInk,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: kBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: kBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: kBrand, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Color(0xFFC74A5B)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: kBrand,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kBrand,
        minimumSize: const Size(0, 44),
        side: const BorderSide(color: kBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFFEEF0FF),
      side: const BorderSide(color: kBorder),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      labelStyle: const TextStyle(fontSize: 12, color: kMutedLight),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: const Color(0xFFEEF0FF),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        return TextStyle(
          fontSize: 11,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
        );
      }),
    ),
  );
}

ThemeData buildDarkTheme() {
  final colors = ColorScheme.fromSeed(
    seedColor: kBrand,
    brightness: Brightness.dark,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: colors,
    scaffoldBackgroundColor: const Color(0xFF131724),
    dividerColor: const Color(0xFF343A4D),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF131724),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF202638),
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Color(0xFF343A4D)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Color(0xFF343A4D)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: kBrand, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: kBrand,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Color(0xFF1A2030),
      indicatorColor: Color(0xFF34345F),
    ),
  );
}

class HomeShell extends StatefulWidget {
  const HomeShell({
    required this.repository,
    required this.darkMode,
    required this.onDarkModeChanged,
    required this.textScaleMultiplier,
    required this.onTextScaleChanged,
    super.key,
  });

  final LibraryRepository repository;
  final bool darkMode;
  final ValueChanged<bool> onDarkModeChanged;
  final double textScaleMultiplier;
  final ValueChanged<double> onTextScaleChanged;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedTab = 0;
  String _searchSeed = '';
  int _searchRevision = 0;

  StreamSubscription<List<SharedMediaFile>>? _shareSubscription;
  final List<({List<SharedMediaFile> media, Completer<void> done})>
      _pendingShareBatches = [];
  final ShareEventDeduplicator _shareDeduplicator =
      ShareEventDeduplicator();
  bool _processingShareBatches = false;
  bool _showStorageReminder = false;

  @override
  void initState() {
    super.initState();
    _showStorageReminder = !widget.repository.hasSeenStorageReminder;
    // Incoming share intents are configured for Android only in this phase.
    // The browser build and unsupported platforms never invoke the native plugin.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _startShareIntake();
      });
    }
  }

  Future<void> _acknowledgeStorageReminder({
    required bool openBackup,
  }) async {
    if (!mounted) return;
    setState(() => _showStorageReminder = false);
    try {
      await widget.repository.markStorageReminderSeen();
    } catch (_) {
      // The reminder is non-critical; if the preference cannot be saved,
      // it will be offered again on the next app/browser launch.
    }
    if (openBackup && mounted) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => BackupPrivacyPage(repository: widget.repository),
        ),
      );
    }
  }

  void _startShareIntake() {
    _shareSubscription = ReceiveSharingIntent.instance.getMediaStream().listen(
      (media) {
        unawaited(_enqueueShareBatch(media));
      },
      onError: (Object _) {
        _showShareMessage(
          'Could not receive that share. You can still add the item manually.',
        );
      },
    );
    unawaited(_readInitialShare());
  }

  Future<void> _readInitialShare() async {
    try {
      await consumeInitialSharedMedia(
        readInitialMedia: ReceiveSharingIntent.instance.getInitialMedia,
        resetInitialMedia: () async {
          await ReceiveSharingIntent.instance.reset();
        },
        enqueue: _enqueueShareBatch,
      );
    } catch (_) {
      if (mounted) {
        _showShareMessage(
          'Could not read the incoming share. You can add it manually.',
        );
      }
    }
  }

  Future<void> _enqueueShareBatch(List<SharedMediaFile> media) async {
    if (media.isEmpty || !_shareDeduplicator.shouldAccept(media)) return;
    final done = Completer<void>();
    _pendingShareBatches.add((
      media: List<SharedMediaFile>.unmodifiable(media),
      done: done,
    ));
    unawaited(_drainShareQueue());
    await done.future;
  }

  Future<void> _drainShareQueue() async {
    if (_processingShareBatches) return;
    _processingShareBatches = true;
    try {
      while (_pendingShareBatches.isNotEmpty && mounted) {
        final batch = _pendingShareBatches.removeAt(0);
        try {
          await _presentSharedItem(batch.media);
        } catch (_) {
          _showShareMessage(
            'That item could not be prepared. Try adding it manually.',
          );
        } finally {
          if (!batch.done.isCompleted) batch.done.complete();
        }
      }
    } finally {
      _processingShareBatches = false;
      if (_pendingShareBatches.isNotEmpty && mounted) {
        unawaited(_drainShareQueue());
      }
    }
  }

  Future<void> _presentSharedItem(List<SharedMediaFile> media) async {
    if (!mounted || media.isEmpty) return;

    // Multi-select shares are reviewed one item at a time. Each route is
    // explicit: the user can save or cancel each draft before the next opens.
    for (var index = 0; index < media.length; index++) {
      if (!mounted) return;
      try {
        final incoming = await ShareIntake.fromSharedMedia(media[index]);
        if (!mounted) return;
        if (incoming == null) {
          _showShareMessage(
            'Item ${index + 1} of ${media.length} is not supported yet; it was skipped.',
          );
          continue;
        }
        final prepared = incoming.withShareProgress(
          position: index + 1,
          total: media.length,
        );
        await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => QuickSavePage(
              repository: widget.repository,
              initialKind: prepared.kind,
              initialShare: prepared,
            ),
          ),
        );
      } on FormatException catch (error) {
        _showShareMessage(
          'Item ${index + 1} of ${media.length}: ${error.message}',
        );
      } catch (_) {
        _showShareMessage(
          'Item ${index + 1} of ${media.length} could not be prepared and was skipped.',
        );
      }
    }
    if (mounted) setState(() => _selectedTab = 0);
  }

  void _showShareMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    unawaited(_shareSubscription?.cancel() ?? Future<void>.value());
    for (final batch in _pendingShareBatches) {
      if (!batch.done.isCompleted) batch.done.complete();
    }
    _pendingShareBatches.clear();
    super.dispose();
  }


  Future<void> _openAdd(ItemKind? kind) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => QuickSavePage(
          repository: widget.repository,
          initialKind: kind ?? ItemKind.link,
        ),
      ),
    );
    if (mounted) setState(() => _selectedTab = 0);
  }

  void _openSearch(String query) {
    setState(() {
      _searchSeed = query;
      _searchRevision++;
      _selectedTab = 1;
    });
  }

  void _openItem(SavedItem item) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ItemDetailsPage(
          repository: widget.repository,
          itemId: item.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      LibraryPage(
        repository: widget.repository,
        onAdd: _openAdd,
        onSearch: _openSearch,
        onOpenItem: _openItem,
        showStorageReminder: _showStorageReminder,
        onDismissStorageReminder: () => unawaited(
          _acknowledgeStorageReminder(openBackup: false),
        ),
        onCreateBackup: () => unawaited(
          _acknowledgeStorageReminder(openBackup: true),
        ),
      ),
      SearchPage(
        key: ValueKey<int>(_searchRevision),
        repository: widget.repository,
        initialQuery: _searchSeed,
        onOpenItem: _openItem,
      ),
      CollectionsPage(
        repository: widget.repository,
        onOpenItem: _openItem,
        onAdd: _openAdd,
      ),
      SettingsPage(
        repository: widget.repository,
        darkMode: widget.darkMode,
        onDarkModeChanged: widget.onDarkModeChanged,
        textScaleMultiplier: widget.textScaleMultiplier,
        onTextScaleChanged: widget.onTextScaleChanged,
      ),
    ];
    return Scaffold(
      body: IndexedStack(index: _selectedTab, children: pages),
      floatingActionButton: _selectedTab == 0
          ? FloatingActionButton(
              onPressed: () => _openAdd(null),
              tooltip: 'Save something',
              backgroundColor: kBrand,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add_rounded, size: 30),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (index) => setState(() => _selectedTab = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view_rounded),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'Library',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_rounded),
            selectedIcon: Icon(Icons.search_rounded),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_copy_outlined),
            selectedIcon: Icon(Icons.folder_copy_rounded),
            label: 'Collections',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _StorageSafetyReminder extends StatelessWidget {
  const _StorageSafetyReminder({
    required this.onDismiss,
    required this.onCreateBackup,
  });

  final VoidCallback onDismiss;
  final VoidCallback onCreateBackup;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined, color: colors.onSecondaryContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Keep your library safe',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.onSecondaryContainer,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            kIsWeb
                ? 'Your library stays in this browser profile. Clearing site data can erase it, and it does not sync to other browsers or devices.'
                : 'Your library stays on this device. Uninstalling the app or clearing app data can erase it, and it does not sync to the web.',
            style: TextStyle(
              color: colors.onSecondaryContainer,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                TextButton(
                  onPressed: onDismiss,
                  child: const Text('Got it'),
                ),
                FilledButton.tonal(
                  onPressed: onCreateBackup,
                  child: const Text('Backup options'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LibraryPage extends StatefulWidget {
  const LibraryPage({
    required this.repository,
    required this.onAdd,
    required this.onSearch,
    required this.onOpenItem,
    this.showStorageReminder = false,
    this.onDismissStorageReminder,
    this.onCreateBackup,
    super.key,
  });

  final LibraryRepository repository;
  final ValueChanged<ItemKind?> onAdd;
  final ValueChanged<String> onSearch;
  final ValueChanged<SavedItem> onOpenItem;
  final bool showStorageReminder;
  final VoidCallback? onDismissStorageReminder;
  final VoidCallback? onCreateBackup;

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  String _filter = 'All';
  String _sort = 'Recently saved';

  List<SavedItem> _applyFilters(List<SavedItem> items) {
    var result = items;
    if (_filter == 'Favorites') {
      result = result.where((item) => item.isFavorite).toList();
    } else if (_filter != 'All') {
      result = result.where((item) => item.kind.pluralLabel == _filter).toList();
    }
    result = List<SavedItem>.from(result);
    final sortMode = switch (_sort) {
      'Title A–Z' => SavedItemSort.titleAZ,
      'Oldest first' => SavedItemSort.oldestFirst,
      _ => SavedItemSort.recentlySaved,
    };
    result.sort((a, b) => compareSavedItemsForSort(a, b, sortMode));
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const BrandMark(size: 37),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'StashHive',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Filter and sort',
                      onPressed: () => _showSortMenu(context),
                      icon: const Icon(Icons.tune_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text('Your library',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.7,
                        )),
                const SizedBox(height: 5),
                Text('A home for the things worth keeping.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        )),
                if (widget.showStorageReminder)
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: _StorageSafetyReminder(
                      onDismiss: widget.onDismissStorageReminder ?? () {},
                      onCreateBackup: widget.onCreateBackup ?? () {},
                    ),
                  ),
                const SizedBox(height: 17),
                ValueListenableBuilder<int>(
                  valueListenable: widget.repository.skippedRecordCount,
                  builder: (context, skippedRecords, _) {
                    return ValueListenableBuilder<int>(
                      valueListenable:
                          widget.repository.skippedCollectionCount,
                      builder: (context, skippedCollections, _) {
                        if (skippedRecords == 0 && skippedCollections == 0) {
                          return const SizedBox.shrink();
                        }
                        final messages = <String>[];
                        if (skippedRecords > 0) {
                          messages.add(
                            skippedRecords == 1
                                ? '1 saved record could not be read.'
                                : '$skippedRecords saved records could not be read.',
                          );
                        }
                        if (skippedCollections > 0) {
                          messages.add(
                            skippedCollections == 1
                                ? '1 collection name or assignment was invalid, duplicated, or beyond the 500-collection limit.'
                                : '$skippedCollections collection names or assignments were invalid, duplicated, or beyond the 500-collection limit.',
                          );
                        }
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Semantics(
                            liveRegion: true,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.errorContainer,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    color: Theme.of(context).colorScheme.onErrorContainer,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      "${messages.join(' ')} The raw entries were not deleted, but this view or a new backup may omit invalid entries. Move any item assigned to a collection beyond the cap to an available collection or choose No collection. Avoid clearing app/browser data; use a previous backup if you need to recover data.",
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onErrorContainer,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                Semantics(
                  button: true,
                  label: 'Search your library',
                  hint: 'Opens the Search tab',
                  onTap: () => widget.onSearch(''),
                  child: InkWell(
                    onTap: () => widget.onSearch(''),
                    borderRadius: BorderRadius.circular(16),
                    child: ExcludeSemantics(
                      child: IgnorePointer(
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Search links, notes, screenshots…',
                            prefixIcon: Icon(Icons.search_rounded),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 13),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final label in const [
                        'All',
                        'Links',
                        'Images',
                        'Notes',
                        'Files',
                        'Favorites',
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 7),
                          child: ChoiceChip(
                            label: Text(label),
                            selected: _filter == label,
                            onSelected: (_) => setState(() => _filter = label),
                            showCheckmark: false,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      _filter == 'All' ? 'Recently saved' : _filter,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const Spacer(),
                    PopupMenuButton<String>(
                      tooltip: 'Sort library',
                      initialValue: _sort,
                      onSelected: (value) => setState(() => _sort = value),
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'Recently saved', child: Text('Recently saved')),
                        PopupMenuItem(value: 'Oldest first', child: Text('Oldest first')),
                        PopupMenuItem(value: 'Title A–Z', child: Text('Title A–Z')),
                      ],
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 3),
                        child: Row(
                          children: [
                            Text(_sort, style: const TextStyle(fontSize: 12, color: kBrand)),
                            const Icon(Icons.expand_more_rounded, color: kBrand, size: 19),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ValueListenableBuilder<List<SavedItem>>(
                    valueListenable: widget.repository.items,
                    builder: (context, items, _) {
                      final shown = _applyFilters(items);
                      if (shown.isEmpty) {
                        return EmptyLibraryState(
                          isFiltered: _filter != 'All',
                          onAdd: () => widget.onAdd(null),
                          onClear: () => setState(() => _filter = 'All'),
                        );
                      }
                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final columns = constraints.maxWidth >= 690 ? 2 : 1;
                          return GridView.builder(
                            padding: const EdgeInsets.fromLTRB(0, 2, 0, 22),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: columns,
                              mainAxisExtent: savedItemCardExtentForTextScale(
                                savedItemTextScaleFactor(
                                  MediaQuery.textScalerOf(context).scale(14.0),
                                ),
                              ),
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 10,
                            ),
                            itemCount: shown.length,
                            itemBuilder: (context, index) => SavedItemTile(
                              item: shown[index],
                              repository: widget.repository,
                              onTap: () => widget.onOpenItem(shown[index]),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showSortMenu(BuildContext context) async {
    final chosen = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Library preferences',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              for (final item in const [
                ('Recently saved', Icons.schedule_rounded),
                ('Oldest first', Icons.history_rounded),
                ('Title A–Z', Icons.sort_by_alpha_rounded),
              ])
                ListTile(
                  leading: Icon(item.$2, color: kBrand),
                  title: Text(item.$1),
                  trailing: _sort == item.$1 ? const Icon(Icons.check_rounded, color: kBrand) : null,
                  onTap: () => Navigator.pop(context, item.$1),
                ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
    if (chosen != null && mounted) setState(() => _sort = chosen);
  }
}

class EmptyLibraryState extends StatelessWidget {
  const EmptyLibraryState({
    required this.isFiltered,
    required this.onAdd,
    required this.onClear,
    super.key,
  });

  final bool isFiltered;
  final VoidCallback onAdd;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 86,
                width: 86,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF0FF),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(Icons.auto_awesome_mosaic_rounded,
                    color: kBrand, size: 40),
              ),
              const SizedBox(height: 20),
              Text(
                isFiltered ? 'Nothing here yet' : 'Save your first good find',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isFiltered
                    ? 'Try another filter or add something new to this library.'
                    : 'Links, ideas, screenshots and files—all in one calm, searchable place.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: mutedTextColor(context)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: isFiltered ? onClear : onAdd,
                icon: Icon(isFiltered ? Icons.filter_alt_off_rounded : Icons.add_rounded),
                label: Text(isFiltered ? 'Clear filter' : 'Save something'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SearchPage extends StatefulWidget {
  const SearchPage({
    required this.repository,
    required this.initialQuery,
    required this.onOpenItem,
    super.key,
  });

  final LibraryRepository repository;
  final String initialQuery;
  final ValueChanged<SavedItem> onOpenItem;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialQuery);
  String _filter = 'All';
  String _sort = 'Recently saved';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<SavedItem> _search(List<SavedItem> items) {
    final query = _controller.text;
    final results = items.where((item) {
      final kindMatch = _filter == 'All' || item.kind.pluralLabel == _filter;
      return kindMatch && item.matchesQuery(query);
    }).toList();

    final sortMode = switch (_sort) {
      'Title A–Z' => SavedItemSort.titleAZ,
      'Oldest first' => SavedItemSort.oldestFirst,
      _ => SavedItemSort.recentlySaved,
    };
    results.sort((a, b) => compareSavedItemsForSort(a, b, sortMode));
    return results;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Search',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.7,
                        )),
                const SizedBox(height: 6),
                Text('Find something you saved, without remembering where.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: mutedTextColor(context))),
                const SizedBox(height: 18),
                TextField(
                  controller: _controller,
                  autofocus: widget.initialQuery.isNotEmpty,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search titles, URLs, notes, tags and collections',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _controller.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            onPressed: () {
                              _controller.clear();
                              setState(() {});
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                ),
                const SizedBox(height: 14),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final label in const ['All', 'Links', 'Images', 'Notes', 'Files'])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(label),
                            selected: _filter == label,
                            onSelected: (_) => setState(() => _filter = label),
                            showCheckmark: false,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ValueListenableBuilder<List<SavedItem>>(
                    valueListenable: widget.repository.items,
                    builder: (context, items, _) {
                      final results = _search(items);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Semantics(
                                liveRegion: true,
                                label:
                                    '${results.length} ${results.length == 1 ? 'result' : 'results'}',
                                child: ExcludeSemantics(
                                  child: Text(
                                    '${results.length} ${results.length == 1 ? 'result' : 'results'}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          color: mutedTextColor(context),
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ),
                              ),
                              PopupMenuButton<String>(
                                tooltip: 'Sort search results',
                                initialValue: _sort,
                                onSelected: (value) =>
                                    setState(() => _sort = value),
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'Recently saved',
                                    child: Text('Recently saved'),
                                  ),
                                  PopupMenuItem(
                                    value: 'Oldest first',
                                    child: Text('Oldest first'),
                                  ),
                                  PopupMenuItem(
                                    value: 'Title A–Z',
                                    child: Text('Title A–Z'),
                                  ),
                                ],
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 6,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _sort,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: kBrand,
                                        ),
                                      ),
                                      const Icon(
                                        Icons.expand_more_rounded,
                                        color: kBrand,
                                        size: 19,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: results.isEmpty
                                ? EmptySearchState(
                                    hasQuery: _controller.text.trim().isNotEmpty,
                                    hasFilter: _filter != 'All',
                                    hasLibraryItems: items.isNotEmpty,
                                    onClear: () {
                                      _controller.clear();
                                      setState(() => _filter = 'All');
                                    },
                                  )
                                : LayoutBuilder(
                                    builder: (context, constraints) {
                                      final columns = constraints.maxWidth >= 690 ? 2 : 1;
                                      return GridView.builder(
                                        padding: const EdgeInsets.only(bottom: 20),
                                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: columns,
                                          mainAxisExtent: savedItemCardExtentForTextScale(
                                            savedItemTextScaleFactor(
                                              MediaQuery.textScalerOf(context).scale(14.0),
                                            ),
                                          ),
                                          crossAxisSpacing: 12,
                                          mainAxisSpacing: 10,
                                        ),
                                        itemCount: results.length,
                                        itemBuilder: (context, index) => SavedItemTile(
                                          item: results[index],
                                          repository: widget.repository,
                                          onTap: () => widget.onOpenItem(results[index]),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EmptySearchState extends StatelessWidget {
  const EmptySearchState({
    required this.hasQuery,
    required this.hasFilter,
    required this.hasLibraryItems,
    required this.onClear,
    super.key,
  });

  final bool hasQuery;
  final bool hasFilter;
  final bool hasLibraryItems;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final filterHasNoMatches = hasFilter && hasLibraryItems;
    final hasNoResults = hasQuery || filterHasNoMatches;
    final actionLabel = hasQuery && hasFilter
        ? 'Clear search and filter'
        : hasQuery
            ? 'Clear search'
            : 'Clear filter';
    final message = hasQuery && hasFilter
        ? 'Try a different word, or clear both the search and type filter.'
        : hasQuery
            ? 'Try a different word, a URL, a note or a tag.'
            : filterHasNoMatches
                ? 'Try another type or clear the filter to see all your saved items.'
                : 'Your saved items will appear here as soon as you add them.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 46, color: mutedTextColor(context)),
            const SizedBox(height: 12),
            Text(
              hasQuery
                  ? 'No matches found'
                  : filterHasNoMatches
                      ? 'No items in this filter'
                      : 'Your search starts here',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: mutedTextColor(context)),
            ),
            if (hasNoResults || hasFilter) ...[
              const SizedBox(height: 14),
              OutlinedButton(onPressed: onClear, child: Text(actionLabel)),
            ],
          ],
        ),
      ),
    );
  }
}

class SavedItemTile extends StatelessWidget {
  const SavedItemTile({
    required this.item,
    required this.repository,
    required this.onTap,
    super.key,
  });

  final SavedItem item;
  final LibraryRepository repository;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _ItemThumbnail(item: item, repository: repository, size: 72),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (item.isFavorite)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Semantics(
                              label: 'Saved as a favorite',
                              child: Icon(
                                Icons.star_rounded,
                                size: 16,
                                color: favoriteStarColor(context),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _summary(item),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(color: mutedTextColor(context)),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: item.kind.softAccent,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            item.kind.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: item.kind.readableTextAccent,
                            ),
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            _dateLabel(item.updatedAt),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: mutedTextColor(context),
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Actions for ${item.title}',
                icon: Icon(Icons.more_horiz_rounded, color: mutedTextColor(context)),
                onSelected: (action) async {
                  if (action == 'favorite') {
                    try {
                      await repository.toggleFavorite(item.id);
                    } catch (error) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Could not update this item. ' +
                                  _messageForOperationError(
                                    error,
                                    fallback:
                                        'Check local storage and try again.',
                                  ),
                            ),
                          ),
                        );
                      }
                    }
                  } else if (action == 'open') {
                    onTap();
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'favorite',
                    child: Text(item.isFavorite ? 'Remove favorite' : 'Add to favorites'),
                  ),
                  const PopupMenuItem(value: 'open', child: Text('View details')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _summary(SavedItem item) {
    if (item.url != null) return item.url!;
    if (item.content.trim().isNotEmpty) return item.content.trim();
    if (item.attachmentName != null) return item.attachmentName!;
    return 'Saved locally';
  }

  String _dateLabel(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return difference.inMinutes.toString() + 'm ago';
    if (difference.inDays < 1) return difference.inHours.toString() + 'h ago';
    if (difference.inDays == 1) return 'Yesterday';
    return date.day.toString().padLeft(2, '0') + ' ' + _monthName(date.month);
  }

  String _monthName(int month) => const [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][month - 1];
}

class _ItemThumbnail extends StatelessWidget {
  const _ItemThumbnail({
    required this.item,
    required this.repository,
    required this.size,
  });

  final SavedItem item;
  final LibraryRepository repository;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (item.kind == ItemKind.image && item.attachmentKey != null) {
      return FutureBuilder<Uint8List?>(
        future: repository.readAttachment(item.attachmentKey!),
        builder: (context, snapshot) {
          if (snapshot.data != null && snapshot.data!.isNotEmpty) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: Image.memory(
                snapshot.data!,
                semanticLabel: 'Image preview: ${item.title}',
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallback(),
              ),
            );
          }
          return _fallback();
        },
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: item.kind.softAccent,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(item.kind.icon, color: item.kind.accent, size: 27),
    );
  }
}

class QuickSavePage extends StatefulWidget {
  const QuickSavePage({
    required this.repository,
    this.initialKind = ItemKind.link,
    this.existingItem,
    this.initialShare,
    super.key,
  });

  final LibraryRepository repository;
  final ItemKind initialKind;
  final SavedItem? existingItem;
  final IncomingShare? initialShare;

  @override
  State<QuickSavePage> createState() => _QuickSavePageState();
}

class _QuickSavePageState extends State<QuickSavePage> {
  final _formKey = GlobalKey<FormState>();
  late ItemKind _kind =
      widget.existingItem?.kind ?? widget.initialShare?.kind ?? widget.initialKind;
  late final TextEditingController _titleController = TextEditingController(
    text: widget.existingItem?.title ?? widget.initialShare?.title ?? '',
  );
  late final TextEditingController _urlController = TextEditingController(
    text: widget.existingItem?.url ?? widget.initialShare?.url ?? '',
  );
  late final TextEditingController _contentController = TextEditingController(
    text: widget.existingItem?.content ?? widget.initialShare?.content ?? '',
  );
  late final TextEditingController _tagsController =
      TextEditingController(text: widget.existingItem?.tags.join(', ') ?? '');
  late String? _collection = widget.existingItem?.collection;
  Uint8List? _selectedBytes;
  String? _selectedName;
  String? _selectedMimeType;
  bool _saving = false;
  bool _pickingAttachment = false;
  bool _allowSaveCompletionPop = false;
  int _attachmentSelectionRevision = 0;

  @override
  void initState() {
    super.initState();
    _selectedBytes = widget.initialShare?.bytes;
    _selectedName = widget.initialShare?.fileName;
    _selectedMimeType = widget.initialShare?.mimeType;
    final existingCollection = _collection;
    if (existingCollection != null) {
      String? canonicalCollection;
      for (final name in widget.repository.collections.value) {
        if (name.toLowerCase() == existingCollection.toLowerCase()) {
          canonicalCollection = name;
          break;
        }
      }
      _collection = canonicalCollection;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  bool _isCurrentAttachmentRequest(int revision, ItemKind requestedKind) =>
      mounted &&
      revision == _attachmentSelectionRevision &&
      _kind == requestedKind;

  Future<void> _pickAttachment() async {
    if (_saving || _pickingAttachment) return;
    final requestedKind = _kind;
    final requestRevision = _attachmentSelectionRevision;
    setState(() => _pickingAttachment = true);

    try {
      final testPicker = quickSaveAttachmentPickerForTesting;
      final file = testPicker != null
          ? await testPicker(requestedKind)
          : await FilePicker.pickFile(
              type: requestedKind == ItemKind.image
                  ? FileType.image
                  : FileType.custom,
              allowedExtensions: requestedKind == ItemKind.image
                  ? null
                  : const ['pdf', 'txt', 'doc', 'docx', 'rtf', 'csv'],
            );
      if (!_isCurrentAttachmentRequest(requestRevision, requestedKind) ||
          file == null) {
        return;
      }
      if (file.name.trim().isEmpty) {
        _showMessage(
          'The selected file has no usable filename. Rename it and try again.',
        );
        return;
      }
      if (file.name.length > 255) {
        _showMessage('Filenames must be 255 characters or shorter.');
        return;
      }

      // Inspect file length before allocating the full byte buffer. On web and
      // mobile this keeps oversized selections from consuming unbounded memory.
      final length = await file.length();
      if (!_isCurrentAttachmentRequest(requestRevision, requestedKind)) return;
      if (length == 0) {
        _showMessage(
          'That file is empty or its size could not be determined. Choose another file.',
        );
        return;
      }
      if (length > kMaxAttachmentBytes) {
        _showMessage('Files must be 15 MB or smaller in this version.');
        return;
      }

      final bytes = await readBoundedByteStream(
        file.readAsByteStream(),
        maxBytes: kMaxAttachmentBytes,
        limitMessage: 'Files must be 15 MB or smaller in this version.',
      );
      if (!_isCurrentAttachmentRequest(requestRevision, requestedKind)) return;
      if (bytes.isEmpty) {
        _showMessage('Could not read that file. Try selecting it again.');
        return;
      }
      setState(() {
        _selectedBytes = bytes;
        _selectedName = file.name;
        _selectedMimeType = _mimeTypeFor(file.name);
      });
    } catch (error) {
      if (_isCurrentAttachmentRequest(requestRevision, requestedKind)) {
        _showMessage(
          _messageForOperationError(
            error,
            fallback: 'The file could not be selected. Try choosing it again.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _pickingAttachment = false);
    }
  }

  String _mimeTypeFor(String name) => guessMimeTypeFromFilename(name);

  List<String> _parseTags() {
    final seen = <String>{};
    final result = <String>[];
    for (final raw in _tagsController.text.split(',')) {
      final tag = raw.trim();
      if (tag.isNotEmpty && seen.add(tag.toLowerCase())) result.add(tag);
    }
    return result;
  }

  Future<void> _save() async {
    if (_saving || _pickingAttachment) return;
    if (!_formKey.currentState!.validate()) return;
    final existing = widget.existingItem;
    final needsAttachment =
        _kind == ItemKind.image || _kind == ItemKind.document;
    final preservesExistingAttachment = needsAttachment &&
        existing?.kind == _kind &&
        (existing?.hasAttachment ?? false);
    if (needsAttachment &&
        _selectedBytes == null &&
        !preservesExistingAttachment) {
      _showMessage('Choose a file before saving.');
      return;
    }
    setState(() => _saving = true);
    try {
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;
      final id = existing?.id ?? widget.repository.createUniqueId();
      String? url;
      var title = _titleController.text.trim();
      final content = _contentController.text.trim();
      if (_kind == ItemKind.link) {
        final entered = _urlController.text.trim();
        final uri = parseUserWebUrl(entered);
        if (uri == null) {
          _showMessage('Enter a valid http or https website URL.');
          setState(() => _saving = false);
          return;
        }
        url = uri.toString();
        if (url.length > maxSavedItemUrlCharacters) {
          _showMessage('Website URLs must be 4,096 characters or shorter.');
          setState(() => _saving = false);
          return;
        }
        if (title.isEmpty) title = uri.host;
      } else if (title.isEmpty) {
        if (_kind == ItemKind.note) {
          final firstLine = content.split('\n').first.trim();
          title = firstLine.length > 38 ? firstLine.substring(0, 38) : firstLine;
          if (title.isEmpty) title = 'Untitled note';
        } else {
          title = _selectedName ??
              existing?.attachmentName ??
              (_kind == ItemKind.image ? 'Saved image' : 'Saved document');
        }
      }
      if (title.length > 500) {
        _showMessage('Use a shorter title (up to 500 characters).');
        setState(() => _saving = false);
        return;
      }
      final tags = _parseTags();
      if (tags.length > 100) {
        _showMessage('Use 100 tags or fewer for each saved item.');
        setState(() => _saving = false);
        return;
      }
      if (tags.any((tag) => tag.length > 100)) {
        _showMessage('Tags must be 100 characters or shorter.');
        setState(() => _saving = false);
        return;
      }
      // Preserve a shared attachment key for metadata-only edits. If the
      // user chooses replacement bytes, use this item's ID as a new key so
      // changing one item does not overwrite the bytes shared by other items.
      final String? attachmentKey = _selectedBytes != null
          ? widget.repository.attachmentKeyForReplacement(
              id,
              currentAttachmentKey: existing?.attachmentKey,
            )
          : preservesExistingAttachment
              ? existing!.attachmentKey
              : null;
      final item = SavedItem(
        id: id,
        kind: _kind,
        title: title,
        content: content,
        url: url,
        tags: List<String>.unmodifiable(tags),
        collection: _collection,
        isFavorite: existing?.isFavorite ?? false,
        createdAtMs: existing?.createdAtMs ?? now,
        updatedAtMs: now,
        attachmentKey: attachmentKey,
        attachmentName: _selectedBytes != null
            ? _selectedName
            : preservesExistingAttachment
                ? existing?.attachmentName
                : null,
        attachmentMimeType: _selectedBytes != null
            ? _selectedMimeType
            : preservesExistingAttachment
                ? existing?.attachmentMimeType
                : null,
      );
      await widget.repository.save(item, attachmentBytes: _selectedBytes);
      if (mounted) {
        // Re-enable route popping only after the successful save has completed,
        // then wait for PopScope to rebuild before closing the route.
        setState(() => _allowSaveCompletionPop = true);
        await WidgetsBinding.instance.endOfFrame;
        if (mounted) Navigator.of(context).pop(true);
      }
    } catch (error) {
      _showMessage(
        'Could not save this item. ' +
            _messageForOperationError(
              error,
              fallback: 'Check the item details and selected file, then try again.',
            ),
      );
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _validateTitle(String? value) {
    if ((value?.length ?? 0) > 500) return 'Use 500 characters or fewer.';
    return null;
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingItem != null;
    final fileKind = _kind == ItemKind.image || _kind == ItemKind.document;
    return PopScope<bool>(
      canPop: !_saving || _allowSaveCompletionPop,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Back',
            onPressed: _saving ? null : () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: Text(isEditing ? 'Edit item' : 'Quick save'),
          actions: [
            if (isEditing)
              IconButton(
                tooltip: 'Cancel',
                onPressed: _saving ? null : () => Navigator.of(context).pop(false),
                icon: const Icon(Icons.close_rounded),
              ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  children: [
                    Text(isEditing ? 'Refine your saved item' : 'Save something useful',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            )),
                    const SizedBox(height: 6),
                    Text(
                      'Keep the things you want to find again.',
                      style: TextStyle(color: mutedTextColor(context)),
                    ),
                    if ((widget.initialShare?.shareTotal ?? 1) > 1) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF2DF),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Text(
                          'Item ${widget.initialShare!.sharePosition} of ${widget.initialShare!.shareTotal}. Save or cancel this draft to continue to the next shared item.',
                          style: const TextStyle(fontSize: 12, height: 1.4),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    if (!isEditing) _buildKindPicker(),
                    if (!isEditing) const SizedBox(height: 20),
                    if (_kind == ItemKind.link) ...[
                      TextFormField(
                        controller: _urlController,
                        enabled: !_saving,
                        keyboardType: TextInputType.url,
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        decoration: const InputDecoration(
                          labelText: 'Website URL',
                          hintText: 'https://example.com',
                          prefixIcon: Icon(Icons.link_rounded),
                        ),
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) {
                            return 'Enter a website URL.';
                          }
                          final uri = parseUserWebUrl(value);
                          if (uri == null) {
                            return 'Enter a valid http or https URL.';
                          }
                          if (uri.toString().length > maxSavedItemUrlCharacters) {
                            return 'Website URLs must be 4,096 characters or shorter.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                    ],
                    TextFormField(
                      controller: _titleController,
                      enabled: !_saving,
                      textInputAction: TextInputAction.next,
                      maxLength: 500,
                      validator: _validateTitle,
                      decoration: InputDecoration(
                        labelText: 'Title' + (_kind == ItemKind.link ? ' (optional)' : ''),
                        hintText: _kind == ItemKind.note
                            ? 'A short title for your note'
                            : 'Give it a helpful name',
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _contentController,
                      enabled: !_saving,
                      minLines: _kind == ItemKind.note ? 5 : 2,
                      maxLines: _kind == ItemKind.note ? 8 : 4,
                      maxLength: 1000000,
                      decoration: InputDecoration(
                        labelText: _kind == ItemKind.note ? 'Your note' : 'Notes (optional)',
                        hintText: _kind == ItemKind.note
                            ? 'Write a thought, quote or reminder…'
                            : 'What do you want to remember about it?',
                        alignLabelWithHint: true,
                        counterText: '',
                      ),
                      validator: (value) {
                        if (_kind == ItemKind.note && (value ?? '').trim().isEmpty) {
                          return 'Write something in your note.';
                        }
                        return null;
                      },
                    ),
                    if (fileKind) ...[
                      const SizedBox(height: 14),
                      _buildAttachmentPicker(),
                    ],
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _tagsController,
                      enabled: !_saving,
                      decoration: const InputDecoration(
                        labelText: 'Tags (optional)',
                        hintText: 'Design, Reading, Work',
                        prefixIcon: Icon(Icons.sell_outlined),
                        helperText: 'Separate tags with commas.',
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String?>(
                      initialValue: _collection,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Collection (optional)',
                        prefixIcon: Icon(Icons.folder_outlined),
                      ),
                      hint: const Text('Choose a collection'),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('No collection'),
                        ),
                        for (final name in widget.repository.collections.value)
                          DropdownMenuItem<String?>(value: name, child: Text(name)),
                      ],
                      onChanged: _saving
                          ? null
                          : (value) => setState(() => _collection = value),
                    ),
                    if (_kind == ItemKind.link) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF2DF),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.bookmark_outline_rounded, color: Color(0xFFB87A22)),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Saved as a bookmark. The website itself is not downloaded for offline use.',
                                style: TextStyle(fontSize: 12, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: (_saving || _pickingAttachment) ? null : _save,
                      icon: (_saving || _pickingAttachment)
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check_rounded),
                      label: Text(
                        _saving
                            ? 'Saving…'
                            : _pickingAttachment
                                ? 'Selecting file…'
                                : isEditing
                                    ? 'Save changes'
                                    : 'Save to StashHive',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _saving ? null : () => Navigator.of(context).maybePop(false),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _selectKind(ItemKind kind) {
    // A save captures the current draft; don't permit type changes while that
    // snapshot is being persisted. Re-selecting a type otherwise remains a no-op.
    if (_saving || _kind == kind) return;
    // Invalidate any picker result started for a previous draft type. This
    // also handles switching away and back before the native dialog completes.
    _attachmentSelectionRevision++;
    setState(() {
      _kind = kind;
      // Clear type-specific attachment selection only for an actual change.
      // Keep shared notes/content just as we preserve title, tags and URL.
      _selectedBytes = null;
      _selectedName = null;
      _selectedMimeType = null;
    });
  }

  Widget _buildKindPicker() {
    final options = <ItemKind>[
      ItemKind.link,
      ItemKind.note,
      ItemKind.image,
      ItemKind.document,
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final scaledLabelFontSize =
            MediaQuery.textScalerOf(context).scale(11);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        // Keep four compact options on roomy desktop layouts, but wrap to two
        // columns when the available width or system text scale needs room.
        final columns = constraints.maxWidth >= 560 &&
                scaledLabelFontSize < 18
            ? 4
            : 2;
        final width =
            (constraints.maxWidth - 8 * (columns - 1)) / columns;

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final kind in options)
              SizedBox(
                width: width,
                child: Semantics(
                  button: true,
                  enabled: !_saving,
                  selected: _kind == kind,
                  label: kind.label,
                  onTap: _saving ? null : () => _selectKind(kind),
                  child: ExcludeSemantics(
                    child: InkWell(
                      onTap: _saving ? null : () => _selectKind(kind),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _kind == kind
                              ? kind.softAccent
                              : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _kind == kind
                                ? kind.accent
                                : Theme.of(context).dividerColor,
                            width: _kind == kind ? 1.4 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              kind.icon,
                              color: _kind == kind
                                  ? kind.readableTextAccent
                                  : isDark
                                      ? kind.softAccent
                                      : kind.accent,
                              size: 21,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              kind.label,
                              maxLines: 2,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _kind == kind || !isDark
                                    ? kind.readableTextAccent
                                    : kind.softAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildAttachmentPicker() {
    final existing = widget.existingItem;
    final name = _selectedName ?? existing?.attachmentName;
    final hasCurrent = _selectedBytes != null || (existing?.hasAttachment ?? false);
    final pickerLabel = name ??
        (_kind == ItemKind.image ? 'Choose an image' : 'Choose a document');
    final pickerHint = hasCurrent
        ? 'Select a replacement file, up to 15 megabytes'
        : 'Select a file, up to 15 megabytes';
    return Semantics(
      button: true,
      enabled: !_saving && !_pickingAttachment,
      label: pickerLabel,
      hint: _saving
          ? 'Wait for the item to finish saving'
          : _pickingAttachment
              ? 'A file selection is already in progress'
              : pickerHint,
      onTap: (_saving || _pickingAttachment) ? null : _pickAttachment,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: (_saving || _pickingAttachment) ? null : _pickAttachment,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _kind.softAccent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _kind.accent.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(_kind.icon, color: _kind.accent, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pickerLabel,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasCurrent
                            ? 'Tap to choose a replacement file'
                            : 'Select a file up to 15 MB',
                        style: TextStyle(
                          color: mutedTextColor(context),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.upload_file_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ItemDetailsPage extends StatefulWidget {
  const ItemDetailsPage({
    required this.repository,
    required this.itemId,
    super.key,
  });

  final LibraryRepository repository;
  final String itemId;

  @override
  State<ItemDetailsPage> createState() => _ItemDetailsPageState();
}

class _ItemDetailsPageState extends State<ItemDetailsPage> {
  SavedItem? _item;
  Future<Uint8List?>? _attachmentFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    final current = widget.repository.findById(widget.itemId);
    _item = current;
    _attachmentFuture = current?.attachmentKey == null
        ? Future<Uint8List?>.value(null)
        : widget.repository.readAttachment(current!.attachmentKey!);
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _openOrShare() async {
    final item = _item;
    if (item == null) return;
    if (item.kind == ItemKind.link && item.url != null) {
      // Persisted records may predate current validation; guard the launcher
      // independently so non-web schemes are never sent to another app.
      final uri = parseHttpUrl(item.url);
      if (uri == null) {
        _message('This saved URL is not a valid HTTP or HTTPS link.');
        return;
      }
      try {
        final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!opened) _message('No app could open this link.');
      } catch (_) {
        _message('Could not open this link. It is still saved in your library.');
      }
      return;
    }
    if (item.kind == ItemKind.image && item.attachmentKey != null) {
      await showDialog<void>(
        context: context,
        builder: (context) => Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: FutureBuilder<Uint8List?>(
              future: _attachmentFuture,
              builder: (context, snapshot) {
                if (snapshot.data == null || snapshot.data!.isEmpty) {
                  return const SizedBox(
                    height: 180,
                    child: Center(child: Text('The local image is missing.')),
                  );
                }
                return InteractiveViewer(
                  child: Image.memory(
                    snapshot.data!,
                    semanticLabel: 'Image: ${item.title}',
                    errorBuilder: (context, error, stackTrace) => SizedBox(
                      height: 180,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.broken_image_outlined,
                                size: 40,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Preview unavailable. The original attachment is still saved and can be shared.',
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
      return;
    }
    final key = item.attachmentKey;
    if (key == null) {
      _message('There is no local file attached to this item.');
      return;
    }
    final data = await widget.repository.readAttachment(key);
    if (data == null || data.isEmpty) {
      _message('The local file is missing. Restore a backup if you have one.');
      return;
    }
    try {
      await SharePlus.instance.share(
        ShareParams(
          title: item.title,
          files: [
            XFile.fromData(
              data,
              name: item.attachmentName ?? 'attachment',
              mimeType: item.attachmentMimeType ?? 'application/octet-stream',
            ),
          ],
        ),
      );
    } catch (_) {
      _message('Could not open the system share sheet for this file.');
    }
  }

  Future<void> _edit() async {
    final item = _item;
    if (item == null) return;
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => QuickSavePage(
          repository: widget.repository,
          initialKind: item.kind,
          existingItem: item,
        ),
      ),
    );
    if (mounted) setState(_reload);
  }

  Future<void> _toggleFavorite(SavedItem item) async {
    try {
      await widget.repository.toggleFavorite(item.id);
      if (mounted) setState(_reload);
    } catch (error) {
      _message(
        'Could not update this item. ' +
            _messageForOperationError(
              error,
              fallback: 'Check local storage and try again.',
            ),
      );
    }
  }

  Future<void> _delete() async {
    final item = _item;
    if (item == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this item?'),
        content: Text(
          item.hasAttachment
              ? 'This removes the saved record and the copy stored inside StashHive. It does not delete an original file in another app.'
              : 'This removes the saved record from your StashHive library.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFC74A5B)),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await widget.repository.delete(item.id);
    } catch (error) {
      _message(
        'Could not delete this item. ' +
            _messageForOperationError(
              error,
              fallback: 'The item remains in your library. Please try again.',
            ),
      );
      return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _shareItem() async {
    final item = _item;
    if (item == null) return;
    final text = <String>[
      item.title,
      if (item.url != null) item.url!,
      if (item.content.trim().isNotEmpty) item.content.trim(),
    ].join('\n');
    try {
      await SharePlus.instance.share(ShareParams(text: text, title: item.title));
    } catch (_) {
      _message('Sharing is not available on this device.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = _item;
    if (item == null) {
      return Scaffold(
        appBar: AppBar(leading: const BackButton()),
        body: const Center(child: Text('This item is no longer in your library.')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Item details'),
        actions: [
          IconButton(
            tooltip: 'Share item details',
            onPressed: _shareItem,
            icon: const Icon(Icons.ios_share_rounded),
          ),
          PopupMenuButton<String>(
            tooltip: 'Item actions',
            onSelected: (value) {
              if (value == 'edit') _edit();
              if (value == 'delete') _delete();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit item')),
              PopupMenuItem(value: 'delete', child: Text('Delete item')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 30),
              children: [
                if (item.kind == ItemKind.image && _attachmentFuture != null)
                  FutureBuilder<Uint8List?>(
                    future: _attachmentFuture,
                    builder: (context, snapshot) {
                      if (snapshot.data == null || snapshot.data!.isEmpty) {
                        return _previewPlaceholder(item, height: 210);
                      }
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 310),
                          child: Image.memory(
                            snapshot.data!,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => _previewPlaceholder(item, height: 210),
                          ),
                        ),
                      );
                    },
                  )
                else
                  _previewPlaceholder(item, height: 160),
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: item.kind.softAccent,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(item.kind.icon, size: 15, color: item.kind.accent),
                        const SizedBox(width: 6),
                        Text(item.kind.label.toUpperCase(),
                            style: TextStyle(
                               fontSize: 11,
                               fontWeight: FontWeight.w700,
                               color: item.kind.readableTextAccent,
                             )),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  item.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                ),
                const SizedBox(height: 7),
                Text('Saved ' + _formatDate(item.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: mutedTextColor(context))),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: _openOrShare,
                      icon: Icon(item.kind == ItemKind.link ? Icons.open_in_new_rounded : Icons.open_in_full_rounded),
                      label: Text(item.kind == ItemKind.link
                          ? 'Open link'
                          : item.kind == ItemKind.image
                              ? 'View image'
                              : 'Open / share file'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _edit,
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _toggleFavorite(item),
                      icon: Icon(
                        item.isFavorite
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: item.isFavorite ? favoriteStarColor(context) : null,
                      ),
                      label: Text(item.isFavorite ? 'Favorited' : 'Favorite'),
                    ),
                  ],
                ),
                if (item.url != null) ...[
                  const SizedBox(height: 24),
                  const DetailSectionLabel(label: 'SOURCE LINK'),
                  const SizedBox(height: 9),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.link_rounded, color: kBrand),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SelectableText(item.url!,
                              style: const TextStyle(color: kBrand, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ],
                if (item.content.trim().isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const DetailSectionLabel(label: 'YOUR NOTES'),
                  const SizedBox(height: 9),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: SelectableText(item.content,
                        style: const TextStyle(height: 1.5)),
                  ),
                ],
                if (item.attachmentName != null) ...[
                  const SizedBox(height: 24),
                  const DetailSectionLabel(label: 'LOCAL ATTACHMENT'),
                  const SizedBox(height: 9),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                    leading: Icon(item.kind.icon, color: item.kind.accent),
                    title: Text(item.attachmentName!, maxLines: 2, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                      kIsWeb
                          ? 'Stored in this browser profile'
                          : 'Stored inside StashHive on this device',
                    ),
                    trailing: const Icon(Icons.more_horiz_rounded),
                  ),
                ],
                if (item.tags.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const DetailSectionLabel(label: 'TAGS'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final tag in item.tags)
                        Chip(
                          avatar: const Icon(Icons.sell_outlined, size: 15, color: kBrand),
                          label: Text(tag),
                        ),
                    ],
                  ),
                ],
                if (item.collection != null) ...[
                  const SizedBox(height: 22),
                  const DetailSectionLabel(label: 'COLLECTION'),
                  const SizedBox(height: 9),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                    leading: const Icon(Icons.folder_copy_outlined, color: kBrand),
                    title: Text(item.collection!),
                  ),
                ],
                const SizedBox(height: 28),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFC74A5B)),
                  onPressed: _delete,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Delete saved item'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _previewPlaceholder(SavedItem item, {required double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: item.kind.softAccent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Icon(item.kind.icon, color: item.kind.accent, size: 62),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final month = const [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ][date.month - 1];
    return month + ' ' + date.day.toString() + ', ' + date.year.toString() +
        ' at ' + date.hour.toString().padLeft(2, '0') + ':' +
        date.minute.toString().padLeft(2, '0');
  }
}

class DetailSectionLabel extends StatelessWidget {
  const DetailSectionLabel({required this.label, super.key});
  final String label;

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: TextStyle(
          color: mutedTextColor(context),
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      );
}

class CollectionsPage extends StatefulWidget {
  const CollectionsPage({
    required this.repository,
    required this.onOpenItem,
    required this.onAdd,
    super.key,
  });

  final LibraryRepository repository;
  final ValueChanged<SavedItem> onOpenItem;
  final ValueChanged<ItemKind?> onAdd;

  @override
  State<CollectionsPage> createState() => _CollectionsPageState();
}

class _CollectionsPageState extends State<CollectionsPage> {
  bool _showTags = false;

  Future<void> _newCollection({String? oldName}) async {
    final controller = TextEditingController(text: oldName ?? '');
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(oldName == null ? 'New collection' : 'Rename collection'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 80,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'For example, Learning',
            labelText: 'Collection name',
          ),
          onSubmitted: (value) => Navigator.pop(context, value.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(oldName == null ? 'Create' : 'Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || !mounted) return;
    try {
      if (oldName == null) {
        await widget.repository.addCollection(name);
      } else {
        await widget.repository.renameCollection(oldName, name);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _messageForOperationError(
                error,
                fallback: oldName == null
                    ? 'Could not create the collection. Please try again.'
                    : 'Could not rename the collection. Please try again.',
              ),
            ),
          ),
        );
      }
    }
  }

  Future<void> _deleteCollection(String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete collection?'),
        content: Text('“' + name + '” will be removed. Its saved items will stay in your library and become unassigned.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete collection'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await widget.repository.deleteCollection(name);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _messageForOperationError(
              error,
              fallback: 'Could not delete the collection. Please try again.',
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('Organize',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.6,
                              )),
                    ),
                    if (!_showTags)
                      IconButton.filledTonal(
                        tooltip: 'New collection',
                        onPressed: () => _newCollection(),
                        icon: const Icon(Icons.add_rounded),
                      ),
                  ],
                ),
                const SizedBox(height: 5),
                Text('Bring related things together.', style: TextStyle(color: mutedTextColor(context))),
                const SizedBox(height: 18),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('Collections'), icon: Icon(Icons.folder_copy_outlined)),
                    ButtonSegment(value: true, label: Text('Tags'), icon: Icon(Icons.sell_outlined)),
                  ],
                  selected: {_showTags},
                  onSelectionChanged: (value) => setState(() => _showTags = value.first),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: _showTags ? _buildTags() : _buildCollections(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollections() {
    return ValueListenableBuilder<List<String>>(
      valueListenable: widget.repository.collections,
      builder: (context, names, _) {
        if (names.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.folder_open_rounded, size: 50, color: kBrand),
                  const SizedBox(height: 13),
                  Text(
                    'Make room for your ideas',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Collections group related items. Tags can still help you connect ideas across collections.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: mutedTextColor(context), height: 1.4),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: () => _newCollection(),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Create collection'),
                  ),
                ],
              ),
            ),
          );
        }

        // Counts depend on saved items as well as collection names. Listen to
        // both sources so this page refreshes after an item is saved, edited,
        // moved, or deleted without requiring a tab change.
        return ValueListenableBuilder<List<SavedItem>>(
          valueListenable: widget.repository.items,
          builder: (context, items, _) {
            return ListView.separated(
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: names.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                if (index == names.length) {
                  return OutlinedButton.icon(
                    onPressed: () => _newCollection(),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('New collection'),
                  );
                }
                final name = names[index];
                final count =
                    items.where((item) => item.collection?.toLowerCase() == name.toLowerCase()).length;
                final palette = [
                  const Color(0xFF5B5CE2),
                  const Color(0xFF3673BE),
                  const Color(0xFF218F84),
                  const Color(0xFFB87A22),
                  const Color(0xFFB24E8C),
                ];
                final color = palette[index % palette.length];
                return Card(
                  margin: EdgeInsets.zero,
                  elevation: 0,
                  color: Theme.of(context).colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.folder_copy_outlined, color: color),
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      count.toString() +
                          (count == 1 ? ' saved item' : ' saved items'),
                    ),
                    trailing: PopupMenuButton<String>(
                      tooltip: 'Actions for $name collection',
                      onSelected: (action) {
                        if (action == 'rename') _newCollection(oldName: name);
                        if (action == 'delete') _deleteCollection(name);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'rename', child: Text('Rename')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                    onTap: () => Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder: (_) => CollectionContentsPage(
                          repository: widget.repository,
                          collection: name,
                          onOpenItem: widget.onOpenItem,
                          onAdd: widget.onAdd,
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildTags() {
    return ValueListenableBuilder<List<SavedItem>>(
      valueListenable: widget.repository.items,
      builder: (context, items, _) {
        final counts = <String, int>{};
        for (final item in items) {
          for (final tag in item.tags) {
            counts[tag] = (counts[tag] ?? 0) + 1;
          }
        }
        final tags = counts.keys.toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
        if (tags.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.sell_outlined, size: 48, color: kBrand),
                  const SizedBox(height: 12),
                  Text('Tags appear as you save items',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  const Text(
                    'Add comma-separated tags while saving or editing an item. They will be collected here automatically.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: mutedTextColor(context)),
                  ),
                ],
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 20),
          itemCount: tags.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final tag = tags[index];
            return Card(
              margin: EdgeInsets.zero,
              elevation: 0,
              color: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Theme.of(context).dividerColor),
              ),
              child: ListTile(
                leading: const Icon(Icons.sell_outlined, color: kBrand),
                title: Text(tag, style: const TextStyle(fontWeight: FontWeight.w600)),
                trailing: Text(counts[tag].toString(), style: TextStyle(color: mutedTextColor(context))),
                onTap: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => CollectionContentsPage(
                      repository: widget.repository,
                      tag: tag,
                      onOpenItem: widget.onOpenItem,
                      onAdd: widget.onAdd,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class CollectionContentsPage extends StatelessWidget {
  const CollectionContentsPage({
    required this.repository,
    required this.onOpenItem,
    required this.onAdd,
    this.collection,
    this.tag,
    super.key,
  });

  final LibraryRepository repository;
  final ValueChanged<SavedItem> onOpenItem;
  final ValueChanged<ItemKind?> onAdd;
  final String? collection;
  final String? tag;

  @override
  Widget build(BuildContext context) {
    final title = collection ?? ('# ' + (tag ?? 'Items'));
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(title),
      ),
      body: ValueListenableBuilder<List<SavedItem>>(
        valueListenable: repository.items,
        builder: (context, items, _) {
          final shown = items.where((item) {
            if (collection != null) {
              return item.collection?.toLowerCase() == collection!.toLowerCase();
            }
            return item.tags.any((value) => value.toLowerCase() == tag?.toLowerCase());
          }).toList();
          if (shown.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.inbox_outlined, color: kBrand, size: 48),
                    const SizedBox(height: 12),
                    Text('No saved items here yet',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: () => onAdd(null),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Save an item'),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: shown.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) => SavedItemTile(
              item: shown[index],
              repository: repository,
              onTap: () => onOpenItem(shown[index]),
            ),
          );
        },
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    required this.repository,
    required this.darkMode,
    required this.onDarkModeChanged,
    required this.textScaleMultiplier,
    required this.onTextScaleChanged,
    super.key,
  });

  final LibraryRepository repository;
  final bool darkMode;
  final ValueChanged<bool> onDarkModeChanged;
  final double textScaleMultiplier;
  final ValueChanged<double> onTextScaleChanged;

  Future<void> _openBackup(BuildContext context) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => BackupPrivacyPage(repository: repository)),
    );
  }

  void _showInfo(BuildContext context, String title, String body) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            children: [
              Text('Settings',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.7,
                      )),
              const SizedBox(height: 5),
              Text('Make StashHive feel like yours.', style: TextStyle(color: mutedTextColor(context))),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF0FF),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: const Row(
                  children: [
                    BrandMark(size: 48),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Your personal library',
                              style: TextStyle(color: kInk, fontWeight: FontWeight.w700)),
                          SizedBox(height: 4),
                          Text('Local-first · No account required',
                              style: TextStyle(color: mutedTextColor(context), fontSize: 12)),
                        ],
                      ),
                    ),
                    Icon(Icons.shield_outlined, color: kBrand),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const DetailSectionLabel(label: 'PREFERENCES'),
              const SizedBox(height: 8),
              Card(
                elevation: 0,
                margin: EdgeInsets.zero,
                child: SwitchListTile(
                  secondary: const SettingIcon(icon: Icons.dark_mode_outlined),
                  title: const Text('Dark appearance'),
                  subtitle: const Text('Use a darker surface throughout the app'),
                  value: darkMode,
                  onChanged: onDarkModeChanged,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Text size',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Adds larger text on top of your device or browser text settings.',
                        style: TextStyle(color: mutedTextColor(context)),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<double>(
                        value: textScaleMultiplier,
                        decoration: const InputDecoration(
                          labelText: 'App text size',
                        ),
                        items: const [
                          DropdownMenuItem<double>(
                            value: 1.0,
                            child: Text('System default'),
                          ),
                          DropdownMenuItem<double>(
                            value: 1.15,
                            child: Text('Large'),
                          ),
                          DropdownMenuItem<double>(
                            value: 1.3,
                            child: Text('Extra large'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) onTextScaleChanged(value);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const DetailSectionLabel(label: 'YOUR DATA'),
              const SizedBox(height: 8),
              SettingsRow(
                icon: Icons.backup_outlined,
                title: 'Backup & privacy',
                subtitle: 'Export, restore and understand storage limits',
                color: const Color(0xFF2F8968),
                background: const Color(0xFFE7F7EF),
                onTap: () => _openBackup(context),
              ),
              const SizedBox(height: 8),
              SettingsRow(
                icon: Icons.manage_search_rounded,
                title: 'Search & saved content',
                subtitle: kIsWeb
                    ? 'What is searchable in this browser'
                    : 'What is searchable on this device',
                color: const Color(0xFFB87A22),
                background: const Color(0xFFFFF2DF),
                onTap: () => _showInfo(
                  context,
                  'What can StashHive search?',
                  'This first version searches titles, URLs, notes, tags and collection names stored in your local library. OCR and PDF text extraction are not enabled yet, so text found only inside an image or PDF is not searchable unless you add it to the notes.',
                ),
              ),
              const SizedBox(height: 24),
              const DetailSectionLabel(label: 'SUPPORT'),
              const SizedBox(height: 8),
              SettingsRow(
                icon: Icons.help_outline_rounded,
                title: 'Help & tips',
                subtitle: 'How local saving and backups work',
                color: const Color(0xFFB24E8C),
                background: const Color(0xFFFCEAF5),
                onTap: () => _showInfo(
                  context,
                  'A few helpful tips',
                  'Save website URLs as bookmarks, or choose a file to keep a local copy. Back up your library before uninstalling the app or clearing browser data. Web and Android libraries do not sync automatically.',
                ),
              ),
              const SizedBox(height: 8),
              SettingsRow(
                icon: Icons.info_outline_rounded,
                title: 'About StashHive',
                subtitle: 'Version 0.1.0 · Local-first personal library',
                color: kBrand,
                background: const Color(0xFFEEF0FF),
                onTap: () => _showInfo(
                  context,
                  'StashHive',
                  'A personal save-and-find library.\n\nVersion 0.1.0 — first development increment.\n\nYour library is stored locally. There is no StashHive cloud account or automatic cross-device sync in this release.',
                ),
              ),
              const SizedBox(height: 22),
              const Center(
                child: Text(
                  'Made for the things you want to keep.',
                  style: TextStyle(color: mutedTextColor(context), fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingIcon extends StatelessWidget {
  const SettingIcon({required this.icon, super.key});
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
        height: 42,
        width: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFEEF0FF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: kBrand),
      );
}

class SettingsRow extends StatelessWidget {
  const SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.background,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: Icon(Icons.chevron_right_rounded, color: mutedTextColor(context)),
      ),
    );
  }
}

class BackupPrivacyPage extends StatefulWidget {
  const BackupPrivacyPage({required this.repository, super.key});
  final LibraryRepository repository;

  @override
  State<BackupPrivacyPage> createState() => _BackupPrivacyPageState();
}

class _BackupPrivacyPageState extends State<BackupPrivacyPage> {
  bool _exporting = false;
  bool _choosingBackup = false;
  bool _restoring = false;

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _export() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final unrepresentedAssignments =
          widget.repository.unrepresentedCollectionAssignmentCount;
      if (unrepresentedAssignments > 0) {
        final message = unrepresentedAssignments == 1
            ? '1 saved item uses a collection name beyond the backup limit.'
            : '$unrepresentedAssignments saved items use collection names beyond the backup limit.';
        _message(
          '$message Edit those items and choose an available collection or No collection before exporting.',
        );
        return;
      }

      final skippedRecords = widget.repository.skippedRecordCount.value;
      final skippedCollections =
          widget.repository.skippedCollectionCount.value;
      final unexportableRecords = widget.repository.unexportableRecordCount;
      if (skippedRecords > 0 ||
          skippedCollections > 0 ||
          unexportableRecords > 0) {
        final omissions = <String>[];
        if (skippedRecords > 0) {
          omissions.add(
            '$skippedRecords saved record(s) could not be read and will be omitted.',
          );
        }
        if (unexportableRecords > 0) {
          omissions.add(
            '$unexportableRecords readable legacy item(s) cannot be represented within portable backup limits (invalid fields, unavailable attachments, item count, or combined attachment size) and will be omitted.',
          );
        }
        if (skippedCollections > 0) {
          final entryLabel = skippedCollections == 1
              ? 'collection name or assignment was'
              : 'collection names or assignments were';
          omissions.add(
            '$skippedCollections $entryLabel invalid, duplicated, or beyond the 500-collection limit.',
          );
        }
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('This backup may be incomplete'),
            content: Text(
              '${omissions.join(' ')} The raw local entries will not be deleted. You can repair omitted items after exporting. Continue with a partial backup?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Export readable items'),
              ),
            ],
          ),
        );
        if (confirmed != true || !mounted) return;
      }

      final json = await widget.repository.createBackup();
      final name = 'stashtrail-backup-' + DateTime.now().toUtc().toIso8601String().substring(0, 10) + '.json';
      final bytes = utf8.encode(json);
      final result = await SharePlus.instance.share(
        ShareParams(
          title: 'StashHive backup',
          subject: 'StashHive personal library backup',
          files: [
            XFile.fromData(
              bytes,
              mimeType: 'application/json',
              name: name,
            ),
          ],
        ),
      );
      if (mounted) {
        _message(
          result.status == ShareResultStatus.success
              ? 'Backup shared. Check the destination you selected.'
              : 'Backup prepared. Choose a destination in the share sheet to keep it safe.',
        );
      }
    } catch (error) {
      _message(
        'Could not create a backup. ' +
            _messageForOperationError(
              error,
              fallback: 'Check available storage and try again.',
            ),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _restore() async {
    if (_choosingBackup || _restoring) return;
    setState(() => _choosingBackup = true);
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['json'],
      );
      if (!mounted || file == null) return;

      // Check the selected file's size before allocating the entire backup
      // buffer; keep a post-read check in case the provider reports a stale
      // or unavailable length.
      final length = await file.length();
      if (!mounted) return;
      if (length == 0) {
        _message('The selected backup is empty or its size is unavailable.');
        return;
      }
      const maxBackupBytes = BackupCodec.maxBackupBytes;
      if (length > maxBackupBytes) {
        _message('That backup is too large to import in this version.');
        return;
      }
      var bytes = await readBoundedByteStream(
        file.readAsByteStream(),
        maxBytes: maxBackupBytes,
        limitMessage: 'That backup is too large to import in this version.',
      );
      if (!mounted) return;
      if (bytes.isEmpty) {
        _message('Could not read the selected backup file.');
        return;
      }
      var source = utf8.decode(bytes, allowMalformed: false);
      // Fully validate before asking for confirmation, then release the raw
      // JSON/base64 buffers so restore does not hold both representations.
      final decodedBackup = BackupCodec.decode(source);
      source = '';
      bytes = Uint8List(0);
      if (!mounted) return;
      final omissionNotes = <String>[];
      if (decodedBackup.omittedUnreadableRecordCount > 0) {
        final count = decodedBackup.omittedUnreadableRecordCount;
        omissionNotes.add(
          '$count unreadable local record(s) were omitted during export and cannot be recovered from this file.',
        );
      }
      if (decodedBackup.omittedCollectionEntryCount > 0) {
        final count = decodedBackup.omittedCollectionEntryCount;
        omissionNotes.add(
          '$count legacy collection name(s) or assignment(s) were normalized or omitted; this backup contains only the valid portable collection list.',
        );
      }
      if (decodedBackup.omittedUnexportableRecordCount > 0) {
        final count = decodedBackup.omittedUnexportableRecordCount;
        omissionNotes.add(
          '$count readable legacy item(s) could not fit within portable backup item/attachment limits and were omitted during export; they cannot be recovered from this file.',
        );
      }
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Merge this backup?'),
          content: Text(
            omissionNotes.isEmpty
                ? 'Items from the backup will be added to your current library. Existing items will not be overwritten. If IDs conflict, restored copies receive new IDs.'
                : '${omissionNotes.join(' ')} The readable items in this backup will be added to your current library; existing items will not be overwritten, and ID conflicts receive new IDs.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Merge backup')),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      setState(() {
        _choosingBackup = false;
        _restoring = true;
      });
      final imported = await widget.repository.restoreDecodedBackup(decodedBackup);
      _message('Restored ' + imported.toString() + (imported == 1 ? ' item.' : ' items.'));
    } on FormatException catch (error) {
      _message('Backup not imported: ' + error.message.toString());
    } catch (error) {
      _message(
        'Could not restore this backup. ' +
            _messageForOperationError(
              error,
              fallback: 'Check the selected file and try again.',
            ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _choosingBackup = false;
          _restoring = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Backup & privacy'),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 740),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
              children: [
                Text('Your library,',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                Text('in your control.',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 7),
                Text('Keep a safe copy you can restore later.', style: TextStyle(color: mutedTextColor(context))),
                const SizedBox(height: 14),
                ValueListenableBuilder<int>(
                  valueListenable: widget.repository.skippedRecordCount,
                  builder: (context, skippedRecords, _) {
                    return ValueListenableBuilder<int>(
                      valueListenable:
                          widget.repository.skippedCollectionCount,
                      builder: (context, skippedCollections, _) {
                        if (skippedRecords == 0 && skippedCollections == 0) {
                          return const SizedBox.shrink();
                        }
                        final warnings = <String>[];
                        if (skippedRecords > 0) {
                          warnings.add(
                            '$skippedRecords saved record(s) could not be read.',
                          );
                        }
                        if (skippedCollections > 0) {
                          final entryLabel = skippedCollections == 1
                              ? 'collection name or assignment was'
                              : 'collection names or assignments were';
                          warnings.add(
                            '$skippedCollections $entryLabel invalid, duplicated, or beyond the 500-collection limit.',
                          );
                        }
                        return Semantics(
                          liveRegion: true,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              '${warnings.join(' ')} A backup may omit unreadable records or normalize collection names. The raw data has not been intentionally deleted. Use a previous known-good backup to recover unreadable records; move any item assignment that exceeds the cap to an available collection or choose No collection before exporting.',
                              style: TextStyle(
                                color:
                                    Theme.of(context).colorScheme.onErrorContainer,
                                height: 1.35,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7F7EF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.verified_user_outlined, color: Color(0xFF2F8968), size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              kIsWeb ? 'Stored in this browser' : 'Stored on this device',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            SizedBox(height: 4),
                            Text(
                              kIsWeb
                                  ? 'Your library stays in this browser profile; it is not synced to the cloud.'
                                  : 'StashHive does not sync your library to the cloud.',
                              style: TextStyle(color: mutedTextColor(context), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                Text('Backup', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 5),
                Text('Export your metadata and copied attachments into a portable file.',
                    style: TextStyle(color: mutedTextColor(context))),
                const SizedBox(height: 12),
                ValueListenableBuilder<List<SavedItem>>(
                  valueListenable: widget.repository.items,
                  builder: (context, items, _) => _BackupCard(
                    icon: Icons.file_download_outlined,
                    title: 'Create a backup',
                    subtitle: items.length.toString() + (items.length == 1 ? ' saved item' : ' saved items'),
                    buttonText: _exporting ? 'Preparing…' : 'Create backup',
                    loading: _exporting,
                    onPressed: _export,
                  ),
                ),
                const SizedBox(height: 24),
                Text('Restore', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 5),
                Text('Bring a previous StashTrail or StashHive backup into this library.',
                    style: TextStyle(color: mutedTextColor(context))),
                const SizedBox(height: 12),
                _BackupCard(
                  icon: Icons.file_upload_outlined,
                  title: 'Restore from backup',
                  subtitle: 'Choose a StashTrail or StashHive .json backup file. Current items are preserved.',
                  buttonText: _restoring
                      ? 'Restoring…'
                      : _choosingBackup
                          ? 'Choosing backup…'
                          : 'Choose backup file',
                  loading: _choosingBackup || _restoring,
                  onPressed: _restore,
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF2DF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Color(0xFFB87A22)),
                          SizedBox(width: 8),
                          Text('Before you continue', style: TextStyle(fontWeight: FontWeight.w700)),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        kIsWeb
                            ? "Clearing this browser's site data can erase your local library. Save backups somewhere safe. Another browser or profile has a separate library."
                            : 'Uninstalling the app or clearing app data can erase your local library. Save backups somewhere safe. The web and Android libraries are separate.',
                        style: TextStyle(fontSize: 12, height: 1.45),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const DetailSectionLabel(label: 'BACKUP FORMAT'),
                const SizedBox(height: 8),
                const Text(
                  'Version 1 JSON backup. Includes saved metadata, tags, collections, and copied attachments up to 15 MB each and 100 MB combined. Import validates the version, IDs, URL schemes, file sizes and attachment data, and checks SHA-256 integrity for checksummed attachments before writing.',
                  style: TextStyle(color: mutedTextColor(context), fontSize: 12, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BackupCard extends StatelessWidget {
  const _BackupCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.loading,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonText;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF0FF),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: kBrand, size: 25),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(subtitle, style: TextStyle(fontSize: 12, color: mutedTextColor(context))),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: loading ? null : onPressed,
                child: loading
                    ? Semantics(
                        label: buttonText,
                        liveRegion: true,
                        child: const SizedBox(
                          height: 17,
                          width: 17,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : Text(buttonText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BrandMark extends StatelessWidget {
  const BrandMark({this.size = 34, super.key});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: const Color(0xFFEEF0FF),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(Icons.hive_rounded, color: kBrand, size: size * 0.62),
    );
  }
}
