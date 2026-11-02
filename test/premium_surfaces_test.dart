import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stashhive/main.dart' as app;
import 'package:stashhive/ui/premium_surfaces.dart';

void main() {
  group('StashHive premium surfaces', () {
    for (final dark in [false, true]) {
      final label = dark ? 'dark' : 'light';

      testWidgets('glass card shows content and handles taps ($label)',
          (tester) async {
        var taps = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: app.buildLightTheme(),
            darkTheme: app.buildDarkTheme(),
            themeMode: dark ? ThemeMode.dark : ThemeMode.light,
            home: Scaffold(
              body: Center(
                child: PremiumGlassCard(
                  onTap: () => taps++,
                  child: const Text('Saved item'),
                ),
              ),
            ),
          ),
        );

        expect(find.text('Saved item'), findsOneWidget);
        await tester.tap(find.text('Saved item'));
        await tester.pump();
        expect(taps, 1);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('glass card forwards taps from a child InkWell',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: PremiumGlassCard(
                padding: EdgeInsets.zero,
                child: InkWell(
                  onTap: () => taps++,
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('Inner tap target'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Inner tap target'));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('selected glass card uses a thicker primary border',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: app.buildLightTheme(),
          home: const Scaffold(
            body: Column(
              children: [
                PremiumGlassCard(selected: true, child: Text('Selected')),
                PremiumGlassCard(child: Text('Plain')),
              ],
            ),
          ),
        ),
      );

      // The card's own decoration is the first DecoratedBox in its subtree.
      BoxDecoration decorationOfCard(int index) {
        final box = tester.widget<DecoratedBox>(
          find
              .descendant(
                of: find.byType(PremiumGlassCard).at(index),
                matching: find.byType(DecoratedBox),
              )
              .first,
        );
        return box.decoration as BoxDecoration;
      }

      final selected = decorationOfCard(0).border! as Border;
      final plain = decorationOfCard(1).border! as Border;
      expect(selected.top.width, greaterThan(plain.top.width));
      expect(selected.top.color, app.buildLightTheme().colorScheme.primary);
    });

    testWidgets('page background keeps content tappable under the glows',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: app.buildLightTheme(),
          home: Scaffold(
            body: PremiumPageBackground(
              child: Center(
                child: FilledButton(
                  onPressed: () => taps++,
                  child: const Text('Tap me'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tap me'));
      await tester.pump();
      expect(taps, 1);
      expect(tester.takeException(), isNull);
    });
  });

  group('StashHive shared theme chrome', () {
    test('light and dark themes share the same polished chrome', () {
      for (final theme in [app.buildLightTheme(), app.buildDarkTheme()]) {
        expect(theme.tooltipTheme.decoration, isNotNull);
        expect(theme.bottomSheetTheme.shape, isA<RoundedRectangleBorder>());
        expect(theme.navigationBarTheme.elevation, greaterThan(0));
        expect(theme.navigationBarTheme.indicatorShape, isNotNull);
        expect(theme.appBarTheme.titleTextStyle?.fontWeight, FontWeight.w900);
        expect(theme.snackBarTheme.backgroundColor, isNotNull);
        expect(theme.dialogTheme.titleTextStyle?.fontWeight, FontWeight.w900);
      }
    });

    test('dark theme uses the same page transitions as light', () {
      final light = app.buildLightTheme().pageTransitionsTheme.builders;
      final dark = app.buildDarkTheme().pageTransitionsTheme.builders;
      for (final platform in TargetPlatform.values) {
        expect(
          dark[platform]?.runtimeType,
          light[platform]?.runtimeType,
          reason: '$platform transition must not differ between themes.',
        );
      }
    });
  });
}
