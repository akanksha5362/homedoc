import 'package:equatable/equatable.dart';

/// Mirrors the home-visit lifecycle from UX/UI Architecture v1 §12.
/// One status enum reused across `AppointmentStatusBadge` everywhere an
/// appointment/order/delivery concept appears (Day 2 §33 component rule).
enum AppointmentStatus {
  booked,
  doctorConfirmed,
  preparing,
  onTheWay,
  arriving,
  arrived,
  inConsultation,
  completed,
  cancelled,
}

enum ConsultationType { homeVisit, video }

class AppointmentModel extends Equatable {
  const AppointmentModel({
    required this.id,
    required this.doctorName,
    required this.specialty,
    required this.type,
    required this.status,
    required this.scheduledAt,
  });

  final String id;
  final String doctorName;
  final String specialty;
  final ConsultationType type;
  final AppointmentStatus status;
  final DateTime scheduledAt;

  @override
  List<Object?> get props => [id, doctorName, specialty, type, status, scheduledAt];
}
