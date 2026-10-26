
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/appointment_model.dart';

/// Extra display information is stored separately from AppointmentModel.
class AppointmentEntry {
  const AppointmentEntry({
    required this.appointment,
    required this.consultationLabel,
  });

  final AppointmentModel appointment;
  final String consultationLabel;
}

class AppointmentNotifier extends StateNotifier<List<AppointmentEntry>> {
  AppointmentNotifier() : super(const []);

  void addAppointment(AppointmentEntry entry) {
    state = [entry, ...state];
  }

  void updateStatus(String appointmentId, AppointmentStatus status) {
    state = [
      for (final entry in state)
        if (entry.appointment.id == appointmentId)
          AppointmentEntry(
            appointment: AppointmentModel(
              id: entry.appointment.id,
              doctorName: entry.appointment.doctorName,
              specialty: entry.appointment.specialty,
              type: entry.appointment.type,
              status: status,
              scheduledAt: entry.appointment.scheduledAt,
            ),
            consultationLabel: entry.consultationLabel,
          )
        else
          entry,
    ];
  }
}

final appointmentProvider =
StateNotifierProvider<AppointmentNotifier, List<AppointmentEntry>>(
      (ref) => AppointmentNotifier(),
);
