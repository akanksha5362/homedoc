import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homedoc/features/chat/data/models/chat_conversation_model.dart';
import 'package:homedoc/features/chat/data/models/chat_message_model.dart';

void main() {
  group('ChatMessageModel', () {
    test('parses complete message map properly', () {
      final now = DateTime.now();
      final map = {
        'id': 'msg_001',
        'conversationId': 'conv_123',
        'senderId': 'doc_01',
        'senderName': 'Dr. Sarah Mitchell',
        'senderRole': 'doctor',
        'content': 'Please review the updated dosage.',
        'type': 'prescription',
        'attachmentUrl': 'https://storage.googleapis.com/rx.pdf',
        'attachmentFileName': 'rx_cardio.pdf',
        'attachmentSizeBytes': 204800, // 200 KB
        'status': 'read',
        'sentAt': Timestamp.fromDate(now),
        'readAt': Timestamp.fromDate(now),
        'relatedAppointmentId': 'APT_99',
      };

      final msg = ChatMessageModel.fromMap(map);

      expect(msg.id, 'msg_001');
      expect(msg.conversationId, 'conv_123');
      expect(msg.senderId, 'doc_01');
      expect(msg.senderName, 'Dr. Sarah Mitchell');
      expect(msg.isDoctorSender, true);
      expect(msg.type, MessageType.prescription);
      expect(msg.status, MessageDeliveryStatus.read);
      expect(msg.hasAttachment, true);
      expect(msg.attachmentFileName, 'rx_cardio.pdf');
      expect(msg.formattedFileSize, '200.0 KB');
      expect(msg.relatedAppointmentId, 'APT_99');
    });

    test('serializes to Map and back without losing fields', () {
      final now = DateTime.now();
      final original = ChatMessageModel(
        id: 'msg_test',
        conversationId: 'conv_test',
        senderId: 'pat_1',
        senderName: 'Alex',
        senderRole: 'patient',
        content: 'Is this report normal?',
        type: MessageType.pdf,
        attachmentUrl: 'https://example.com/report.pdf',
        attachmentFileName: 'blood_report.pdf',
        attachmentSizeBytes: 1048576, // 1 MB
        status: MessageDeliveryStatus.delivered,
        sentAt: now,
      );

      final map = original.toMap();
      final reconstituted = ChatMessageModel.fromMap(map);

      expect(reconstituted.id, original.id);
      expect(reconstituted.content, original.content);
      expect(reconstituted.type, MessageType.pdf);
      expect(reconstituted.formattedFileSize, '1.0 MB');
      expect(reconstituted.status, MessageDeliveryStatus.delivered);
      expect(reconstituted.isDoctorSender, false);
    });

    test('handles fallback defaults safely when fields are omitted', () {
      final map = <String, dynamic>{
        'id': 'empty_test',
      };

      final msg = ChatMessageModel.fromMap(map);

      expect(msg.id, 'empty_test');
      expect(msg.senderRole, 'patient');
      expect(msg.type, MessageType.text);
      expect(msg.status, MessageDeliveryStatus.sent);
      expect(msg.hasAttachment, false);
      expect(msg.formattedFileSize, '');
    });
  });

  group('ConversationModel', () {
    test('parses conversation map correctly', () {
      final now = DateTime.now();
      final map = {
        'id': 'conv_1',
        'patientId': 'pat_101',
        'patientName': 'Alex Doe',
        'doctorId': 'doc_202',
        'doctorName': 'Dr. Marcus Vance',
        'doctorSpecialty': 'General Physician',
        'isDoctorOnline': true,
        'participantIds': ['pat_101', 'doc_202'],
        'appointmentId': 'APT_404',
        'appointmentStatus': 'Confirmed',
        'lastMessage': 'See you at the clinic.',
        'lastMessageAt': Timestamp.fromDate(now),
        'lastSenderId': 'doc_202',
        'unreadCountPatient': 2,
        'unreadCountDoctor': 0,
        'createdAt': Timestamp.fromDate(now),
      };

      final conv = ConversationModel.fromMap(map);

      expect(conv.id, 'conv_1');
      expect(conv.patientName, 'Alex Doe');
      expect(conv.doctorName, 'Dr. Marcus Vance');
      expect(conv.isDoctorOnline, true);
      expect(conv.appointmentId, 'APT_404');
      expect(conv.unreadCountForRole('patient'), 2);
      expect(conv.unreadCountForRole('doctor'), 0);
    });

    test('formats last message time accurately', () {
      final now = DateTime.now();
      final convToday = ConversationModel(
        id: 'c1',
        patientId: 'p1',
        patientName: 'P',
        doctorId: 'd1',
        doctorName: 'D',
        doctorSpecialty: 'S',
        participantIds: const ['p1', 'd1'],
        lastMessage: 'Hi',
        lastMessageAt: now.subtract(const Duration(minutes: 5)),
        createdAt: now,
      );

      // Should be time format hh:mm
      expect(convToday.formattedLastTime(), isNotEmpty);
      expect(convToday.formattedLastTime().contains(':'), true);

      final convYesterday = convToday.copyWith(
        lastMessageAt: now.subtract(const Duration(days: 1, hours: 2)),
      );
      expect(convYesterday.formattedLastTime(), 'Yesterday');
    });

    test('copyWith produces clean immutable updates', () {
      final now = DateTime.now();
      final conv = ConversationModel(
        id: 'c1',
        patientId: 'p1',
        patientName: 'Patient One',
        doctorId: 'd1',
        doctorName: 'Dr. One',
        doctorSpecialty: 'Specialty One',
        participantIds: const ['p1', 'd1'],
        lastMessage: 'Old message',
        lastMessageAt: now,
        unreadCountPatient: 3,
        createdAt: now,
      );

      final readConv = conv.copyWith(
        unreadCountPatient: 0,
        lastMessage: 'New message',
      );

      expect(readConv.unreadCountPatient, 0);
      expect(readConv.lastMessage, 'New message');
      expect(readConv.doctorName, 'Dr. One'); // preserved
    });
  });
}
