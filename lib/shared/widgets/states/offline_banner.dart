import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';

/// Thin, non-blocking banner shown when [ConnectivityService] reports
/// offline. Never blocks interaction with cached/local content — it only
/// informs (Day 3 §20: "distinguish Online / Offline / Poor connection").
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.warning.withValues(alpha: 0.12),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      child: const Row(
        children: [
          Icon(Icons.wifi_off, size: 16, color: AppColors.warning),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              "You're offline. Some features may be unavailable.",
              style: TextStyle(color: AppColors.warning, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
