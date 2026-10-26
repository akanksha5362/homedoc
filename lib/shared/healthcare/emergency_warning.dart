import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';

/// Full-width, high-contrast interrupt — visually and behaviorally
/// distinct from a normal AI result card per UX/UI Architecture v1 §6/§10:
/// "emergency escalation must break out of the AI UI entirely." This is
/// one of the only places in the app allowed to use [AppColors.emergency],
/// reserved exclusively for real emergency signals (Day 2 §30) — never
/// reused for merely "urgent".
///
/// MOVED to shared/healthcare (Day 3.2) from features/ai_care/presentation/
/// widgets — now used by both the symptom-triage flow (AiCarePage) and the
/// new AI Care Assistant (AiAssistantPage), so per this project's own rule
/// ("used by 2+ features -> shared"), it belongs here, not owned by one
/// feature and imported cross-feature by the other.
class EmergencyWarning extends StatelessWidget {
  const EmergencyWarning({
    super.key,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    this.redFlags = const [],
    this.redFlagsLabel,
  });

  final String message;
  final List<String> redFlags;
  final String? redFlagsLabel;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: message,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.emergencyContainer,
          borderRadius: AppRadius.mediumRadius,
          border: Border.all(color: AppColors.emergency, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.emergency_outlined, color: AppColors.emergency),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    message,
                    style: AppTypography.h2.copyWith(color: AppColors.emergency),
                  ),
                ),
              ],
            ),
            if (redFlags.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                redFlagsLabel ?? 'Things to watch for',
                style: AppTypography.label.copyWith(color: AppColors.emergency),
              ),
              const SizedBox(height: AppSpacing.xs),
              for (final flag in redFlags)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text('• $flag', style: AppTypography.body),
                ),
            ],
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.emergency),
                onPressed: onAction,
                child: Text(actionLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
