import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Typography hierarchy from UX/UI Architecture v1, Section 30:
/// Display -> H1 -> H2 -> Body -> Label -> Caption -> Button.
///
/// Font family is a placeholder (system default) pending the visual-identity
/// decision — swap [_fontFamily] once chosen; every text style below is
/// built from it so the change is one line.
class AppTypography {
  AppTypography._();

  static const String? _fontFamily = null; // null = platform default for now

  static const TextStyle display = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 28,
    height: 1.25,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle h1 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 22,
    height: 1.3,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18,
    height: 1.35,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMuted = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
  );

  static const TextStyle label = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    height: 1.4,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    height: 1.4,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
  );

  static const TextStyle button = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    height: 1.2,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );
}
