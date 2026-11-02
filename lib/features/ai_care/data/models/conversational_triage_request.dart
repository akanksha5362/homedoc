import 'package:equatable/equatable.dart';

/// Request contract for `POST /ai/triage/conversational`.
class ConversationalTriageRequest extends Equatable {
  const ConversationalTriageRequest({
    required this.chiefComplaint,
    required this.duration,
    required this.severity,
    required this.associatedSymptoms,
    required this.medicalHistory,
    this.sessionId,
    this.ageContext,
  });

  final String? sessionId;
  final String chiefComplaint;
  final String duration;
  final String severity;
  final List<String> associatedSymptoms;
  final String? medicalHistory;
  final int? ageContext;

  Map<String, dynamic> toJson() => {
    'session_id': sessionId,
    'chief_complaint': chiefComplaint,
    'duration': duration,
    'severity': severity,
    'associated_symptoms': associatedSymptoms,
    'medical_history': medicalHistory,
    'age_context': ageContext,
  };

  @override
  List<Object?> get props => [
    sessionId,
    chiefComplaint,
    duration,
    severity,
    associatedSymptoms,
    medicalHistory,
    ageContext,
  ];
}
