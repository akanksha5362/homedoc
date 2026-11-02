import 'package:flutter_test/flutter_test.dart';
import 'package:homedoc/features/tracking/data/models/doctor_tracking_model.dart';

void main() {
  group('DoctorTrackingUpdate', () {
    final sample = <String, dynamic>{
      'appointmentId': 'appt-1',
      'doctorId': 'doctor-1',
      'latitude': 26.2183,
      'longitude': 78.1828,
      'locationUpdatedAt': '2026-11-01T10:00:00.000Z',
      'trackingStatus': 'onTheWay',
      'etaMinutes': 12,
      'accuracy': 8.5,
    };

    test('parses a valid tracking payload', () {
      final model = DoctorTrackingUpdate.fromJson(sample);
      expect(model.appointmentId, 'appt-1');
      expect(model.doctorId, 'doctor-1');
      expect(model.latitude, 26.2183);
      expect(model.etaMinutes, 12);
      expect(model.accuracyMeters, 8.5);
    });

    test('rejects payload with missing coordinates', () {
      expect(
        () => DoctorTrackingUpdate.fromJson(const {
          'appointmentId': 'appt-1',
          'doctorId': 'doctor-1',
          'locationUpdatedAt': '2026-11-01T10:00:00Z',
        }),
        throwsFormatException,
      );
    });

    test('formats ETA without inventing a value', () {
      expect(
        DoctorTrackingUpdate.fromJson(sample).formattedEta,
        '12 mins',
      );
      final noEta = DoctorTrackingUpdate.fromJson({
        ...sample,
        'etaMinutes': null,
      });
      expect(noEta.formattedEta, 'ETA unavailable');
    });

    test('formats hours and minutes', () {
      final model = DoctorTrackingUpdate.fromJson({
        ...sample,
        'etaMinutes': 75,
      });
      expect(model.formattedEta, '1h 15m');
    });

    test('detects stale location updates', () {
      final model = DoctorTrackingUpdate.fromJson({
        ...sample,
        'locationUpdatedAt': '2026-10-30T10:00:00Z',
      });
      expect(
        model.isStale(now: DateTime.utc(2026, 11, 1, 10)),
        isTrue,
      );
    });

    test('detects invalid zero coordinates', () {
      final model = DoctorTrackingUpdate.fromJson({
        ...sample,
        'latitude': 0,
        'longitude': 0,
      });
      expect(model.hasValidCoordinates, isFalse);
    });
  });
}
