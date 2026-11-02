import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/auth_provider.dart' show firestoreProvider;
import '../../data/models/doctor_tracking_model.dart';
import '../../data/repositories/doctor_tracking_repository.dart';
import '../../data/repositories/firestore_doctor_tracking_repository.dart';

final doctorTrackingRepositoryProvider = Provider<DoctorTrackingRepository>(
  (ref) => FirestoreDoctorTrackingRepository(ref.watch(firestoreProvider)),
);

final doctorTrackingProvider =
    StreamProvider.family<
      DoctorTrackingUpdate?,
      ({String appointmentId, String doctorId})
    >((ref, args) {
      if (args.appointmentId.isEmpty || args.doctorId.isEmpty) {
        return Stream<DoctorTrackingUpdate?>.value(null);
      }
      return ref
          .watch(doctorTrackingRepositoryProvider)
          .watchTracking(
            appointmentId: args.appointmentId,
            doctorId: args.doctorId,
          );
    });
