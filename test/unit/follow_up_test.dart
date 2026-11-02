import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homedoc/features/continuity/data/models/follow_up_reminder_model.dart';

void main() {
  group('FollowUpReminderModel', () {
    test('parses doctor-recommended follow-up properly', () {
      final now = DateTime.now();
      final map = {
        'id': 'fu_101',
        'patientId': 'pat_1',
        'doctorId': 'doc_1',
        'doctorName': 'Dr. Sarah Mitchell',
        'doctorSpecialty': 'Cardiologist',
        'doctorPhotoUrl': 'https://example.com/dr_sarah.jpg',
        'relatedAppointmentId': 'APT_901',
        'targetDate': Timestamp.fromDate(now.add(const Duration(days: 14))),
        'reminderDateTime': Timestamp.fromDate(now.add(const Duration(days: 13))),
        'isDoctorRecommended': true,
        'reason': 'Blood pressure review after 14 days course.',
        'status': 'pending',
        'recurringInterval': 'monthly',
        'createdAt': Timestamp.fromDate(now),
      };

      final model = FollowUpReminderModel.fromMap(map);

      expect(model.id, 'fu_101');
      expect(model.doctorName, 'Dr. Sarah Mitchell');
      expect(model.isDoctorRecommended, true);
      expect(model.reason, 'Blood pressure review after 14 days course.');
      expect(model.status, FollowUpStatus.pending);
      expect(model.recurringInterval, RecurringInterval.monthly);
      expect(model.formattedTargetDate, isNotEmpty);
      expect(model.formattedReminderTime, isNotEmpty);
    });

    test('correctly identifies appointments due soon (within 3 days)', () {
      final now = DateTime.now();
      final dueSoon = FollowUpReminderModel(
        id: 'fu_soon',
        patientId: 'pat_1',
        doctorId: 'doc_1',
        doctorName: 'Dr. One',
        doctorSpecialty: 'Cardio',
        relatedAppointmentId: 'APT_1',
        targetDate: now.add(const Duration(days: 2)),
        reminderDateTime: now.add(const Duration(days: 1)),
        createdAt: now,
      );
      expect(dueSoon.isDueSoon, true);

      final notDueSoon = dueSoon.copyWith(
        targetDate: now.add(const Duration(days: 20)),
      );
      expect(notDueSoon.isDueSoon, false);
    });

    test('serializes to map and back immutably', () {
      final now = DateTime.now();
      final original = FollowUpReminderModel(
        id: 'fu_test',
        patientId: 'pat_test',
        doctorId: 'doc_test',
        doctorName: 'Dr. Marcus',
        doctorSpecialty: 'GP',
        relatedAppointmentId: 'APT_2',
        targetDate: now.add(const Duration(days: 7)),
        reminderDateTime: now.add(const Duration(days: 6)),
        isDoctorRecommended: false,
        reason: 'Patient self-scheduled routine review.',
        status: FollowUpStatus.pending,
        recurringInterval: RecurringInterval.quarterly,
        createdAt: now,
      );

      final map = original.toMap();
      final reconstituted = FollowUpReminderModel.fromMap(map);

      expect(reconstituted.id, original.id);
      expect(reconstituted.isDoctorRecommended, false);
      expect(reconstituted.reason, 'Patient self-scheduled routine review.');
      expect(reconstituted.recurringInterval, RecurringInterval.quarterly);
    });

    test('transitions through dismissal and completion statuses cleanly', () {
      final now = DateTime.now();
      final pending = FollowUpReminderModel(
        id: 'fu_status',
        patientId: 'pat_1',
        doctorId: 'doc_1',
        doctorName: 'Dr. Sarah',
        doctorSpecialty: 'Cardio',
        relatedAppointmentId: 'APT_1',
        targetDate: now.add(const Duration(days: 5)),
        reminderDateTime: now.add(const Duration(days: 4)),
        createdAt: now,
      );

      final completed = pending.copyWith(status: FollowUpStatus.completed);
      expect(completed.status, FollowUpStatus.completed);

      final dismissed = pending.copyWith(status: FollowUpStatus.dismissed);
      expect(dismissed.status, FollowUpStatus.dismissed);
    });
  });
}
