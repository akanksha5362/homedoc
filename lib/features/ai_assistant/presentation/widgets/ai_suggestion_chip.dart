import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';

/// The "quick action" chips on the assistant's initial state
/// ("Check my symptoms", "Find a doctor", ...) — Day 3.2 §27. Deliberately
/// styled as chips, not chat "suggested reply" bubbles, to keep the AI
/// design language (Day 2 §31) consistent with the rest of the app rather
/// than looking like a generic chat product.
class AISuggestionChip extends StatelessWidget {
  const AISuggestionChip({super.key, required this.label, required this.onTap, this.icon});

  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.aiContainer,
      borderRadius: AppRadius.smallRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.smallRadius,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: AppColors.ai),
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(label, style: AppTypography.label.copyWith(color: AppColors.ai)),
            ],
          ),
        ),
      ),
    );
  }
}
