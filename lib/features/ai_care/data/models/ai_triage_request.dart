import 'package:equatable/equatable.dart';

/// Request payload for `POST /ai/triage` (see docs/backend_contract_ai_triage.md).
///
/// MODEL CONVENTION NOTE: the AI implementation prompt suggested Freezed
/// models. `freezed`/`freezed_annotation` are already in pubspec.yaml, but
/// no model in the existing codebase actually uses them yet — `UserModel`,
/// `DoctorModel`, and `AppointmentModel` are all plain `Equatable` classes
/// with hand-written `fromJson`. Priority order for this change is
/// "preserve existing architecture" first, so this model (and
/// [AITriageResult]) follow that *actual* established convention rather
/// than introducing Freezed as the first codegen-dependent model in the
/// project — which would also mean this feature can't compile without a
/// `build_runner` pass, unlike everything else added today. Freezed
/// remains available in pubspec if a future, deliberate migration of all
/// models is wanted — that's a separate decision from this one.
class AITriageRequest extends Equatable {
  const AITriageRequest({
    required this.symptoms,
    this.duration,
    this.additionalContext,
  });

  /// Free-text patient description, e.g. "headache and mild fever since yesterday".
  final String symptoms;

  /// Optional structured-ish duration hint, e.g. "since yesterday", "2 days".
  final String? duration;

  /// Optional extra context (e.g. answers to follow-up questions).
  final String? additionalContext;

  Map<String, dynamic> toJson() => {
        'symptoms': symptoms,
        if (duration != null) 'duration': duration,
        if (additionalContext != null) 'additional_context': additionalContext,
      };

  @override
  List<Object?> get props => [symptoms, duration, additionalContext];
}
