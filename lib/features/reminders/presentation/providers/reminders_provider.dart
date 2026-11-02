import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/services/notification_service.dart';
import '../../data/models/medication_reminder_model.dart';

/// Live stream of medication reminders for the current patient.
final patientRemindersProvider =
    StreamProvider<List<MedicationReminderModel>>((ref) {
  final auth = ref.watch(authStateProvider);
  final patientId = auth.user?.id;

  if (patientId == null || patientId.isEmpty) {
    return Stream.value([]);
  }

  final firestore = ref.watch(firestoreProvider);

  return firestore
      .collection('users')
      .doc(patientId)
      .collection('medication_reminders')
      .snapshots()
      .map((snapshot) {
    final list = snapshot.docs
        .map(MedicationReminderModel.fromFirestore)
        .toList();
    list.sort((a, b) {
      if (a.hour != b.hour) return a.hour.compareTo(b.hour);
      return a.minute.compareTo(b.minute);
    });
    return list;
  });
});

class RemindersActions {
  RemindersActions(this._ref);

  final Ref _ref;

  Future<void> addReminder({
    required String medicineName,
    required String dosage,
    required int hour,
    required int minute,
    String doctorOrSource = 'Prescription',
    String instructions = '',
  }) async {
    final auth = _ref.read(authStateProvider);
    final patientId = auth.user?.id;

    if (patientId == null || patientId.isEmpty) {
      throw Exception('Patient not authenticated.');
    }

    // Request permissions upfront
    await NotificationService.instance.requestPermissions();

    final notificationId = DateTime.now().millisecondsSinceEpoch % 10000000;

    // Schedule local notification alarm
    await NotificationService.instance.scheduleMedicationAlarm(
      id: notificationId,
      medicineName: medicineName,
      dosage: dosage,
      hour: hour,
      minute: minute,
      instructions: instructions,
    );

    final firestore = _ref.read(firestoreProvider);
    await firestore
        .collection('users')
        .doc(patientId)
        .collection('medication_reminders')
        .add({
      'notificationId': notificationId,
      'medicineName': medicineName.trim(),
      'dosage': dosage.trim(),
      'doctorOrSource': doctorOrSource.trim(),
      'instructions': instructions.trim(),
      'hour': hour,
      'minute': minute,
      'isEnabled': true,
      'dosesHistory': [],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> toggleReminder(
      MedicationReminderModel reminder, bool enabled) async {
    final auth = _ref.read(authStateProvider);
    final patientId = auth.user?.id;
    if (patientId == null || patientId.isEmpty) return;

    if (enabled) {
      await NotificationService.instance.scheduleMedicationAlarm(
        id: reminder.notificationId,
        medicineName: reminder.medicineName,
        dosage: reminder.dosage,
        hour: reminder.hour,
        minute: reminder.minute,
        instructions: reminder.instructions,
      );
    } else {
      await NotificationService.instance.cancelAlarm(reminder.notificationId);
    }

    final firestore = _ref.read(firestoreProvider);
    await firestore
        .collection('users')
        .doc(patientId)
        .collection('medication_reminders')
        .doc(reminder.id)
        .update({'isEnabled': enabled});
  }

  Future<void> logDose(
      MedicationReminderModel reminder, DoseStatus status) async {
    final auth = _ref.read(authStateProvider);
    final patientId = auth.user?.id;
    if (patientId == null || patientId.isEmpty) return;

    final todayStr = DateTime.now().toIso8601String().substring(0, 10);

    // Filter out existing log for today if any, and append new one
    final updatedHistory = reminder.dosesHistory
        .where((l) => l.dateString != todayStr)
        .toList()
      ..add(
        MedicationDoseLog(
          dateString: todayStr,
          status: status,
          loggedAt: DateTime.now(),
        ),
      );

    final firestore = _ref.read(firestoreProvider);
    await firestore
        .collection('users')
        .doc(patientId)
        .collection('medication_reminders')
        .doc(reminder.id)
        .update({
      'dosesHistory': updatedHistory.map((h) => h.toMap()).toList(),
    });
  }

  Future<void> deleteReminder(MedicationReminderModel reminder) async {
    final auth = _ref.read(authStateProvider);
    final patientId = auth.user?.id;
    if (patientId == null || patientId.isEmpty) return;

    await NotificationService.instance.cancelAlarm(reminder.notificationId);

    final firestore = _ref.read(firestoreProvider);
    await firestore
        .collection('users')
        .doc(patientId)
        .collection('medication_reminders')
        .doc(reminder.id)
        .delete();
  }
}

final remindersActionsProvider = Provider<RemindersActions>((ref) {
  return RemindersActions(ref);
});
