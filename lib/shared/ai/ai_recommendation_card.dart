import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';
import '../models/ai_urgency.dart';

/// Renders the AI triage result. Deliberately NOT a chat bubble
/// (UX/UI Architecture v1 §6/§7) — this is a structured recommendation
/// card so it visually reads as "guidance," not "conversation with an
/// entity that knows medicine."
///
/// The "AI guidance, not a diagnosis" disclaimer is built into this
/// component and cannot be omitted by a caller — that's a safety rule
/// (UX/UI Architecture v1 §37, rule 1 & 2), not a style choice.
///
/// REFACTORED (AI Care implementation) from a 2-field (recommendation,
/// reasoning) card to a structured-urgency card, since it now has a real
/// caller (`AiCarePage`) that needs to show urgency and next steps. No
/// other file used the old API (verified before this change), so this is
/// a clean refactor, not a breaking one in practice.
class AIRecommendationCard extends StatelessWidget {
  const AIRecommendationCard({
    super.key,
    required this.recommendation,
    required this.reasoning,
    required this.disclaimer,
    this.urgency,
    this.nextStep,
    this.isUncertain = false,
  });

  final String recommendation;
  final String reasoning;
  final String disclaimer;
  final AIUrgency? urgency;
  final String? nextStep;
  final bool isUncertain;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.aiContainer,
        borderRadius: AppRadius.mediumRadius,
        border: isUncertain ? Border.all(color: AppColors.ai, width: 1) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.spa_outlined, size: 18, color: AppColors.ai),
              const SizedBox(width: AppSpacing.xs),
              Text('AI care guidance', style: AppTypography.label.copyWith(color: AppColors.ai)),
              if (urgency != null) ...[
                const Spacer(),
                _UrgencyPill(urgency: urgency!),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(recommendation, style: AppTypography.h2),
          const SizedBox(height: AppSpacing.xs),
          Text(reasoning, style: AppTypography.bodyMuted),
          if (nextStep != null && nextStep!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            const Text('Next step', style: AppTypography.label),
            const SizedBox(height: 2),
            Text(nextStep!, style: AppTypography.body),
          ],
          const SizedBox(height: AppSpacing.md),
          Text(disclaimer, style: AppTypography.caption),
        ],
      ),
    );
  }
}

class _UrgencyPill extends StatelessWidget {
  const _UrgencyPill({required this.urgency});

  final AIUrgency urgency;

  @override
  Widget build(BuildContext context) {
    final (label, color, bg) = switch (urgency) {
      AIUrgency.selfCare => ('Self-Care', AppColors.primary, AppColors.primaryContainer),
      AIUrgency.routine => ('Routine', AppColors.textMuted, AppColors.surfaceMuted),
      AIUrgency.soon => ('Soon', AppColors.secondary, AppColors.secondaryContainer),
      AIUrgency.urgent => ('Urgent', AppColors.warning, const Color(0xFFFAF0DA)),
      AIUrgency.emergency => ('Emergency', AppColors.emergency, AppColors.emergencyContainer),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.smallRadius),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}
