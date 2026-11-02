import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum MessageType {
  text,
  image,
  pdf,
  prescription,
  appointmentNotice,
}

enum MessageDeliveryStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}

class ChatMessageModel extends Equatable {
  const ChatMessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.content,
    this.type = MessageType.text,
    this.attachmentUrl,
    this.attachmentFileName,
    this.attachmentSizeBytes,
    this.status = MessageDeliveryStatus.sent,
    required this.sentAt,
    this.readAt,
    this.relatedAppointmentId,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String senderRole; // 'patient' or 'doctor'
  final String content;
  final MessageType type;
  final String? attachmentUrl;
  final String? attachmentFileName;
  final int? attachmentSizeBytes;
  final MessageDeliveryStatus status;
  final DateTime sentAt;
  final DateTime? readAt;
  final String? relatedAppointmentId;

  bool get isDoctorSender => senderRole.toLowerCase() == 'doctor';
  bool get hasAttachment => attachmentUrl != null && attachmentUrl!.isNotEmpty;

  String get formattedFileSize {
    if (attachmentSizeBytes == null || attachmentSizeBytes == 0) return '';
    final kb = attachmentSizeBytes! / 1024;
    if (kb < 1000) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB';
  }

  factory ChatMessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ChatMessageModel.fromMap(data, doc.id);
  }

  factory ChatMessageModel.fromMap(Map<String, dynamic> data, [String? docId]) {
    final rawSentAt = data['sentAt'];
    DateTime sentAtTime;
    if (rawSentAt is Timestamp) {
      sentAtTime = rawSentAt.toDate();
    } else if (rawSentAt is String) {
      sentAtTime = DateTime.tryParse(rawSentAt) ?? DateTime.now();
    } else {
      sentAtTime = DateTime.now();
    }

    final rawReadAt = data['readAt'];
    DateTime? readAtTime;
    if (rawReadAt is Timestamp) {
      readAtTime = rawReadAt.toDate();
    } else if (rawReadAt is String) {
      readAtTime = DateTime.tryParse(rawReadAt);
    }

    MessageType type = MessageType.text;
    final typeStr = data['type']?.toString().toLowerCase();
    if (typeStr == 'image') type = MessageType.image;
    if (typeStr == 'pdf') type = MessageType.pdf;
    if (typeStr == 'prescription') type = MessageType.prescription;
    if (typeStr == 'appointmentnotice' || typeStr == 'appointment') {
      type = MessageType.appointmentNotice;
    }

    MessageDeliveryStatus status = MessageDeliveryStatus.sent;
    final statusStr = data['status']?.toString().toLowerCase();
    if (statusStr == 'sending') status = MessageDeliveryStatus.sending;
    if (statusStr == 'delivered') status = MessageDeliveryStatus.delivered;
    if (statusStr == 'read') status = MessageDeliveryStatus.read;
    if (statusStr == 'failed') status = MessageDeliveryStatus.failed;

    return ChatMessageModel(
      id: docId ?? (data['id'] ?? '').toString(),
      conversationId: (data['conversationId'] ?? '').toString(),
      senderId: (data['senderId'] ?? '').toString(),
      senderName: (data['senderName'] ?? '').toString(),
      senderRole: (data['senderRole'] ?? 'patient').toString(),
      content: (data['content'] ?? '').toString(),
      type: type,
      attachmentUrl: data['attachmentUrl'] as String?,
      attachmentFileName: data['attachmentFileName'] as String?,
      attachmentSizeBytes: data['attachmentSizeBytes'] as int?,
      status: status,
      sentAt: sentAtTime,
      readAt: readAtTime,
      relatedAppointmentId: data['relatedAppointmentId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'content': content,
      'type': type.name,
      'attachmentUrl': attachmentUrl,
      'attachmentFileName': attachmentFileName,
      'attachmentSizeBytes': attachmentSizeBytes,
      'status': status.name,
      'sentAt': Timestamp.fromDate(sentAt),
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      'relatedAppointmentId': relatedAppointmentId,
    };
  }

  ChatMessageModel copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? senderName,
    String? senderRole,
    String? content,
    MessageType? type,
    String? attachmentUrl,
    String? attachmentFileName,
    int? attachmentSizeBytes,
    MessageDeliveryStatus? status,
    DateTime? sentAt,
    DateTime? readAt,
    String? relatedAppointmentId,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderRole: senderRole ?? this.senderRole,
      content: content ?? this.content,
      type: type ?? this.type,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      attachmentFileName: attachmentFileName ?? this.attachmentFileName,
      attachmentSizeBytes: attachmentSizeBytes ?? this.attachmentSizeBytes,
      status: status ?? this.status,
      sentAt: sentAt ?? this.sentAt,
      readAt: readAt ?? this.readAt,
      relatedAppointmentId: relatedAppointmentId ?? this.relatedAppointmentId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        conversationId,
        senderId,
        senderName,
        senderRole,
        content,
        type,
        attachmentUrl,
        attachmentFileName,
        attachmentSizeBytes,
        status,
        sentAt,
        readAt,
        relatedAppointmentId,
      ];
}
