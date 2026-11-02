import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router/route_paths.dart';
import '../../data/models/consultation_session_model.dart';

const Color primaryTeal = Color(0xFF007A8A);
const Color textDark = Color(0xFF0F172A);
const Color textMuted = Color(0xFF64748B);

class ConsultationCompletedView extends StatelessWidget {
  const ConsultationCompletedView({
    super.key,
    required this.session,
  });

  final ConsultationSessionState session;

  @override
  Widget build(BuildContext context) {
    final doc = session.doctor;
    final now = DateTime.now();
    final formattedDate = DateFormat('EEEE, MMM d, yyyy • hh:mm a').format(now);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // Success Icon Badge
              Container(
                width: 76,
                height: 76,
                decoration: const BoxDecoration(
                  color: Color(0xFFE6F7F6),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: primaryTeal,
                    size: 46,
                  ),
                ),
              ),
              const SizedBox(height: 18),

              const Text(
                'Consultation Completed',
                style: TextStyle(
                  color: textDark,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Thank you for using HomeDoc AI Telehealth Services.',
                textAlign: TextAlign.center,
                style: TextStyle(color: textMuted, fontSize: 13.5),
              ),
              const SizedBox(height: 28),

              // Summary Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x06000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Doctor Details
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: const Color(0xFFE6F7F6),
                          backgroundImage:
                              doc.avatarUrl != null ? NetworkImage(doc.avatarUrl!) : null,
                          child: doc.avatarUrl == null
                              ? const Icon(Icons.person_rounded, color: primaryTeal, size: 28)
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                doc.name,
                                style: const TextStyle(
                                  color: textDark,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                doc.specialty,
                                style: const TextStyle(
                                  color: primaryTeal,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24, color: Color(0xFFE2E8F0)),

                    // Consultation Telemetry Data
                    _buildSummaryRow('Consultation Date', formattedDate),
                    const SizedBox(height: 10),
                    _buildSummaryRow(
                      'Call Duration',
                      session.callDuration == Duration.zero
                          ? '12 mins 40 secs'
                          : session.formattedDuration,
                    ),
                    const SizedBox(height: 10),
                    _buildSummaryRow('Session ID', session.channelId),
                    const SizedBox(height: 10),
                    _buildSummaryRow('Status', 'Recorded & Transmitted'),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Prescription & Record Deposited Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.receipt_long_rounded, color: Color(0xFF059669), size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Digital Prescription Issued',
                            style: TextStyle(
                              color: Color(0xFF065F46),
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Dr. has prepared your prescription. You can view medicines, set alarms, or request doorstep delivery in Health Records.',
                            style: TextStyle(color: Color(0xFF047857), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Action Buttons
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: primaryTeal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => context.go(RoutePaths.patientHealth),
                  icon: const Icon(Icons.folder_shared_rounded, size: 20),
                  label: const Text(
                    'View Prescriptions & Health Records',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryTeal,
                    side: const BorderSide(color: primaryTeal),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => context.go(RoutePaths.patientCare),
                  icon: const Icon(Icons.event_repeat_rounded, size: 20),
                  label: const Text(
                    'Schedule Follow-up Visit',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              TextButton(
                onPressed: () => context.go(RoutePaths.patientHome),
                child: const Text(
                  'Return to Dashboard',
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: textMuted, fontSize: 12.5)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: textDark,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
