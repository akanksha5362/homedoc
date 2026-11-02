import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homedoc/core/errors/app_exception.dart';
import 'package:homedoc/core/localization/generated/app_localizations.dart';
import 'package:homedoc/features/ai_care/data/models/ai_triage_request.dart';
import 'package:homedoc/features/ai_care/data/models/ai_triage_result.dart';
import 'package:homedoc/features/ai_care/data/models/conversational_triage_request.dart';
import 'package:homedoc/features/ai_care/domain/repositories/ai_care_repository.dart';
import 'package:homedoc/features/ai_care/presentation/pages/ai_care_page.dart';
import 'package:homedoc/features/ai_care/presentation/providers/ai_care_provider.dart';
import 'package:homedoc/shared/models/ai_urgency.dart';

/// NOTE: this test depends on generated localization code
/// (`flutter gen-l10n`) which is not committed to the repo (see
/// .gitignore) and was not runnable in the authoring sandbox (no Flutter
/// SDK). Run `flutter gen-l10n` before `flutter test` — see README.

class _ControllableRepository implements AiCareRepository {
  AITriageResult? nextResult;
  Object? nextError;
  int callCount = 0;

  @override
  Future<AITriageResult> analyzeSymptoms(AITriageRequest request) async {
    callCount++;
    await Future<void>.delayed(const Duration(milliseconds: 10));
    if (nextError != null) throw nextError!;
    return nextResult!;
  }

  @override
  Future<AITriageResult> analyzeConversationalSymptoms(
    ConversationalTriageRequest request,
  ) =>
      analyzeSymptoms(AITriageRequest(symptoms: request.chiefComplaint));
}

const _routineResult = AITriageResult(
  summary: 'Your symptoms may have several common causes.',
  urgency: AIUrgency.routine,
  recommendation: 'Consider a video consultation if symptoms persist.',
  reasoning: 'No red flags were identified from the description given.',
  redFlags: [],
  nextStep: 'Monitor symptoms for the next day.',
  isUncertain: true,
  emergencyDetected: false,
);

const _emergencyResult = AITriageResult(
  summary: 'Some symptoms described can indicate a serious condition.',
  urgency: AIUrgency.emergency,
  recommendation: 'Seek emergency medical attention now.',
  reasoning: 'Chest pain with breathlessness is a red flag combination.',
  redFlags: ['Chest pain', 'Shortness of breath'],
  nextStep: 'Request emergency help immediately.',
  isUncertain: false,
  emergencyDetected: true,
);

Widget _wrap(_ControllableRepository repo) {
  return ProviderScope(
    overrides: [aiCareRepositoryProvider.overrideWithValue(repo)],
    child: const MaterialApp(
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [Locale('en'), Locale('hi')],
      home: AiCarePage(),
    ),
  );
}

void main() {
  group('AiCarePage', () {
    testWidgets('shows a validation error and does not call the repository for empty symptoms', (tester) async {
      final repo = _ControllableRepository();
      await tester.pumpWidget(_wrap(repo));

      await tester.tap(find.byIcon(Icons.spa_outlined).first);
      await tester.pump();

      expect(repo.callCount, 0);
      expect(find.text("Please describe what you're experiencing first."), findsOneWidget);
    });

    testWidgets('shows the thinking indicator while analyzing, then the result on success', (tester) async {
      final repo = _ControllableRepository()..nextResult = _routineResult;
      await tester.pumpWidget(_wrap(repo));

      await tester.enterText(find.byType(TextField).first, 'headache and mild fever since yesterday');
      await tester.tap(find.text('Get care guidance'));
      await tester.pump(); // start analyzing

      expect(find.text("Thinking through what you've shared…"), findsOneWidget);

      await tester.pumpAndSettle();

      expect(find.text('AI guidance, not a diagnosis.'), findsOneWidget); // disclaimer always present
      expect(find.text('Routine'), findsOneWidget);
      expect(find.textContaining('several common causes'), findsOneWidget);
    });

    testWidgets('shows the full-screen emergency warning when emergency_detected is true', (tester) async {
      final repo = _ControllableRepository()..nextResult = _emergencyResult;
      await tester.pumpWidget(_wrap(repo));

      await tester.enterText(find.byType(TextField).first, 'severe chest pain and shortness of breath');
      await tester.tap(find.text('Get care guidance'));
      await tester.pumpAndSettle();

      expect(find.text('This may need urgent attention'), findsOneWidget);
      expect(find.textContaining('chest pain'), findsOneWidget);
      expect(find.text('View Emergency Options'), findsOneWidget);
      // The normal AIRecommendationCard (with its disclaimer) must NOT
      // also render — emergency breaks out of the AI UI entirely rather
      // than stacking alongside it.
      expect(find.text('AI guidance, not a diagnosis.'), findsNothing);
    });

    testWidgets('shows AppErrorState with a retry action on failure', (tester) async {
      final repo = _ControllableRepository()..nextError = const AIServiceException();
      await tester.pumpWidget(_wrap(repo));

      await tester.enterText(find.byType(TextField).first, 'headache');
      await tester.tap(find.text('Get care guidance'));
      await tester.pumpAndSettle();

      expect(find.text('Care guidance is temporarily unavailable.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      // retry re-invokes the repository
      repo.nextError = null;
      repo.nextResult = _routineResult;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(repo.callCount, 2);
      expect(find.text('AI guidance, not a diagnosis.'), findsOneWidget);
    });
  });
}
