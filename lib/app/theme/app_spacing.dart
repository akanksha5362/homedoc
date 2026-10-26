/// 4px-based spacing scale (UX/UI Architecture v1, Section 30).
/// Never use arbitrary padding/margin values in feature code — reference
/// these constants so spacing stays visually consistent app-wide.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 48;
  static const double giant = 64;
}
