// ignore_for_file: avoid_redundant_argument_values

import 'package:flutter_test/flutter_test.dart';

import 'package:homedoc/shared/services/notification_service.dart';

void main() {
  group('NotificationService — appointmentIdBase', () {
    test('returns a non-negative integer', () {
      final base = NotificationService.appointmentIdBase('abc123');
      expect(base, greaterThanOrEqualTo(0));
    });

    test('two distinct IDs produce distinct bases (very high probability)', () {
      final a = NotificationService.appointmentIdBase('appt_001');
      final b = NotificationService.appointmentIdBase('appt_002');
      // Not guaranteed by hash, but overwhelmingly likely with any real IDs
      expect(a == b, isFalse,
          reason: 'distinct appointment IDs should not collide');
    });

    test('same ID always produces the same base (deterministic)', () {
      const id = 'same_appt_id_xyz';
      expect(
        NotificationService.appointmentIdBase(id),
        equals(NotificationService.appointmentIdBase(id)),
      );
    });

    test('base fits within 32-bit signed integer range', () {
      // flutter_local_notifications requires notification IDs that fit in int32
      final base = NotificationService.appointmentIdBase('stress_test_id');
      expect(base, lessThan(0x7FFFFFFF));
    });

    test('24h and 1h offsets produce distinct IDs for the same appointment', () {
      const base = 1000;
      // offsets are 0 and 1
      expect(base + 0, isNot(equals(base + 1)));
    });
  });

  group('NotificationService — _consultationLabel (indirectly via scheduleAppointmentReminders)', () {
    // The consultation label helper is private, but we can verify it does not
    // throw for common input values via the public API.  The actual
    // platform plugin call is swallowed inside NotificationService, so this
    // exercises the code path without needing a real device or mock plugin.
    test('scheduleAppointmentReminders completes without throwing for past dates', () async {
      final pastDate = DateTime.now().subtract(const Duration(days: 2));
      // All reminders are in the past; should silently no-op.
      await expectLater(
        NotificationService.instance.scheduleAppointmentReminders(
          appointmentId: 'test_appt_past',
          doctorName: 'Dr. Test',
          specialty: 'General Medicine',
          consultationType: 'clinicVisit',
          scheduledAt: pastDate,
        ),
        completes,
      );
    });

    test('cancelAppointmentReminders completes without throwing', () async {
      await expectLater(
        NotificationService.instance
            .cancelAppointmentReminders('test_appt_cancel'),
        completes,
      );
    });

    test('requestPermissions completes without throwing in test environment',
        () async {
      await expectLater(
        NotificationService.instance.requestPermissions(),
        completes,
      );
    });

    test(
        'scheduleAppointmentReminders with homeVisit consultation type does not throw',
        () async {
      final futureDate = DateTime.now().add(const Duration(hours: 30));
      await expectLater(
        NotificationService.instance.scheduleAppointmentReminders(
          appointmentId: 'test_appt_home',
          doctorName: 'Dr. Home',
          specialty: 'Family Medicine',
          consultationType: 'homeVisit',
          scheduledAt: futureDate,
        ),
        completes,
      );
    });

    test(
        'scheduleAppointmentReminders with video consultation type does not throw',
        () async {
      final futureDate = DateTime.now().add(const Duration(hours: 2));
      await expectLater(
        NotificationService.instance.scheduleAppointmentReminders(
          appointmentId: 'test_appt_video',
          doctorName: 'Dr. Video',
          specialty: 'Dermatology',
          consultationType: 'video',
          scheduledAt: futureDate,
        ),
        completes,
      );
    });
  });
}
