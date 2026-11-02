import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

class ConversationModel extends Equatable {
  const ConversationModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    this.patientPhotoUrl,
    required this.doctorId,
    required this.doctorName,
    required this.doctorSpecialty,
    this.doctorPhotoUrl,
    this.isDoctorOnline = false,
    required this.participantIds,
    this.appointmentId,
    this.appointmentStatus,
    required this.lastMessage,
    required this.lastMessageAt,
    this.lastSenderId = '',
    this.unreadCountPatient = 0,
    this.unreadCountDoctor = 0,
    required this.createdAt,
  });

  final String id;
  final String patientId;
  final String patientName;
  final String? patientPhotoUrl;
  final String doctorId;
  final String doctorName;
  final String doctorSpecialty;
  final String? doctorPhotoUrl;
  final bool isDoctorOnline;
  final List<String> participantIds;
  final String? appointmentId;
  final String? appointmentStatus;
  final String lastMessage;
  final DateTime lastMessageAt;
  final String lastSenderId;
  final int unreadCountPatient;
  final int unreadCountDoctor;
  final DateTime createdAt;

  int unreadCountForRole(String role) {
    if (role.toLowerCase() == 'doctor') {
      return unreadCountDoctor;
    }
    return unreadCountPatient;
  }

  String formattedLastTime() {
    final now = DateTime.now();
    final diff = now.difference(lastMessageAt);

    if (diff.inDays == 0) {
      return DateFormat('hh:mm a').format(lastMessageAt);
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return DateFormat('EEE').format(lastMessageAt);
    }
    return DateFormat('MMM d').format(lastMessageAt);
  }

  factory ConversationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ConversationModel.fromMap(data, doc.id);
  }

  factory ConversationModel.fromMap(Map<String, dynamic> data, [String? docId]) {
    final rawLastAt = data['lastMessageAt'];
    DateTime lastMessageAtTime;
    if (rawLastAt is Timestamp) {
      lastMessageAtTime = rawLastAt.toDate();
    } else if (rawLastAt is String) {
      lastMessageAtTime = DateTime.tryParse(rawLastAt) ?? DateTime.now();
    } else {
      lastMessageAtTime = DateTime.now();
    }

    final rawCreatedAt = data['createdAt'];
    DateTime createdAtTime;
    if (rawCreatedAt is Timestamp) {
      createdAtTime = rawCreatedAt.toDate();
    } else if (rawCreatedAt is String) {
      createdAtTime = DateTime.tryParse(rawCreatedAt) ?? DateTime.now();
    } else {
      createdAtTime = DateTime.now();
    }

    final participants = (data['participantIds'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [
          (data['patientId'] ?? '').toString(),
          (data['doctorId'] ?? '').toString(),
        ];

    return ConversationModel(
      id: docId ?? (data['id'] ?? '').toString(),
      patientId: (data['patientId'] ?? '').toString(),
      patientName: (data['patientName'] ?? 'Patient').toString(),
      patientPhotoUrl: data['patientPhotoUrl'] as String?,
      doctorId: (data['doctorId'] ?? '').toString(),
      doctorName: (data['doctorName'] ?? 'Doctor').toString(),
      doctorSpecialty: (data['doctorSpecialty'] ?? 'General Medicine').toString(),
      doctorPhotoUrl: data['doctorPhotoUrl'] as String?,
      isDoctorOnline: data['isDoctorOnline'] as bool? ?? false,
      participantIds: participants,
      appointmentId: data['appointmentId'] as String?,
      appointmentStatus: data['appointmentStatus'] as String?,
      lastMessage: (data['lastMessage'] ?? 'Conversation started').toString(),
      lastMessageAt: lastMessageAtTime,
      lastSenderId: (data['lastSenderId'] ?? '').toString(),
      unreadCountPatient: (data['unreadCountPatient'] as num?)?.toInt() ?? 0,
      unreadCountDoctor: (data['unreadCountDoctor'] as num?)?.toInt() ?? 0,
      createdAt: createdAtTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'patientName': patientName,
      'patientPhotoUrl': patientPhotoUrl,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'doctorSpecialty': doctorSpecialty,
      'doctorPhotoUrl': doctorPhotoUrl,
      'isDoctorOnline': isDoctorOnline,
      'participantIds': participantIds,
      'appointmentId': appointmentId,
      'appointmentStatus': appointmentStatus,
      'lastMessage': lastMessage,
      'lastMessageAt': Timestamp.fromDate(lastMessageAt),
      'lastSenderId': lastSenderId,
      'unreadCountPatient': unreadCountPatient,
      'unreadCountDoctor': unreadCountDoctor,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  ConversationModel copyWith({
    String? id,
    String? patientId,
    String? patientName,
    String? patientPhotoUrl,
    String? doctorId,
    String? doctorName,
    String? doctorSpecialty,
    String? doctorPhotoUrl,
    bool? isDoctorOnline,
    List<String>? participantIds,
    String? appointmentId,
    String? appointmentStatus,
    String? lastMessage,
    DateTime? lastMessageAt,
    String? lastSenderId,
    int? unreadCountPatient,
    int? unreadCountDoctor,
    DateTime? createdAt,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      patientPhotoUrl: patientPhotoUrl ?? this.patientPhotoUrl,
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      doctorSpecialty: doctorSpecialty ?? this.doctorSpecialty,
      doctorPhotoUrl: doctorPhotoUrl ?? this.doctorPhotoUrl,
      isDoctorOnline: isDoctorOnline ?? this.isDoctorOnline,
      participantIds: participantIds ?? this.participantIds,
      appointmentId: appointmentId ?? this.appointmentId,
      appointmentStatus: appointmentStatus ?? this.appointmentStatus,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastSenderId: lastSenderId ?? this.lastSenderId,
      unreadCountPatient: unreadCountPatient ?? this.unreadCountPatient,
      unreadCountDoctor: unreadCountDoctor ?? this.unreadCountDoctor,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        patientId,
        patientName,
        patientPhotoUrl,
        doctorId,
        doctorName,
        doctorSpecialty,
        doctorPhotoUrl,
        isDoctorOnline,
        participantIds,
        appointmentId,
        appointmentStatus,
        lastMessage,
        lastMessageAt,
        lastSenderId,
        unreadCountPatient,
        unreadCountDoctor,
        createdAt,
      ];
}
