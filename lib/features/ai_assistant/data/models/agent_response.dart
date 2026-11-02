import 'package:equatable/equatable.dart';

import 'agent_risk_level.dart';

class AgentRequest extends Equatable {
  const AgentRequest({
    required this.message,
    this.sessionId,
  });

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
  const AgentAction({
    required this.type,
    required this.data,
  });

  final AgentActionType type;
  final Map<String, dynamic> data;

  factory AgentAction.fromJson(Map<String, dynamic> json) {
    return AgentAction(
      type: AgentActionType.fromApi(
        _stringValue(json['type']),
      ),
      data: _mapValue(json['data']),
    );
  }

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

  factory AgentResponse.fromJson(Map<String, dynamic> json) {
    final rawActions = json['actions'];

    final actions = rawActions is List
        ? rawActions
        .whereType<Map>()
        .map(
          (action) => AgentAction.fromJson(
        _mapValue(action),
      ),
    )
        .toList()
        : <AgentAction>[];

    return AgentResponse(
      message: _stringValue(json['message']) ?? '',
      intent: _stringValue(json['intent']) ?? 'unknown',
      riskLevel: AgentRiskLevel.fromApi(
        _stringValue(json['risk_level']),
      ),

      // Fail-safe: missing or malformed confirmation values default
      // to true so the app does not silently treat an action as safe.
      requiresConfirmation:
      json['requires_confirmation'] is bool
          ? json['requires_confirmation'] as bool
          : true,

      actions: actions,
      sessionId: _stringValue(json['session_id']) ?? '',
      toolUsed: _stringValue(json['tool_used']),
      modelUsed: _stringValue(json['model_used']),
    );
  }

  @override
  List<Object?> get props => [
    message,
    intent,
    riskLevel,
    requiresConfirmation,
    actions,
    sessionId,
    toolUsed,
    modelUsed,
  ];
}

/// Returns a trimmed string only when the input is a non-empty string.
String? _stringValue(Object? value) {
  if (value is String && value.trim().isNotEmpty) {
    return value.trim();
  }

  return null;
}

/// Converts a map into a JSON-style map, ignoring non-string keys.
Map<String, dynamic> _mapValue(Object? value) {
  if (value is! Map) {
    return <String, dynamic>{};
  }

  return {
    for (final entry in value.entries)
      if (entry.key is String)
        entry.key as String: entry.value,
  };
}