import 'package:flutter_test/flutter_test.dart';
import 'package:homedoc/features/doctor/presentation/providers/doctor_location_provider.dart';
import 'package:homedoc/features/tracking/data/models/doctor_tracking_model.dart';
import 'package:homedoc/shared/models/appointment_model.dart';

void main() {
  group('Doctor Experience & Location Sharing', () {
    test('DoctorLocationState starts uninitialized with safe defaults', () {
      const state = DoctorLocationState();
      expect(state.isSharing, isFalse);
      expect(state.activeAppointmentId, isNull);
      expect(state.latitude, isNull);
      expect(state.longitude, isNull);
      expect(state.errorMessage, isNull);
    });

    test('DoctorLocationState copyWith produces clean immutable updates', () {
      const initial = DoctorLocationState();
      final now = DateTime.now();

      final updated = initial.copyWith(
        isSharing: true,
        activeAppointmentId: 'appt_123',
        latitude: 28.6139,
        longitude: 77.2090,
        lastUpdated: now,
      );

      expect(updated.isSharing, isTrue);
      expect(updated.activeAppointmentId, 'appt_123');
      expect(updated.latitude, 28.6139);
      expect(updated.longitude, 77.2090);
      expect(updated.lastUpdated, now);
      expect(updated.errorMessage, isNull);
    });

    test('DoctorTrackingUpdate detects stopped tracking status', () {
      final update = DoctorTrackingUpdate(
        appointmentId: 'appt_123',
        doctorId: 'doc_456',
        latitude: 28.6139,
        longitude: 77.2090,
        locationUpdatedAt: DateTime.now(),
        trackingStatus: 'stopped',
      );

      expect(update.trackingStatus, 'stopped');
      expect(update.hasValidCoordinates, isTrue);
    });
  });

  group('Doctor Appointment Lifecycle & Consultation Types', () {
    test('AppointmentModel parses all permitted doctor consultation types', () {
      final now = DateTime.now();
      final homeVisit = AppointmentModel(
        id: 'home_1',
        patientName: 'Rohan Verma',
        doctorName: 'Dr. Practitioner',
        specialty: 'Fever check',
        type: ConsultationType.homeVisit,
        status: AppointmentStatus.booked,
        scheduledAt: now,
      );

      final video = AppointmentModel(
        id: 'video_1',
        patientName: 'Priya Nair',
        doctorName: 'Dr. Practitioner',
        specialty: 'Teleconsultation',
        type: ConsultationType.video,
        status: AppointmentStatus.doctorConfirmed,
        scheduledAt: now,
      );

      final clinic = AppointmentModel(
        id: 'clinic_1',
        patientName: 'Amit Patel',
        doctorName: 'Dr. Practitioner',
        specialty: 'Routine clinic visit',
        type: ConsultationType.clinicVisit,
        status: AppointmentStatus.inConsultation,
        scheduledAt: now,
      );

      expect(homeVisit.type, ConsultationType.homeVisit);
      expect(homeVisit.status, AppointmentStatus.booked);

      expect(video.type, ConsultationType.video);
      expect(video.status, AppointmentStatus.doctorConfirmed);

      expect(clinic.type, ConsultationType.clinicVisit);
      expect(clinic.status, AppointmentStatus.inConsultation);
    });

    test('AppointmentStatus values follow permitted clinical lifecycle', () {
      expect(AppointmentStatus.booked.name, 'booked');
      expect(AppointmentStatus.doctorConfirmed.name, 'doctorConfirmed');
      expect(AppointmentStatus.onTheWay.name, 'onTheWay');
      expect(AppointmentStatus.arrived.name, 'arrived');
      expect(AppointmentStatus.inConsultation.name, 'inConsultation');
      expect(AppointmentStatus.completed.name, 'completed');
      expect(AppointmentStatus.rejected.name, 'rejected');
      expect(AppointmentStatus.cancelled.name, 'cancelled');
    });
  });
}
