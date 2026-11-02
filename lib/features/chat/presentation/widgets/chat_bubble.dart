import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router/route_paths.dart';
import '../../data/models/chat_message_model.dart';

const Color primaryTeal = Color(0xFF007A8A);
const Color lightTealSurface = Color(0xFFE6F7F6);
const Color textDark = Color(0xFF0F172A);
const Color textMuted = Color(0xFF64748B);

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  final ChatMessageModel message;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('hh:mm a').format(message.sentAt);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 14),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            const CircleAvatar(
              radius: 14,
              backgroundColor: lightTealSurface,
              child: Icon(Icons.person_rounded, color: primaryTeal, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.76,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? primaryTeal : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                border: isMe ? null : Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  // Sender name tag if incoming doctor message
                  if (!isMe && message.isDoctorSender) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          message.senderName,
                          style: const TextStyle(
                            color: primaryTeal,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.verified_rounded, color: primaryTeal, size: 12),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],

                  // Attachment Content Renderers
                  if (message.type == MessageType.prescription)
                    _buildPrescriptionCard(context)
                  else if (message.type == MessageType.pdf)
                    _buildPdfCard(context)
                  else if (message.type == MessageType.image)
                    _buildImageCard(context)
                  else if (message.type == MessageType.appointmentNotice)
                    _buildAppointmentNotice(context),

                  // Text Content
                  if (message.content.isNotEmpty &&
                      message.type != MessageType.prescription) ...[
                    Text(
                      message.content,
                      style: TextStyle(
                        color: isMe ? Colors.white : textDark,
                        fontSize: 14.5,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],

                  // Timestamp & Delivery status ticks
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        timeStr,
                        style: TextStyle(
                          color: isMe ? Colors.white70 : textMuted,
                          fontSize: 10.5,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        _buildStatusTick(message.status),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMe ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMe ? Colors.white30 : const Color(0xFFBBF7D0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isMe ? Colors.white24 : const Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.receipt_long_rounded,
                  color: isMe ? Colors.white : const Color(0xFF16A34A),
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Digital Prescription',
                  style: TextStyle(
                    color: isMe ? Colors.white : const Color(0xFF14532D),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            message.content,
            style: TextStyle(
              color: isMe ? Colors.white : const Color(0xFF166534),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => context.go(RoutePaths.patientHealth),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isMe ? Colors.white : const Color(0xFF16A34A),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.folder_shared_outlined,
                    color: isMe ? primaryTeal : Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Open in Health Records',
                    style: TextStyle(
                      color: isMe ? primaryTeal : Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isMe ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isMe ? Colors.white24 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isMe ? Colors.white24 : const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.picture_as_pdf_rounded,
              color: isMe ? Colors.white : Colors.red.shade700,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.attachmentFileName ?? 'Medical_Document.pdf',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isMe ? Colors.white : textDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
                if (message.attachmentSizeBytes != null)
                  Text(
                    message.formattedFileSize,
                    style: TextStyle(
                      color: isMe ? Colors.white70 : textMuted,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      constraints: const BoxConstraints(maxHeight: 180),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.black12,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(Icons.image_outlined, color: textMuted, size: 40),
          Positioned(
            bottom: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.zoom_in_rounded, color: Colors.white, size: 12),
                  SizedBox(width: 3),
                  Text(
                    'Preview',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentNotice(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isMe ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isMe ? Colors.white24 : const Color(0xFFBFDBFE),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.event_note_rounded,
            color: isMe ? Colors.white : const Color(0xFF2563EB),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Appointment Note',
              style: TextStyle(
                color: isMe ? Colors.white : const Color(0xFF1E40AF),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTick(MessageDeliveryStatus status) {
    switch (status) {
      case MessageDeliveryStatus.sending:
        return const SizedBox(
          width: 10,
          height: 10,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
          ),
        );
      case MessageDeliveryStatus.sent:
        return const Icon(Icons.check_rounded, color: Colors.white70, size: 12);
      case MessageDeliveryStatus.delivered:
        return const Icon(Icons.done_all_rounded, color: Colors.white70, size: 12);
      case MessageDeliveryStatus.read:
        return const Icon(Icons.done_all_rounded, color: Colors.cyanAccent, size: 12);
      case MessageDeliveryStatus.failed:
        return const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 12);
    }
  }
}
