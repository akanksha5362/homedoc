import 'package:flutter/material.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.errorText,
    this.keyboardType,
    this.obscureText = false,
    this.semanticLabel,
    this.maxLines = 1,
    this.hintText,
  });

  final String label;
  final TextEditingController? controller;
  final String? errorText;
  final TextInputType? keyboardType;
  final bool obscureText;

  /// Falls back to [label] when omitted — every input must be reachable
  /// by a screen reader (Day 2 §28 / Day 3 §18).
  final String? semanticLabel;

  /// Defaults to 1 (unchanged prior behavior). Pass a higher value for
  /// multi-line input such as the AI symptom description field.
  final int maxLines;

  final String? hintText;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel ?? label,
      textField: true,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label, errorText: errorText, hintText: hintText),
      ),
    );
  }
}
