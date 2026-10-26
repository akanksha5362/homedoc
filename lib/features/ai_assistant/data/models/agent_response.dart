import 'package:equatable/equatable.dart';
import 'agent_risk_level.dart';

class AgentRequest extends Equatable {
  const AgentRequest({required this.message, this.sessionId});

  final String message;
  final String? sessionId;

  Map<String, dynamic> toJson() => {
        'message': message,
        if (sessionId != null) 'session_id': sessionId,
      };

  @override
  List<Object?> get props => [message, sessionId];
}

class AgentAction extends Equatable {
  const AgentAction({required this.type, required this.data});

  final AgentActionType type;
  final Map<String, dynamic> data;

  factory AgentAction.fromJson(Map<String, dynamic> json) => AgentAction(
        type: AgentActionType.fromApi(json['type'] as String?),
        data: (json['data'] as Map<String, dynamic>?) ?? const {},
      );

  @override
  List<Object?> get props => [type, data];
}

class AgentResponse extends Equatable {
  const AgentResponse({
    required this.message,
    required this.intent,
    required this.riskLevel,
    required this.requiresConfirmation,
    required this.actions,
    required this.sessionId,
    this.toolUsed,
    this.modelUsed,
  });

  final String message;
  final String intent;
  final AgentRiskLevel riskLevel;
  final bool requiresConfirmation;
  final List<AgentAction> actions;
  final String sessionId;
  final String? toolUsed;
  final String? modelUsed;

  bool get isEmergency => riskLevel == AgentRiskLevel.escalation;

  factory AgentResponse.fromJson(Map<String, dynamic> json) => AgentResponse(
        message: json['message'] as String? ?? '',
        intent: json['intent'] as String? ?? 'unknown',
        riskLevel: AgentRiskLevel.fromApi(json['risk_level'] as String?),
        requiresConfirmation: json['requires_confirmation'] as bool? ?? true, // fail-safe default
        actions: (json['actions'] as List<dynamic>? ?? [])
            .map((e) => AgentAction.fromJson(e as Map<String, dynamic>))
            .toList(),
        sessionId: json['session_id'] as String? ?? '',
        toolUsed: json['tool_used'] as String?,
        modelUsed: json['model_used'] as String?,
      );

  @override
  List<Object?> get props =>
      [message, intent, riskLevel, requiresConfirmation, actions, sessionId, toolUsed, modelUsed];
}
