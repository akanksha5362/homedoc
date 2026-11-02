import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../shared/models/appointment_model.dart';
import '../../../../shared/providers/appointment_provider.dart';
import '../../../chat/presentation/providers/chat_provider.dart';
import '../providers/doctor_appointment_actions.dart';
import '../providers/doctor_location_provider.dart';

/// Doctor Today Dashboard (Master Prompt §11).
///
/// Features real-time appointments, pending visit requests, acceptance/rejection,
/// home visit live GPS broadcasting with consent controls, follow-up scheduling,
/// and unread patient chat integration.
class DoctorTodayPage extends ConsumerStatefulWidget {
  const DoctorTodayPage({super.key});

  @override
  ConsumerState<DoctorTodayPage> createState() => _DoctorTodayPageState();
}

class _DoctorTodayPageState extends ConsumerState<DoctorTodayPage> {
  static const Color teal = Color(0xFF078B8B);
  static const Color darkTeal = Color(0xFF075D63);
  static const Color lightTeal = Color(0xFFE8F7F6);
  static const Color pageBackground = Color(0xFFF5F9FA);
  static const Color textDark = Color(0xFF172B3A);
  static const Color headerNavy = Color(0xFF111827);
  static const Color headerIndigo = Color(0xFF312E81);

  String _selectedFilter = 'All';

