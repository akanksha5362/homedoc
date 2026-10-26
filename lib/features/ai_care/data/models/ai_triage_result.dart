import 'package:equatable/equatable.dart';
import '../../domain/entities/ai_urgency.dart';

/// Structured response from `POST /ai/triage`
/// (see docs/backend_contract_ai_triage.md for the full contract).
///
/// Doubles as the feature's domain entity (see the convention note in
/// `ai_triage_request.dart`) — there is no separate `domain/entities/
/// ai_triage_result.dart` because it would be an identical, redundant
/// class at this stage. If a future backend response needs transport-only
/// fields the UI shouldn't see, split them then — not preemptively now
/// (Day 3 AI prompt, Step 20: don't overengineer).
class AITriageResult extends Equatable {
  const AITriageResult({
    required this.summary,
    required this.urgency,
    required this.recommendation,
    required this.reasoning,
    required this.redFlags,
    required this.nextStep,
    required this.isUncertain,
    required this.emergencyDetected,
    this.disclaimer = 'AI guidance, not a diagnosis.',
  });

  final String summary;
  final AIUrgency urgency;
  final String recommendation;
  final String reasoning;
  final List<String> redFlags;
  final String nextStep;
  final bool isUncertain;

  /// Backend-authoritative emergency flag (Day 3 AI prompt, Step 5: "the
  /// backend should ultimately be responsible for clinical safety logic").
  /// The Flutter UI reacts to this — it never independently decides
  /// "this looks like an emergency" from free text.
  final bool emergencyDetected;

  final String disclaimer;

  factory AITriageResult.fromJson(Map<String, dynamic> json) {
    return AITriageResult(
      summary: json['summary'] as String? ?? '',
      urgency: AIUrgency.fromApi(json['urgency'] as String?),
      recommendation: json['recommendation'] as String? ?? '',
      reasoning: json['reasoning'] as String? ?? '',
      redFlags: (json['red_flags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      nextStep: json['next_step'] as String? ?? '',
      isUncertain: json['is_uncertain'] as bool? ?? true, // default to cautious
      emergencyDetected: json['emergency_detected'] as bool? ?? false,
      disclaimer: json['disclaimer'] as String? ?? 'AI guidance, not a diagnosis.',
    );
  }

  @override
  List<Object?> get props => [
        summary,
        urgency,
        recommendation,
        reasoning,
        redFlags,
        nextStep,
        isUncertain,
        emergencyDetected,
        disclaimer,
      ];
}
