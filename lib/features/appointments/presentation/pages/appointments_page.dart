import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../shared/models/appointment_model.dart';
import '../../../../shared/providers/appointment_provider.dart';

class AppointmentsPage extends ConsumerStatefulWidget {
  const AppointmentsPage({super.key});

  @override
  ConsumerState<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends ConsumerState<AppointmentsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final List<Map<String, dynamic>> _appointments = [
    {
      'id': 'APT001',
      'doctor': 'Dr. Ananya Sharma',
      'specialty': 'General Physician',
      'date': DateTime.now().add(const Duration(days: 1)),
      'time': '10:30 AM',
      'type': 'Home Visit',
      'status': 'Upcoming',
      'lifecycleStatus': AppointmentStatus.booked,
      'icon': Icons.medical_services_outlined,
    },
    {
      'id': 'APT002',
      'doctor': 'Dr. Rahul Verma',
      'specialty': 'Cardiologist',
      'date': DateTime.now().add(const Duration(days: 3)),
      'time': '04:00 PM',
      'type': 'Clinic Visit',
      'status': 'Upcoming',
      'lifecycleStatus': AppointmentStatus.booked,
      'icon': Icons.favorite_border,
    },
    {
      'id': 'APT003',
      'doctor': 'Dr. Priya Mehta',
      'specialty': 'Dermatologist',
      'date': DateTime.now().subtract(const Duration(days: 5)),
      'time': '11:00 AM',
      'type': 'Video Consultation',
      'status': 'Completed',
      'lifecycleStatus': AppointmentStatus.completed,
      'icon': Icons.videocam_outlined,
    },
    {
      'id': 'APT004',
      'doctor': 'Dr. Karan Patel',
      'specialty': 'Orthopedic',
      'date': DateTime.now().subtract(const Duration(days: 2)),
      'time': '02:30 PM',
      'type': 'Clinic Visit',
      'status': 'Cancelled',
      'lifecycleStatus': AppointmentStatus.cancelled,
      'icon': Icons.accessibility_new,
    },
  ];

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
    };
  }

  AppointmentStatus _currentStatus(Map<String, dynamic> appointment) {
    final id = appointment['id'] as String;

    if (appointment['shared'] == true) {
      final entries = ref.read(appointmentProvider);

      for (final entry in entries) {
        if (entry.appointment.id == id) {
          return entry.appointment.status;
        }
      }

      return AppointmentStatus.booked;
    }

    // Find the ORIGINAL demo appointment, not its display copy.
    final original = _appointments.firstWhere((item) => item['id'] == id);

    return original['lifecycleStatus'] as AppointmentStatus;
  }

  String _tabStatus(AppointmentStatus status) {
    return switch (status) {
      AppointmentStatus.completed => 'Completed',
      AppointmentStatus.cancelled => 'Cancelled',
      _ => 'Upcoming',
    };
  }

  List<Map<String, dynamic>> _appointmentsFor(String status) {
    final sharedEntries = ref.watch(appointmentProvider);

    final sharedAppointments = sharedEntries.map((entry) {
      final appointment = entry.appointment;

      return <String, dynamic>{
        'id': appointment.id,
        'doctor': appointment.doctorName,
        'specialty': appointment.specialty,
        'date': appointment.scheduledAt,
        'time': DateFormat('hh:mm a').format(appointment.scheduledAt),
        'type': entry.consultationLabel,
        'status': _tabStatus(appointment.status),
        'lifecycleStatus': appointment.status,
        'icon': switch (appointment.type) {
          ConsultationType.homeVisit => Icons.home_outlined,
          ConsultationType.video => Icons.videocam_outlined,
        },
        'shared': true,
      };
    }).toList();

    // Update demo appointment display status from its lifecycle status.
    final demoAppointments = _appointments.map((appointment) {
      final lifecycle = appointment['lifecycleStatus'] as AppointmentStatus;
      return <String, dynamic>{...appointment, 'status': _tabStatus(lifecycle)};
    }).toList();

    final allAppointments = [...demoAppointments, ...sharedAppointments];

    final filtered = allAppointments
        .where((appointment) => appointment['status'] == status)
        .toList();

    filtered.sort((a, b) {
      final aDate = a['date'] as DateTime;
      final bDate = b['date'] as DateTime;

      return status == 'Upcoming'
          ? aDate.compareTo(bDate)
          : bDate.compareTo(aDate);
    });

    return filtered;
  }

  void _cancelAppointment(Map<String, dynamic> appointment) {
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
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
            onPressed: () {
              if (appointment['shared'] == true) {
                ref
                    .read(appointmentProvider.notifier)
                    .updateStatus(
                      appointment['id'] as String,
                      AppointmentStatus.cancelled,
                    );
              } else {
                setState(() {
                  final original = _appointments.firstWhere(
                    (item) => item['id'] == appointment['id'],
                  );
                  original['lifecycleStatus'] = AppointmentStatus.cancelled;
                });
              }

              Navigator.pop(dialogContext);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Appointment cancelled successfully.'),
                ),
              );
            },
            child: const Text('Cancel appointment'),
          ),
        ],
      ),
    );
  }

  List<AppointmentStatus> _stepsFor(Map<String, dynamic> appointment) {
    return appointment['type'] == 'Home Visit'
        ? _homeVisitSteps
        : _otherConsultationSteps;
  }

  void _advanceStatus(
    Map<String, dynamic> appointment,
    AppointmentStatus nextStatus,
    StateSetter setSheetState,
  ) {
    final id = appointment['id'] as String;

    if (appointment['shared'] == true) {
      // Riverpod updates the shared appointment state.
      ref.read(appointmentProvider.notifier).updateStatus(id, nextStatus);
    } else {
      // Update the local demo appointment.
      setState(() {
        final original = _appointments.firstWhere((item) => item['id'] == id);
        original['lifecycleStatus'] = nextStatus;
      });

      // Immediately rebuild the bottom sheet for demo appointments.
      setSheetState(() {});
    }
  }

  void _showDetails(Map<String, dynamic> appointment) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Consumer(
              builder: (context, sheetRef, child) {
                // WATCH instead of READ so the sheet rebuilds on updates.
                final entries = sheetRef.watch(appointmentProvider);

                final currentStatus = appointment['shared'] == true
                    ? entries
                          .firstWhere(
                            (entry) =>
                                entry.appointment.id == appointment['id'],
                          )
                          .appointment
                          .status
                    : _currentStatus(appointment);

                final steps = _stepsFor(appointment);
                final isCancelled =
                    currentStatus == AppointmentStatus.cancelled;
                final currentIndex = steps.indexOf(currentStatus);
                final isCompleted =
                    currentStatus == AppointmentStatus.completed;
                final canAdvance =
                    !isCancelled && !isCompleted && currentIndex >= 0;

                final date = DateFormat(
                  'EEEE, d MMM yyyy',
                ).format(appointment['date'] as DateTime);

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
                          appointment['id'].toString(),
                        ),
                        _detailRow('Doctor', appointment['doctor'].toString()),
                        _detailRow(
                          'Specialty',
                          appointment['specialty'].toString(),
                        ),
                        _detailRow('Date', date),
                        _detailRow('Time', appointment['time'].toString()),
                        _detailRow(
                          'Consultation',
                          appointment['type'].toString(),
                        ),
                        _detailRow(
                          'Current Status',
                          _statusLabel(currentStatus),
                        ),

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
                            message: 'This appointment has been cancelled.',
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

                        if (isCompleted)
                          _terminalStatusMessage(
                            icon: Icons.check_circle_outline,
                            color: Colors.green.shade700,
                            message: 'This appointment is completed.',
                          ),

                        const SizedBox(height: 20),

                        if (canAdvance)
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () {
                                final nextIndex = currentIndex + 1;
                                if (nextIndex >= steps.length) return;

                                _advanceStatus(
                                  appointment,
                                  steps[nextIndex],
                                  setSheetState,
                                );
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: primaryTeal,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.arrow_forward),
                              label: Text(
                                'Advance to ${_statusLabel(steps[currentIndex + 1])}',
                              ),
                            ),
                          ),

                        const SizedBox(height: 10),
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
  }

  Widget _appointmentCard(Map<String, dynamic> appointment) {
    final status = appointment['status'] as String;
    final date = appointment['date'] as DateTime;
    final isUpcoming = status == 'Upcoming';

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
                Expanded(
                  child: FilledButton(
                    onPressed: () => _cancelAppointment(appointment),
                    style: FilledButton.styleFrom(
                      backgroundColor: primaryTeal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
