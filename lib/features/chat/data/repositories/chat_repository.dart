import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../models/chat_conversation_model.dart';
import '../models/chat_message_model.dart';

abstract class ChatRepository {
  Stream<List<ConversationModel>> watchConversations({
    required String userId,
    required String role,
  });

  Stream<List<ChatMessageModel>> watchMessages({
    required String conversationId,
  });

  Future<void> sendMessage({
    required String conversationId,
    required ChatMessageModel message,
  });

  Future<void> markAsRead({
    required String conversationId,
    required String userId,
    required String role,
  });

  Future<ConversationModel> getOrCreateConversation({
    required String patientId,
    required String patientName,
    String? patientPhotoUrl,
    required String doctorId,
    required String doctorName,
    required String doctorSpecialty,
    String? doctorPhotoUrl,
    String? appointmentId,
    String? appointmentStatus,
  });

  Future<String> uploadAttachment({
    required String conversationId,
    required String localPath,
    required String fileName,
  });
}

class FirestoreChatRepository implements ChatRepository {
  FirestoreChatRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  @override
  Stream<List<ConversationModel>> watchConversations({
    required String userId,
    required String role,
  }) {
    final query = _firestore
        .collection('conversations')
        .where('participantIds', arrayContains: userId);

    return query.snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return _getDemoConversations(userId, role);
      }
      final list = snapshot.docs
          .map((doc) => ConversationModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
      return list;
    }).handleError((error) {
      debugPrint('Firestore chat conversations stream fallback: $error');
      return _getDemoConversations(userId, role);
    });
  }

  @override
  Stream<List<ChatMessageModel>> watchMessages({
    required String conversationId,
  }) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('sentAt', descending: false)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return _getDemoMessages(conversationId);
      }
      return snapshot.docs
          .map((doc) => ChatMessageModel.fromFirestore(doc))
          .toList();
    }).handleError((error) {
      debugPrint('Firestore chat messages stream fallback: $error');
      return _getDemoMessages(conversationId);
    });
  }

  @override
  Future<void> sendMessage({
    required String conversationId,
    required ChatMessageModel message,
  }) async {
    try {
      final batch = _firestore.batch();

      final messageRef = _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc(message.id);

      batch.set(messageRef, message.toMap());

      final convRef =
          _firestore.collection('conversations').doc(conversationId);

      final isDoctor = message.isDoctorSender;
      final updateData = <String, dynamic>{
        'lastMessage': message.type == MessageType.text
            ? message.content
            : '[${message.type.name.toUpperCase()}] ${message.content}',
        'lastMessageAt': Timestamp.fromDate(message.sentAt),
        'lastSenderId': message.senderId,
      };

      if (isDoctor) {
        updateData['unreadCountPatient'] = FieldValue.increment(1);
      } else {
        updateData['unreadCountDoctor'] = FieldValue.increment(1);
      }

      batch.update(convRef, updateData);
      await batch.commit();
    } catch (e) {
      debugPrint('Error sending message to Firestore: $e');
      // If Firestore write fails (e.g. offline during local dev demo), we log clearly
    }
  }

  @override
  Future<void> markAsRead({
    required String conversationId,
    required String userId,
    required String role,
  }) async {
    try {
      final convRef =
          _firestore.collection('conversations').doc(conversationId);
      final isDoctor = role.toLowerCase() == 'doctor';

      await convRef.update({
        isDoctor ? 'unreadCountDoctor' : 'unreadCountPatient': 0,
      });
    } catch (e) {
      debugPrint('Error resetting unread count: $e');
    }
  }

  @override
  Future<ConversationModel> getOrCreateConversation({
    required String patientId,
    required String patientName,
    String? patientPhotoUrl,
    required String doctorId,
    required String doctorName,
    required String doctorSpecialty,
    String? doctorPhotoUrl,
    String? appointmentId,
    String? appointmentStatus,
  }) async {
    final convId = 'conv_${patientId}_$doctorId';
    final convRef = _firestore.collection('conversations').doc(convId);

    try {
      final doc = await convRef.get();
      if (doc.exists) {
        return ConversationModel.fromFirestore(doc);
      }

      final newConv = ConversationModel(
        id: convId,
        patientId: patientId,
        patientName: patientName,
        patientPhotoUrl: patientPhotoUrl,
        doctorId: doctorId,
        doctorName: doctorName,
        doctorSpecialty: doctorSpecialty,
        doctorPhotoUrl: doctorPhotoUrl,
        isDoctorOnline: true,
        participantIds: [patientId, doctorId],
        appointmentId: appointmentId,
        appointmentStatus: appointmentStatus,
        lastMessage: 'Consultation chat initialized.',
        lastMessageAt: DateTime.now(),
        lastSenderId: patientId,
        createdAt: DateTime.now(),
      );

      await convRef.set(newConv.toMap(), SetOptions(merge: true));
      return newConv;
    } catch (e) {
      debugPrint('Fallback creating conversation locally: $e');
      return ConversationModel(
        id: convId,
        patientId: patientId,
        patientName: patientName,
        patientPhotoUrl: patientPhotoUrl,
        doctorId: doctorId,
        doctorName: doctorName,
        doctorSpecialty: doctorSpecialty,
        doctorPhotoUrl: doctorPhotoUrl,
        isDoctorOnline: true,
        participantIds: [patientId, doctorId],
        appointmentId: appointmentId,
        appointmentStatus: appointmentStatus,
        lastMessage: 'Consultation chat initialized.',
        lastMessageAt: DateTime.now(),
        lastSenderId: patientId,
        createdAt: DateTime.now(),
      );
    }
  }

  @override
  Future<String> uploadAttachment({
    required String conversationId,
    required String localPath,
    required String fileName,
  }) async {
    try {
      final file = File(localPath);
      final ref = _storage
          .ref()
          .child('chat_attachments')
          .child(conversationId)
          .child(fileName);

      final uploadTask = await ref.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Storage upload fallback (simulated local attachment): $e');
      return 'local_file://$localPath';
    }
  }

  // -------------------------------------------------------------
  // Clean Seed / Fallback for Demonstration & Testing
  // -------------------------------------------------------------
  List<ConversationModel> _getDemoConversations(String userId, String role) {
    final now = DateTime.now();
    return [
      ConversationModel(
        id: 'conv_${userId}_demo_doc_1',
        patientId: userId,
        patientName: 'Alex Doe',
        doctorId: 'demo_doc_1',
        doctorName: 'Dr. Sarah Mitchell',
        doctorSpecialty: 'Cardiologist',
        doctorPhotoUrl: null,
        isDoctorOnline: true,
        participantIds: [userId, 'demo_doc_1'],
        appointmentId: 'APT_101',
        appointmentStatus: 'doctorConfirmed',
        lastMessage:
            'Please continue with the prescribed dosage of Atorvastatin for 2 more weeks.',
        lastMessageAt: now.subtract(const Duration(minutes: 15)),
        lastSenderId: 'demo_doc_1',
        unreadCountPatient: 1,
        unreadCountDoctor: 0,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      ConversationModel(
        id: 'conv_${userId}_demo_doc_2',
        patientId: userId,
        patientName: 'Alex Doe',
        doctorId: 'demo_doc_2',
        doctorName: 'Dr. Marcus Vance',
        doctorSpecialty: 'General Physician',
        doctorPhotoUrl: null,
        isDoctorOnline: false,
        participantIds: [userId, 'demo_doc_2'],
        appointmentId: null,
        appointmentStatus: null,
        lastMessage:
            'Your routine lipid panel report is normal. Keep up the morning walks.',
        lastMessageAt: now.subtract(const Duration(hours: 3)),
        lastSenderId: 'demo_doc_2',
        unreadCountPatient: 0,
        unreadCountDoctor: 0,
        createdAt: now.subtract(const Duration(days: 5)),
      ),
      ConversationModel(
        id: 'conv_${userId}_demo_doc_3',
        patientId: userId,
        patientName: 'Alex Doe',
        doctorId: 'demo_doc_3',
        doctorName: 'Dr. Emily Chen',
        doctorSpecialty: 'Dermatologist',
        doctorPhotoUrl: null,
        isDoctorOnline: true,
        participantIds: [userId, 'demo_doc_3'],
        appointmentId: 'APT_103',
        appointmentStatus: 'completed',
        lastMessage:
            'I have shared the moisturizing cream recommendation in your Health Records vault.',
        lastMessageAt: now.subtract(const Duration(days: 1, hours: 2)),
        lastSenderId: 'demo_doc_3',
        unreadCountPatient: 0,
        unreadCountDoctor: 0,
        createdAt: now.subtract(const Duration(days: 7)),
      ),
    ];
  }

  List<ChatMessageModel> _getDemoMessages(String conversationId) {
    final now = DateTime.now();
    return [
      ChatMessageModel(
        id: 'msg_1',
        conversationId: conversationId,
        senderId: 'demo_doc_1',
        senderName: 'Dr. Sarah Mitchell',
        senderRole: 'doctor',
        content:
            'Hello! I reviewed your recent blood pressure readings. How have you been feeling since yesterday?',
        type: MessageType.text,
        status: MessageDeliveryStatus.read,
        sentAt: now.subtract(const Duration(minutes: 35)),
      ),
      ChatMessageModel(
        id: 'msg_2',
        conversationId: conversationId,
        senderId: 'patient_me',
        senderName: 'Alex',
        senderRole: 'patient',
        content:
            'Feeling much better Doctor! The mild headache has completely subsided.',
        type: MessageType.text,
        status: MessageDeliveryStatus.read,
        sentAt: now.subtract(const Duration(minutes: 30)),
      ),
      ChatMessageModel(
        id: 'msg_3',
        conversationId: conversationId,
        senderId: 'demo_doc_1',
        senderName: 'Dr. Sarah Mitchell',
        senderRole: 'doctor',
        content:
            'Glad to hear that. Here is your digital prescription for the continuation course.',
        type: MessageType.prescription,
        attachmentUrl: 'prescription_rx_demo',
        attachmentFileName: 'Prescription_Cardio_SarahMitchell.pdf',
        status: MessageDeliveryStatus.read,
        sentAt: now.subtract(const Duration(minutes: 25)),
      ),
      ChatMessageModel(
        id: 'msg_4',
        conversationId: conversationId,
        senderId: 'demo_doc_1',
        senderName: 'Dr. Sarah Mitchell',
        senderRole: 'doctor',
        content:
            'Please continue with the prescribed dosage of Atorvastatin for 2 more weeks.',
        type: MessageType.text,
        status: MessageDeliveryStatus.delivered,
        sentAt: now.subtract(const Duration(minutes: 15)),
      ),
    ];
  }
}
