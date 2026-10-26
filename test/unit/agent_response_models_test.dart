import 'package:flutter_test/flutter_test.dart';
import 'package:homedoc/features/ai_assistant/data/models/agent_response.dart';
import 'package:homedoc/features/ai_assistant/data/models/agent_risk_level.dart';

void main() {
  group('AgentRiskLevel.fromApi', () {
    test('parses each known value', () {
      expect(AgentRiskLevel.fromApi('info'), AgentRiskLevel.info);
      expect(AgentRiskLevel.fromApi('low'), AgentRiskLevel.low);
      expect(AgentRiskLevel.fromApi('confirm'), AgentRiskLevel.confirm);
      expect(AgentRiskLevel.fromApi('sensitive'), AgentRiskLevel.sensitive);
      expect(AgentRiskLevel.fromApi('escalation'), AgentRiskLevel.escalation);
    });

    test('defaults unknown/null to confirm, not info (fail-safe)', () {
      expect(AgentRiskLevel.fromApi(null), AgentRiskLevel.confirm);
      expect(AgentRiskLevel.fromApi('made_up'), AgentRiskLevel.confirm);
    });
  });

  group('AgentActionType.fromApi', () {
    test('parses SHOW_DOCTORS and EMERGENCY — the two the backend actually sends', () {
      expect(AgentActionType.fromApi('SHOW_DOCTORS'), AgentActionType.showDoctors);
      expect(AgentActionType.fromApi('EMERGENCY'), AgentActionType.emergency);
    });

    test('unrecognized value falls back to unknown, never crashes', () {
      expect(AgentActionType.fromApi('SOMETHING_NEW'), AgentActionType.unknown);
      expect(AgentActionType.fromApi(null), AgentActionType.unknown);
    });
  });

  group('AgentResponse.fromJson', () {
    test('parses a full doctor-search response matching the real backend shape', () {
      final response = AgentResponse.fromJson(const {
        'message': "Here's what I found based on what you shared.",
        'intent': 'doctor_search',
        'risk_level': 'low',
        'requires_confirmation': false,
        'actions': [
          {
            'type': 'SHOW_DOCTORS',
            'data': {
              'doctors': [
                {
                  'id': '1',
                  'name': 'Dr. Ananya Sharma',
                  'specialty': 'General Physician',
                  'verified': true,
                  'rating': 4.8,
                  'experience_years': 9,
                  'supports_home_visit': true,
                  'supports_video': true,
                }
              ]
            },
          }
        ],
        'session_id': 'abc-123',
        'tool_used': 'search_doctors',
        'model_used': 'mock-rule-based-v1',
      });

      expect(response.intent, 'doctor_search');
      expect(response.riskLevel, AgentRiskLevel.low);
      expect(response.requiresConfirmation, isFalse);
      expect(response.isEmergency, isFalse);
      expect(response.sessionId, 'abc-123');
      expect(response.actions, hasLength(1));
      expect(response.actions.first.type, AgentActionType.showDoctors);
      expect(response.actions.first.data['doctors'], hasLength(1));
    });

    test('parses an emergency response with no doctors', () {
      final response = AgentResponse.fromJson(const {
        'message': 'This may be a medical emergency.',
        'intent': 'doctor_search',
        'risk_level': 'escalation',
        'requires_confirmation': true,
        'actions': [
          {'type': 'EMERGENCY', 'data': {}}
        ],
        'session_id': 'abc-456',
      });

      expect(response.isEmergency, isTrue);
      expect(response.requiresConfirmation, isTrue);
      expect(response.actions.first.type, AgentActionType.emergency);
    });

    test('missing requires_confirmation defaults to true (fail-safe), not false', () {
      final response = AgentResponse.fromJson(const {
        'message': 'm',
        'intent': 'unknown',
        'risk_level': 'info',
        'actions': [],
        'session_id': 's',
      });

      expect(response.requiresConfirmation, isTrue);
    });
  });
}
