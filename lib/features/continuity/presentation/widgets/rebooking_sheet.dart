import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router/route_paths.dart';
import 'schedule_follow_up_dialog.dart';

const Color primaryTeal = Color(0xFF007A8A);
const Color lightTealSurface = Color(0xFFE6F7F6);
const Color textDark = Color(0xFF0F172A);
const Color textMuted = Color(0xFF64748B);

class RebookingSheet extends StatelessWidget {
  const RebookingSheet({
    super.key,
    required this.appointment,
  });

  final Map<String, dynamic> appointment;

  @override
  Widget build(BuildContext context) {
    final doctorId = (appointment['doctorId'] ?? appointment['id'] ?? 'demo_doc_1').toString();
    final doctorName = (appointment['doctor'] ?? 'Doctor').toString();
    final specialty = (appointment['specialty'] ?? 'General Medicine').toString();
    final date = appointment['date'];
    final dateStr = date is DateTime
        ? DateFormat('d MMM yyyy').format(date)
        : (date?.toString() ?? 'Recent');
    final typeStr = (appointment['type'] ?? 'Clinic Visit').toString();
    final isDemo = doctorId.startsWith('demo_');

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            const Text(
              'Appointment Continuity',
              style: TextStyle(
                color: textDark,
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Rebook or set follow-up reminders with your preferred clinician.',
              style: TextStyle(color: textMuted, fontSize: 13),
            ),
            const SizedBox(height: 18),

            // Doctor Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x04000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 26,
                    backgroundColor: lightTealSurface,
                    child: Icon(Icons.person_rounded, color: primaryTeal, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                doctorName,
                                style: const TextStyle(
                                  color: textDark,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isDemo) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Demo',
                                  style: TextStyle(
                                    color: Color(0xFF2563EB),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          specialty,
                          style: const TextStyle(
                            color: primaryTeal,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Previous Consultation: $dateStr • $typeStr',
                          style: const TextStyle(color: textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Action 1: One-tap Book Again
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: primaryTeal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  context.push(
                    '${RoutePaths.patientBookAppointment}?doctorId=$doctorId',
                    extra: doctorId,
                  );
                },
                icon: const Icon(Icons.event_available_rounded, size: 20),
                label: Text(
                  'Book Again with $doctorName',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Action 2: Schedule Follow-up Reminder
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryTeal,
                  side: const BorderSide(color: primaryTeal),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  showDialog<void>(
                    context: context,
                    builder: (dialogCtx) => ScheduleFollowUpDialog(
                      doctorId: doctorId,
                      doctorName: doctorName,
                      doctorSpecialty: specialty,
                      relatedAppointmentId: (appointment['id'] ?? '').toString(),
                      isDoctorRecommended: true,
                      initialReason: 'Follow-up consultation after $dateStr visit.',
                    ),
                  );
                },
                icon: const Icon(Icons.alarm_add_rounded, size: 20),
                label: const Text(
                  'Set Follow-Up Reminder',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
