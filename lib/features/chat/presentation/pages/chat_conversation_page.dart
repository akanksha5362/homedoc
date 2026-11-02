import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_paths.dart';
import '../../data/models/chat_conversation_model.dart';
import '../../data/models/chat_message_model.dart';
import '../providers/chat_provider.dart';
import '../widgets/chat_attachment_sheet.dart';
import '../widgets/chat_bubble.dart';

const Color primaryTeal = Color(0xFF007A8A);
const Color lightTealSurface = Color(0xFFE6F7F6);
const Color textDark = Color(0xFF0F172A);
const Color textMuted = Color(0xFF64748B);

class ChatConversationPage extends ConsumerStatefulWidget {
  const ChatConversationPage({
    super.key,
    required this.conversation,
  });

  final ConversationModel conversation;

  @override
  ConsumerState<ChatConversationPage> createState() =>
      _ChatConversationPageState();
}

class _ChatConversationPageState extends ConsumerState<ChatConversationPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isComposing = false;

  @override
  void initState() {
    super.initState();
    // Mark conversation read on entry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatActionsProvider).markAsRead(widget.conversation.id);
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _handleSend() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    setState(() => _isComposing = false);

    await ref.read(chatActionsProvider).sendTextMessage(
          conversationId: widget.conversation.id,
          text: text,
          relatedAppointmentId: widget.conversation.appointmentId,
        );

    _scrollToBottom();
  }

  void _openAttachmentSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return ChatAttachmentSheet(
          onAttachmentSelected: ({
            required String filePath,
            required String fileName,
            required MessageType type,
            int? sizeBytes,
            String? caption,
          }) async {
            await ref.read(chatActionsProvider).sendAttachmentMessage(
                  conversationId: widget.conversation.id,
                  localPath: filePath,
                  fileName: fileName,
                  type: type,
                  fileSizeBytes: sizeBytes,
                  caption: caption,
                );
            _scrollToBottom();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final conv = widget.conversation;
    final messagesAsync =
        ref.watch(conversationMessagesProvider(conv.id));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: textDark, size: 20),
          onPressed: () => context.pop(),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: lightTealSurface,
                  backgroundImage: conv.doctorPhotoUrl != null
                      ? NetworkImage(conv.doctorPhotoUrl!)
                      : null,
                  child: conv.doctorPhotoUrl == null
                      ? const Icon(Icons.person_rounded,
                          color: primaryTeal, size: 22)
                      : null,
                ),
                if (conv.isDoctorOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conv.doctorName,
                    style: const TextStyle(
                      color: textDark,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    conv.doctorSpecialty,
                    style: const TextStyle(
                      color: primaryTeal,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Video Consultation',
            icon: const Icon(Icons.videocam_rounded, color: primaryTeal),
            onPressed: () {
              context.push(
                RoutePaths.patientVideoConsultation,
                extra: {
                  'doctorId': conv.doctorId,
                  'doctorName': conv.doctorName,
                  'specialty': conv.doctorSpecialty,
                  'id': conv.appointmentId ?? 'conv_telehealth_${conv.id}',
                },
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Safety & Emergency Guidance Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              color: const Color(0xFFFEF3C7),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Color(0xFFD97706), size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Non-emergency chat only. In case of acute medical emergencies, dial 112 / 911 immediately.',
                      style: TextStyle(
                        color: Color(0xFF92400E),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Linked Appointment Chip Banner (if associated with an appointment)
            if (conv.appointmentId != null) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                color: const Color(0xFFF1F5F9),
                child: Row(
                  children: [
                    const Icon(Icons.event_available_rounded,
                        color: primaryTeal, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Linked to Appointment ${conv.appointmentId}',
                        style: const TextStyle(
                          color: textDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => context.go(RoutePaths.patientAppointments),
                      child: const Text(
                        'View visit',
                        style: TextStyle(
                          color: primaryTeal,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Message Stream Area
            Expanded(
              child: messagesAsync.when(
                data: (messages) {
                  if (messages.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                color: lightTealSurface,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.chat_bubble_outline_rounded,
                                color: primaryTeal,
                                size: 36,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Start Consultation with ${conv.doctorName}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: textDark,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'You can ask questions, describe symptoms, or attach medical reports and prescriptions.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: textMuted, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToBottom();
                  });

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isMe = !msg.isDoctorSender;
                      return ChatBubble(message: msg, isMe: isMe);
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: primaryTeal),
                ),
                error: (err, stack) => Center(
                  child: Text(
                    'Error loading messages: $err',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ),

            // Bottom Input Bar
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Attach report or image',
                    onPressed: _openAttachmentSheet,
                    icon: const Icon(
                      Icons.add_circle_outline_rounded,
                      color: primaryTeal,
                      size: 26,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: TextField(
                        controller: _textController,
                        textCapitalization: TextCapitalization.sentences,
                        minLines: 1,
                        maxLines: 4,
                        onChanged: (text) {
                          setState(() {
                            _isComposing = text.trim().isNotEmpty;
                          });
                        },
                        decoration: const InputDecoration(
                          hintText: 'Type a message to your doctor...',
                          hintStyle: TextStyle(
                            color: textMuted,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          contentPadding:
                              EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor:
                          _isComposing ? primaryTeal : const Color(0xFFCBD5E1),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _isComposing ? _handleSend : null,
                    icon: const Icon(Icons.arrow_upward_rounded, size: 20),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
