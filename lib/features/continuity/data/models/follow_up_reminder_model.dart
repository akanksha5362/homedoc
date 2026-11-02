import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

enum FollowUpStatus {
  pending,
  notified,
  completed,
  dismissed,
}

enum RecurringInterval {
  none,
  weekly,
  monthly,
  quarterly,
}

class FollowUpReminderModel extends Equatable {
  const FollowUpReminderModel({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.doctorName,
    required this.doctorSpecialty,
    this.doctorPhotoUrl,
    required this.relatedAppointmentId,
    required this.targetDate,
    required this.reminderDateTime,
    this.isDoctorRecommended = false,
    this.reason = '',
    this.status = FollowUpStatus.pending,
    this.recurringInterval = RecurringInterval.none,
    required this.createdAt,
  });

  final String id;
  final String patientId;
  final String doctorId;
  final String doctorName;
  final String doctorSpecialty;
  final String? doctorPhotoUrl;
  final String relatedAppointmentId;
  final DateTime targetDate;
  final DateTime reminderDateTime;
  final bool isDoctorRecommended;
  final String reason;
  final FollowUpStatus status;
  final RecurringInterval recurringInterval;
  final DateTime createdAt;

  String get formattedTargetDate =>
      DateFormat('EEEE, d MMM yyyy').format(targetDate);

  String get formattedReminderTime =>
      DateFormat('d MMM, hh:mm a').format(reminderDateTime);

  bool get isDueSoon {
    final diff = targetDate.difference(DateTime.now()).inDays;
    return diff >= 0 && diff <= 3;
  }

  factory FollowUpReminderModel.fromMap(Map<String, dynamic> data, [String? id]) {
    final rawTarget = data['targetDate'];
    DateTime targetTime;
    if (rawTarget is Timestamp) {
      targetTime = rawTarget.toDate();
    } else if (rawTarget is String) {
      targetTime = DateTime.tryParse(rawTarget) ?? DateTime.now();
    } else {
      targetTime = DateTime.now();
    }

    final rawReminder = data['reminderDateTime'];
    DateTime reminderTime;
    if (rawReminder is Timestamp) {
      reminderTime = rawReminder.toDate();
    } else if (rawReminder is String) {
      reminderTime = DateTime.tryParse(rawReminder) ?? DateTime.now();
    } else {
      reminderTime = DateTime.now();
    }

    final rawCreated = data['createdAt'];
    DateTime createdTime;
    if (rawCreated is Timestamp) {
      createdTime = rawCreated.toDate();
    } else if (rawCreated is String) {
      createdTime = DateTime.tryParse(rawCreated) ?? DateTime.now();
    } else {
      createdTime = DateTime.now();
    }

    FollowUpStatus status = FollowUpStatus.pending;
    final statusStr = data['status']?.toString().toLowerCase();
    if (statusStr == 'notified') status = FollowUpStatus.notified;
    if (statusStr == 'completed') status = FollowUpStatus.completed;
    if (statusStr == 'dismissed') status = FollowUpStatus.dismissed;

    RecurringInterval interval = RecurringInterval.none;
    final intervalStr = data['recurringInterval']?.toString().toLowerCase();
    if (intervalStr == 'weekly') interval = RecurringInterval.weekly;
    if (intervalStr == 'monthly') interval = RecurringInterval.monthly;
    if (intervalStr == 'quarterly') interval = RecurringInterval.quarterly;

    return FollowUpReminderModel(
      id: id ?? (data['id'] ?? '').toString(),
      patientId: (data['patientId'] ?? '').toString(),
      doctorId: (data['doctorId'] ?? '').toString(),
      doctorName: (data['doctorName'] ?? 'Doctor').toString(),
      doctorSpecialty: (data['doctorSpecialty'] ?? 'General Medicine').toString(),
      doctorPhotoUrl: data['doctorPhotoUrl'] as String?,
      relatedAppointmentId: (data['relatedAppointmentId'] ?? '').toString(),
      targetDate: targetTime,
      reminderDateTime: reminderTime,
      isDoctorRecommended: data['isDoctorRecommended'] as bool? ?? false,
      reason: (data['reason'] ?? '').toString(),
      status: status,
      recurringInterval: interval,
      createdAt: createdTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'doctorSpecialty': doctorSpecialty,
      'doctorPhotoUrl': doctorPhotoUrl,
      'relatedAppointmentId': relatedAppointmentId,
      'targetDate': Timestamp.fromDate(targetDate),
      'reminderDateTime': Timestamp.fromDate(reminderDateTime),
      'isDoctorRecommended': isDoctorRecommended,
      'reason': reason,
      'status': status.name,
      'recurringInterval': recurringInterval.name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  FollowUpReminderModel copyWith({
    String? id,
    String? patientId,
    String? doctorId,
    String? doctorName,
    String? doctorSpecialty,
    String? doctorPhotoUrl,
    String? relatedAppointmentId,
    DateTime? targetDate,
    DateTime? reminderDateTime,
    bool? isDoctorRecommended,
    String? reason,
    FollowUpStatus? status,
    RecurringInterval? recurringInterval,
    DateTime? createdAt,
  }) {
    return FollowUpReminderModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      doctorSpecialty: doctorSpecialty ?? this.doctorSpecialty,
      doctorPhotoUrl: doctorPhotoUrl ?? this.doctorPhotoUrl,
      relatedAppointmentId: relatedAppointmentId ?? this.relatedAppointmentId,
      targetDate: targetDate ?? this.targetDate,
      reminderDateTime: reminderDateTime ?? this.reminderDateTime,
      isDoctorRecommended: isDoctorRecommended ?? this.isDoctorRecommended,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      recurringInterval: recurringInterval ?? this.recurringInterval,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        patientId,
        doctorId,
        doctorName,
        doctorSpecialty,
        doctorPhotoUrl,
        relatedAppointmentId,
        targetDate,
        reminderDateTime,
        isDoctorRecommended,
        reason,
        status,
        recurringInterval,
        createdAt,
      ];
}
