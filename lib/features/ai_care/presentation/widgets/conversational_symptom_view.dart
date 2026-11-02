import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_paths.dart';
import '../../../../shared/ai/ai_thinking_indicator.dart';
import '../../../../shared/healthcare/emergency_warning.dart';
import '../../../../shared/widgets/states/app_error_state.dart';
import '../../data/models/conversational_symptom_model.dart';
import '../providers/conversational_symptom_provider.dart';
import 'urgency_classification_view.dart';

/// Interactive Conversational Symptom Checker (Master Prompt §7.A).
///
/// Guides patients through clinically relevant questions step-by-step
/// (Chief complaint -> Duration -> Severity -> Associated Symptoms -> Review),
/// provides quick selectable suggestion chips, validates emergency keywords
/// in real time, and renders the comprehensive Urgency Classification Screen.
class ConversationalSymptomView extends ConsumerStatefulWidget {
  const ConversationalSymptomView({super.key});

  @override
  ConsumerState<ConversationalSymptomView> createState() =>
      _ConversationalSymptomViewState();
}

class _ConversationalSymptomViewState
    extends ConsumerState<ConversationalSymptomView> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _submitText(String text) {
    if (text.trim().isEmpty) return;
    _textController.clear();
    ref.read(conversationalTriageProvider.notifier).submitAnswer(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(conversationalTriageProvider);

    // If an emergency has been flagged, immediately break out into the EmergencyWarning
    if (state.hasEmergency) {
      final redFlags =
          state.emergencyResult?.matchedTriggers ??
              state.triageResult?.redFlags ??
              const ['Critical emergency symptoms identified'];
      return Padding(
        padding: const EdgeInsets.all(20),
        child: EmergencyWarning(
          message:
          'CRITICAL HEALTH ALERT: The symptoms you described indicate a potential medical emergency. Please seek immediate medical evaluation.',
          redFlags: redFlags,
          redFlagsLabel: 'Identified Red Flags',
          actionLabel: 'View Emergency Options',
          onAction: () => context.push(RoutePaths.patientEmergency),
        ),
      );
    }

    // If complete and triageResult exists, render the full Urgency Classification screen
    if (state.stage == SymptomStage.complete && state.triageResult != null) {
      return UrgencyClassificationView(
        result: state.triageResult!,
        onStartOver: () {
          ref.read(conversationalTriageProvider.notifier).reset();
        },
      );
    }

    final (stepNumber, stepLabel) = switch (state.stage) {
      SymptomStage.chiefComplaint => (1, 'Primary Symptoms'),
      SymptomStage.duration => (2, 'Duration & Timeline'),
      SymptomStage.severity => (3, 'Severity Rating'),
      SymptomStage.associatedSymptoms => (4, 'Associated Symptoms'),
      SymptomStage.review => (5, 'Clinical Context'),
      SymptomStage.analyzing => (5, 'Analyzing Guidance'),
      SymptomStage.complete => (5, 'Complete'),
      SymptomStage.emergency => (0, 'Emergency'),
    };

    return Column(
      children: [
        // 1. Progress Indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF007A8A).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Step $stepNumber of 5',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF007A8A),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  stepLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
              ),
              const Icon(
                Icons.shield_outlined,
                size: 16,
                color: Color(0xFF007A8A),
              ),
            ],
          ),
        ),

        // 2. Chat / Dialogue Stream
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: state.messages.length + (state.isAnalyzing ? 1 : 0),
            itemBuilder: (context, index) {
              if (index < state.messages.length) {
                final message = state.messages[index];
                return _buildMessageTurn(message);
              } else {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: AIThinkingIndicator(
                      message: 'Synthesizing clinical guidance…',
                    ),
                  ),
                );
              }
            },
          ),
        ),

        // 3. Quick Chips Section (if active message has suggested chips)
        if (!state.isAnalyzing &&
            state.errorMessage == null &&
            state.messages.isNotEmpty)
          _buildQuickChips(state),

        if (state.errorMessage != null)
          SizedBox(
            height: 190,
            child: AppErrorState(
              message: state.errorMessage!,
              onRetry: () =>
                  ref.read(conversationalTriageProvider.notifier).retryTriage(),
            ),
          ),

        // 4. Composer Input Field
        if (!state.isAnalyzing && state.errorMessage == null) ...[
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: 'Type your answer or select a suggestion…',
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF9CA3AF),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF3F4F6),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: _submitText,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF007A8A),
                    foregroundColor: Colors.white,
                    shape: const CircleBorder(),
                  ),
                  icon: const Icon(Icons.arrow_upward_rounded, size: 20),
                  onPressed: () => _submitText(_textController.text),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildQuickChips(ConversationalTriageState state) {
    final lastAiMsg = state.messages.lastWhere(
          (m) => !m.isUser,
      orElse: () => state.messages.first,
    );
    if (lastAiMsg.suggestedChips.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFFF9FAFB),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            for (final chip in lastAiMsg.suggestedChips)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFF007A8A), width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  label: Text(
                    chip,
                    style: const TextStyle(
                      color: Color(0xFF007A8A),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () => _submitText(chip),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageTurn(DialogueMessage message) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              backgroundColor: Color(0xFFE6F7F6),
              foregroundColor: Color(0xFF007A8A),
              radius: 16,
              child: Icon(Icons.auto_awesome, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF007A8A) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isUser
                      ? const Radius.circular(16)
                      : const Radius.circular(4),
                  bottomRight: isUser
                      ? const Radius.circular(4)
                      : const Radius.circular(16),
                ),
                border: isUser
                    ? null
                    : Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: isUser
                    ? null
                    : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: isUser ? Colors.white : const Color(0xFF1F2937),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 4),
        ],
      ),
    );
  }
}
