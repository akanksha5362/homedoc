import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_paths.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../shared/models/ai_urgency.dart';
import '../../../../shared/providers/doctor_provider.dart';
import '../../data/models/ai_triage_result.dart';

/// Clinical Urgency Classification Screen (Master Prompt §7.B).
///
/// Clearly presents the medically-reviewed triage category, rationale,
/// warning signs to monitor, recommended clinical next action, and matched
/// real clinicians from HomeDoc's verified directory.
class UrgencyClassificationView extends ConsumerWidget {
  const UrgencyClassificationView({
    super.key,
    required this.result,
    required this.onStartOver,
  });

  final AITriageResult result;
  final VoidCallback onStartOver;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doctorsAsync = ref.watch(verifiedDoctorsProvider);

    final (
    badgeLabel,
    badgeColor,
    badgeBg,
    urgencyIcon,
    urgencyHeadline,
    ) = switch (result.urgency) {
      AIUrgency.emergency => (
      'EMERGENCY',
      AppColors.emergency,
      AppColors.emergencyContainer,
      Icons.emergency_rounded,
      'Immediate Emergency Care Required',
      ),
      AIUrgency.urgent => (
      'URGENT',
      const Color(0xFFD97706),
      const Color(0xFFFEF3C7),
      Icons.warning_amber_rounded,
      'Prompt Medical Evaluation Needed',
      ),
      AIUrgency.soon => (
      'ATTENTION SOON',
      const Color(0xFF2563EB),
      const Color(0xFFEFF6FF),
      Icons.schedule_rounded,
      'Schedule Consultation Soon',
      ),
      AIUrgency.routine => (
      'ROUTINE',
      const Color(0xFF0D9488),
      const Color(0xFFCCFBF1),
      Icons.event_available_rounded,
      'Schedule Non-Emergency Visit',
      ),
      AIUrgency.selfCare => (
      'SELF-CARE',
      const Color(0xFF059669),
      const Color(0xFFECFDF5),
      Icons.spa_rounded,
      'Cautious Self-Care & Monitoring',
      ),
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Triage Urgency Header Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: badgeColor.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(urgencyIcon, color: badgeColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badgeLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  urgencyHeadline,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: badgeColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  result.summary,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF374151),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. Clinical Rationale & Why Assigned
          _buildSectionCard(
            title: 'Why this level was assigned',
            icon: Icons.psychology_alt_rounded,
            accentColor: const Color(0xFF0284C7),
            content: result.whyAssigned ?? result.reasoning,
          ),
          const SizedBox(height: 16),

          // 3. Recommended Clinical Action
          _buildSectionCard(
            title: 'Recommended Next Action',
            icon: Icons.check_circle_outline_rounded,
            accentColor: const Color(0xFF059669),
            content:
            '${result.recommendation}\n\nNext Step: ${result.nextStep}',
          ),
          const SizedBox(height: 16),

          // 4. Red Flag Warning Signs to Monitor
          if (result.redFlags.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.flag_rounded,
                        color: Color(0xFFDC2626),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Warning Signs to Monitor',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Seek immediate emergency medical care if you experience any of the following:',
                    style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 10),
                  for (final flag in result.redFlags)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '• ',
                            style: TextStyle(
                              color: Color(0xFFDC2626),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              flag,
                              style: const TextStyle(
                                fontSize: 13.5,
                                color: Color(0xFF374151),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // 5. Matched Doctor Recommendations
          _buildMatchedDoctorsSection(
            context,
            doctorsAsync,
            result.suggestedSpecialty,
          ),
          const SizedBox(height: 20),

          // 6. Clinical Disclaimer
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFF6B7280),
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    result.disclaimer,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 7. Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onStartOver,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('New Assessment'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.go(RoutePaths.patientCare),
                  icon: const Icon(Icons.search_rounded, size: 18),
                  label: const Text('Find Doctors'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007A8A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color accentColor,
    required String content,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: const TextStyle(
              fontSize: 13.5,
              color: Color(0xFF374151),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchedDoctorsSection(
      BuildContext context,
      AsyncValue<List<Map<String, dynamic>>> doctorsAsync,
      String? suggestedSpecialty,
      ) {
    final specialtyQuery = suggestedSpecialty?.trim().toLowerCase();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.medical_services_outlined,
                color: Color(0xFF007A8A),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  suggestedSpecialty != null
                      ? 'Recommended: $suggestedSpecialty Specialists'
                      : 'Recommended Specialists',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Matching verified doctors in the HomeDoc directory:',
            style: TextStyle(fontSize: 12.5, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 12),
          doctorsAsync.when(
            data: (allDoctors) {
              final displayDoctors =
              specialtyQuery == null || specialtyQuery.isEmpty
                  ? <Map<String, dynamic>>[]
                  : allDoctors
                  .where((doc) {
                final doctorId = (doc['doctorId'] as String? ?? '')
                    .trim();
                final name =
                (doc['displayName'] as String? ??
                    doc['name'] as String? ??
                    '')
                    .trim();
                final sp =
                (doc['specialization'] as String? ??
                    doc['specialty'] as String? ??
                    '')
                    .trim();
                final isDemo =
                    doc['isDemo'] == true ||
                        doc['profileType'] == 'demo' ||
                        doctorId.startsWith('demo_');
                return !isDemo &&
                    doctorId.isNotEmpty &&
                    name.isNotEmpty &&
                    name != 'Doctor' &&
                    sp.isNotEmpty &&
                    sp != 'Specialization not added' &&
                    (sp.toLowerCase().contains(specialtyQuery) ||
                        specialtyQuery.contains(sp.toLowerCase()));
              })
                  .take(2)
                  .toList();

              if (displayDoctors.isEmpty) {
                return const Text(
                  'No matching verified doctor profiles are available right now.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                );
              }

              return Column(
                children: [
                  for (final doc in displayDoctors)
                    _buildDoctorItem(context, doc),
                ],
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (err, _) => const Text(
              'Unable to load doctor matches at this time.',
              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorItem(BuildContext context, Map<String, dynamic> doctor) {
    final name = doctor['displayName'] as String? ?? doctor['name'] as String;
    final specialty =
        doctor['specialization'] as String? ?? doctor['specialty'] as String;
    final doctorId = doctor['doctorId'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFFE6F7F6),
            foregroundColor: Color(0xFF007A8A),
            radius: 22,
            child: Icon(Icons.person, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                Text(
                  specialty,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF007A8A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              context.push(
                '${RoutePaths.patientBookAppointment}?doctorId=$doctorId',
                extra: doctor,
              );
            },
            child: const Text(
              'Book',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
