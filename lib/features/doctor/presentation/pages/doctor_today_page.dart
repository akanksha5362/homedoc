
import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/healthcare/appointment_card.dart';
import '../../../../shared/models/appointment_model.dart';
import '../../../../shared/widgets/states/app_empty_state.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_paths.dart';

/// Doctor's landing screen.
/// Uses local mock appointments until the appointment API is implemented.
class DoctorTodayPage extends StatelessWidget {
  const DoctorTodayPage({super.key});

  static final List<AppointmentModel> _mockToday = [
    AppointmentModel(
      id: 'mock-1',
      doctorName: 'Rohan Verma',
      specialty: 'Fever, 3 days',
      type: ConsultationType.homeVisit,
      status: AppointmentStatus.booked,
      scheduledAt: DateTime.now().add(const Duration(hours: 1)),
    ),
    AppointmentModel(
      id: 'mock-2',
      doctorName: 'Priya Nair',
      specialty: 'Follow-up consultation',
      type: ConsultationType.video,
      status: AppointmentStatus.booked,
      scheduledAt: DateTime.now().add(const Duration(hours: 3)),
    ),
  ];

  String _formattedDate(DateTime date) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${weekdays[date.weekday - 1]}, '
        '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final appointments = _mockToday;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Today'),
        actions: [
          IconButton(
            tooltip: 'Doctor Profile',
            onPressed: () => context.go(RoutePaths.doctorProfile),
            icon: const Icon(Icons.person_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: appointments.isEmpty
            ? const AppEmptyState(
          message: 'No appointments scheduled today.',
          icon: Icons.event_available_outlined,
        )
            : ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // Date and welcome section
            Text(
              _formattedDate(DateTime.now()),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Your schedule',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Review your patients and upcoming consultations.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Today's appointment summary
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: colors.onPrimaryContainer.withValues(
                        alpha: 0.08,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.calendar_month_outlined,
                      size: 28,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${appointments.length}',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: colors.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          appointments.length == 1
                              ? 'Appointment today'
                              : 'Appointments today',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.event_available_outlined,
                    color: colors.onPrimaryContainer,
                    size: 26,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Appointment list heading
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Upcoming appointments',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${appointments.length} total',
                  style: AppTypography.label.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Existing appointment cards are retained.
            for (final appointment in appointments) ...[
              AppointmentCard(
                appointment: appointment,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Patient details for '
                            '${appointment.doctorName} '
                            'will be available in a future update.',
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            const SizedBox(height: AppSpacing.sm),

            // Honest development-state indicator
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Demo appointments shown. Live scheduling '
                        'will be connected in a later phase.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
