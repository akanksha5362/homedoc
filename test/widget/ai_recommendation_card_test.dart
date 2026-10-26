import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homedoc/shared/ai/ai_recommendation_card.dart';
import 'package:homedoc/shared/models/ai_urgency.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  group('AIRecommendationCard', () {
    testWidgets('always renders the disclaimer text passed to it', (tester) async {
      await tester.pumpWidget(
        wrap(const AIRecommendationCard(
          recommendation: 'Consider a video consultation.',
          reasoning: 'Symptoms are mild but persistent.',
          disclaimer: 'AI guidance, not a diagnosis.',
        )),
      );

      expect(find.text('AI guidance, not a diagnosis.'), findsOneWidget);
    });

    testWidgets('renders recommendation, reasoning, and next step', (tester) async {
      await tester.pumpWidget(
        wrap(const AIRecommendationCard(
          recommendation: 'Consider a video consultation.',
          reasoning: 'Symptoms are mild but persistent.',
          disclaimer: 'AI guidance, not a diagnosis.',
          nextStep: 'Book a video consultation if symptoms persist.',
        )),
      );

      expect(find.text('Consider a video consultation.'), findsOneWidget);
      expect(find.text('Symptoms are mild but persistent.'), findsOneWidget);
      expect(find.text('Book a video consultation if symptoms persist.'), findsOneWidget);
    });

    testWidgets('shows an urgency pill when urgency is provided', (tester) async {
      await tester.pumpWidget(
        wrap(const AIRecommendationCard(
          recommendation: 'r',
          reasoning: 're',
          disclaimer: 'd',
          urgency: AIUrgency.urgent,
        )),
      );

      expect(find.text('Urgent'), findsOneWidget);
    });

    testWidgets('shows no urgency pill when urgency is omitted', (tester) async {
      await tester.pumpWidget(
        wrap(const AIRecommendationCard(recommendation: 'r', reasoning: 're', disclaimer: 'd')),
      );

      expect(find.text('Routine'), findsNothing);
      expect(find.text('Urgent'), findsNothing);
      expect(find.text('Emergency'), findsNothing);
    });
  });
}
