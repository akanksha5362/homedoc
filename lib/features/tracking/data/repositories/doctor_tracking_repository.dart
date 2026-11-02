import '../models/doctor_tracking_model.dart';

/// Contract for the live tracking API/stream owned by the backend team.
///
/// No endpoint currently exists in the supplied frontend API contracts.
/// Implementations must only emit coordinates/ETA actually supplied by the
/// doctor device/backend. Never substitute the patient's device location.
abstract interface class DoctorTrackingRepository {
  Stream<DoctorTrackingUpdate?> watchTracking({
    required String appointmentId,
    required String doctorId,
  });
}

/// Explicit frontend placeholder until the backend tracking contract is ready.
/// It intentionally emits no location rather than fabricated coordinates.
class PendingDoctorTrackingRepository implements DoctorTrackingRepository {
  const PendingDoctorTrackingRepository();

  @override
  Stream<DoctorTrackingUpdate?> watchTracking({
    required String appointmentId,
    required String doctorId,
  }) => Stream<DoctorTrackingUpdate?>.value(null);
}
