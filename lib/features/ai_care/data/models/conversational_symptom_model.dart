import 'package:equatable/equatable.dart';
import '../models/ai_triage_result.dart';
import '../../domain/safety/symptom_safety_checker.dart';

/// Progressive stages in guided conversational symptom checking (Prompt §7.A).
enum SymptomStage {
  chiefComplaint,
  duration,
  severity,
  associatedSymptoms,
  review,
  analyzing,
  complete,
  emergency,
}

/// A single message turn inside the conversational symptom dialogue.
class DialogueMessage extends Equatable {
  const DialogueMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.suggestedChips = const [],
    this.isEmergency = false,
  });

  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<String> suggestedChips;
  final bool isEmergency;

  @override
  List<Object?> get props => [
    id,
    text,
    isUser,
    timestamp,
    suggestedChips,
    isEmergency,
  ];
}

/// Immutable state representing the interactive conversational symptom session.
class ConversationalTriageState extends Equatable {
  const ConversationalTriageState({
    this.stage = SymptomStage.chiefComplaint,
    this.messages = const [],
    this.chiefComplaint,
    this.duration,
    this.severity,
    this.associatedSymptoms = const [],
    this.contextNote,
    this.triageResult,
    this.emergencyResult,
    this.isAnalyzing = false,
    this.errorMessage,
  });

  final SymptomStage stage;
  final List<DialogueMessage> messages;
  final String? chiefComplaint;
  final String? duration;
  final String? severity;
  final List<String> associatedSymptoms;
  final String? contextNote;
  final AITriageResult? triageResult;
  final EmergencyDetectionResult? emergencyResult;
  final bool isAnalyzing;
  final String? errorMessage;

  bool get hasEmergency =>
      stage == SymptomStage.emergency ||
          (emergencyResult?.isEmergency ?? false) ||
          (triageResult?.emergencyDetected ?? false);

  ConversationalTriageState copyWith({
    SymptomStage? stage,
    List<DialogueMessage>? messages,
    String? chiefComplaint,
    String? duration,
    String? severity,
    List<String>? associatedSymptoms,
    String? contextNote,
    AITriageResult? triageResult,
    EmergencyDetectionResult? emergencyResult,
    bool? isAnalyzing,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ConversationalTriageState(
      stage: stage ?? this.stage,
      messages: messages ?? this.messages,
      chiefComplaint: chiefComplaint ?? this.chiefComplaint,
      duration: duration ?? this.duration,
      severity: severity ?? this.severity,
      associatedSymptoms: associatedSymptoms ?? this.associatedSymptoms,
      contextNote: contextNote ?? this.contextNote,
      triageResult: triageResult ?? this.triageResult,
      emergencyResult: emergencyResult ?? this.emergencyResult,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    stage,
    messages,
    chiefComplaint,
    duration,
    severity,
    associatedSymptoms,
    contextNote,
    triageResult,
    emergencyResult,
    isAnalyzing,
    errorMessage,
  ];
}
