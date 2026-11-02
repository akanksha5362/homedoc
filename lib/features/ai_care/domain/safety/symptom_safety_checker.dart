import 'package:equatable/equatable.dart';

/// Clinical Emergency Detection Result (Day 3.2 §24 & Master Handover Prompt §7.E).
class EmergencyDetectionResult extends Equatable {
  const EmergencyDetectionResult({
    required this.isEmergency,
    this.matchedTriggers = const [],
    this.guidance,
  });

  final bool isEmergency;
  final List<String> matchedTriggers;
  final String? guidance;

  @override
  List<Object?> get props => [isEmergency, matchedTriggers, guidance];
}

/// Medically-reviewed rules engine for immediate emergency detection.
///
/// Master Handover Prompt §7.B:
/// "Do not let an ordinary LLM response independently determine emergency safety.
///  Do not delay emergency advice while continuing a questionnaire."
///
/// This client-side guard evaluates text instantaneously at any stage of input
/// to intercept critical red-flag conditions before any network roundtrip or LLM.
class SymptomSafetyChecker {
  SymptomSafetyChecker._();

  static const List<_EmergencyTrigger> _triggers = [
    _EmergencyTrigger(
      category: 'Cardiac / Chest',
      patterns: [
        'chest pain',
        'chest pressure',
        'chest tightness',
        'heart attack',
        'pain in left arm',
        'crushing chest',
      ],
      guidance:
      'Severe chest discomfort or potential cardiac symptoms require immediate evaluation by emergency medical services.',
    ),
    _EmergencyTrigger(
      category: 'Respiratory',
      patterns: [
        'cannot breathe',
        'cant breathe',
        'shortness of breath',
        'gasping for air',
        'choking',
        'blue lips',
      ],
      guidance: 'Severe respiratory distress is a critical medical emergency.',
    ),
    _EmergencyTrigger(
      category: 'Neurological / Stroke',
      patterns: [
        'sudden numbness',
        'facial drooping',
        'face drooping',
        'arm weakness',
        'slurred speech',
        'stroke',
        'loss of consciousness',
        'fainted',
        'unconscious',
        'seizure',
      ],
      guidance:
      'Sudden neurological deficits or loss of consciousness require rapid emergency intervention.',
    ),
    _EmergencyTrigger(
      category: 'Severe Hemorrhage',
      patterns: [
        'coughing blood',
        'vomiting blood',
        'uncontrolled bleeding',
        'profuse bleeding',
      ],
      guidance:
      'Severe or uncontrollable bleeding requires emergency trauma care.',
    ),
    _EmergencyTrigger(
      category: 'Anaphylaxis',
      patterns: [
        'anaphylaxis',
        'throat closing',
        'swollen tongue',
        'swollen throat',
        'severe allergic reaction',
      ],
      guidance:
      'Airway compromise from acute allergic reactions is life-threatening.',
    ),
    _EmergencyTrigger(
      category: 'High-Risk Infection',
      patterns: [
        'stiff neck and fever',
        'high fever with confusion',
        'fever with purple rash',
      ],
      guidance:
      'High fever accompanied by neurological signs or rigid neck warrants immediate hospital triage.',
    ),
  ];

  /// Checks whether [input] contains any critical emergency triggers.
  static EmergencyDetectionResult evaluate(String input) {
    final lower = input.toLowerCase().trim();
    if (lower.isEmpty) {
      return const EmergencyDetectionResult(isEmergency: false);
    }

    final matchedTriggers = <String>[];
    String? matchedGuidance;

    for (final trigger in _triggers) {
      for (final pattern in trigger.patterns) {
        final matchIndex = lower.indexOf(pattern);
        if (matchIndex >= 0 && !_isNegated(lower, matchIndex)) {
          matchedTriggers.add('${trigger.category}: $pattern');
          matchedGuidance ??= trigger.guidance;
        }
      }
    }

    if (matchedTriggers.isNotEmpty) {
      return EmergencyDetectionResult(
        isEmergency: true,
        matchedTriggers: matchedTriggers,
        guidance: matchedGuidance,
      );
    }

    return const EmergencyDetectionResult(isEmergency: false);
  }

  static bool _isNegated(String input, int matchIndex) {
    final sentenceStart = input.lastIndexOf(RegExp(r'[,!.?;\n]'), matchIndex);
    var prefix = input.substring(sentenceStart + 1, matchIndex);
    if (RegExp(r'\bnot\s+only\b\s*$', caseSensitive: false).hasMatch(prefix)) {
      return false;
    }
    final contrast = RegExp(
      r'\b(?:but|however|although|yet|except|whereas)\b',
      caseSensitive: false,
    );
    var contrastEnd = 0;
    for (final match in contrast.allMatches(prefix)) {
      contrastEnd = match.end;
    }
    if (contrastEnd > 0) prefix = prefix.substring(contrastEnd);
    return RegExp(
      r"\b(?:no|not|never|denies|without|don't|dont|doesn't|doesnt|isn't|isnt|aren't|arent)\b(?:\s+\w+){0,4}\s*$",
      caseSensitive: false,
    ).hasMatch(prefix);
  }
}

class _EmergencyTrigger {
  const _EmergencyTrigger({
    required this.category,
    required this.patterns,
    required this.guidance,
  });

  final String category;
  final List<String> patterns;
  final String guidance;
}
