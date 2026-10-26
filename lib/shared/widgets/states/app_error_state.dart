import 'package:flutter/material.dart';
import '../../../app/theme/app_spacing.dart';
import '../buttons/app_button.dart';

/// The app's one canonical way to show a failure.
///
/// HARD RULE (Day 3 §28, carried from UX/UI Architecture v1 §27): never
/// show "Something went wrong" alone. [message] must already be the
/// user-safe [AppException.message] (see core/errors), and [onRetry] is
/// required — every use of this widget must have a recovery action.
class AppErrorState extends StatelessWidget {
  const AppErrorState({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 40),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(label: 'Retry', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
