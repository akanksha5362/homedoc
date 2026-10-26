import 'package:flutter_test/flutter_test.dart';
import 'package:homedoc/features/ai_care/data/models/ai_triage_request.dart';
import 'package:homedoc/features/ai_care/data/models/ai_triage_result.dart';
import 'package:homedoc/shared/models/ai_urgency.dart';

void main() {
  group('AITriageRequest.toJson', () {
    test('includes only symptoms when optional fields are omitted', () {
      const request = AITriageRequest(symptoms: 'headache');
      final json = request.toJson();

      expect(json, {'symptoms': 'headache'});
      expect(json.containsKey('duration'), isFalse);
      expect(json.containsKey('additional_context'), isFalse);
    });

    test('includes duration and additional_context when provided', () {
      const request = AITriageRequest(
        symptoms: 'headache and mild fever',
        duration: 'since yesterday',
        additionalContext: 'no other symptoms',
      );
      final json = request.toJson();

      expect(json['symptoms'], 'headache and mild fever');
      expect(json['duration'], 'since yesterday');
      expect(json['additional_context'], 'no other symptoms');
    });
  });

  group('AIUrgency.fromApi', () {
    test('parses each known value', () {
      expect(AIUrgency.fromApi('routine'), AIUrgency.routine);
      expect(AIUrgency.fromApi('soon'), AIUrgency.soon);
      expect(AIUrgency.fromApi('urgent'), AIUrgency.urgent);
      expect(AIUrgency.fromApi('emergency'), AIUrgency.emergency);
    });

    test('defaults unknown/null values to urgent, not routine (fail-safe)', () {
      expect(AIUrgency.fromApi(null), AIUrgency.urgent);
      expect(AIUrgency.fromApi('unexpected_value'), AIUrgency.urgent);
      expect(AIUrgency.fromApi(''), AIUrgency.urgent);
    });
  });

  group('AITriageResult.fromJson', () {
    test('parses a complete, well-formed response', () {
      final result = AITriageResult.fromJson(const {
        'summary': 'Your symptoms may be consistent with several common causes.',
        'urgency': 'routine',
        'recommendation': 'Consider consulting a general physician if symptoms persist.',
        'reasoning': 'The duration and symptoms provided do not indicate an obvious emergency.',
        'red_flags': <String>[],
        'next_step': 'Monitor symptoms and consider a doctor consultation.',
        'is_uncertain': true,
        'emergency_detected': false,
        'disclaimer': 'AI guidance, not a diagnosis.',
      });

      expect(result.summary, contains('several common causes'));
      expect(result.urgency, AIUrgency.routine);
      expect(result.redFlags, isEmpty);
      expect(result.isUncertain, isTrue);
      expect(result.emergencyDetected, isFalse);
      expect(result.disclaimer, 'AI guidance, not a diagnosis.');
    });

    test('parses emergency signals correctly', () {
      final result = AITriageResult.fromJson(const {
        'summary': 'Some symptoms you described can indicate a serious condition.',
        'urgency': 'emergency',
        'recommendation': 'Seek emergency medical attention now.',
        'reasoning': 'Chest pain with breathlessness is a red flag combination.',
        'red_flags': ['Chest pain', 'Shortness of breath'],
        'next_step': 'Request emergency help immediately.',
        'is_uncertain': false,
        'emergency_detected': true,
      });

      expect(result.urgency, AIUrgency.emergency);
      expect(result.emergencyDetected, isTrue);
      expect(result.redFlags, containsAll(['Chest pain', 'Shortness of breath']));
    });

    test('defaults missing fields to safe/cautious values, not empty-crash', () {
      final result = AITriageResult.fromJson(const <String, dynamic>{});

      expect(result.summary, '');
      expect(result.urgency, AIUrgency.urgent); // fail-safe default
      expect(result.redFlags, isEmpty);
      expect(result.isUncertain, isTrue); // defaults to cautious
      expect(result.emergencyDetected, isFalse);
      expect(result.disclaimer, 'AI guidance, not a diagnosis.'); // never blank
    });
  });
}
