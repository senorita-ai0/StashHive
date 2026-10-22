import 'package:flutter_test/flutter_test.dart';
import 'package:stashhive/ui/layout_metrics.dart';

void main() {
  group('savedItemTextScaleFactor', () {
    test('normalizes a representative scaled body font size', () {
      expect(savedItemTextScaleFactor(14), 1);
      expect(savedItemTextScaleFactor(21), 1.5);
      expect(savedItemTextScaleFactor(28), 2);
      expect(savedItemCardExtentForTextScale(savedItemTextScaleFactor(21)), 152);
    });

    test('does not shrink layouts for smaller or invalid values', () {
      expect(savedItemTextScaleFactor(13), 1);
      expect(savedItemTextScaleFactor(double.nan), 1);
      expect(savedItemTextScaleFactor(double.infinity), 1);
      expect(savedItemTextScaleFactor(28, baseBodyFontSize: 0), 1);
    });
  });

  group('savedItemCardExtentForTextScale', () {
    test('uses the standard card extent at default text scale', () {
      expect(savedItemCardExtentForTextScale(1), 120);
    });

    test('adds vertical room when text is scaled up', () {
      expect(savedItemCardExtentForTextScale(1.5), 152);
      expect(savedItemCardExtentForTextScale(2), 184);
    });

    test('caps extreme text scaling to a bounded extent', () {
      expect(savedItemCardExtentForTextScale(8), 248);
    });

    test('falls back to the standard extent for invalid scales', () {
      expect(savedItemCardExtentForTextScale(0.8), 120);
      expect(savedItemCardExtentForTextScale(double.nan), 120);
      expect(savedItemCardExtentForTextScale(double.infinity), 120);
    });
  });
}
