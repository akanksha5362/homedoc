import 'package:flutter/material.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/ai/ai_recommendation_card.dart';
import '../../data/models/ai_triage_result.dart';

/// Renders exactly one of two states from [result]:
///   - [EmergencyWarning] if `emergencyDetected` — nothing else competes
///     with it (UX/UI Architecture v1 §10).
///   - Otherwise, the (now structured) [AIRecommendationCard], with any
///     non-emergency red flags listed underneath as a supporting detail
///     rather than as their own alarming block.
class AiResultSection extends StatelessWidget {
  const AiResultSection({
    super.key,
    required this.result,
    required this.redFlagsLabel,
    required this.summaryLabel,
  });

  final AITriageResult result;
  final String redFlagsLabel;
  final String summaryLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(summaryLabel, style: AppTypography.label),
        const SizedBox(height: AppSpacing.xs),
        Text(result.summary, style: AppTypography.body),
        const SizedBox(height: AppSpacing.lg),
        AIRecommendationCard(
          recommendation: result.recommendation,
          reasoning: result.reasoning,
          disclaimer: result.disclaimer,
          urgency: result.urgency,
          nextStep: result.nextStep,
          isUncertain: result.isUncertain,
        ),
        if (result.redFlags.isNotEmpty && !result.emergencyDetected) ...[
          const SizedBox(height: AppSpacing.md),
          Text(redFlagsLabel, style: AppTypography.label),
          const SizedBox(height: AppSpacing.xs),
          for (final flag in result.redFlags)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text('• $flag', style: AppTypography.bodyMuted),
            ),
        ],
      ],
    );
  }
}