  static final List<AppointmentModel> _mockFallback = [
    AppointmentModel(
      id: 'demo-appt-1',
      patientId: 'patient_rohan',
      patientName: 'Rohan Verma',
      doctorId: 'doc_1',
      doctorName: 'Dr. Practitioner',
      specialty: 'High fever and body ache (3 days)',
      type: ConsultationType.homeVisit,
      status: AppointmentStatus.booked,
      scheduledAt: DateTime.now().add(const Duration(hours: 1)),
    ),
    AppointmentModel(
      id: 'demo-appt-2',
      patientId: 'patient_priya',
      patientName: 'Priya Nair',
      doctorId: 'doc_1',
      doctorName: 'Dr. Practitioner',
      specialty: 'Post-consultation follow-up',
      type: ConsultationType.video,
      status: AppointmentStatus.doctorConfirmed,
      scheduledAt: DateTime.now().add(const Duration(hours: 3)),
    ),
    AppointmentModel(
      id: 'demo-appt-3',
      patientId: 'patient_amit',
      patientName: 'Amit Patel',
      doctorId: 'doc_1',
      doctorName: 'Dr. Practitioner',
      specialty: 'Hypertension checkup',
      type: ConsultationType.clinicVisit,
      status: AppointmentStatus.completed,
      scheduledAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
  ];

  String _formattedDate(DateTime date) {
    return DateFormat('EEEE, d MMMM y').format(date);
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning, Doctor';
    if (hour < 17) return 'Good afternoon, Doctor';
    return 'Good evening, Doctor';
  }

  @override
  Widget build(BuildContext context) {
    final liveAppointmentsAsync = ref.watch(doctorAppointmentsProvider);
    final conversationsAsync = ref.watch(userConversationsProvider);
    final locationState = ref.watch(doctorLocationProvider);

    // Merge live Firestore stream with demo fallback if live is empty
    final appointments = liveAppointmentsAsync.when(
      data: (list) => list.isNotEmpty ? list : _mockFallback,
      loading: () => _mockFallback,
      error: (_, _) => _mockFallback,
    );

    // Compute total unread patient messages for doctor
    final unreadMessagesCount = conversationsAsync.when(
      data: (convs) => convs.fold<int>(0, (sum, c) => sum + c.unreadCountDoctor),
      loading: () => 0,
      error: (_, _) => 0,
    );

    final homeVisits = appointments.where((a) => a.type == ConsultationType.homeVisit).length;
    final videoConsultations = appointments.where((a) => a.type == ConsultationType.video).length;
    final pendingRequests = appointments.where((a) => a.status == AppointmentStatus.booked).length;

    // Filter appointments
    final filteredAppointments = appointments.where((a) {
      if (_selectedFilter == 'Pending') return a.status == AppointmentStatus.booked;
      if (_selectedFilter == 'Confirmed') return a.status == AppointmentStatus.doctorConfirmed || a.status == AppointmentStatus.onTheWay || a.status == AppointmentStatus.arrived || a.status == AppointmentStatus.inConsultation;
      if (_selectedFilter == 'Home Visits') return a.type == ConsultationType.homeVisit;
      if (_selectedFilter == 'Completed') return a.status == AppointmentStatus.completed;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: pageBackground,
      bottomNavigationBar: _buildBottomNavigation(context, unreadCount: unreadMessagesCount),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _buildHeader(context, appointments.length),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Active GPS Location Broadcasting Banner
                  if (locationState.isSharing) ...[
                    _buildActiveTrackingBanner(context, locationState),
                    const SizedBox(height: 20),
                  ],

                  // Overview & Stats Section
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          "Today's Overview",
                          style: TextStyle(
                            color: textDark,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: lightTeal,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.circle, size: 7, color: teal),
                            const SizedBox(width: 6),
                            Text(
                              DateFormat('d MMM').format(DateTime.now()),
                              style: const TextStyle(
                                color: darkTeal,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 4 Quick Stats
                  Row(
                    children: [
                      Expanded(
                        child: _statCard(
                          title: 'Total Visits',
                          value: '${appointments.length}',
                          subtitle: '$pendingRequests pending',
                          icon: Icons.calendar_month_rounded,
                          color: teal,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _statCard(
                          title: 'Home Visits',
                          value: '$homeVisits',
                          subtitle: locationState.isSharing ? 'Live GPS Active' : 'Coverage enabled',
                          icon: Icons.home_work_rounded,
                          color: const Color(0xFF2563EB),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _statCard(
                          title: 'Video Consults',
                          value: '$videoConsultations',
                          subtitle: 'Telehealth room',
                          icon: Icons.videocam_rounded,
                          color: const Color(0xFF7C3AED),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => context.push(RoutePaths.doctorChatList),
                          child: _statCard(
                            title: 'Patient Messages',
                            value: '$unreadMessagesCount',
                            subtitle: unreadMessagesCount > 0 ? 'Unread replies' : 'All caught up',
                            icon: Icons.chat_bubble_rounded,
                            color: const Color(0xFFEA580C),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Quick Operational Actions
                  Row(
                    children: [
                      Expanded(
                        child: _quickAction(
                          icon: Icons.event_available_rounded,
                          title: 'Manage Schedule',
                          subtitle: 'Weekly slots & fees',
                          onTap: () => context.push(RoutePaths.doctorAvailability),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _quickAction(
                          icon: Icons.forum_rounded,
                          title: 'Patient Chats',
                          subtitle: '$unreadMessagesCount unread messages',
                          onTap: () => context.push(RoutePaths.doctorChatList),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),

                  // Interactive Filter Tabs
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Consultations Queue',
                        style: TextStyle(
                          color: textDark,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${filteredAppointments.length} visits',
                        style: const TextStyle(color: Colors.blueGrey, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildFilterChips(appointments),
                  const SizedBox(height: 16),

                  // Appointments List
                  if (filteredAppointments.isEmpty)
                    _buildEmptyQueueState()
                  else
                    for (final appt in filteredAppointments)
                      _buildDoctorAppointmentCard(context, appt, locationState),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. HEADER SECTION
  // ---------------------------------------------------------------------------
  Widget _buildHeader(BuildContext context, int count) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [headerNavy, headerIndigo],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.medical_services_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _greeting(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formattedDate(DateTime.now()),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                ),
                icon: const Icon(Icons.person_rounded, color: Colors.white, size: 20),
                onPressed: () => context.go(RoutePaths.doctorProfile),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF34D399), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    count > 0
                        ? 'You have $count consultations scheduled for today.'
                        : 'No appointments scheduled today. Availability is active.',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. ACTIVE LOCATION SHARING BANNER
  // ---------------------------------------------------------------------------
  Widget _buildActiveTrackingBanner(BuildContext context, DoctorLocationState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.4), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFF2563EB),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.navigation_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text(
                      'Live GPS Sharing Active',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.circle, color: Color(0xFF10B981), size: 8),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Broadcasting real-time visit ETA to patient for visit #${state.activeAppointmentId}',
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF3B82F6)),
                ),
              ],
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFDC2626),
              textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
            onPressed: () => ref.read(doctorLocationProvider.notifier).stopBroadcasting(),
            child: const Text('Stop Sharing'),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. FILTER CHIPS
  // ---------------------------------------------------------------------------
  Widget _buildFilterChips(List<AppointmentModel> all) {
    final filters = ['All', 'Pending', 'Confirmed', 'Home Visits', 'Completed'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (final filter in filters)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(filter),
                selected: _selectedFilter == filter,
                selectedColor: teal,
                labelStyle: TextStyle(
                  color: _selectedFilter == filter ? Colors.white : textDark,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: _selectedFilter == filter ? teal : const Color(0xFFE2E8F0),
                ),
                onSelected: (val) {
                  if (val) setState(() => _selectedFilter = filter);
                },
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. DOCTOR APPOINTMENT CARD
  // ---------------------------------------------------------------------------
  Widget _buildDoctorAppointmentCard(
    BuildContext context,
    AppointmentModel appt,
    DoctorLocationState locationState,
  ) {
    final (typeLabel, typeColor, typeBg, typeIcon) = switch (appt.type) {
      ConsultationType.homeVisit => (
          'Home Visit',
          const Color(0xFF2563EB),
          const Color(0xFFEFF6FF),
          Icons.home_outlined
        ),
      ConsultationType.video => (
          'Video Consult',
          const Color(0xFF7C3AED),
          const Color(0xFFF5F3FF),
          Icons.videocam_outlined
        ),
      ConsultationType.clinicVisit => (
          'Clinic Visit',
          teal,
          lightTeal,
          Icons.local_hospital_outlined
        ),
    };

    final isSharingThis = locationState.isSharing && locationState.activeAppointmentId == appt.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSharingThis ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
          width: isSharingThis ? 1.5 : 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Type + Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: typeBg, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    Icon(typeIcon, size: 14, color: typeColor),
                    const SizedBox(width: 5),
                    Text(
                      typeLabel,
                      style: TextStyle(color: typeColor, fontSize: 11.5, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              _buildStatusPill(appt.status),
            ],
          ),
          const SizedBox(height: 12),

          // Patient Name & Clinical Complaint
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: lightTeal,
                foregroundColor: teal,
                child: Text(
                  appt.patientName.isNotEmpty ? appt.patientName[0].toUpperCase() : 'P',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appt.patientName.isNotEmpty ? appt.patientName : 'Patient Visit',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      appt.specialty,
                      style: const TextStyle(fontSize: 12.5, color: Colors.blueGrey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Scheduled Time
          Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 16, color: Colors.blueGrey),
              const SizedBox(width: 6),
              Text(
                DateFormat('hh:mm a').format(appt.scheduledAt),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textDark),
              ),
              const Spacer(),
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: teal,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                label: const Text('Message', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                onPressed: () {
                  context.push(
                    '${RoutePaths.patientChatConversation}?conversationId=${appt.id}&doctorId=${appt.doctorId}&doctorName=${Uri.encodeComponent(appt.doctorName)}&specialty=${Uri.encodeComponent(appt.specialty)}&appointmentId=${appt.id}',
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Contextual Action Buttons
          _buildActionButtons(context, appt, isSharingThis),
        ],
      ),
    );
  }

  Widget _buildStatusPill(AppointmentStatus status) {
    final (label, color, bg) = switch (status) {
      AppointmentStatus.booked => ('Pending Request', const Color(0xFFD97706), const Color(0xFFFEF3C7)),
      AppointmentStatus.doctorConfirmed => ('Confirmed', const Color(0xFF2563EB), const Color(0xFFEFF6FF)),
      AppointmentStatus.preparing => ('Preparing', const Color(0xFF7C3AED), const Color(0xFFF5F3FF)),
      AppointmentStatus.onTheWay => ('On the Way', const Color(0xFF0284C7), const Color(0xFFE0F2FE)),
      AppointmentStatus.arriving => ('Arriving', const Color(0xFF0284C7), const Color(0xFFE0F2FE)),
      AppointmentStatus.arrived => ('Arrived', const Color(0xFF059669), const Color(0xFFECFDF5)),
      AppointmentStatus.inConsultation => ('In Consultation', const Color(0xFF0D9488), const Color(0xFFCCFBF1)),
      AppointmentStatus.completed => ('Completed', const Color(0xFF10B981), const Color(0xFFD1FAE5)),
      AppointmentStatus.rejected => ('Declined', const Color(0xFFDC2626), const Color(0xFFFEE2E2)),
      AppointmentStatus.cancelled => ('Cancelled', const Color(0xFF6B7280), const Color(0xFFF3F4F6)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, AppointmentModel appt, bool isSharingThis) {
    final actions = ref.read(doctorAppointmentActionsProvider);

    // 1. Pending Request -> Accept / Decline
    if (appt.status == AppointmentStatus.booked) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFDC2626),
                side: const BorderSide(color: Color(0xFFFCA5A5)),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => _showRejectDialog(context, appt.id),
              child: const Text('Decline', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                await actions.acceptAppointment(appt.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Appointment confirmed.')),
                  );
                }
              },
              child: const Text('Accept Visit', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      );
    }

    // 2. Confirmed Home Visit
    if (appt.type == ConsultationType.homeVisit &&
        (appt.status == AppointmentStatus.doctorConfirmed || appt.status == AppointmentStatus.onTheWay)) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isSharingThis ? const Color(0xFFDC2626) : const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: Icon(isSharingThis ? Icons.stop_rounded : Icons.navigation_rounded, size: 16),
              label: Text(
                isSharingThis ? 'Stop Live GPS' : 'Share Live GPS',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              onPressed: () => _toggleLocationSharing(context, appt, isSharingThis),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: teal,
                side: const BorderSide(color: teal),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => actions.updateStatus(appt.id, AppointmentStatus.arrived),
              child: const Text('Mark Arrived', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      );
    }

    // 3. Video Consultation Confirmed
    if (appt.type == ConsultationType.video && appt.status == AppointmentStatus.doctorConfirmed) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7C3AED),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 11),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
          icon: const Icon(Icons.videocam_rounded, size: 18),
          label: const Text('Join Video Consultation Room', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          onPressed: () {
            context.push(
              RoutePaths.patientVideoConsultation,
              extra: {
                'appointmentId': appt.id,
                'doctorId': appt.doctorId,
                'doctorName': appt.doctorName,
                'specialty': appt.specialty,
                'isDoctor': true,
              },
            );
          },
        ),
      );
    }

    // 4. In Consultation -> Complete & Recommend Follow-Up
    if (appt.status == AppointmentStatus.inConsultation || appt.status == AppointmentStatus.arrived) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0284C7),
                side: const BorderSide(color: Color(0xFF0284C7)),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.edit_calendar_rounded, size: 16),
              label: const Text('Follow-Up', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              onPressed: () => _showFollowUpDialog(context, appt.id),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.check_circle_rounded, size: 16),
              label: const Text('Finish Visit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              onPressed: () async {
                await actions.updateStatus(appt.id, AppointmentStatus.completed);
                if (isSharingThis) {
                  await ref.read(doctorLocationProvider.notifier).stopBroadcasting();
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Consultation completed.')),
                  );
                }
              },
            ),
          ),
        ],
      );
    }

    // 5. Completed
    if (appt.status == AppointmentStatus.completed) {
      return OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF0284C7),
          side: const BorderSide(color: Color(0xFFBAE6FD)),
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: const Icon(Icons.schedule_rounded, size: 16),
        label: const Text('Recommend Follow-Up Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        onPressed: () => _showFollowUpDialog(context, appt.id),
      );
    }

    return const SizedBox.shrink();
  }

