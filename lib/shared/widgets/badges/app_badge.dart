import 'package:flutter/material.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';

/// Small labeled pill. Foundation for `DoctorVerificationBadge`,
/// `AppointmentStatusBadge`, and future status indicators — those should
/// compose this rather than reimplementing the pill shape.
class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.label,
    required this.color,
    required this.backgroundColor,
    this.icon,
  });

  final String label;
  final Color color;
  final Color backgroundColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(color: backgroundColor, borderRadius: AppRadius.smallRadius),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 14, color: color), const SizedBox(width: 4)],
          Text(label, style: AppTypography.caption.copyWith(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
