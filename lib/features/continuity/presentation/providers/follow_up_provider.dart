import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/services/notification_service.dart';
import '../../data/models/follow_up_reminder_model.dart';

final followUpRemindersProvider =
    StateNotifierProvider<FollowUpNotifier, List<FollowUpReminderModel>>((ref) {
  final auth = ref.watch(authStateProvider);
  final userId = auth.user?.id.isNotEmpty == true ? auth.user!.id : 'patient_me';
  return FollowUpNotifier(userId);
});

class FollowUpNotifier extends StateNotifier<List<FollowUpReminderModel>> {
  FollowUpNotifier(this.userId) : super([]) {
    _loadReminders();
  }

  final String userId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _loadReminders() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('follow_up_reminders')
          .orderBy('targetDate', descending: false)
          .get();

      if (snapshot.docs.isNotEmpty) {
        state = snapshot.docs
            .map((doc) => FollowUpReminderModel.fromMap(doc.data(), doc.id))
            .toList();
        return;
      }
    } catch (e) {
      debugPrint('Firestore follow-up load notice: $e');
    }

    // Default Seed Follow-ups for Demonstration
    final now = DateTime.now();
    state = [
      FollowUpReminderModel(
        id: 'fu_demo_1',
        patientId: userId,
        doctorId: 'demo_doc_1',
        doctorName: 'Dr. Sarah Mitchell',
        doctorSpecialty: 'Cardiologist',
        relatedAppointmentId: 'APT_101',
        targetDate: now.add(const Duration(days: 3)),
        reminderDateTime: now.add(const Duration(days: 2, hours: 9)),
        isDoctorRecommended: true,
        reason: 'Post-consultation blood pressure review and medication efficacy check.',
        status: FollowUpStatus.pending,
        createdAt: now.subtract(const Duration(days: 11)),
      ),
      FollowUpReminderModel(
        id: 'fu_demo_2',
        patientId: userId,
        doctorId: 'demo_doc_2',
        doctorName: 'Dr. Marcus Vance',
        doctorSpecialty: 'General Physician',
        relatedAppointmentId: 'APT_102',
        targetDate: now.add(const Duration(days: 14)),
        reminderDateTime: now.add(const Duration(days: 13, hours: 10)),
        isDoctorRecommended: false,
        reason: 'Routine quarterly check-up.',
        status: FollowUpStatus.pending,
        recurringInterval: RecurringInterval.quarterly,
        createdAt: now.subtract(const Duration(days: 75)),
      ),
    ];
  }

  Future<void> scheduleFollowUp({
    required String doctorId,
    required String doctorName,
    required String doctorSpecialty,
    String? doctorPhotoUrl,
    required String relatedAppointmentId,
    required DateTime targetDate,
    required DateTime reminderDateTime,
    required bool isDoctorRecommended,
    String reason = '',
    RecurringInterval recurringInterval = RecurringInterval.none,
  }) async {
    final id = 'fu_${DateTime.now().millisecondsSinceEpoch}';
    final newReminder = FollowUpReminderModel(
      id: id,
      patientId: userId,
      doctorId: doctorId,
      doctorName: doctorName,
      doctorSpecialty: doctorSpecialty,
      doctorPhotoUrl: doctorPhotoUrl,
      relatedAppointmentId: relatedAppointmentId,
      targetDate: targetDate,
      reminderDateTime: reminderDateTime,
      isDoctorRecommended: isDoctorRecommended,
      reason: reason,
      status: FollowUpStatus.pending,
      recurringInterval: recurringInterval,
      createdAt: DateTime.now(),
    );

    state = [...state, newReminder];

    // Persist to Firestore
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('follow_up_reminders')
          .doc(id)
          .set(newReminder.toMap());
    } catch (e) {
      debugPrint('Firestore follow-up save notice: $e');
    }

    // Schedule local notification
    try {
      final notifId = id.hashCode.abs() % 100000;
      await NotificationService.instance.scheduleFollowUpAlert(
        id: notifId,
        doctorName: doctorName,
        reason: reason.isNotEmpty
            ? reason
            : (isDoctorRecommended
                ? 'Doctor recommended follow-up visit'
                : 'Scheduled follow-up consultation'),
        scheduledDateTime: reminderDateTime,
      );
    } catch (e) {
      debugPrint('Notification schedule notice: $e');
    }
  }

  Future<void> dismissReminder(String id) async {
    state = state.map((item) {
      if (item.id == id) {
        return item.copyWith(status: FollowUpStatus.dismissed);
      }
      return item;
    }).toList();

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('follow_up_reminders')
          .doc(id)
          .update({'status': FollowUpStatus.dismissed.name});
    } catch (e) {
      debugPrint('Firestore update notice: $e');
    }
  }

  Future<void> completeReminder(String id) async {
    state = state.map((item) {
      if (item.id == id) {
        return item.copyWith(status: FollowUpStatus.completed);
      }
      return item;
    }).toList();

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('follow_up_reminders')
          .doc(id)
          .update({'status': FollowUpStatus.completed.name});
    } catch (e) {
      debugPrint('Firestore update notice: $e');
    }
  }
}
