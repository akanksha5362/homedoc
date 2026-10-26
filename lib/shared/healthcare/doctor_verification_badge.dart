import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../widgets/badges/app_badge.dart';

/// Renders identically everywhere a doctor's identity appears — search
/// card, profile, tracking, arrival confirmation (UX/UI Architecture v1
/// §14: "consistent icon, not re-explained each time"). Do not create a
/// second verified-badge visual anywhere else in the app.
class DoctorVerificationBadge extends StatelessWidget {
  const DoctorVerificationBadge({super.key, required this.verified});

  final bool verified;

  @override
  Widget build(BuildContext context) {
    if (!verified) return const SizedBox.shrink();
    return const AppBadge(
      label: 'Verified',
      icon: Icons.verified,
      color: AppColors.success,
      backgroundColor: Color(0xFFE4F3E8),
    );
  }
}
