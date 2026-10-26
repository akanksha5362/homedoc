/// Accessibility constants shared across the design system
/// (UX/UI Architecture v1, §28; Day 3 §18).
///
/// This is intentionally a small constants file, not a framework — the
/// real accessibility work happens per-widget (Semantics labels, sizing
/// widgets against [minTouchTarget], respecting textScaleFactor). This
/// class exists so those numbers are defined once, not copy-pasted.
class A11y {
  A11y._();

  /// WCAG-aligned minimum interactive target size.
  static const double minTouchTarget = 44.0;

  /// Emergency-adjacent actions get a larger target given the brief's
  /// explicit elderly/low-literacy-user accessibility requirement.
  static const double emergencyTouchTarget = 56.0;
}
