/// Normalizes the system-scaled body font size to a layout scale factor.
///
/// The caller should pass the scaled output for a representative body font
/// size (14 logical pixels here), not for a 1-pixel font. Text scaling can be
/// non-linear, so sampling at 1 pixel can underestimate the space needed by
/// actual labels.
double savedItemTextScaleFactor(
  double scaledBodyFontSize, {
  double baseBodyFontSize = 14,
}) {
  if (!scaledBodyFontSize.isFinite ||
      !baseBodyFontSize.isFinite ||
      baseBodyFontSize <= 0 ||
      scaledBodyFontSize < baseBodyFontSize) {
    return 1;
  }
  return scaledBodyFontSize / baseBodyFontSize;
}

/// Returns a bounded card extent that gives scaled text more vertical room.
///
/// The baseline is sized for the two-line saved-item title. Larger accessibility
/// text scales add height for title and metadata wrapping without unbounded growth.
double savedItemCardExtentForTextScale(double textScale) {
  if (!textScale.isFinite || textScale < 1) return 120;
  return 120.0 + ((textScale - 1) * 64).clamp(0.0, 128.0).toDouble();
}
