import 'package:firebase_ai/firebase_ai.dart';

import '../models/agent_response.dart';
import '../models/agent_risk_level.dart';
import 'package:flutter/foundation.dart';

class GeminiAiDataSource {
  GeminiAiDataSource()
      : _model = FirebaseAI.googleAI().generativeModel(
    model: 'gemini-3.5-flash-lite',
    systemInstruction: Content.text(_systemPrompt),
  );

  final GenerativeModel _model;

  // Maintain a separate chat session for each conversation.
  final Map<String, ChatSession> _sessions = {};

  static const String _systemPrompt = '''
You are HomeDoc AI, a healthcare information assistant.

Your responsibilities:
- Provide general health information in clear, simple language.
- Help users understand symptoms without diagnosing them.
- Encourage users to consult qualified healthcare professionals.
- Ask relevant follow-up questions when necessary.
- Be empathetic, calm, and concise.

Safety rules:
- Never claim to provide a definitive diagnosis.
- Never prescribe medicines or recommend medication dosages.
- Never claim to have booked appointments or contacted doctors.
- Never claim to have accessed medical records.
- Do not invent doctors, hospitals, appointments, or other services.
- If a user describes potentially life-threatening symptoms,
  advise them to seek emergency medical care immediately.
- Do not delay emergency advice by asking more questions.
- Clearly state that AI guidance is not a substitute for
  professional medical advice.

You cannot perform actions in the HomeDoc AI application.
''';

  Future<AgentResponse> sendMessage(AgentRequest request) async {
    debugPrint('GEMINI: sendMessage called');
    debugPrint('GEMINI: user message = ${request.message}');

    final sessionId = request.sessionId ??
        DateTime.now().microsecondsSinceEpoch.toString();

    final chat = _sessions.putIfAbsent(
      sessionId,
          () => _model.startChat(),
    );

    try {
      debugPrint('GEMINI: Sending request to model...');

      final response = await chat
          .sendMessage(
        Content.text(request.message),
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception(
            'Gemini request timed out after 30 seconds.',
          );
        },
      );

      debugPrint('GEMINI: Response received');

      final responseText = response.text?.trim();

      debugPrint('GEMINI: Response text = $responseText');

      if (responseText == null || responseText.isEmpty) {
        throw Exception('Gemini returned an empty response.');
      }

      return AgentResponse(
        message: responseText,
        intent: 'assistant',
        riskLevel: AgentRiskLevel.confirm,
        requiresConfirmation: true,
        actions: const [],
        sessionId: sessionId,
        toolUsed: null,
        modelUsed: 'gemini-3.5-flash-lite',
      );
    } catch (e, stackTrace) {
      debugPrint('GEMINI ERROR: $e');
      debugPrint('GEMINI STACKTRACE: $stackTrace');
      rethrow;
    }
  }

  void clearSession(String? sessionId) {
    if (sessionId != null) {
      _sessions.remove(sessionId);
    }
  }
}