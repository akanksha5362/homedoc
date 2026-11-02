import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/appointment_model.dart';
import '../../../../shared/providers/auth_provider.dart';

class DoctorAppointmentActions {
  DoctorAppointmentActions(this._firestore);

  final FirebaseFirestore _firestore;

  Future<void> acceptAppointment(String appointmentId) async {
    await _firestore.collection('appointments').doc(appointmentId).update({
      'status': AppointmentStatus.doctorConfirmed.name,
      'confirmedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> rejectAppointment(String appointmentId, String reason) async {
    await _firestore.collection('appointments').doc(appointmentId).update({
      'status': AppointmentStatus.rejected.name,
      'rejectionReason': reason,
      'rejectedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateStatus(String appointmentId, AppointmentStatus status) async {
    await _firestore.collection('appointments').doc(appointmentId).update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> recommendFollowUp({
    required String appointmentId,
    required DateTime followUpDate,
    required String clinicalNotes,
  }) async {
    await _firestore.collection('appointments').doc(appointmentId).update({
      'followUpRecommendedAt': Timestamp.fromDate(followUpDate),
      'clinicalNotes': clinicalNotes,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

final doctorAppointmentActionsProvider = Provider<DoctorAppointmentActions>((ref) {
  return DoctorAppointmentActions(ref.watch(firestoreProvider));
});
