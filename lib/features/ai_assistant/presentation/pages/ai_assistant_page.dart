import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../shared/healthcare/emergency_warning.dart';
import '../../data/models/agent_response.dart';
import '../providers/ai_assistant_provider.dart';
import '../widgets/ai_agent_action_card.dart';
import '../widgets/ai_message_bubble.dart';

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
    final text = message.trim();

    if (text.isEmpty) return;

    _lastSentMessage = text;
    _inputController.clear();

    ref.read(aiAssistantControllerProvider.notifier).sendMessage(text);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _retry() {
    final message = _lastSentMessage;

    if (message != null) {
      _send(message);
    }
  }

  void _newConversation() {
    ref.read(aiAssistantControllerProvider.notifier).reset();
    _inputController.clear();
    _lastSentMessage = null;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiAssistantControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 18,
        title: Row(
          children: [
            Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF28A895)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.18),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.health_and_safety_rounded,
                color: Colors.white,
                size: 25,
              ),
            ),
            const SizedBox(width: 11),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Care Assistant',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Your health companion',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'AI Health Search',
            onPressed: () {
              context.push(RoutePaths.patientAiSearch);
            },
            icon: const Icon(Icons.search_rounded, color: AppColors.primary),
          ),
          if (state.turns.isNotEmpty)
            IconButton(
              tooltip: 'New conversation',
              onPressed: _newConversation,
              icon: const Icon(
                Icons.add_comment_outlined,
                color: AppColors.primary,
              ),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: state.turns.isEmpty
                  ? _WelcomeView(onQuickAction: _send)
                  : ListView(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      children: [
                        for (final turn in state.turns) ...[
                          _UserBubble(text: turn.userMessage),
                          const SizedBox(height: 18),
                          if (turn.response != null)
                            _AssistantResponse(
                              response: turn.response!,
                              onFollowUp: _send,
                            )
                          else if (state.isSending)
                            const _ThinkingBubble(),
                          const SizedBox(height: 24),
                        ],
                        if (state.status == AiAssistantStatus.error)
                          _ErrorMessage(
                            message:
                                state.errorMessage ??
                                'Care guidance is temporarily unavailable.',
                            onRetry: _retry,
                          ),
                      ],
                    ),
            ),
            _MessageComposer(
              controller: _inputController,
              isSending: state.isSending,
              onSend: _send,
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Welcome screen
// -----------------------------------------------------------------------------

class _WelcomeView extends StatelessWidget {
  const _WelcomeView({required this.onQuickAction});

  final void Function(String message) onQuickAction;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeroHeader(),
          const SizedBox(height: 28),
          const Row(
            children: [
              Text(
                'HOW CAN I HELP?',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.25,
                  color: AppColors.textMuted,
                ),
              ),
              Spacer(),
              Icon(Icons.touch_app_rounded, size: 15, color: AppColors.primary),
              SizedBox(width: 5),
              Text(
                'Choose a topic',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          _QuickActionCard(
            icon: Icons.monitor_heart_rounded,
            title: 'Check my symptoms',
            subtitle: 'Understand symptoms and possible next steps',
            accent: const Color(0xFFE0F4EE),
            onTap: () {
              context.push(RoutePaths.patientAiCare);
            },
          ),
          _QuickActionCard(
            icon: Icons.search_rounded,
            title: 'AI Health Search',
            subtitle: 'Explore health topics and information',
            accent: const Color(0xFFE3F0FA),
            onTap: () {
              context.push(RoutePaths.patientAiSearch);
            },
          ),
          _QuickActionCard(
            icon: Icons.description_rounded,
            title: 'Explain lab reports',
            subtitle: 'Understand common medical terms',
            accent: const Color(0xFFF0EAF8),
            onTap: () => onQuickAction(
              'Can you explain common lab report terms and values in simple language?',
            ),
          ),
          _QuickActionCard(
            icon: Icons.question_answer_rounded,
            title: 'Questions for my doctor',
            subtitle: 'Prepare for your next consultation',
            accent: const Color(0xFFFFF0DB),
            onTap: () => onQuickAction(
              'What questions should I ask my doctor during a consultation?',
            ),
          ),
          _QuickActionCard(
            icon: Icons.medical_services_rounded,
            title: 'Find a doctor',
            subtitle: 'Get help finding the right doctor',
            accent: const Color(0xFFE0F4EE),
            onTap: () => onQuickAction('I want to find a doctor'),
          ),
          _QuickActionCard(
            icon: Icons.home_rounded,
            title: 'Book a home visit',
            subtitle: 'Explore doctor home visit options',
            accent: const Color(0xFFE3F0FA),
            onTap: () => onQuickAction('I want a home visit from a doctor'),
          ),
          _QuickActionCard(
            icon: Icons.videocam_rounded,
            title: 'Video consultation',
            subtitle: 'Ask about an online consultation',
            accent: const Color(0xFFF0EAF8),
            onTap: () => onQuickAction('I want a video consultation'),
          ),
          const SizedBox(height: 12),
          const _SafetyNote(),
        ],
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(21, 23, 21, 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE0F5ED), Color(0xFFEAF7F8), Color(0xFFF0F8FC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(27),
        border: Border.all(color: const Color(0xFFD5ECE5), width: 0.8),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -9,
            top: -14,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.28),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 24,
            bottom: -24,
            child: Container(
              width: 65,
              height: 65,
              decoration: BoxDecoration(
                color: const Color(0xFF8FD7C3).withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 13,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'HOMEDOC AI',
                      style: TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Your health,\\nour priority.',
                style: TextStyle(
                  fontSize: 30,
                  height: 1.13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 11),
              const Text(
                'Ask questions, explore health topics,\\nand find your next step with confidence.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.55,
                  color: Color(0xFF526F6A),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 7),
                    Text(
                      'Hi there! How can I help today?',
                      style: TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Quick-action cards
// -----------------------------------------------------------------------------

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(19),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(19),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(19),
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.75),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF173F36).withValues(alpha: 0.025),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 47,
                  height: 47,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(icon, color: AppColors.primaryDark, size: 23),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11.5,
                          height: 1.35,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Conversation bubbles
// -----------------------------------------------------------------------------

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, Color(0xFF148F7D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(19),
            topRight: Radius.circular(19),
            bottomLeft: Radius.circular(19),
            bottomRight: Radius.circular(5),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

class _AssistantResponse extends StatelessWidget {
  const _AssistantResponse({required this.response, required this.onFollowUp});

  final AgentResponse response;
  final void Function(String message) onFollowUp;

  @override
  Widget build(BuildContext context) {
    if (response.isEmergency) {
      return EmergencyWarning(
        message: response.message,
        actionLabel: 'Get emergency help',
        onAction: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Emergency flow — connecting to emergency services',
              ),
            ),
          );
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 33,
              height: 33,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF28A895)],
                ),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.health_and_safety_rounded,
                color: Colors.white,
                size: 19,
              ),
            ),
            const SizedBox(width: 9),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HomeDoc Assistant',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'AI health guidance',
                  style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(5),
              topRight: Radius.circular(19),
              bottomLeft: Radius.circular(19),
              bottomRight: Radius.circular(19),
            ),
            border: Border.all(color: AppColors.primaryContainer),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.035),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            response.message,
            style: const TextStyle(
              fontSize: 14,
              height: 1.65,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (response.actions.isNotEmpty) ...[
          const SizedBox(height: 12),
          for (final action in response.actions)
            AIAgentActionCard(action: action),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _FollowUpChip(
              label: 'Find specialist doctors',
              onTap: () =>
                  onFollowUp('Which specialist should I see for this?'),
            ),
            _FollowUpChip(
              label: 'Warning signs to monitor',
              onTap: () => onFollowUp(
                'What are the critical warning signs I should monitor?',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FollowUpChip extends StatelessWidget {
  const _FollowUpChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: onTap,
      backgroundColor: AppColors.primaryContainer,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      label: Text(
        label,
        style: const TextStyle(
          color: AppColors.primaryDark,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Thinking and error states
// -----------------------------------------------------------------------------

class _ThinkingBubble extends StatelessWidget {
  const _ThinkingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: AppColors.primaryContainer),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 17,
              height: 17,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
            SizedBox(width: 10),
            Text(
              'Thinking...',
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4F1),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFF5D5CD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.cloud_off_rounded, color: AppColors.error, size: 19),
              SizedBox(width: 8),
              Text(
                'Something went wrong',
                style: TextStyle(
                  color: Color(0xFF9A3F32),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              color: Color(0xFF9A3F32),
              fontSize: 12.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Try again'),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Message composer
// -----------------------------------------------------------------------------

class _MessageComposer extends StatelessWidget {
  const _MessageComposer({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isSending;
  final void Function(String message) onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 11, 15, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border.withValues(alpha: 0.8)),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.035),
            blurRadius: 15,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(23),
                    border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.7),
                    ),
                  ),
                  child: TextField(
                    controller: controller,
                    enabled: !isSending,
                    minLines: 1,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.send,
                    onSubmitted: isSending ? null : onSend,
                    decoration: const InputDecoration(
                      hintText: 'Ask anything about your health...',
                      hintStyle: TextStyle(
                        color: Color(0xFF8A9A94),
                        fontSize: 13,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 17,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 49,
                height: 49,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isSending
                          ? [
                              AppColors.primary.withValues(alpha: 0.55),
                              AppColors.primaryDark.withValues(alpha: 0.55),
                            ]
                          : [AppColors.primary, const Color(0xFF148F7D)],
                    ),
                    borderRadius: BorderRadius.circular(17),
                    boxShadow: [
                      if (!isSending)
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(17),
                      onTap: isSending ? null : () => onSend(controller.text),
                      child: Center(
                        child: isSending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.arrow_upward_rounded,
                                color: Colors.white,
                                size: 25,
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const _SafetyNote(),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Safety note
// -----------------------------------------------------------------------------

class _SafetyNote extends StatelessWidget {
  const _SafetyNote();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.shield_outlined, size: 13, color: AppColors.textMuted),
        SizedBox(width: 5),
        Flexible(
          child: Text(
            'AI guidance is not a substitute for professional medical advice.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
