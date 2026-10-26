import 'package:flutter/material.dart';

/// Small ergonomic helpers — kept deliberately minimal at foundation stage
/// (Day 3 §36: avoid unnecessary abstractions). Add more only when a
/// pattern repeats across 3+ screens.
extension BuildContextX on BuildContext {
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  void showSnack(String message) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
