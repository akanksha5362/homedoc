import 'package:flutter/material.dart';

/// Only two radius tiers by design (UX/UI Architecture v1, Section 30) —
/// deliberately avoids a third "extra rounded" tier to keep the app from
/// drifting toward the "excessive rounded cards" anti-pattern flagged in
/// the product brief.
class AppRadius {
  AppRadius._();

  /// Inputs, chips, badges, buttons.
  static const double small = 8;

  /// Cards, sheets, dialogs, modals.
  static const double medium = 16;

  static const BorderRadius smallRadius = BorderRadius.all(Radius.circular(small));
  static const BorderRadius mediumRadius = BorderRadius.all(Radius.circular(medium));
}

/// One subtle elevation level for cards/sheets, per Day 2's "minimal shadow"
/// design instruction — avoid heavy drop shadows or glassmorphism.
class AppElevation {
  AppElevation._();

  static const double card = 1;
  static const double sheet = 4;
  static const double dialog = 8;
}
