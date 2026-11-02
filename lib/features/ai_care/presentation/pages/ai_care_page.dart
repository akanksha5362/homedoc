import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_paths.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/localization/generated/app_localizations.dart';
import '../../../../shared/ai/ai_thinking_indicator.dart';
import '../../../../shared/healthcare/emergency_warning.dart';
import '../../domain/safety/symptom_safety_checker.dart';
import '../../../../shared/widgets/buttons/app_button.dart';
import '../../../../shared/widgets/states/app_error_state.dart';
import '../providers/ai_care_provider.dart';
import '../widgets/ai_result_section.dart';
import '../widgets/conversational_symptom_view.dart';
import '../widgets/symptom_input.dart';

/// The real AI Care Guidance screen (Day 3 AI prompt, Step 8 & Master Prompt §7.A),
/// supporting both guided conversational symptom dialogues and direct structured inputs.
class AiCarePage extends ConsumerStatefulWidget {
  const AiCarePage({super.key});

  @override
  ConsumerState<AiCarePage> createState() => _AiCarePageState();
}

class _AiCarePageState extends ConsumerState<AiCarePage> {
  final _symptomsController = TextEditingController();
  final _durationController = TextEditingController();
  String? _validationError;
  EmergencyDetectionResult? _localEmergencyResult;
  bool _isGuidedMode = false;

  @override
  void dispose() {
    _symptomsController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _submit(AppLocalizations l10n) {
    final symptoms = _symptomsController.text.trim();
    if (symptoms.isEmpty) {
      setState(() => _validationError = l10n.aiCareEmptySymptomsError);
      return;
    }
    final safetyResult = SymptomSafetyChecker.evaluate(symptoms);
    if (safetyResult.isEmergency) {
      setState(() {
        _validationError = null;
        _localEmergencyResult = safetyResult;
      });
      return;
    }
    setState(() => _validationError = null);
    ref
        .read(aiCareControllerProvider.notifier)
        .analyzeSymptoms(
      symptoms: symptoms,
      duration: _durationController.text.trim().isEmpty
          ? null
          : _durationController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(aiCareControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isGuidedMode ? 'Guided AI Triage' : l10n.aiCareTitle),
        actions: [
          TextButton.icon(
            onPressed: () {
              setState(() {
                _isGuidedMode = !_isGuidedMode;
              });
            },
            icon: Icon(
              _isGuidedMode ? Icons.edit_note_rounded : Icons.forum_rounded,
              color: const Color(0xFF007A8A),
              size: 20,
            ),
            label: Text(
              _isGuidedMode ? 'Direct Form' : 'Guided Flow',
              style: const TextStyle(
                color: Color(0xFF007A8A),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _isGuidedMode
            ? const ConversationalSymptomView()
            : SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.aiCareExplanation,
                style: AppTypography.bodyMuted,
              ),
              const SizedBox(height: AppSpacing.xl),

              if (_localEmergencyResult != null) ...[
                EmergencyWarning(
                  message: l10n.aiCareEmergencyMessage,
                  redFlags: _localEmergencyResult!.matchedTriggers,
                  redFlagsLabel: l10n.aiCareRedFlagsLabel,
                  actionLabel: 'View Emergency Options',
                  onAction: () =>
                      context.push(RoutePaths.patientEmergency),
                ),
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _localEmergencyResult = null;
                      _symptomsController.clear();
                      _durationController.clear();
                    });
                  },
                  child: Text(l10n.aiCareStartOver),
                ),
              ],

              if (_localEmergencyResult == null &&
                  state.status != AiCareStatus.success) ...[
                SymptomInput(
                  symptomsController: _symptomsController,
                  durationController: _durationController,
                  symptomsLabel: l10n.aiCareSymptomsLabel,
                  symptomsHint: l10n.aiCareSymptomsHint,
                  durationLabel: l10n.aiCareDurationLabel,
                ),
                if (_validationError != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _validationError!,
                    style: AppTypography.body.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: l10n.aiCareSubmit,
                  icon: Icons.spa_outlined,
                  isLoading: state.isAnalyzing,
                  onPressed: state.isAnalyzing
                      ? null
                      : () => _submit(l10n),
                ),
              ],

              if (state.isAnalyzing) ...[
                const SizedBox(height: AppSpacing.xxl),
                Center(
                  child: AIThinkingIndicator(message: l10n.aiThinking),
                ),
              ],

              if (_localEmergencyResult == null &&
                  state.status == AiCareStatus.error) ...[
                const SizedBox(height: AppSpacing.xxl),
                AppErrorState(
                  message: state.errorMessage ?? l10n.errorGeneric,
                  onRetry: () => _submit(l10n),
                ),
              ],

              if (state.status == AiCareStatus.success &&
                  state.result != null) ...[
                if (state.result!.emergencyDetected) ...[
                  // Emergency breaks out of the normal AI result UI
                  // entirely (UX/UI Architecture v1 §6/§10) — the
                  // structured recommendation card is deliberately NOT
                  // also shown here, so there's one unambiguous message,
                  // not two competing ones.
                  EmergencyWarning(
                    message: l10n.aiCareEmergencyMessage,
                    redFlags: state.result!.redFlags,
                    redFlagsLabel: l10n.aiCareRedFlagsLabel,
                    actionLabel: 'View Emergency Options',
                    onAction: () =>
                        context.push(RoutePaths.patientEmergency),
                  ),
                ] else
                  AiResultSection(
                    result: state.result!,
                    redFlagsLabel: l10n.aiCareRedFlagsLabel,
                    summaryLabel: l10n.aiCareSummaryLabel,
                  ),
                const SizedBox(height: AppSpacing.xl),
                OutlinedButton(
                  onPressed: () {
                    ref.read(aiCareControllerProvider.notifier).reset();
                    _symptomsController.clear();
                    _durationController.clear();
                  },
                  child: Text(l10n.aiCareStartOver),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppSecondaryButton(
                  label: l10n.homeBrowseDoctors,
                  onPressed: () => context.pop(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
