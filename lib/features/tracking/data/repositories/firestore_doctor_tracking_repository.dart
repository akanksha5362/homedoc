import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/doctor_tracking_model.dart';
import 'doctor_tracking_repository.dart';

/// Real Firestore live tracking repository for home doctor visits.
///
/// Listens to `active_tracking/{appointmentId}` for genuine GPS coordinate updates
/// published by the doctor device during active home visits.
class FirestoreDoctorTrackingRepository implements DoctorTrackingRepository {
  FirestoreDoctorTrackingRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Stream<DoctorTrackingUpdate?> watchTracking({
    required String appointmentId,
    required String doctorId,
  }) {
    if (appointmentId.isEmpty) return Stream.value(null);

    return _firestore
        .collection('active_tracking')
        .doc(appointmentId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      final data = snapshot.data()!;
      if (data['trackingStatus'] == 'stopped') {
        return null;
      }

      try {
        return DoctorTrackingUpdate.fromJson(data);
      } catch (_) {
        return null;
      }
    });
  }
}
