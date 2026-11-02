import 'package:flutter/material.dart';

import 'premium_kit.dart';

/// StashHive-specific premium surfaces layered on the shared kit.
///
/// `premium_kit.dart` is intentionally identical in FinMate, Stockly and
/// StashHive, so app-level surfaces that were adapted from FinMate's page
/// background and glass card live here instead of changing that shared file.
/// Nothing in this file changes layout metrics: it only paints behind or
/// around existing content.

/// Soft brand-coloured glows painted behind a whole page.
///
/// The scaffold canvas colour is left untouched so text contrast measured
/// against the theme canvas stays valid; the glows are low-alpha radial
/// gradients near two corners and never receive pointer input.
class PremiumPageBackground extends StatelessWidget {
  const PremiumPageBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      // Passthrough keeps the page's original constraints; only the glows are
      // positioned, so they never affect layout.
      fit: StackFit.passthrough,
      children: [
        Positioned(
          top: -130,
          right: -120,
          child: _Glow(
            size: 380,
            color: PremiumTokens.mint.withValues(alpha: dark ? .16 : .07),
          ),
        ),
        Positioned(
          bottom: -170,
          left: -140,
          child: _Glow(
            size: 440,
            color: PremiumTokens.brand.withValues(alpha: dark ? .18 : .07),
          ),
        ),
        child,
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: size,
        height: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color, color.withValues(alpha: 0)],
            ),
          ),
        ),
      ),
    );
  }
}

/// Elevated surface with a faint gradient, hairline border and soft shadow.
///
/// Content stays the focus: the card is quieter than hero/action surfaces. A
/// transparent [Material] sits inside the decoration so ink splashes from a
/// child [InkWell] (or from [onTap]) are painted above the gradient.
class PremiumGlassCard extends StatelessWidget {
  const PremiumGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.onLongPress,
    this.selected = false,
    this.radius = PremiumTokens.radiusCard,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Draws a stronger primary-coloured border. Callers must still expose the
  /// selected state non-visually (for example with a checkbox or semantics).
  final bool selected;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final borderRadius = BorderRadius.circular(radius);
    final borderColor = selected
        ? theme.colorScheme.primary
        : dark
            ? Colors.white.withValues(alpha: .08)
            : const Color(0xFFDDE7F5);
    final padded = Padding(padding: padding, child: child);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? const [Color(0xFF17263E), Color(0xFF101B2C)]
              // Kept very close to white so muted text retains its contrast.
              : const [Colors.white, Color(0xFFF8FAFE)],
        ),
        borderRadius: borderRadius,
        border: Border.all(color: borderColor, width: selected ? 1.6 : 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? .2 : .05),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: onTap == null && onLongPress == null
            ? padded
            : InkWell(onTap: onTap, onLongPress: onLongPress, child: padded),
      ),
    );
  }
}
