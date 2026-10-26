import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../app/theme/app_spacing.dart';
import '../models/appointment_model.dart';
import '../widgets/cards/app_card.dart';
import 'appointment_status_badge.dart';

/// Reused by both the patient Home (State C/D) and the doctor Today screen
/// (Day 2 §12/§17) — same shell, different data, per the shared-component
/// principle in UX/UI Architecture v1 §34.
class AppointmentCard extends StatelessWidget {
  const AppointmentCard({super.key, required this.appointment, this.onTap});

  final AppointmentModel appointment;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final typeLabel = appointment.type == ConsultationType.homeVisit ? 'Home visit' : 'Video consultation';
    final timeLabel = DateFormat('EEE, d MMM · h:mm a').format(appointment.scheduledAt);

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(appointment.doctorName, style: textTheme.headlineMedium),
              AppointmentStatusBadge(status: appointment.status),
            ],
          ),
          const SizedBox(height: 4),
          Text('${appointment.specialty} · $typeLabel', style: textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(Icons.schedule, size: 16),
              const SizedBox(width: 4),
              Text(timeLabel, style: textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}
