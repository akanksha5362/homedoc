
import 'package:equatable/equatable.dart';

enum AppointmentStatus {
  booked,
  doctorConfirmed,
  rejected,
  preparing,
  onTheWay,
  arriving,
  arrived,
  inConsultation,
  completed,
  cancelled,
}

enum ConsultationType {
  clinicVisit,
  homeVisit,
  video,
}

class AppointmentModel extends Equatable {
  const AppointmentModel({
    required this.id,
    this.patientId = '',
    this.patientName = '',
    this.familyMemberId,
    this.familyRelationship,
    this.doctorId = '',
    required this.doctorName,
    required this.specialty,
    required this.type,
    required this.status,
    required this.scheduledAt,
  });

  final String id;

  // Patient identification
  final String patientId;
  final String patientName;
  final String? familyMemberId;
  final String? familyRelationship;

  // Doctor identification
  final String doctorId;
  final String doctorName;
  final String specialty;

  final ConsultationType type;
  final AppointmentStatus status;
  final DateTime scheduledAt;

  @override
  List<Object?> get props => [
    id,
    patientId,
    patientName,
    familyMemberId,
    familyRelationship,
    doctorId,
    doctorName,
    specialty,
    type,
    status,
    scheduledAt,
  ];
}
