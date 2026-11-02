import 'package:flutter_test/flutter_test.dart';
import 'package:homedoc/features/consultation/data/models/consultation_session_model.dart';

void main() {
  group('DoctorConsultationInfo', () {
    test('parses complete doctor map properly', () {
      final map = {
        'doctorId': 'doc_101',
        'doctorName': 'Dr. Marcus Vance',
        'specialty': 'Cardiologist',
        'hospital': 'City Heart Institute',
        'avatarUrl': 'https://example.com/doc.jpg',
        'isDemo': true,
      };

      final doc = DoctorConsultationInfo.fromMap(map);

      expect(doc.doctorId, 'doc_101');
      expect(doc.name, 'Dr. Marcus Vance');
      expect(doc.specialty, 'Cardiologist');
      expect(doc.hospital, 'City Heart Institute');
      expect(doc.avatarUrl, 'https://example.com/doc.jpg');
      expect(doc.isDemo, true);
    });

    test('handles fallback defaults safely when keys are missing or alt names used', () {
      final map = {
        'id': 'fallback_doc_id',
        'doctor': 'Dr. Sarah Connor',
      };

      final doc = DoctorConsultationInfo.fromMap(map);

      expect(doc.doctorId, 'fallback_doc_id');
      expect(doc.name, 'Dr. Sarah Connor');
      expect(doc.specialty, 'General Medicine');
      expect(doc.hospital, 'HomeDoc Medical Network');
      expect(doc.avatarUrl, isNull);
      expect(doc.isDemo, false);
    });
  });

  group('ConsultationSessionState', () {
    const doctor = DoctorConsultationInfo(
      doctorId: 'doc_1',
      name: 'Dr. Sarah Mitchell',
      specialty: 'Pediatrician',
    );

    test('initializes with waiting room status and safe defaults', () {
      const state = ConsultationSessionState(
        appointmentId: 'apt_test_1',
        channelId: 'channel_test_1',
        doctor: doctor,
      );

      expect(state.status, ConsultationSessionStatus.waitingRoom);
      expect(state.isMicMuted, false);
      expect(state.isCameraOff, false);
      expect(state.isSpeakerOn, true);
      expect(state.isFrontCamera, true);
      expect(state.isDoctorOnline, false);
      expect(state.callDuration, Duration.zero);
      expect(state.formattedDuration, '00:00');
    });

    test('formats call duration correctly for minutes and hours', () {
      const stateSeconds = ConsultationSessionState(
        appointmentId: 'apt_1',
        channelId: 'ch_1',
        doctor: doctor,
        callDuration: Duration(minutes: 5, seconds: 23),
      );
      expect(stateSeconds.formattedDuration, '05:23');

      const stateHours = ConsultationSessionState(
        appointmentId: 'apt_1',
        channelId: 'ch_1',
        doctor: doctor,
        callDuration: Duration(hours: 1, minutes: 12, seconds: 4),
      );
      expect(stateHours.formattedDuration, '1:12:04');
    });

    test('copyWith updates state immutably without altering untouched fields', () {
      const initial = ConsultationSessionState(
        appointmentId: 'apt_1',
        channelId: 'ch_1',
        doctor: doctor,
        status: ConsultationSessionStatus.waitingRoom,
      );

      final inCall = initial.copyWith(
        status: ConsultationSessionStatus.inCall,
        isDoctorOnline: true,
        isMicMuted: true,
      );

      expect(inCall.status, ConsultationSessionStatus.inCall);
      expect(inCall.isDoctorOnline, true);
      expect(inCall.isMicMuted, true);
      expect(inCall.isCameraOff, false); // preserved
      expect(inCall.doctor.name, 'Dr. Sarah Mitchell'); // preserved
    });

    test('transitions through end call lifecycle with session notes', () {
      const initial = ConsultationSessionState(
        appointmentId: 'apt_1',
        channelId: 'ch_1',
        doctor: doctor,
        status: ConsultationSessionStatus.inCall,
        callDuration: Duration(minutes: 14, seconds: 12),
      );

      final ended = initial.copyWith(
        status: ConsultationSessionStatus.completed,
        sessionNotes: 'Prescription sent to records vault.',
      );

      expect(ended.status, ConsultationSessionStatus.completed);
      expect(ended.sessionNotes, 'Prescription sent to records vault.');
      expect(ended.formattedDuration, '14:12');
    });
  });
}
