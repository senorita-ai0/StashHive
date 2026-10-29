import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shared premium design kit.
///
/// This file is intentionally IDENTICAL in Stockly and FinMate
/// (`lib/core/theme/premium_kit.dart`). Both apps build their Settings screen
/// and other chrome from these widgets so they look and behave the same.
/// If you change it, copy it to the other app.
abstract final class PremiumTokens {
  static const brand = Color(0xFF2563EB);
  static const brandDark = Color(0xFF60A5FA);
  static const mint = Color(0xFF17C7A1);
  static const violet = Color(0xFF8B7CFF);
  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFD97706);
  static const danger = Color(0xFFDC2626);

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1D4ED8), Color(0xFF2563EB), Color(0xFF17C7A1)],
  );

  static const radiusCard = 24.0;
  static const radiusControl = 17.0;
  static const pagePadding = EdgeInsets.fromLTRB(20, 18, 20, 32);
}

/// Large page title + subtitle used at the top of every top-level screen.
class PremiumPageHeader extends StatelessWidget {
  const PremiumPageHeader({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.9,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}

/// Gradient hero panel (profile, summary). Content is always white-on-colour.
class PremiumHeroCard extends StatelessWidget {
  const PremiumHeroCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return PremiumReveal(child: _build());
  }

  Widget _build() {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: PremiumTokens.heroGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: PremiumTokens.brand.withValues(alpha: .28),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Account/profile hero shown at the top of Settings in both apps.
class PremiumProfileHero extends StatelessWidget {
  const PremiumProfileHero({
    super.key,
    required this.title,
    required this.subtitle,
    this.photoUrl,
    this.signedIn = false,
    this.busy = false,
    this.onSignIn,
    this.onSignOut,
  });

  final String title;
  final String subtitle;
  final String? photoUrl;
  final bool signedIn;
  final bool busy;
  final VoidCallback? onSignIn;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    final photo = photoUrl;
    return PremiumHeroCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white.withValues(alpha: .18),
            backgroundImage: photo == null || photo.isEmpty ? null : NetworkImage(photo),
            child: photo == null || photo.isEmpty
                ? const Icon(Icons.person_rounded, color: Colors.white, size: 30)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -.3,
                        ),
                      ),
                    ),
                    if (signedIn) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.verified_rounded, color: Colors.white, size: 18),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .8),
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (busy)
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
            )
          else if (signedIn && onSignOut != null)
            IconButton(
              color: Colors.white,
              tooltip: 'Sign out',
              onPressed: onSignOut,
              icon: const Icon(Icons.logout_rounded),
            )
          else if (!signedIn && onSignIn != null)
            FilledButton(
              onPressed: onSignIn,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: PremiumTokens.brand,
                minimumSize: const Size(0, 44),
              ),
              child: const Text('Sign in'),
            ),
        ],
      ),
    );
  }
}

/// Titled group of tiles inside one rounded card, with thin dividers.
class PremiumSection extends StatelessWidget {
  const PremiumSection({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final divider = Divider(
      height: 1,
      indent: 70,
      color: theme.colorScheme.outlineVariant.withValues(alpha: .4),
    );
    return PremiumReveal(
      delay: const Duration(milliseconds: 80),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) divider,
                children[i],
              ],
            ],
          ),
        ),
      ],
    ),
    );
  }
}

/// Icon chip used by every settings row so icons look identical in both apps.
class PremiumIconChip extends StatelessWidget {
  const PremiumIconChip({super.key, required this.icon, this.color, this.size = 40});

  final IconData icon;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, color: tint, size: size * .52),
    );
  }
}

class PremiumTile extends StatelessWidget {
  const PremiumTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.color,
    this.trailing,
    this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? color;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      enabled: enabled,
      onTap: enabled ? onTap : null,
      leading: PremiumIconChip(icon: icon, color: color),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: trailing ??
          (onTap == null ? null : const Icon(Icons.chevron_right_rounded)),
    );
  }
}

