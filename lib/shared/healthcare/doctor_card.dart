import 'package:flutter/material.dart';
import '../../app/theme/app_spacing.dart';
import '../models/doctor_model.dart';
import '../widgets/cards/app_card.dart';
import 'doctor_verification_badge.dart';

/// Kept deliberately minimal (UX/UI Architecture v1 §9: "do not overload
/// the card"). Receives data only — never fetches it itself (Day 3 §17).
class DoctorCard extends StatelessWidget {
  const DoctorCard({super.key, required this.doctor, this.onTap});

  final DoctorModel doctor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundImage: doctor.photoUrl != null ? NetworkImage(doctor.photoUrl!) : null,
            child: doctor.photoUrl == null ? const Icon(Icons.person) : null,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: Text(doctor.name, style: textTheme.headlineMedium)),
                    const SizedBox(width: AppSpacing.sm),
                    DoctorVerificationBadge(verified: doctor.verified),
                  ],
                ),
                const SizedBox(height: 2),
                Text('${doctor.specialty} · ${doctor.experienceYears} yrs experience', style: textTheme.bodyMedium),
                const SizedBox(height: 4),
                Text('⭐ ${doctor.rating.toStringAsFixed(1)}', style: textTheme.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}
