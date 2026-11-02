
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Notification ID offsets for appointment reminders.
/// Given an appointment hash base [b]:
///   24-hour reminder  → b
///   1-hour  reminder  → b + 1
const int _kAppt24hOffset = 0;
const int _kAppt1hOffset = 1;

/// Service for scheduling and delivering local prescription, medication,
/// follow-up, and appointment reminders.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // ─── Notification channels ──────────────────────────────────────────────────

  static const _apptChannel = AndroidNotificationDetails(
    'homedoc_appointment_reminders',
    'Appointment Reminders',
    channelDescription: 'Upcoming appointment alerts 24 hours and 1 hour before',
    importance: Importance.max,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
    playSound: true,
    enableVibration: true,
  );

  static const _apptDetails = NotificationDetails(
    android: _apptChannel,
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  // ─── Initialisation ─────────────────────────────────────────────────────────

  /// Initialize time zones and platform-specific notification settings.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();

      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _plugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (response) {
          // Handle notification taps or actions here when needed.
        },
      );

      _isInitialized = true;
    } catch (_) {
      // Initialization may fail in tests or headless environments.
    }
  }

  /// Request runtime permissions for Android 13+ and iOS.
  Future<bool> requestPermissions() async {
    await initialize();

    try {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        final granted =
        await androidPlugin.requestNotificationsPermission();

        if (granted != null) return granted;
      }

      final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();

      if (iosPlugin != null) {
        final granted = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

        if (granted != null) return granted;
      }
    } catch (_) {
      return false;
    }

    return true;
  }

  // ─── Appointment reminders ───────────────────────────────────────────────────

  /// Stable integer ID base derived from an appointment Firestore document ID.
  ///
  /// The base is used directly for the 24-hour reminder; +1 is used for the
  /// 1-hour reminder.  Both values must fit in a 32-bit signed integer so we
  /// mod by 10 million and ensure a non-negative result.
  static int appointmentIdBase(String appointmentDocId) =>
      (appointmentDocId.hashCode.abs() % 10000000) * 10;

  /// Schedule a 24-hour and a 1-hour local reminder for an upcoming appointment.
  ///
  /// Reminders are silently skipped when [scheduledAt] is in the past or within
  /// the reminder window.  Safe to call in tests — any platform plugin error is
  /// swallowed.
  Future<void> scheduleAppointmentReminders({
    required String appointmentId,
    required String doctorName,
    required String specialty,
    required String consultationType,
    required DateTime scheduledAt,
  }) async {
    await initialize();

    final base = appointmentIdBase(appointmentId);
    final now = DateTime.now();

    final remind24h = scheduledAt.subtract(const Duration(hours: 24));
    final remind1h = scheduledAt.subtract(const Duration(hours: 1));

    final typeLabel = _consultationLabel(consultationType);

    Future<void> scheduleAt(int id, DateTime fireAt, String title, String body) async {
      if (fireAt.isBefore(now)) return; // already past — skip silently
      try {
        await _plugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: tz.TZDateTime.from(fireAt, tz.local),
          notificationDetails: _apptDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      } catch (_) {
        // Platform may deny exact alarms; silently skip.
      }
    }

    await scheduleAt(
      base + _kAppt24hOffset,
      remind24h,
      '🗓️ Appointment tomorrow — $doctorName',
      'Your $typeLabel with $doctorName ($specialty) is in 24 hours.',
    );

    await scheduleAt(
      base + _kAppt1hOffset,
      remind1h,
      '⏰ Appointment in 1 hour — $doctorName',
      'Your $typeLabel with $doctorName ($specialty) starts soon. Get ready!',
    );
  }

  /// Cancel both appointment reminders (24 h + 1 h) for a given appointment.
  Future<void> cancelAppointmentReminders(String appointmentId) async {
    await initialize();
    final base = appointmentIdBase(appointmentId);
    try {
      await _plugin.cancel(id: base + _kAppt24hOffset);
      await _plugin.cancel(id: base + _kAppt1hOffset);
    } catch (_) {
      // Ignore cancellation errors.
    }
  }

  String _consultationLabel(String rawType) {
    switch (rawType.toLowerCase()) {
      case 'homevisit':
      case 'home visit':
      case 'home_visit':
        return 'home visit';
      case 'video':
      case 'videoconsultation':
      case 'video consultation':
        return 'video consultation';
      default:
        return 'clinic appointment';
    }
  }

  // ─── Medication alarms ───────────────────────────────────────────────────────

  /// Schedule a daily medication alarm at a specified hour and minute.
  Future<void> scheduleMedicationAlarm({
    required int id,
    required String medicineName,
    required String dosage,
    required int hour,
    required int minute,
    String? instructions,
  }) async {
    await initialize();

    final scheduledDate = _nextInstanceOfTime(hour, minute);

    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'homedoc_medication_reminders',
        'Medication Reminders',
        channelDescription:
        'Alarms and notifications for scheduled prescription doses',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    final body = instructions != null && instructions.isNotEmpty
        ? 'Dose: $dosage • $instructions'
        : 'Take your prescribed dose: $dosage';

    try {
      await _plugin.zonedSchedule(
        id: id,
        title: '💊 Time for $medicineName',
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {
      // Scheduling can fail if platform permissions or settings are missing.
    }
  }

  /// Schedule a follow-up consultation reminder at a specific DateTime.
  Future<void> scheduleFollowUpAlert({
    required int id,
    required String doctorName,
    required String reason,
    required DateTime scheduledDateTime,
  }) async {
    await initialize();

    final tzDateTime = tz.TZDateTime.from(scheduledDateTime, tz.local);

    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'homedoc_follow_up_reminders',
        'Follow-Up Reminders',
        channelDescription:
            'Alerts for scheduled and doctor-recommended follow-up consultations',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    try {
      await _plugin.zonedSchedule(
        id: id,
        title: '🗓️ Follow-up Consultation with $doctorName',
        body: reason.isNotEmpty
            ? reason
            : 'Scheduled consultation check per your clinical plan.',
        scheduledDate: tzDateTime,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (_) {
      // Scheduling can fail if platform permissions or settings are missing.
    }
  }

  /// Cancel a scheduled alarm by its notification ID.
  Future<void> cancelAlarm(int id) async {
    await initialize();

    try {
      await _plugin.cancel(id: id);
    } catch (_) {
      // Ignore cancellation errors.
    }
  }

  /// Send an immediate test notification.
  Future<void> showTestNotification({
    required String title,
    required String body,
  }) async {
    await initialize();

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'homedoc_medication_reminders',
        'Medication Reminders',
        channelDescription: 'Medication notifications',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(),
    );

    try {
      await _plugin.show(
        id: 999999,
        title: title,
        body: body,
        notificationDetails: details,
      );
    } catch (_) {
      // Ignore notification display errors.
    }
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);

    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }
}