  void _toggleLocationSharing(BuildContext context, AppointmentModel appt, bool isSharingThis) async {
    final notifier = ref.read(doctorLocationProvider.notifier);

    if (isSharingThis) {
      await notifier.stopBroadcasting();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Live GPS broadcasting stopped.')),
        );
      }
    } else {
      // Consent prompt before broadcasting
      final consent = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.share_location_rounded, color: Color(0xFF2563EB)),
              SizedBox(width: 8),
              Text('Doctor Location Sharing'),
            ],
          ),
          content: const Text(
            'You are about to broadcast your real-time GPS coordinates to the patient for this home visit.\n\nCoordinates will only be shared while you are on the way and automatically stop once the visit is completed.',
            style: TextStyle(fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Start Sharing'),
            ),
          ],
        ),
      );

      if (consent == true) {
        final success = await notifier.startBroadcasting(
          appointmentId: appt.id,
          doctorId: appt.doctorId,
        );
        if (context.mounted && !success) {
          final err = ref.read(doctorLocationProvider).errorMessage;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err ?? 'Could not start location sharing.')),
          );
        }
      }
    }
  }

  void _showRejectDialog(BuildContext context, String apptId) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Decline Appointment Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please provide a brief reason for declining (e.g. slot conflict, out of coverage):',
              style: TextStyle(fontSize: 13, color: Colors.blueGrey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Reason for declining…',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () async {
              final reason = reasonController.text.trim();
              await ref.read(doctorAppointmentActionsProvider).rejectAppointment(
                    apptId,
                    reason.isNotEmpty ? reason : 'Slot unavailable',
                  );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Confirm Decline'),
          ),
        ],
      ),
    );
  }

  void _showFollowUpDialog(BuildContext context, String apptId) {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.calendar_month_rounded, color: teal),
              SizedBox(width: 8),
              Text('Recommend Follow-Up'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Recommended Date:', style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 180)),
                    );
                    if (picked != null) {
                      setModalState(() => selectedDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.event, size: 18, color: teal),
                        const SizedBox(width: 8),
                        Text(DateFormat('EEE, d MMM y').format(selectedDate)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Clinical Notes & Instructions:', style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
                const SizedBox(height: 6),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Review blood pressure, check response to medication…',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: teal),
              onPressed: () async {
                await ref.read(doctorAppointmentActionsProvider).recommendFollowUp(
                      appointmentId: apptId,
                      followUpDate: selectedDate,
                      clinicalNotes: notesController.text.trim(),
                    );
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Follow-up instructions saved.')),
                  );
                }
              },
              child: const Text('Save Recommendation'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyQueueState() {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.event_available_rounded, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text(
            'No visits in this queue',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textDark),
          ),
          const SizedBox(height: 4),
          const Text(
            'Switch filters or review availability settings.',
            style: TextStyle(color: Colors.blueGrey, fontSize: 12.5),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5. STATS & QUICK ACTIONS
  // ---------------------------------------------------------------------------
  Widget _statCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Color(0x05000000), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: textDark,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(color: textDark, fontSize: 12.5, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.blueGrey, fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: lightTeal,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: teal, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(color: textDark, fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.blueGrey, fontSize: 11),
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

  // ---------------------------------------------------------------------------
  // 6. BOTTOM NAVIGATION BAR
  // ---------------------------------------------------------------------------
  Widget _buildBottomNavigation(BuildContext context, {required int unreadCount}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.blueGrey.withValues(alpha: 0.12))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _navItem(
              icon: Icons.home_rounded,
              label: 'Today',
              selected: true,
              onTap: () {},
            ),
            _navItem(
              icon: Icons.chat_bubble_outline_rounded,
              label: 'Chats',
              badgeCount: unreadCount,
              selected: false,
              onTap: () => context.push(RoutePaths.doctorChatList),
            ),
            _navItem(
              icon: Icons.event_available_outlined,
              label: 'Availability',
              selected: false,
              onTap: () => context.push(RoutePaths.doctorAvailability),
            ),
            _navItem(
              icon: Icons.person_outline_rounded,
              label: 'Profile',
              selected: false,
              onTap: () => context.go(RoutePaths.doctorProfile),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Badge(
                isLabelVisible: badgeCount > 0,
                label: Text('$badgeCount'),
                backgroundColor: teal,
                child: Icon(
                  icon,
                  color: selected ? teal : Colors.blueGrey,
                  size: 22,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: selected ? teal : Colors.blueGrey,
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
              if (selected)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  width: 24,
                  height: 3,
                  decoration: BoxDecoration(
                    color: teal,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
