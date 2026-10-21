/// Returns a bounded card extent that gives scaled text more vertical room.
///
/// The baseline is sized for the two-line saved-item title. Larger accessibility
/// text scales add height for title and metadata wrapping without unbounded growth.
double savedItemCardExtentForTextScale(double textScale) {
  if (!textScale.isFinite || textScale < 1) return 120;
  return 120.0 + ((textScale - 1) * 64).clamp(0.0, 128.0).toDouble();
}
