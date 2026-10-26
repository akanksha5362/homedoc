import 'package:flutter/material.dart';

/// HomeDoc semantic design tokens.
/// Feature code should use these tokens instead of raw colors so the visual
/// identity can evolve without rewriting individual screens.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF0B6B5A);
  static const Color primaryDark = Color(0xFF075247);
  static const Color primaryContainer = Color(0xFFDDF3ED);
  static const Color secondary = Color(0xFF3678A9);
  static const Color secondaryContainer = Color(0xFFE4F0F8);

  // Surfaces
  static const Color background = Color(0xFFF7FAF9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF0F5F3);
  static const Color surfaceTint = Color(0xFFEAF6F2);

  // Text
  static const Color textPrimary = Color(0xFF15201D);
  static const Color textMuted = Color(0xFF63706C);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnDark = Color(0xFFF7FFFC);

  // Structure
  static const Color border = Color(0xFFDDE7E3);
  static const Color divider = Color(0xFFE8EFEC);

  // Status
  static const Color success = Color(0xFF2F855A);
  static const Color successContainer = Color(0xFFE4F5EA);
  static const Color warning = Color(0xFFB7791F);
  static const Color warningContainer = Color(0xFFFFF3D8);
  static const Color error = Color(0xFFC53030);

  // Reserved for Emergency.
  static const Color emergency = Color(0xFFD32F2F);
  static const Color emergencyContainer = Color(0xFFFCE4E4);

  // Reserved for AI-originated content.
  static const Color ai = Color(0xFF6B4FA0);
  static const Color aiDeep = Color(0xFF4E397B);
  static const Color aiContainer = Color(0xFFF0EAF8);

  // Decorative accents used only for dashboard illustration/highlight areas.
  static const Color mintAccent = Color(0xFFBCE8DB);
  static const Color blueAccent = Color(0xFFCFE6F5);
}
