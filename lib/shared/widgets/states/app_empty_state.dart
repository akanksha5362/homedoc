import 'package:flutter/material.dart';
import '../../../app/theme/app_spacing.dart';
import '../buttons/app_button.dart';

/// Explains *why* a screen is empty and offers a relevant next action —
/// never a bare "No data" (UX/UI Architecture v1 §27).
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.icon = Icons.inbox_outlined,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: AppSpacing.md),
            Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              AppButton(label: actionLabel!, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}
