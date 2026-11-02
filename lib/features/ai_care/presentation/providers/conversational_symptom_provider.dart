import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../data/models/conversational_triage_request.dart';
import '../../data/models/conversational_symptom_model.dart';
import '../../domain/repositories/ai_care_repository.dart';
import '../../domain/safety/symptom_safety_checker.dart';
import 'ai_care_provider.dart';

/// Notifier managing conversational, guided symptom triage sessions (Master Prompt §7.A).
class ConversationalTriageNotifier
    extends StateNotifier<ConversationalTriageState> {
  ConversationalTriageNotifier(this._repository)
      : super(const ConversationalTriageState()) {
    _initDialogue();
  }

  final AiCareRepository _repository;

  void _initDialogue() {
    state = ConversationalTriageState(
      stage: SymptomStage.chiefComplaint,
      messages: [
        DialogueMessage(
          id: 'welcome',
          text:
          'Hello! I am HomeDoc AI’s clinical triage assistant. What primary symptoms or health concerns are you experiencing today?',
          isUser: false,
          timestamp: DateTime.now(),
          suggestedChips: const [
            'Frequent headaches',
            'Persistent fever',
            'Abdominal pain',
            'Skin rash & itching',
            'Joint or back pain',
            'Dry cough & sore throat',
          ],
        ),
      ],
    );
  }

  /// Submits user response for the active stage.
  Future<void> submitAnswer(String answer) async {
    final trimmed = answer.trim();
    if (trimmed.isEmpty) return;

    // 1. Instant Medical Safety Check (Rules Engine — Prompt §7.B/§7.E)
    final safetyCheck = SymptomSafetyChecker.evaluate(trimmed);
    if (safetyCheck.isEmergency) {
      _triggerEmergency(trimmed, safetyCheck);
      return;
    }

    final userMsg = DialogueMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: trimmed,
      isUser: true,
      timestamp: DateTime.now(),
    );

    final updatedMessages = [...state.messages, userMsg];

    switch (state.stage) {
      case SymptomStage.chiefComplaint:
        state = state.copyWith(
          chiefComplaint: trimmed,
          stage: SymptomStage.duration,
          messages: [
            ...updatedMessages,
            DialogueMessage(
              id: 'q_duration',
              text: 'How long have you been experiencing these symptoms?',
              isUser: false,
              timestamp: DateTime.now(),
              suggestedChips: const [
                'Just started today',
                '2 to 3 days',
                'About a week',
                'Over 2 weeks',
                'Recurring episodes',
              ],
            ),
          ],
        );
        break;

      case SymptomStage.duration:
        state = state.copyWith(
          duration: trimmed,
          stage: SymptomStage.severity,
          messages: [
            ...updatedMessages,
            DialogueMessage(
              id: 'q_severity',
              text: 'How severe would you rate the discomfort or pain?',
              isUser: false,
              timestamp: DateTime.now(),
              suggestedChips: const [
                'Mild (noticeable but manageable)',
                'Moderate (limits some daily activities)',
                'Severe (intense, prevents normal tasks)',
              ],
            ),
          ],
        );
        break;

      case SymptomStage.severity:
        state = state.copyWith(
          severity: trimmed,
          stage: SymptomStage.associatedSymptoms,
          messages: [
            ...updatedMessages,
            DialogueMessage(
              id: 'q_associated',
              text: 'Are you experiencing any other accompanying symptoms?',
              isUser: false,
              timestamp: DateTime.now(),
              suggestedChips: const [
                'Fever or chills',
                'Nausea / dizziness',
                'Fatigue or body ache',
                'Blurry vision',
                'None of these',
              ],
            ),
          ],
        );
        break;

      case SymptomStage.associatedSymptoms:
        final associated = trimmed.toLowerCase() == 'none of these'
            ? <String>[]
            : trimmed
            .split(RegExp(r'[,;]'))
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList(growable: false);
        state = state.copyWith(
          associatedSymptoms: associated,
          stage: SymptomStage.review,
          messages: [
            ...updatedMessages,
            DialogueMessage(
              id: 'q_history',
              text:
              'Any relevant medical history (e.g. hypertension, diabetes, asthma) or current medications?',
              isUser: false,
              timestamp: DateTime.now(),
              suggestedChips: const [
                'No pre-existing conditions',
                'Hypertension / High BP',
                'Diabetes',
                'Asthma / Allergies',
              ],
            ),
          ],
        );
        break;

      case SymptomStage.review:
        state = state.copyWith(contextNote: trimmed, messages: updatedMessages);
        await _performTriage();
        break;

      case SymptomStage.analyzing:
      case SymptomStage.complete:
      case SymptomStage.emergency:
        break;
    }
  }

  void _triggerEmergency(String userInput, EmergencyDetectionResult result) {
    state = state.copyWith(
      stage: SymptomStage.emergency,
      emergencyResult: result,
      messages: [
        ...state.messages,
        DialogueMessage(
          id: 'user_emergency',
          text: userInput,
          isUser: true,
          timestamp: DateTime.now(),
        ),
        DialogueMessage(
          id: 'ai_emergency_alert',
          text:
          'CRITICAL HEALTH ALERT: The symptoms you described indicate a potential emergency. Do not wait — seek immediate emergency evaluation.',
          isUser: false,
          timestamp: DateTime.now(),
          isEmergency: true,
        ),
      ],
    );
  }

  Future<void> _performTriage() async {
    state = state.copyWith(
      stage: SymptomStage.analyzing,
      isAnalyzing: true,
      clearError: true,
    );

    try {
      final result = await _repository.analyzeConversationalSymptoms(
        ConversationalTriageRequest(
          chiefComplaint: state.chiefComplaint ?? '',
          duration: state.duration ?? '',
          severity: state.severity ?? '',
          associatedSymptoms: state.associatedSymptoms,
          medicalHistory: state.contextNote,
        ),
      );

      if (result.emergencyDetected) {
        state = state.copyWith(
          stage: SymptomStage.emergency,
          isAnalyzing: false,
          triageResult: result,
        );
      } else {
        state = state.copyWith(
          stage: SymptomStage.complete,
          isAnalyzing: false,
          triageResult: result,
        );
      }
    } catch (error) {
      final appException = error is AppException
          ? error
          : ErrorMapper.map(error);
      state = state.copyWith(
        stage: SymptomStage.review,
        isAnalyzing: false,
        errorMessage: appException.message,
      );
    }
  }

  Future<void> retryTriage() async {
    if (state.stage != SymptomStage.review || state.isAnalyzing) return;
    await _performTriage();
  }

  void reset() {
    _initDialogue();
  }
}

final conversationalTriageProvider =
StateNotifierProvider<
    ConversationalTriageNotifier,
    ConversationalTriageState
>((ref) {
  return ConversationalTriageNotifier(ref.watch(aiCareRepositoryProvider));
});
