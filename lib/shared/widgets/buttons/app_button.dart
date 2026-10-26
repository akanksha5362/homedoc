import 'package:flutter/material.dart';

/// Primary call-to-action button.
///
/// Rule (Day 3 §17): this widget never calls an API itself — it only
/// exposes [onPressed]. Business logic (what happens on tap) belongs to
/// the calling feature/provider, not here. This keeps `AppButton` reusable
/// and testable in isolation.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
                Text(label),
              ],
            ),
    );
  }
}

/// Secondary/outlined variant — same rule applies (no API calls inside).
class AppSecondaryButton extends StatelessWidget {
  const AppSecondaryButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(onPressed: onPressed, child: Text(label));
  }
}
