import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../models/appointment_model.dart';
import '../widgets/badges/app_badge.dart';

/// One consistent status pattern intended for reuse across appointments,
/// and later (Phase 2+) medicine orders and delivery tracking (Day 2 §34).
class AppointmentStatusBadge extends StatelessWidget {
  const AppointmentStatusBadge({super.key, required this.status});

  final AppointmentStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color, bg) = switch (status) {
      AppointmentStatus.booked =>
      ('Booked', AppColors.textMuted, AppColors.surfaceMuted),

      AppointmentStatus.doctorConfirmed =>
      ('Confirmed', AppColors.success, const Color(0xFFE4F3E8)),

      AppointmentStatus.rejected =>
      ('Rejected', AppColors.error, const Color(0xFFFBE6E6)),

      AppointmentStatus.preparing =>
      ('Preparing', AppColors.secondary, AppColors.secondaryContainer),

      AppointmentStatus.onTheWay =>
      ('On the way', AppColors.secondary, AppColors.secondaryContainer),

      AppointmentStatus.arriving =>
      ('Arriving soon', AppColors.warning, const Color(0xFFFAF0DA)),

      AppointmentStatus.arrived =>
      ('Arrived', AppColors.success, const Color(0xFFE4F3E8)),

      AppointmentStatus.inConsultation =>
      ('In consultation', AppColors.primary, AppColors.primaryContainer),

      AppointmentStatus.completed =>
      ('Completed', AppColors.textMuted, AppColors.surfaceMuted),

      AppointmentStatus.cancelled =>
      ('Cancelled', AppColors.error, const Color(0xFFFBE6E6)),
    };
    return AppBadge(label: label, color: color, backgroundColor: bg);
  }
}
