import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../shared/healthcare/doctor_card.dart';
import '../../../../shared/models/doctor_model.dart';
import '../../data/models/agent_response.dart';
import '../../data/models/agent_risk_level.dart';

/// Renders structured AI Assistant actions as UI and links to existing
/// HomeDoc patient flows. Navigation is intentionally not a substitute for
/// backend actions (e.g. booking, reminder creation, or starting a call).
class AIAgentActionCard extends StatelessWidget {
  const AIAgentActionCard({
    super.key,
    required this.action,
    this.onDoctorTap,
  });

  final AgentAction action;
  final void Function(DoctorModel doctor)? onDoctorTap;

  @override
  Widget build(BuildContext context) {
    switch (action.type) {
      case AgentActionType.showDoctors:
        return _DoctorResultsList(
          action: action,
          onDoctorTap: onDoctorTap,
        );

      case AgentActionType.emergency:
      // The parent page handles emergency risk/actions with its warning UI.
        return const SizedBox.shrink();

      case AgentActionType.showAppointments:
        return _ActionLink(
          icon: Icons.calendar_month_outlined,
          title: 'View appointments',
          subtitle: 'Open your appointments to review scheduled visits.',
          onTap: () => context.push(RoutePaths.patientAppointments),
        );

      case AgentActionType.bookAppointment:
        return _ActionLink(
          icon: Icons.event_available_outlined,
          title: 'Continue to appointment booking',
          subtitle: 'Review available booking options in HomeDoc AI.',
          onTap: () => _openBooking(context),
        );

      case AgentActionType.showPrescription:
        return _ActionLink(
          icon: Icons.medical_information_outlined,
          title: 'Open health records',
          subtitle: 'View your health information and records.',
          onTap: () => context.push(RoutePaths.patientHealth),
        );

      case AgentActionType.startVideo:
        return _ActionLink(
          icon: Icons.video_call_outlined,
          title: 'Open video consultation',
          subtitle: 'Continue to your consultation screen.',
          onTap: () => _openVideoConsultation(context),
        );

      case AgentActionType.trackDoctor:
        return _ActionLink(
          icon: Icons.location_searching_outlined,
          title: 'Track your doctor',
          subtitle: 'Open appointment details to continue tracking.',
          onTap: () => _openTracking(context),
        );

      case AgentActionType.setReminder:
        return _ActionLink(
          icon: Icons.notifications_active_outlined,
          title: 'Open reminders',
          subtitle: 'Review or add a reminder in the reminders screen.',
          onTap: () => _openReminders(context),
        );

      case AgentActionType.requestHomeVisit:
        return _ActionLink(
          icon: Icons.home_work_outlined,
          title: 'Request a home visit',
          subtitle: 'Continue to appointment booking to review options.',
          onTap: () => _openBooking(context),
        );

      case AgentActionType.escalateToDoctor:
        return _ActionLink(
          icon: Icons.support_agent_outlined,
          title: 'Contact your care team',
          subtitle: 'Open your chat list to continue with your care team.',
          onTap: () => context.push(RoutePaths.patientChatList),
        );

      case AgentActionType.unknown:
        return const SizedBox.shrink();
    }
  }

  void _openBooking(BuildContext context) {
    final doctorId = _stringValue(action.data['doctor_id']) ??
        _stringValue(action.data['doctorId']);

    final location = doctorId == null
        ? RoutePaths.patientBookAppointment
        : '${RoutePaths.patientBookAppointment}'
        '?doctorId=${Uri.encodeComponent(doctorId)}';

    context.push(location);
  }

  void _openVideoConsultation(BuildContext context) {
    final appointment = _mapValue(action.data['appointment']);

    if (appointment != null) {
      context.push(
        RoutePaths.patientVideoConsultation,
        extra: appointment,
      );
      return;
    }

    // No appointment payload was supplied. Open the existing screen
    // without fabricating an appointment.
    context.push(RoutePaths.patientVideoConsultation);
  }

  void _openTracking(BuildContext context) {
    final appointment = _mapValue(action.data['appointment']);

    if (appointment != null) {
      context.push(
        RoutePaths.patientDoctorTracking,
        extra: appointment,
      );
      return;
    }

    // Tracking requires appointment details. When they are missing,
    // navigate to the appointments screen instead.
    context.push(RoutePaths.patientAppointments);
  }

  void _openReminders(BuildContext context) {
    final query = <String, String>{};

    final medicine = _stringValue(action.data['medicine_name']) ??
        _stringValue(action.data['medicine']);

    final dosage = _stringValue(action.data['dosage']);
    final doctor = _stringValue(action.data['doctor']);

    if (medicine != null) {
      query['medicine'] = medicine;
    }

    if (dosage != null) {
      query['dosage'] = dosage;
    }

    if (doctor != null) {
      query['doctor'] = doctor;
    }

    final location = query.isEmpty
        ? RoutePaths.patientReminders
        : '${RoutePaths.patientReminders}'
        '?${Uri(queryParameters: query).query}';

    context.push(location);
  }

  static String? _stringValue(Object? value) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }

    return null;
  }

  static Map<String, dynamic>? _mapValue(Object? value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return null;
  }
}

class _DoctorResultsList extends StatelessWidget {
  const _DoctorResultsList({
    required this.action,
    this.onDoctorTap,
  });

  final AgentAction action;
  final void Function(DoctorModel doctor)? onDoctorTap;

  @override
  Widget build(BuildContext context) {
    final rawDoctors = action.data['doctors'];

    final doctors = <DoctorModel>[];

    if (rawDoctors is List) {
      for (final rawDoctor in rawDoctors) {
        if (rawDoctor is! Map) continue;

        try {
          final doctorJson = Map<String, dynamic>.from(rawDoctor);

          doctors.add(
            DoctorModel.fromJson(doctorJson),
          );
        } catch (_) {
          // Skip malformed doctor data.
          // A single invalid entry should not crash the UI.
        }
      }
    }

    if (doctors.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(
          vertical: AppSpacing.sm,
        ),
        child: Text(
          'No doctors found for that right now.',
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final doctor in doctors) ...[
          DoctorCard(
            doctor: doctor,
            onTap: () {
              if (onDoctorTap != null) {
                onDoctorTap!(doctor);
                return;
              }

              final location =
                  '${RoutePaths.patientBookAppointment}'
                  "?doctorId=${Uri.encodeComponent(doctor.id)}";

              context.push(location);
            },
          ),
          const SizedBox(
            height: AppSpacing.sm,
          ),
        ],
      ],
    );
  }
}

class _ActionLink extends StatelessWidget {
  const _ActionLink({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(
        vertical: AppSpacing.xs,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: theme.colorScheme.primary,
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(
          Icons.chevron_right_rounded,
        ),
        onTap: onTap,
      ),
    );
  }
}