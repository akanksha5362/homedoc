import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/user_model.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../data/models/chat_conversation_model.dart';
import '../../data/models/chat_message_model.dart';
import '../../data/repositories/chat_repository.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return FirestoreChatRepository();
});

/// Streams all conversations for the currently authenticated user
final userConversationsProvider = StreamProvider<List<ConversationModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.user;
  final userId = user?.id.isNotEmpty == true ? user!.id : 'patient_me';
  final role = user?.role == UserRole.doctor ? 'doctor' : 'patient';

  final repository = ref.watch(chatRepositoryProvider);
  return repository.watchConversations(userId: userId, role: role);
});

/// Streams messages for a given conversation ID
final conversationMessagesProvider =
    StreamProvider.family<List<ChatMessageModel>, String>((ref, conversationId) {
  final repository = ref.watch(chatRepositoryProvider);
  return repository.watchMessages(conversationId: conversationId);
});

/// Actions provider for chat operations
final chatActionsProvider = Provider<ChatActions>((ref) {
  return ChatActions(ref);
});

class ChatActions {
  ChatActions(this._ref);

  final Ref _ref;

  ChatRepository get _repository => _ref.read(chatRepositoryProvider);

  String get _currentUserId {
    final user = _ref.read(authStateProvider).user;
    return user?.id.isNotEmpty == true ? user!.id : 'patient_me';
  }

  String get _currentUserName {
    final user = _ref.read(authStateProvider).user;
    return user?.displayName?.isNotEmpty == true ? user!.displayName! : 'Alex';
  }

  String get _currentUserRole {
    final user = _ref.read(authStateProvider).user;
    return user?.role == UserRole.doctor ? 'doctor' : 'patient';
  }

  Future<void> sendTextMessage({
    required String conversationId,
    required String text,
    String? relatedAppointmentId,
  }) async {
    if (text.trim().isEmpty) return;

    final message = ChatMessageModel(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: conversationId,
      senderId: _currentUserId,
      senderName: _currentUserName,
      senderRole: _currentUserRole,
      content: text.trim(),
      type: MessageType.text,
      status: MessageDeliveryStatus.sent,
      sentAt: DateTime.now(),
      relatedAppointmentId: relatedAppointmentId,
    );

    await _repository.sendMessage(
      conversationId: conversationId,
      message: message,
    );
  }

  Future<void> sendAttachmentMessage({
    required String conversationId,
    required String localPath,
    required String fileName,
    required MessageType type,
    int? fileSizeBytes,
    String? caption,
  }) async {
    final attachmentUrl = await _repository.uploadAttachment(
      conversationId: conversationId,
      localPath: localPath,
      fileName: fileName,
    );

    final message = ChatMessageModel(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: conversationId,
      senderId: _currentUserId,
      senderName: _currentUserName,
      senderRole: _currentUserRole,
      content: caption?.trim().isNotEmpty == true
          ? caption!.trim()
          : (type == MessageType.prescription
              ? 'Shared digital prescription document'
              : 'Shared medical report document'),
      type: type,
      attachmentUrl: attachmentUrl,
      attachmentFileName: fileName,
      attachmentSizeBytes: fileSizeBytes,
      status: MessageDeliveryStatus.sent,
      sentAt: DateTime.now(),
    );

    await _repository.sendMessage(
      conversationId: conversationId,
      message: message,
    );
  }

  Future<void> markAsRead(String conversationId) async {
    await _repository.markAsRead(
      conversationId: conversationId,
      userId: _currentUserId,
      role: _currentUserRole,
    );
  }

  Future<ConversationModel> openOrCreateConversation({
    required String doctorId,
    required String doctorName,
    required String doctorSpecialty,
    String? doctorPhotoUrl,
    String? appointmentId,
    String? appointmentStatus,
  }) async {
    return _repository.getOrCreateConversation(
      patientId: _currentUserId,
      patientName: _currentUserName,
      doctorId: doctorId,
      doctorName: doctorName,
      doctorSpecialty: doctorSpecialty,
      doctorPhotoUrl: doctorPhotoUrl,
      appointmentId: appointmentId,
      appointmentStatus: appointmentStatus,
    );
  }
}
