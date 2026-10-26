import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/healthcare/appointment_card.dart';
import '../../../../shared/healthcare/emergency_action.dart';
import '../../../../shared/models/appointment_model.dart';
import '../../../../shared/widgets/buttons/app_button.dart';

class PatientHomePage extends StatelessWidget {
  const PatientHomePage({super.key});

  // Clearly marked mock data until backend integration.
  // Set to null to display the AI guidance state instead.
  static final AppointmentModel? _mockActiveAppointment = AppointmentModel(
    id: 'mock-appt-1',
    doctorName: 'Dr. Ananya Sharma',
    specialty: 'General Physician',
    type: ConsultationType.homeVisit,
    status: AppointmentStatus.onTheWay,
    scheduledAt: DateTime.now().add(const Duration(minutes: 20)),
  );

  static const Color primaryTeal = Color(0xFF14B8A6);
  static const Color darkTeal = Color(0xFF007A8A);
  static const Color lightTeal = Color(0xFFE6F7F6);
  static const Color darkText = Color(0xFF1F2937);
  static const Color mutedText = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    final hasActiveAppointment = _mockActiveAppointment != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 20,
        title: const Row(
          children: [
            Icon(Icons.health_and_safety_rounded, color: darkTeal, size: 29),
            SizedBox(width: 9),
            Text(
              'HomeDoc AI',
              style: TextStyle(
                color: darkText,
                fontWeight: FontWeight.bold,
                fontSize: 21,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              tooltip: 'Notifications',
              onPressed: () => _showComingSoon(context, 'Notifications'),
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: darkText,
                size: 27,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: EmergencyAction(
        onTap: () => _showComingSoon(context, 'Emergency flow'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome section
              const Text(
                'WELCOME TO HOMEDOC',
                style: TextStyle(
                  color: darkTeal,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Good morning!',
                style: TextStyle(
                  color: darkText,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'How are you feeling today?',
                style: TextStyle(color: mutedText, fontSize: 15),
              ),

              const SizedBox(height: 24),

              // Search doctors
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: TextField(
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => context.go(RoutePaths.patientCare),
                  decoration: InputDecoration(
                    hintText: 'Search doctors, specialists...',
                    hintStyle: const TextStyle(color: mutedText, fontSize: 14),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: darkTeal,
                    ),
                    suffixIcon: IconButton(
                      tooltip: 'Browse doctors',
                      onPressed: () => context.go(RoutePaths.patientCare),
                      icon: const Icon(
                        Icons.arrow_forward_rounded,
                        color: darkTeal,
                      ),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 17),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Healthcare services
              const Text(
                'Healthcare services',
                style: TextStyle(
                  color: darkText,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Care that fits your needs.',
                style: TextStyle(color: mutedText, fontSize: 13),
              ),
              const SizedBox(height: 16),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.28,
                children: [
                  _ServiceCard(
                    icon: Icons.calendar_month_rounded,
                    title: 'Appointments',
                    subtitle: 'Manage your visits',
                    onTap: () => context.go(RoutePaths.patientAppointments),
                  ),
                  _ServiceCard(
                    icon: Icons.home_rounded,
                    title: 'Home visits',
                    subtitle: 'Care at your doorstep',
                    onTap: () => context.go(RoutePaths.patientCare),
                  ),
                  _ServiceCard(
                    icon: Icons.psychology_alt_rounded,
                    title: 'AI health assistant',
                    subtitle: 'Get health guidance',
                    onTap: () => context.push(RoutePaths.patientAiAssistant),
                  ),
                  _ServiceCard(
                    icon: Icons.monitor_heart_rounded,
                    title: 'Health records',
                    subtitle: 'Your health information',
                    onTap: () => context.go(RoutePaths.patientHealth),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Active appointment or AI guidance
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Your care',
                      style: TextStyle(
                        color: darkText,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (hasActiveAppointment)
                    TextButton(
                      onPressed: () =>
                          _showComingSoon(context, 'Appointment details'),
                      child: const Text(
                        'View details',
                        style: TextStyle(color: darkTeal),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              if (hasActiveAppointment) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: lightTeal,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.directions_walk_rounded,
                        color: darkTeal,
                        size: 28,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Home visit in progress',
                              style: TextStyle(
                                color: darkTeal,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Your doctor is on the way.',
                              style: TextStyle(color: darkText, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AppointmentCard(
                  appointment: _mockActiveAppointment!,
                  onTap: () => _showComingSoon(context, 'Live tracking'),
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.spa_outlined, color: darkTeal, size: 32),
                      const SizedBox(height: 12),
                      const Text(
                        'Need help with your health?',
                        style: TextStyle(
                          color: darkText,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Start with AI care guidance or find '
                        'a healthcare professional.',
                        style: TextStyle(
                          color: mutedText,
                          height: 1.5,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 16),
                      AppButton(
                        label: 'Start AI care guidance',
                        icon: Icons.spa_outlined,
                        onPressed: () =>
                            context.push(RoutePaths.patientAiAssistant),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => context.go(RoutePaths.patientCare),
                          child: const Text('Browse doctors'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Health reminder
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.favorite_outline_rounded,
                      color: darkTeal,
                      size: 25,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Take care of yourself',
                            style: TextStyle(
                              color: darkText,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Stay hydrated, get enough rest, '
                            'and keep up with your appointments.',
                            style: TextStyle(
                              color: mutedText,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature — coming in the next implementation phase'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  static const Color darkTeal = Color(0xFF007A8A);
  static const Color darkText = Color(0xFF1F2937);
  static const Color mutedText = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: darkTeal, size: 27),
              const SizedBox(height: 10),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: darkText,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: mutedText,
                  fontSize: 11,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
