import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../shared/models/appointment_model.dart';
import '../../../../shared/providers/appointment_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../chat/presentation/providers/chat_provider.dart';
import '../../../continuity/presentation/widgets/rebooking_sheet.dart';

import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/services/notification_service.dart';
import '../widgets/reschedule_sheet.dart';

class AppointmentsPage extends ConsumerStatefulWidget {
  const AppointmentsPage({super.key});

  @override
  ConsumerState<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends ConsumerState<AppointmentsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const Color primaryTeal = Color(0xFF007A8A);
  static const Color accentTeal = Color(0xFF14B8A6);
  static const Color lightTeal = Color(0xFFE6F7F6);
  static const Color darkText = Color(0xFF1F2937);
  static const Color mutedText = Color(0xFF6B7280);

  static const List<AppointmentStatus> _homeVisitSteps = [
    AppointmentStatus.booked,
    AppointmentStatus.doctorConfirmed,
    AppointmentStatus.preparing,
    AppointmentStatus.onTheWay,
    AppointmentStatus.arriving,
    AppointmentStatus.arrived,
    AppointmentStatus.inConsultation,
    AppointmentStatus.completed,
  ];

  static const List<AppointmentStatus> _otherConsultationSteps = [
    AppointmentStatus.booked,
    AppointmentStatus.doctorConfirmed,
    AppointmentStatus.inConsultation,
    AppointmentStatus.completed,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _statusLabel(AppointmentStatus status) {
    return switch (status) {
      AppointmentStatus.booked => 'Booked',
      AppointmentStatus.doctorConfirmed => 'Doctor Confirmed',
      AppointmentStatus.preparing => 'Preparing',
      AppointmentStatus.onTheWay => 'On the Way',
      AppointmentStatus.arriving => 'Arriving',
      AppointmentStatus.arrived => 'Arrived',
      AppointmentStatus.inConsultation => 'In Consultation',
      AppointmentStatus.completed => 'Completed',
      AppointmentStatus.cancelled => 'Cancelled',
      AppointmentStatus.rejected => 'Rejected',
    };
  }


  String _tabStatus(AppointmentStatus status) {
    return switch (status) {
      AppointmentStatus.completed => 'Completed',
      AppointmentStatus.cancelled || AppointmentStatus.rejected => 'Cancelled',
      _ => 'Upcoming',
    };
  }

  List<Map<String, dynamic>> _appointmentsFor(String status) {
    final appointments =
        ref.watch(patientAppointmentsProvider).valueOrNull ?? [];

    final filteredAppointments = appointments
        .where((appointment) {
          final lifecycleStatus =
              appointment['lifecycleStatus'] as AppointmentStatus;

          return _tabStatus(lifecycleStatus) == status;
        })
        .map((appointment) {
          final lifecycleStatus =
              appointment['lifecycleStatus'] as AppointmentStatus;

          return {...appointment, 'status': _tabStatus(lifecycleStatus)};
        })
        .toList();

    filteredAppointments.sort((a, b) {
      final dateA = a['date'] as DateTime;
      final dateB = b['date'] as DateTime;

      return dateA.compareTo(dateB);
    });

    return filteredAppointments;
  }

  Future<void> _cancelAppointment(Map<String, dynamic> appointment) async {
    unawaited(
      showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Cancel appointment?'),
          content: Text(
            'Are you sure you want to cancel your appointment with '
            '${appointment['doctor']}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Keep appointment'),
            ),
            FilledButton(
              style:
                  FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
              onPressed: () async {
                final appointmentId = appointment['id'] as String;

                try {
                  final firestore = ref.read(firestoreProvider);

                  await firestore
                      .collection('appointments')
                      .doc(appointmentId)
                      .update({
                        'status': 'cancelled',
                        'updatedAt': FieldValue.serverTimestamp(),
                      });

                  // Cancel local appointment reminders so they don't
                  // fire after the appointment has been cancelled.
                  await NotificationService.instance
                      .cancelAppointmentReminders(appointmentId);

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Appointment cancelled successfully.'),
                      ),
                    );
                  }
                } catch (error) {
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Unable to cancel appointment: $error'),
                      ),
                    );
                  }
                }
              },
              child: const Text('Cancel appointment'),
            ),
          ],
        ),
      ),
    );
  }

  List<AppointmentStatus> _stepsFor(Map<String, dynamic> appointment) {
    return appointment['type'] == 'Home Visit'
        ? _homeVisitSteps
        : _otherConsultationSteps;
  }


  void _showRebookingSheet(Map<String, dynamic> appointment) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => RebookingSheet(appointment: appointment),
    );
  }

  void _showRescheduleSheet(Map<String, dynamic> appointment) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => RescheduleSheet(appointment: appointment),
    );
  }

  void _showDetails(Map<String, dynamic> appointment) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        return Consumer(
          builder: (context, sheetRef, child) {
            // Listen to Firestore so the timeline can update
            // when the doctor changes the appointment status.
            final appointmentsAsync = sheetRef.watch(
              patientAppointmentsProvider,
            );

            final latestAppointments = appointmentsAsync.valueOrNull ?? [];

            // Safely find the latest version of this appointment.
            final matchingAppointments = latestAppointments.where(
              (item) => item['id'] == appointment['id'],
            );

            final currentAppointment = matchingAppointments.isNotEmpty
                ? matchingAppointments.first
                : appointment;

            final currentStatus =
                currentAppointment['lifecycleStatus'] as AppointmentStatus? ??
                AppointmentStatus.booked;

            final steps = _stepsFor(currentAppointment);

            final isCancelled =
                currentStatus == AppointmentStatus.cancelled ||
                currentStatus == AppointmentStatus.rejected;

            final currentIndex = steps.indexOf(currentStatus);

            final isCompleted = currentStatus == AppointmentStatus.completed;

            final date = DateFormat(
              'EEEE, d MMM yyyy',
            ).format(currentAppointment['date'] as DateTime);

            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Appointment Details',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: darkText,
                      ),
                    ),
                    const SizedBox(height: 20),

                    _detailRow(
                      'Appointment ID',
                      currentAppointment['id'].toString(),
                    ),
                    _detailRow(
                      'Doctor',
                      currentAppointment['doctor'].toString(),
                    ),
                    _detailRow(
                      'Specialty',
                      currentAppointment['specialty'].toString(),
                    ),
                    _detailRow('Date', date),
                    _detailRow('Time', currentAppointment['time'].toString()),
                    _detailRow(
                      'Consultation',
                      currentAppointment['type'].toString(),
                    ),
                    _detailRow('Current Status', _statusLabel(currentStatus)),

                    if (currentAppointment['consultationType'] == 'homeVisit' &&
                        !isCancelled &&
                        !isCompleted) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () {
                            final trackingAppointment =
                                Map<String, dynamic>.from(currentAppointment);
                            Navigator.of(sheetContext).pop();
                            context.push(
                              RoutePaths.patientDoctorTracking,
                              extra: trackingAppointment,
                            );
                          },
                          icon: const Icon(Icons.location_on_outlined),
                          label: const Text('Track doctor'),
                          style: FilledButton.styleFrom(
                            backgroundColor: primaryTeal,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],

                    if ((currentAppointment['consultationType'] == 'video' ||
                            currentAppointment['type'] == 'Video Consultation' ||
                            currentAppointment['type'] == 'Video') &&
                        !isCancelled &&
                        !isCompleted) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () {
                            final videoAppointment =
                                Map<String, dynamic>.from(currentAppointment);
                            Navigator.of(sheetContext).pop();
                            context.push(
                              RoutePaths.patientVideoConsultation,
                              extra: videoAppointment,
                            );
                          },
                          icon: const Icon(Icons.videocam_rounded),
                          label: const Text('Join Video Consultation'),
                          style: FilledButton.styleFrom(
                            backgroundColor: primaryTeal,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    const Text(
                      'Appointment Progress',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: darkText,
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (isCancelled)
                      _terminalStatusMessage(
                        icon: Icons.cancel_outlined,
                        color: Colors.red.shade600,
                        message: currentStatus == AppointmentStatus.rejected
                            ? 'This appointment has been rejected.'
                            : 'This appointment has been cancelled.',
                      )
                    else
                      ...steps.asMap().entries.map((entry) {
                        final index = entry.key;
                        final step = entry.value;

                        final isCurrent = step == currentStatus;
                        final isPast =
                            currentIndex >= 0 && index < currentIndex;
                        final isLast = index == steps.length - 1;

                        return _timelineStep(
                          label: _statusLabel(step),
                          isCurrent: isCurrent,
                          isPast: isPast,
                          isLast: isLast,
                        );
                      }),

                    if (isCompleted) ...[
                      _terminalStatusMessage(
                        icon: Icons.check_circle_outline,
                        color: Colors.green.shade700,
                        message: 'This appointment is completed.',
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.event_repeat_rounded,
                                    color: Color(0xFF16A34A), size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Appointment Continuity & Rebooking',
                                  style: TextStyle(
                                    color: Color(0xFF14532D),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Doctor recommended routine follow-up. Maintain continuity with your preferred physician.',
                              style: TextStyle(
                                  color: Color(0xFF166534), fontSize: 12),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: primaryTeal,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10),
                                ),
                                onPressed: () {
                                  Navigator.pop(sheetContext);
                                  _showRebookingSheet(currentAppointment);
                                },
                                icon: const Icon(Icons.event_available_rounded,
                                    size: 16),
                                label: const Text('Book Again / Set Reminder'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Message Doctor Action
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0D9488),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          Navigator.pop(sheetContext);
                          final conv = await ref
                              .read(chatActionsProvider)
                              .openOrCreateConversation(
                                doctorId: (currentAppointment['doctorId'] ??
                                        currentAppointment['id'] ??
                                        'demo_doc_1')
                                    .toString(),
                                doctorName: (currentAppointment['doctor'] ??
                                        'Doctor')
                                    .toString(),
                                doctorSpecialty: (currentAppointment['specialty'] ??
                                        'General Medicine')
                                    .toString(),
                                appointmentId: (currentAppointment['id'] ?? '')
                                    .toString(),
                                appointmentStatus: _statusLabel(currentStatus),
                              );
                          if (context.mounted) {
                            unawaited(
                              context.push(
                                RoutePaths.patientChatConversation,
                                extra: conv,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.chat_bubble_outline_rounded,
                            size: 18),
                        label: const Text(
                          'Message Doctor',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Patients can view progress but cannot advance it.
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryTeal,
                          side: const BorderSide(color: accentTeal),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Close'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _timelineStep({
    required String label,
    required bool isCurrent,
    required bool isPast,
    required bool isLast,
  }) {
    final active = isCurrent || isPast;
    final color = active ? primaryTeal : Colors.grey.shade300;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 34,
            child: Column(
              children: [
                Container(
                  width: 25,
                  height: 25,
                  decoration: BoxDecoration(
                    color: active ? color : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                  ),
                  child: active
                      ? Icon(
                          isPast ? Icons.check : Icons.circle,
                          color: Colors.white,
                          size: isPast ? 15 : 9,
                        )
                      : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isPast ? primaryTeal : Colors.grey.shade300,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3, bottom: 22),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                  color: isCurrent
                      ? primaryTeal
                      : active
                      ? darkText
                      : mutedText,
                ),
              ),
            ),
          ),
          if (isCurrent)
            const Padding(
              padding: EdgeInsets.only(top: 3),
              child: Text(
                'CURRENT',
                style: TextStyle(
                  color: primaryTeal,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _terminalStatusMessage({
    required IconData icon,
    required Color color,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(color: mutedText)),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: darkText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFA),

      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(RoutePaths.patientHome);
            }
          },
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: darkText,
            size: 20,
          ),
          tooltip: 'Back to Home',
        ),
        title: const Text(
          'My Appointments',
          style: TextStyle(color: darkText, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryTeal,
          unselectedLabelColor: Colors.grey,
          indicatorColor: accentTeal,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),

      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAppointmentList('Upcoming'),
          _buildAppointmentList('Completed'),
          _buildAppointmentList('Cancelled'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push(RoutePaths.patientBookAppointment);
        },
        backgroundColor: primaryTeal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Book Appointment'),
      ),
    );
  }

  Widget _buildAppointmentList(String status) {
    final appointmentsAsync = ref.watch(patientAppointmentsProvider);

    return appointmentsAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: primaryTeal)),
      error: (error, stackTrace) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 42,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 12),
              const Text(
                'Unable to load appointments.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: darkText,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please check your internet connection and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(color: mutedText),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  ref.invalidate(patientAppointmentsProvider);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (_) {
        final appointments = _appointmentsFor(status);

        if (appointments.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: const BoxDecoration(
                      color: lightTeal,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.calendar_month_outlined,
                      size: 42,
                      color: primaryTeal,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No $status appointments',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: darkText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    status == 'Upcoming'
                        ? 'Your scheduled appointments will appear here.'
                        : 'Your $status appointments will appear here.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: mutedText),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: appointments.length,
          separatorBuilder: (_, _) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            return _appointmentCard(appointments[index]);
          },
        );
      },
    );
  }

  Widget _appointmentCard(Map<String, dynamic> appointment) {
    final status = appointment['status'] as String;
    final date = appointment['date'] as DateTime;
    final isUpcoming = status == 'Upcoming';
    final isCompleted = status == 'Completed';

    final Color statusColor = switch (status) {
      'Upcoming' => primaryTeal,
      'Completed' => const Color(0xFF15803D),
      _ => Colors.red.shade600,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5EEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  color: lightTeal,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  appointment['icon'] as IconData,
                  color: primaryTeal,
                  size: 27,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment['doctor'] as String,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: darkText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      appointment['specialty'] as String,
                      style: const TextStyle(fontSize: 13, color: mutedText),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFEDF1F1)),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 17,
                color: primaryTeal,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  DateFormat('d MMM yyyy').format(date),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(Icons.access_time, size: 17, color: primaryTeal),
              const SizedBox(width: 5),
              Text(
                appointment['time'] as String,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.local_hospital_outlined,
                size: 17,
                color: primaryTeal,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  appointment['type'] as String,
                  style: const TextStyle(fontSize: 13, color: mutedText),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showDetails(appointment),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryTeal,
                    side: const BorderSide(color: accentTeal),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('View Details'),
                ),
              ),
              if (isUpcoming) ...[
                const SizedBox(width: 10),
                // Reschedule button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showRescheduleSheet(appointment),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryTeal,
                      side: const BorderSide(color: primaryTeal),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.edit_calendar_rounded, size: 15),
                    label: const Text(
                      'Reschedule',
                      style: TextStyle(fontSize: 12.5),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Cancel button
                Expanded(
                  child: FilledButton(
                    onPressed: () => _cancelAppointment(appointment),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red.shade700,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.red.shade200),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontSize: 12.5),
                    ),
                  ),
                ),
              ] else if (isCompleted) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _showRebookingSheet(appointment),
                    style: FilledButton.styleFrom(
                      backgroundColor: primaryTeal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.event_repeat_rounded, size: 16),
                    label: const Text('Book Again'),
                  ),
                ),
              ],
            ],
          ),
          if (isUpcoming &&
              (appointment['consultationType'] == 'video' ||
                  appointment['type'] == 'Video Consultation' ||
                  appointment['type'] == 'Video')) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  context.push(
                    RoutePaths.patientVideoConsultation,
                    extra: Map<String, dynamic>.from(appointment),
                  );
                },
                icon: const Icon(Icons.videocam_rounded, size: 18),
                label: const Text('Join Video Consultation'),
                style: FilledButton.styleFrom(
                  backgroundColor: primaryTeal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
