
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/appointment_model.dart';
import 'auth_provider.dart';

// Extra display information is stored separately from AppointmentModel.
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
              patientId: entry.appointment.patientId,
              patientName: entry.appointment.patientName,
              familyMemberId: entry.appointment.familyMemberId,
              familyRelationship: entry.appointment.familyRelationship,
              doctorId: entry.appointment.doctorId,
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

/// Real-time stream of appointments for the currently authenticated patient.
final patientAppointmentsProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final auth = ref.watch(authStateProvider);
  final patientId = auth.user?.id;

  if (patientId == null || patientId.isEmpty) {
    return Stream.value([]);
  }

  final firestore = ref.watch(firestoreProvider);

  return firestore
      .collection('appointments')
      .where('patientId', isEqualTo: patientId)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data();

      final scheduledAt = (data['scheduledAt'] as Timestamp).toDate();
      final statusValue = data['status'] as String? ?? 'booked';

      final lifecycleStatus = AppointmentStatus.values.firstWhere(
        (status) => status.name == statusValue,
        orElse: () => AppointmentStatus.booked,
      );

      final consultationType =
          data['consultationType'] as String? ?? 'clinicVisit';

      final consultationLabel = data['consultationLabel'] as String? ??
          switch (consultationType) {
            'homeVisit' => 'Home Visit',
            'video' => 'Video Consultation',
            _ => 'Clinic Visit',
          };

      final icon = switch (consultationType) {
        'homeVisit' => Icons.home_outlined,
        'video' => Icons.videocam_outlined,
        _ => Icons.local_hospital_outlined,
      };

      return <String, dynamic>{
        'id': doc.id,
        'doctorId': data['doctorId'] ?? '',
        'doctor': data['doctorName'] ?? 'Doctor',
        'specialty': data['specialty'] ?? 'Specialization not added',
        'date': scheduledAt,
        'time': DateFormat('hh:mm a').format(scheduledAt),
        'type': consultationLabel,
        'consultationType': consultationType,
        'lifecycleStatus': lifecycleStatus,
        'icon': icon,
        'shared': true,
      };
    }).toList();
  });
});

/// Real-time stream of appointments assigned to the currently authenticated doctor.
final doctorAppointmentsProvider =
    StreamProvider<List<AppointmentModel>>((ref) {
  final auth = ref.watch(authStateProvider);
  final doctorId = auth.user?.id;

  if (doctorId == null || doctorId.isEmpty) {
    return Stream.value([]);
  }

  final firestore = ref.watch(firestoreProvider);

  return firestore
      .collection('appointments')
      .where('doctorId', isEqualTo: doctorId)
      .snapshots()
      .map((snapshot) {
    final list = snapshot.docs.map((doc) {
      final data = doc.data();
      final scheduledAt = (data['scheduledAt'] is Timestamp)
          ? (data['scheduledAt'] as Timestamp).toDate()
          : (data['scheduledAt'] is String
              ? DateTime.tryParse(data['scheduledAt'] as String) ?? DateTime.now()
              : DateTime.now());

      final statusValue = data['status'] as String? ?? 'booked';
      final status = AppointmentStatus.values.firstWhere(
        (s) => s.name == statusValue,
        orElse: () => AppointmentStatus.booked,
      );

      final typeStr = data['consultationType'] as String? ?? 'clinicVisit';
      final type = switch (typeStr) {
        'homeVisit' => ConsultationType.homeVisit,
        'video' => ConsultationType.video,
        _ => ConsultationType.clinicVisit,
      };

      return AppointmentModel(
        id: doc.id,
        patientId: data['patientId'] as String? ?? '',
        patientName: data['patientName'] as String? ?? 'Patient',
        doctorId: doctorId,
        doctorName: data['doctorName'] as String? ?? 'Doctor',
        specialty: data['specialty'] as String? ?? 'General Consultation',
        type: type,
        status: status,
        scheduledAt: scheduledAt,
      );
    }).toList();

    list.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return list;
  });
});

