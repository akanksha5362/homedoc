import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';

/// The assistant's short conversational reply text. Distinct from
/// `AIRecommendationCard` (Day 3's structured symptom-triage result) —
/// this is for the Care Assistant's shorter, less formal "here's what I
/// found" messages that precede a structured action card, not a
/// standalone clinical recommendation in its own right.
class AIMessageBubble extends StatelessWidget {
  const AIMessageBubble({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: AppRadius.mediumRadius,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.spa_outlined, size: 16, color: AppColors.ai),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, style: AppTypography.body)),
        ],
      ),
    );
  }
}

/// A patient's own message, right-aligned, visually distinct from the
/// assistant's reply.
class UserMessageBubble extends StatelessWidget {
  const UserMessageBubble({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: const BoxDecoration(
          color: AppColors.primaryContainer,
          borderRadius: AppRadius.mediumRadius,
        ),
        child: Text(text, style: AppTypography.body),
      ),
    );
  }
}
