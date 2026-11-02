import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../shared/healthcare/appointment_status_badge.dart';
import '../../../../shared/models/appointment_model.dart';
import '../../../../shared/providers/appointment_provider.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../continuity/data/models/follow_up_reminder_model.dart';
import '../../../continuity/presentation/providers/follow_up_provider.dart';

/// Premium, modern Patient Dashboard for HomeDoc AI.
class PatientHomePage extends ConsumerStatefulWidget {
  const PatientHomePage({super.key});

  @override
  ConsumerState<PatientHomePage> createState() => _PatientHomePageState();
}

class _PatientHomePageState extends ConsumerState<PatientHomePage> {
  final TextEditingController _searchController = TextEditingController();

  // Primary brand palette
  static const Color primaryTeal = Color(0xFF007A8A);
  static const Color lightTealSurface = Color(0xFFE8F7F6);
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color textDark = Color(0xFF111827);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color cardBorder = Color(0xFFE5E7EB);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _greetingText() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;

    final displayName = user?.displayName?.trim() ?? '';
    final firstName = displayName.isNotEmpty
        ? displayName.split(' ').first
        : null;
    final greeting = firstName != null
        ? '${_greetingText()}, $firstName 👋'
        : '${_greetingText()} 👋';

    // Watch real-time patient appointments
    final appointmentsAsync = ref.watch(patientAppointmentsProvider);
    final followUps = ref.watch(followUpRemindersProvider);
    final pendingFollowUp = followUps
        .where((item) => item.status == FollowUpStatus.pending)
        .firstOrNull;

    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: _buildAppBar(context, user?.displayName),
      bottomNavigationBar: _buildBottomNavigationBar(context, selectedIndex: 0),
      body: SafeArea(
        child: RefreshIndicator(
          color: primaryTeal,
          onRefresh: () async {
            ref.invalidate(patientAppointmentsProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Personalized Welcome Section
                _buildWelcomeSection(greeting),
                const SizedBox(height: 20),

                // 2. Doctor & Specialist Search Bar
                _buildSearchBar(context),
                const SizedBox(height: 24),

                // 3. Compact Horizontal Feature Strip (replaces 2x2 grid)
                _buildFeatureStrip(context),
                const SizedBox(height: 28),

                // 4. Meaningful Upcoming Appointment Section
                _buildUpcomingAppointmentSection(context, appointmentsAsync),
                const SizedBox(height: 28),

                // 4b. Follow-Up & Appointment Continuity Banner
                if (pendingFollowUp != null) ...[
                  _buildFollowUpBanner(context, pendingFollowUp),
                  const SizedBox(height: 28),
                ],

                // 5. Compact Health Overview Snapshot
                _buildHealthSnapshotSection(context, appointmentsAsync),
                const SizedBox(height: 24),

                // 6. Emergency Assistance Banner
                _buildEmergencyBanner(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // 1. APP BAR
  // ------------------------------------------------------------
  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    String? userDisplayName,
  ) {
    final initial =
        (userDisplayName != null && userDisplayName.trim().isNotEmpty)
        ? userDisplayName.trim()[0].toUpperCase()
        : 'U';

    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleSpacing: 20,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: lightTealSurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.health_and_safety_rounded,
              color: primaryTeal,
              size: 24,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'HomeDoc AI',
            style: TextStyle(
              color: textDark,
              fontWeight: FontWeight.w700,
              fontSize: 20,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Doctor messages',
          onPressed: () => context.push(RoutePaths.patientChatList),
          icon: const Icon(
            Icons.chat_bubble_outline_rounded,
            color: textDark,
            size: 23,
          ),
        ),
        IconButton(
          tooltip: 'Notifications',
          onPressed: () => context.push(RoutePaths.patientNotifications),
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(
                Icons.notifications_none_rounded,
                color: textDark,
                size: 26,
              ),
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16, left: 4),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => context.go(RoutePaths.patientProfile),
            child: CircleAvatar(
              radius: 17,
              backgroundColor: lightTealSurface,
              child: Text(
                initial,
                style: const TextStyle(
                  color: primaryTeal,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // 2. WELCOME SECTION
  // ------------------------------------------------------------
  Widget _buildWelcomeSection(String greeting) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: const TextStyle(
            color: textDark,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Your health, our priority.',
          style: TextStyle(
            color: textMuted,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // 3. SEARCH BAR
  // ------------------------------------------------------------
  Widget _buildSearchBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        onSubmitted: (query) {
          final trimmed = query.trim();
          if (trimmed.isNotEmpty) {
            context.push(
              '${RoutePaths.patientAiSearch}?query=${Uri.encodeComponent(trimmed)}',
            );
          } else {
            context.push(RoutePaths.patientAiSearch);
          }
        },
        decoration: InputDecoration(
          hintText: 'Search health concerns, doctors, symptoms...',
          hintStyle: const TextStyle(
            color: textMuted,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: primaryTeal,
            size: 22,
          ),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'AI Health Search',
                onPressed: () => context.push(RoutePaths.patientAiSearch),
                icon: const Icon(
                  Icons.auto_awesome,
                  color: primaryTeal,
                  size: 20,
                ),
              ),
              IconButton(
                tooltip: 'Explore specialists',
                onPressed: () => context.go(RoutePaths.patientCare),
                icon: const Icon(
                  Icons.tune_rounded,
                  color: textMuted,
                  size: 20,
                ),
              ),
            ],
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // 4. HORIZONTALLY SCROLLABLE FEATURE STRIP
  // ------------------------------------------------------------
  Widget _buildFeatureStrip(BuildContext context) {
    final features = [
      _FeatureItem(
        title: 'Appointments',
        icon: Icons.calendar_month_rounded,
        iconColor: const Color(0xFF007A8A),
        backgroundColor: const Color(0xFFE6F7F6),
        onTap: () => context.go(RoutePaths.patientAppointments),
      ),
      _FeatureItem(
        title: 'Health Search',
        icon: Icons.saved_search_rounded,
        iconColor: const Color(0xFF0284C7),
        backgroundColor: const Color(0xFFE0F2FE),
        onTap: () => context.push(RoutePaths.patientAiSearch),
      ),
      _FeatureItem(
        title: 'Find Doctors',
        icon: Icons.person_search_rounded,
        iconColor: const Color(0xFF2563EB),
        backgroundColor: const Color(0xFFEFF6FF),
        onTap: () => context.go(RoutePaths.patientCare),
      ),
      _FeatureItem(
        title: 'AI Assistant',
        icon: Icons.auto_awesome_rounded,
        iconColor: const Color(0xFF7C3AED),
        backgroundColor: const Color(0xFFF5F3FF),
        onTap: () => context.push(RoutePaths.patientAiAssistant),
      ),
      _FeatureItem(
        title: 'Doctor Chat',
        icon: Icons.chat_bubble_rounded,
        iconColor: const Color(0xFF0D9488),
        backgroundColor: const Color(0xFFCCFBF1),
        onTap: () => context.push(RoutePaths.patientChatList),
      ),
      _FeatureItem(
        title: 'Video Consult',
        icon: Icons.videocam_rounded,
        iconColor: const Color(0xFF0284C7),
        backgroundColor: const Color(0xFFE0F2FE),
        onTap: () => context.push(RoutePaths.patientVideoConsultation),
      ),
      _FeatureItem(
        title: 'Med Reminders',
        icon: Icons.alarm_rounded,
        iconColor: const Color(0xFFEA580C),
        backgroundColor: const Color(0xFFFFF7ED),
        onTap: () => context.push(RoutePaths.patientReminders),
      ),
      _FeatureItem(
        title: 'Health Records',
        icon: Icons.folder_shared_rounded,
        iconColor: const Color(0xFF059669),
        backgroundColor: const Color(0xFFECFDF5),
        onTap: () => context.go(RoutePaths.patientHealth),
      ),
      _FeatureItem(
        title: 'Symptom Triage',
        icon: Icons.spa_rounded,
        iconColor: const Color(0xFFD97706),
        backgroundColor: const Color(0xFFFFFBEB),
        onTap: () => context.push(RoutePaths.patientAiCare),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Quick Services',
              style: TextStyle(
                color: textDark,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => context.go(RoutePaths.patientCare),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  children: [
                    Text(
                      'Explore',
                      style: TextStyle(
                        color: primaryTeal,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 11,
                      color: primaryTeal,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 98,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: features.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = features[index];
              return _buildFeatureChip(item);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureChip(_FeatureItem item) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 86,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder),
          boxShadow: const [
            BoxShadow(
              color: Color(0x04000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: item.backgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(item.icon, color: item.iconColor, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              item.title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: textDark,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // 5. UPCOMING APPOINTMENT SECTION (Live Firestore Data)
  // ------------------------------------------------------------
  Widget _buildUpcomingAppointmentSection(
    BuildContext context,
    AsyncValue<List<Map<String, dynamic>>> appointmentsAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Upcoming Appointment',
              style: TextStyle(
                color: textDark,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextButton(
              onPressed: () => context.go(RoutePaths.patientAppointments),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'View all',
                style: TextStyle(
                  color: primaryTeal,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        appointmentsAsync.when(
          data: (appointments) {
            final upcoming =
                appointments.where((apt) {
                  final status = apt['lifecycleStatus'] as AppointmentStatus;
                  return status != AppointmentStatus.completed &&
                      status != AppointmentStatus.cancelled &&
                      status != AppointmentStatus.rejected;
                }).toList()..sort(
                  (a, b) =>
                      (a['date'] as DateTime).compareTo(b['date'] as DateTime),
                );

            if (upcoming.isEmpty) {
              return _buildNoAppointmentCard(context);
            }

            final nextAppointment = upcoming.first;
            return _buildActiveAppointmentCard(context, nextAppointment);
          },
          loading: () => _buildAppointmentLoadingCard(),
          error: (err, _) => _buildAppointmentErrorCard(),
        ),
      ],
    );
  }

  Widget _buildActiveAppointmentCard(
    BuildContext context,
    Map<String, dynamic> appointment,
  ) {
    final doctorName = appointment['doctor'] as String? ?? 'Doctor';
    final specialty = appointment['specialty'] as String? ?? 'General Medicine';
    final date = appointment['date'] as DateTime;
    final formattedTime =
        appointment['time'] as String? ?? DateFormat('hh:mm a').format(date);
    final status = appointment['lifecycleStatus'] as AppointmentStatus;
    final typeLabel = appointment['type'] as String? ?? 'Clinic Visit';
    final icon =
        appointment['icon'] as IconData? ?? Icons.local_hospital_outlined;

    final isToday = DateUtils.isSameDay(date, DateTime.now());
    final dateDisplay = isToday
        ? 'Today, $formattedTime'
        : '${DateFormat('MMM d').format(date)}, $formattedTime';

    final isHomeVisitActive =
        (status == AppointmentStatus.onTheWay ||
        status == AppointmentStatus.arriving ||
        status == AppointmentStatus.arrived);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => context.go(RoutePaths.patientAppointments),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // In-progress banner if home visit is travelling
                if (isHomeVisitActive) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: lightTealSurface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.directions_run_rounded,
                          color: primaryTeal,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Doctor is on the way for your home consultation',
                            style: TextStyle(
                              color: primaryTeal,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Doctor Information and Status
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 24,
                      backgroundColor: lightTealSurface,
                      child: Icon(
                        Icons.person_rounded,
                        color: primaryTeal,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doctorName,
                            style: const TextStyle(
                              color: textDark,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            specialty,
                            style: const TextStyle(
                              color: textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppointmentStatusBadge(status: status),
                  ],
                ),

                const SizedBox(height: 14),
                const Divider(height: 1, color: cardBorder),
                const SizedBox(height: 12),

                // Appointment Meta Details (Schedule & Consultation Type)
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            size: 16,
                            color: primaryTeal,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              dateDisplay,
                              style: const TextStyle(
                                color: textDark,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Icon(icon, size: 16, color: textMuted),
                        const SizedBox(width: 6),
                        Text(
                          typeLabel,
                          style: const TextStyle(
                            color: textMuted,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                if (appointment['consultationType'] == 'video' ||
                    typeLabel.toLowerCase().contains('video')) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: primaryTeal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        context.push(
                          RoutePaths.patientVideoConsultation,
                          extra: appointment,
                        );
                      },
                      icon: const Icon(Icons.videocam_rounded, size: 18),
                      label: const Text(
                        'Join Video Consultation',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoAppointmentCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: lightTealSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.event_available_rounded,
                  color: primaryTeal,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No upcoming appointments',
                      style: TextStyle(
                        color: textDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Need care? Book a clinic, home, or video visit.',
                      style: TextStyle(color: textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => context.push(RoutePaths.patientBookAppointment),
              style: FilledButton.styleFrom(
                backgroundColor: primaryTeal,
                foregroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text(
                'Book an appointment',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentLoadingCard() {
    return Container(
      width: double.infinity,
      height: 110,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorder),
      ),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: primaryTeal,
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentErrorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorder),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: textMuted, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Unable to load appointments. Please check connection.',
              style: TextStyle(color: textMuted, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowUpBanner(
    BuildContext context,
    FollowUpReminderModel followUp,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBBF7D0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.event_repeat_rounded,
                  color: Color(0xFF16A34A),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      followUp.isDoctorRecommended
                          ? 'Recommended Follow-Up'
                          : 'Scheduled Follow-Up Reminder',
                      style: const TextStyle(
                        color: Color(0xFF14532D),
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                    Text(
                      'With ${followUp.doctorName} (${followUp.doctorSpecialty})',
                      style: const TextStyle(
                        color: Color(0xFF166534),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Dismiss reminder',
                icon: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: textMuted,
                ),
                onPressed: () {
                  ref
                      .read(followUpRemindersProvider.notifier)
                      .dismissReminder(followUp.id);
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Target Date: ${followUp.formattedTargetDate}',
            style: const TextStyle(
              color: textDark,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (followUp.reason.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              followUp.reason,
              style: const TextStyle(color: textMuted, fontSize: 12),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: primaryTeal,
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                context.push(
                  '${RoutePaths.patientBookAppointment}?doctorId=${followUp.doctorId}',
                  extra: followUp.doctorId,
                );
              },
              icon: const Icon(Icons.event_available_rounded, size: 16),
              label: Text('Book Consultation with ${followUp.doctorName}'),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // 6. COMPACT HEALTH SNAPSHOT SECTION
  // ------------------------------------------------------------
  Widget _buildHealthSnapshotSection(
    BuildContext context,
    AsyncValue<List<Map<String, dynamic>>> appointmentsAsync,
  ) {
    final appointmentCount = appointmentsAsync.maybeWhen(
      data: (list) => list
          .where(
            (a) =>
                a['lifecycleStatus'] != AppointmentStatus.completed &&
                a['lifecycleStatus'] != AppointmentStatus.cancelled &&
                a['lifecycleStatus'] != AppointmentStatus.rejected,
          )
          .length,
      orElse: () => 0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Health Overview',
          style: TextStyle(
            color: textDark,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSnapshotCard(
                title: 'Active Visits',
                value: '$appointmentCount',
                subtitle: appointmentCount == 1
                    ? 'Upcoming booking'
                    : 'Upcoming bookings',
                icon: Icons.calendar_today_rounded,
                color: primaryTeal,
                onTap: () => context.go(RoutePaths.patientAppointments),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSnapshotCard(
                title: 'Health Vault',
                value: 'Records',
                subtitle: 'Prescriptions & tests',
                icon: Icons.assignment_outlined,
                color: const Color(0xFF2563EB),
                onTap: () => context.go(RoutePaths.patientHealth),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSnapshotCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
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
            border: Border.all(color: cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(icon, size: 18, color: color),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  color: textDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: textMuted, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // 7. EMERGENCY ASSISTANCE BANNER
  // ------------------------------------------------------------
  Widget _buildEmergencyBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(RoutePaths.patientEmergency),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1F2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFECDD3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF43F5E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.emergency_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Emergency SOS',
                    style: TextStyle(
                      color: Color(0xFF9F1239),
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Tap to alert contacts, dial 112/108, or get emergency help.',
                    style: TextStyle(
                      color: Color(0xFFBE123C),
                      fontSize: 11.5,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFBE123C),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // 8. BOTTOM NAVIGATION BAR
  // ------------------------------------------------------------
  Widget _buildBottomNavigationBar(
    BuildContext context, {
    required int selectedIndex,
  }) {
    return NavigationBar(
      selectedIndex: selectedIndex,
      backgroundColor: Colors.white,
      indicatorColor: lightTealSurface,
      elevation: 3,
      onDestinationSelected: (index) {
        if (index == selectedIndex) return;
        switch (index) {
          case 0:
            context.go(RoutePaths.patientHome);
            break;
          case 1:
            context.go(RoutePaths.patientCare);
            break;
          case 2:
            context.go(RoutePaths.patientAppointments);
            break;
          case 3:
            context.go(RoutePaths.patientHealth);
            break;
          case 4:
            context.go(RoutePaths.patientProfile);
            break;
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded, color: primaryTeal),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.explore_outlined),
          selectedIcon: Icon(Icons.explore_rounded, color: primaryTeal),
          label: 'Explore',
        ),
        NavigationDestination(
          icon: Icon(Icons.calendar_today_outlined),
          selectedIcon: Icon(Icons.calendar_today_rounded, color: primaryTeal),
          label: 'Visits',
        ),
        NavigationDestination(
          icon: Icon(Icons.shield_outlined),
          selectedIcon: Icon(Icons.shield_rounded, color: primaryTeal),
          label: 'Health',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded, color: primaryTeal),
          label: 'Profile',
        ),
      ],
    );
  }


}

class _FeatureItem {
  const _FeatureItem({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final VoidCallback onTap;
}
