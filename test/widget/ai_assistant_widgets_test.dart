import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homedoc/features/ai_assistant/data/models/agent_response.dart';
import 'package:homedoc/features/ai_assistant/data/models/agent_risk_level.dart';
import 'package:homedoc/features/ai_assistant/presentation/widgets/ai_agent_action_card.dart';
import 'package:homedoc/features/ai_assistant/presentation/widgets/ai_suggestion_chip.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  group('AISuggestionChip', () {
    testWidgets('renders label and fires onTap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        wrap(AISuggestionChip(label: 'Find a doctor', onTap: () => tapped = true)),
      );

      expect(find.text('Find a doctor'), findsOneWidget);
      await tester.tap(find.text('Find a doctor'));
      expect(tapped, isTrue);
    });
  });

  group('AIAgentActionCard', () {
    testWidgets('renders a doctor card for each doctor in a SHOW_DOCTORS action', (tester) async {
      const action = AgentAction(
        type: AgentActionType.showDoctors,
        data: {
          'doctors': [
            {
              'id': '1',
              'name': 'Dr. Ananya Sharma',
              'specialty': 'General Physician',
              'verified': true,
              'rating': 4.8,
              'experience_years': 9,
            },
            {
              'id': '2',
              'name': 'Dr. Ravi Iyer',
              'specialty': 'General Physician',
              'verified': true,
              'rating': 4.6,
              'experience_years': 6,
            },
          ],
        },
      );

      await tester.pumpWidget(wrap(const AIAgentActionCard(action: action)));

      expect(find.text('Dr. Ananya Sharma'), findsOneWidget);
      expect(find.text('Dr. Ravi Iyer'), findsOneWidget);
    });

    testWidgets('shows an empty message when SHOW_DOCTORS has no doctors', (tester) async {
      const action = AgentAction(type: AgentActionType.showDoctors, data: {'doctors': []});

      await tester.pumpWidget(wrap(const AIAgentActionCard(action: action)));

      expect(find.text('No doctors found for that right now.'), findsOneWidget);
    });

    testWidgets('renders nothing for EMERGENCY (handled by the page via EmergencyWarning)', (tester) async {
      const action = AgentAction(type: AgentActionType.emergency, data: {});

      await tester.pumpWidget(wrap(const AIAgentActionCard(action: action)));

      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('shows an honest "not yet available" row for unimplemented action types', (tester) async {
      const action = AgentAction(type: AgentActionType.bookAppointment, data: {});

      await tester.pumpWidget(wrap(const AIAgentActionCard(action: action)));

      expect(find.textContaining('coming in a later implementation phase'), findsOneWidget);
    });
  });
}
