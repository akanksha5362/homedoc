import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_paths.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/ai/ai_thinking_indicator.dart';
import '../../../../shared/healthcare/emergency_warning.dart';
import '../../../../shared/widgets/buttons/app_button.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/states/app_error_state.dart';
import '../../data/models/agent_response.dart';
import '../providers/ai_assistant_provider.dart';
import '../widgets/ai_agent_action_card.dart';
import '../widgets/ai_message_bubble.dart';
import '../widgets/ai_suggestion_chip.dart';

/// HomeDoc AI Care Assistant (Day 3.2 §27) — the real replacement for the
/// generic "AI symptom checker" entry point. This is now the primary AI
/// entry from Home; the single-purpose symptom triage flow (Day 3's
/// AiCarePage, still calling /ai/triage against a documented-but-unbuilt
/// backend contract) is reachable from here via the "Check my symptoms"
/// quick action, not bypassed.
///
/// Deliberately structured, not a chat clone (Day 3.2 §27): quick-action
/// chips up front, short assistant messages, and STRUCTURED action cards
/// (doctor results, emergency warning) rather than an open-ended
/// scrolling transcript.
class AiAssistantPage extends ConsumerStatefulWidget {
  const AiAssistantPage({super.key});

  @override
  ConsumerState<AiAssistantPage> createState() => _AiAssistantPageState();
}

class _AiAssistantPageState extends ConsumerState<AiAssistantPage> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  String? _lastSentMessage;

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send(String message) {
    if (message.trim().isEmpty) return;
    _lastSentMessage = message.trim();
    _inputController.clear();
    ref.read(aiAssistantControllerProvider.notifier).sendMessage(message);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _retry() {
    final message = _lastSentMessage;
    if (message != null) _send(message);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiAssistantControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('AI Care Assistant')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: state.turns.isEmpty
                  ? _InitialState(onQuickAction: _send)
                  : ListView(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      children: [
                        for (final turn in state.turns) ...[
                          UserMessageBubble(text: turn.userMessage),
                          const SizedBox(height: AppSpacing.sm),
                          if (turn.response != null)
                            _TurnResult(response: turn.response!)
                          else if (state.isSending)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                              child: AIThinkingIndicator(message: 'Thinking…'),
                            ),
                          const SizedBox(height: AppSpacing.lg),
                        ],
                        if (state.status == AiAssistantStatus.error)
                          AppErrorState(
                            message: state.errorMessage ?? 'Care guidance is temporarily unavailable.',
                            onRetry: _retry,
                          ),
                      ],
                    ),
            ),
            _Composer(controller: _inputController, isSending: state.isSending, onSend: _send),
          ],
        ),
      ),
    );
  }
}

class _InitialState extends StatelessWidget {
  const _InitialState({required this.onQuickAction});

  final void Function(String message) onQuickAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Hi, how can I help you today?', style: AppTypography.h1),
          const SizedBox(height: AppSpacing.xl),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              AISuggestionChip(
                label: 'Check my symptoms',
                icon: Icons.health_and_safety_outlined,
                onTap: () => context.push(RoutePaths.patientAiCare),
              ),
              AISuggestionChip(
                label: 'Find a doctor',
                icon: Icons.search,
                onTap: () => onQuickAction('I want to find a doctor'),
              ),
              AISuggestionChip(
                label: 'Book home visit',
                icon: Icons.home_outlined,
                onTap: () => onQuickAction('I want a home visit from a doctor'),
              ),
              AISuggestionChip(
                label: 'Video consultation',
                icon: Icons.videocam_outlined,
                onTap: () => onQuickAction('I want a video consultation'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TurnResult extends StatelessWidget {
  const _TurnResult({required this.response});

  final AgentResponse response;

  @override
  Widget build(BuildContext context) {
    if (response.isEmergency) {
      return EmergencyWarning(
        message: response.message,
        actionLabel: 'Get emergency help',
        onAction: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Emergency flow — coming in a later implementation phase')),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AIMessageBubble(text: response.message),
        if (response.actions.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          for (final action in response.actions) AIAgentActionCard(action: action),
        ],
      ],
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.isSending, required this.onSend});

  final TextEditingController controller;
  final bool isSending;
  final void Function(String message) onSend;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: AppTextField(
              label: 'Message',
              controller: controller,
              hintText: 'e.g. I have a fever and want a doctor',
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          AppButton(
            label: 'Send',
            isLoading: isSending,
            onPressed: () => onSend(controller.text),
          ),
        ],
      ),
    );
  }
}
