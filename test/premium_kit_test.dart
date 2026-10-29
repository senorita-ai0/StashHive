import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stashhive/main.dart' as app;
import 'package:stashhive/ui/premium_kit.dart';

void main() {
  group('StashHive premium UI kit', () {
    test('uses the shared FinMate and Stockly visual tokens', () {
      expect(PremiumTokens.brand, const Color(0xFF2563EB));
      expect(PremiumTokens.brandDark, const Color(0xFF60A5FA));
      expect(PremiumTokens.mint, const Color(0xFF17C7A1));
      expect(PremiumTokens.violet, const Color(0xFF8B7CFF));
      expect(PremiumTokens.radiusCard, 24);
      expect(PremiumTokens.radiusControl, 17);
      expect(PremiumTokens.pagePadding.left, 20);
      expect(PremiumTokens.pagePadding.right, 20);
    });

    test('light and dark app themes use the shared brand tokens', () {
      final light = app.buildLightTheme();
      final dark = app.buildDarkTheme();

      expect(light.colorScheme.primary, PremiumTokens.brand);
      expect(dark.colorScheme.primary, PremiumTokens.brandDark);
      expect(light.scaffoldBackgroundColor, const Color(0xFFF6F8FC));
      expect(dark.scaffoldBackgroundColor, const Color(0xFF07111F));
      expect(light.cardTheme.shape, isA<RoundedRectangleBorder>());
      expect(dark.cardTheme.shape, isA<RoundedRectangleBorder>());
    });

    testWidgets('page header presents the title and supporting description',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: EdgeInsets.all(20),
              child: PremiumPageHeader(
                title: 'Your library',
                subtitle: 'A home for the things worth keeping.',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Your library'), findsOneWidget);
      expect(find.text('A home for the things worth keeping.'), findsOneWidget);
    });

    testWidgets('icon chip applies its requested size and icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: PremiumIconChip(
                icon: Icons.hive_rounded,
                size: 44,
              ),
            ),
          ),
        ),
      );

      final chip = tester.widget<PremiumIconChip>(find.byType(PremiumIconChip));
      expect(chip.size, 44);
      expect(find.byIcon(Icons.hive_rounded), findsOneWidget);
    });

    testWidgets('premium empty state keeps a clear action visible',
        (tester) async {
      var actionPressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PremiumEmptyState(
              icon: Icons.auto_awesome_mosaic_rounded,
              title: 'Save your first good find',
              message: 'Keep useful links, ideas and files in one place.',
              actionLabel: 'Save something',
              onAction: () => actionPressed = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Save your first good find'), findsOneWidget);
      expect(find.text('Keep useful links, ideas and files in one place.'),
          findsOneWidget);
      await tester.tap(find.text('Save something'));
      expect(actionPressed, isTrue);
    });
  });
}