class PremiumSwitchTile extends StatelessWidget {
  const PremiumSwitchTile({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.color,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? color;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      secondary: PremiumIconChip(icon: icon, color: color),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: subtitle == null ? null : Text(subtitle!),
      value: value,
      onChanged: onChanged,
    );
  }
}

String premiumThemeLabel(ThemeMode mode) => switch (mode) {
      ThemeMode.system => 'System default',
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
    };

IconData premiumThemeIcon(ThemeMode mode) => switch (mode) {
      ThemeMode.system => Icons.brightness_auto_rounded,
      ThemeMode.light => Icons.light_mode_rounded,
      ThemeMode.dark => Icons.dark_mode_rounded,
    };

/// Same appearance picker in both apps: a bottom sheet with three choices.
Future<ThemeMode?> showPremiumThemeSheet(BuildContext context, ThemeMode current) {
  return showModalBottomSheet<ThemeMode>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Appearance',
              style: Theme.of(sheetContext).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            for (final mode in ThemeMode.values)
              ListTile(
                leading: PremiumIconChip(icon: premiumThemeIcon(mode)),
                title: Text(
                  premiumThemeLabel(mode),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                trailing: current == mode
                    ? Icon(Icons.check_circle_rounded,
                        color: Theme.of(sheetContext).colorScheme.primary)
                    : null,
                onTap: () => Navigator.pop(sheetContext, mode),
              ),
          ],
        ),
      ),
    ),
  );
}

/// Shows text in a sheet the user can copy (used for backups / CSV export).
Future<void> showPremiumExportSheet(
  BuildContext context, {
  required String title,
  required String description,
  required String content,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          20 + MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(sheetContext).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              description,
              style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 14),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(sheetContext).colorScheme.surfaceContainerHighest.withValues(alpha: .5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    content,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                await Clipboard.setData(ClipboardData(text: content));
                if (sheetContext.mounted) Navigator.pop(sheetContext);
                messenger.showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard.')),
                );
              },
              icon: const Icon(Icons.copy_rounded),
              label: const Text('Copy to clipboard'),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Small centered footer: app name, tagline and version.
class PremiumFooter extends StatelessWidget {
  const PremiumFooter({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Center(
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );
}

/// Fades and slides its child in once when it first appears. Respects the
/// system "reduce motion" setting by showing the child immediately.
class PremiumReveal extends StatelessWidget {
  const PremiumReveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = 14,
  });

  final Widget child;
  final Duration delay;
  final double offset;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return child;
    final total = const Duration(milliseconds: 420) + delay;
    final startAt = total.inMilliseconds == 0
        ? 0.0
        : delay.inMilliseconds / total.inMilliseconds;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: Interval(startAt, 1, curve: Curves.easeOutCubic),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * offset),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// Friendly empty state used when a list has nothing to show yet.
class PremiumEmptyState extends StatelessWidget {
  const PremiumEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                gradient: PremiumTokens.heroGradient,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: PremiumTokens.brand.withValues(alpha: .26),
                    blurRadius: 26,
                    offset: const Offset(0, 11),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 38),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Pulsing placeholder rows shown while a list loads (instead of a spinner).
class PremiumSkeletonList extends StatefulWidget {
  const PremiumSkeletonList({super.key, this.itemCount = 5});

  final int itemCount;

  @override
  State<PremiumSkeletonList> createState() => _PremiumSkeletonListState();
}

class _PremiumSkeletonListState extends State<PremiumSkeletonList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Semantics(
      label: 'Loading',
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final tone = base.withValues(alpha: .35 + _controller.value * .35);
          Widget bar(double width, double height) => Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  color: tone,
                  borderRadius: BorderRadius.circular(8),
                ),
              );
          return ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            itemCount: widget.itemCount,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: tone,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            bar(150, 14),
                            const SizedBox(height: 8),
                            bar(100, 11),
                          ],
                        ),
                      ),
                      bar(56, 14),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
