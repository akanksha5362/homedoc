import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../shared/providers/doctor_provider.dart';

/// Doctor Discovery and Medical Specialist Directory for HomeDoc AI.
class CarePage extends ConsumerStatefulWidget {
  const CarePage({super.key});

  @override
  ConsumerState<CarePage> createState() => _CarePageState();
}

class _CarePageState extends ConsumerState<CarePage> {
  final TextEditingController _searchController = TextEditingController();

  String _selectedSpecialty = 'All';
  String _sortBy = 'Recommended';

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

  @override
  Widget build(BuildContext context) {
    final doctorsAsync = ref.watch(verifiedDoctorsProvider);

    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: _buildAppBar(),
      bottomNavigationBar: _buildBottomNavigationBar(context, selectedIndex: 1),
      body: SafeArea(
        child: RefreshIndicator(
          color: primaryTeal,
          onRefresh: () async {
            ref.invalidate(verifiedDoctorsProvider);
          },
          child: doctorsAsync.when(
            data: (allDoctors) {
              // Extract unique specialties dynamically from live Firestore doctors
              final specialties = ['All'];
              for (final doc in allDoctors) {
                final sp = doc['specialization'] as String? ?? doc['specialty'] as String?;
                if (sp != null && sp.isNotEmpty && !specialties.contains(sp)) {
                  specialties.add(sp);
                }
              }

              // Filter doctors
              final query = _searchController.text.trim().toLowerCase();
              final filtered = allDoctors.where((doctor) {
                final specialty = (doctor['specialization'] as String? ??
                        doctor['specialty'] as String? ??
                        '')
                    .toLowerCase();
                final name = (doctor['displayName'] as String? ??
                        doctor['name'] as String? ??
                        '')
                    .toLowerCase();
                final hospital =
                    (doctor['hospital'] as String? ?? '').toLowerCase();
                final location =
                    (doctor['location'] as String? ?? '').toLowerCase();

                final matchesSpecialty = _selectedSpecialty == 'All' ||
                    (doctor['specialization'] == _selectedSpecialty ||
                        doctor['specialty'] == _selectedSpecialty);

                final matchesQuery = query.isEmpty ||
                    name.contains(query) ||
                    specialty.contains(query) ||
                    hospital.contains(query) ||
                    location.contains(query);

                return matchesSpecialty && matchesQuery;
              }).toList();

              // Sort doctors
              if (_sortBy == 'Most experienced') {
                filtered.sort((a, b) => ((b['experienceYears'] as num?) ?? 0)
                    .compareTo((a['experienceYears'] as num?) ?? 0));
              } else if (_sortBy == 'Lowest fee') {
                filtered.sort((a, b) => ((a['consultationFee'] as num?) ?? 0)
                    .compareTo((b['consultationFee'] as num?) ?? 0));
              } else if (_sortBy == 'Doctor name') {
                filtered.sort((a, b) => (a['name'] as String? ?? '')
                    .compareTo(b['name'] as String? ?? ''));
              }

              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics()),
                slivers: [
                  // 1. Header & Title
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Find Medical Specialists',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: textDark,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Consult certified doctors for home, clinic, or video visits.',
                            style: TextStyle(
                              fontSize: 13.5,
                              color: textMuted,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Search input
                          _buildSearchField(),
                          const SizedBox(height: 14),

                          // AI Tools: Symptom Checker + AI Health Search
                          _buildAiToolsStrip(context),
                          const SizedBox(height: 20),

                          // Specialty Filter Chips
                          _buildSpecialtyFilterRow(specialties, allDoctors),
                          const SizedBox(height: 16),

                          // Results Counter & Sorting Action
                          _buildResultsHeader(filtered.length),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),

                  // 2. Doctor Directory Cards
                  if (filtered.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final doctor = filtered[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _buildDoctorCard(context, doctor),
                            );
                          },
                          childCount: filtered.length,
                        ),
                      ),
                    ),
                ],
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(
                  color: primaryTeal, strokeWidth: 2.5),
            ),
            error: (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Failed to load doctors: $err',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: textMuted),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // 1. APP BAR
  // ------------------------------------------------------------
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleSpacing: 20,
      title: const Row(
        children: [
          Icon(Icons.person_search_rounded, color: primaryTeal, size: 24),
          SizedBox(width: 10),
          Text(
            'Doctor Discovery',
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
          tooltip: 'AI Health Search',
          onPressed: () => context.push(RoutePaths.patientAiSearch),
          icon: const Icon(Icons.auto_awesome, color: primaryTeal),
        ),
        IconButton(
          tooltip: 'Direct Booking',
          onPressed: () => context.push(RoutePaths.patientBookAppointment),
          icon: const Icon(Icons.calendar_month_outlined, color: primaryTeal),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ------------------------------------------------------------
  // 2. AI TOOLS STRIP — Symptom Checker + AI Health Search
  // ------------------------------------------------------------
  Widget _buildAiToolsStrip(BuildContext context) {
    final services = [
      _ExploreService(
        icon: Icons.monitor_heart_outlined,
        title: 'Symptom Checker',
        subtitle: 'AI-powered triage',
        colors: const [Color(0xFF007A8A), Color(0xFF2D9CA5)],
        onTap: () => context.push(RoutePaths.patientAiCare),
      ),
      _ExploreService(
        icon: Icons.auto_awesome_rounded,
        title: 'AI Health Search',
        subtitle: 'Grounded health answers',
        colors: const [Color(0xFF0062A3), Color(0xFF328BC5)],
        onTap: () => context.push(RoutePaths.patientAiSearch),
      ),
      _ExploreService(
        icon: Icons.calendar_month_rounded,
        title: 'Appointments',
        subtitle: 'Manage your visits',
        colors: const [Color(0xFF6D45C2), Color(0xFF9874E8)],
        onTap: () => context.push(RoutePaths.patientAppointments),
      ),
      _ExploreService(
        icon: Icons.person_search_rounded,
        title: 'Find Doctors',
        subtitle: 'Explore specialists',
        colors: const [Color(0xFF0D9488), Color(0xFF45B9A7)],
        onTap: () => context.push(RoutePaths.patientCare),
      ),
      _ExploreService(
        icon: Icons.chat_rounded,
        title: 'AI Assistant',
        subtitle: 'Ask health questions',
        colors: const [Color(0xFFDB6A28), Color(0xFFF49A4C)],
        onTap: () => context.push(RoutePaths.patientAiAssistant),
      ),
      _ExploreService(
        icon: Icons.health_and_safety_rounded,
        title: 'Health Records',
        subtitle: 'View health information',
        colors: const [Color(0xFF3475C5), Color(0xFF69A6E8)],
        onTap: () => context.push(RoutePaths.patientHealth),
      ),
      _ExploreService(
        icon: Icons.notifications_active_rounded,
        title: 'Reminders',
        subtitle: 'Stay on track',
        colors: const [Color(0xFFB84F85), Color(0xFFE47CA8)],
        onTap: () => context.push(RoutePaths.patientReminders),
      ),
      _ExploreService(
        icon: Icons.calendar_today_rounded,
        title: 'Book Appointment',
        subtitle: 'Schedule a consultation',
        colors: const [Color(0xFF547A37), Color(0xFF8EB85C)],
        onTap: () => context.push(RoutePaths.patientBookAppointment),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: services.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.55,
      ),
      itemBuilder: (context, index) {
        return _ExploreServiceCard(service: services[index]);
      },
    );
  }

  // ------------------------------------------------------------
  // 3. SEARCH FIELD
  // ------------------------------------------------------------
  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Search by doctor name, specialty, hospital...',
          hintStyle: const TextStyle(color: textMuted, fontSize: 13.5),
          prefixIcon:
              const Icon(Icons.search_rounded, color: primaryTeal, size: 22),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // 3. SPECIALTY FILTERS
  // ------------------------------------------------------------
  Widget _buildSpecialtyFilterRow(
      List<String> specialties, List<Map<String, dynamic>> allDoctors) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: specialties.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final specialty = specialties[index];
          final selected = _selectedSpecialty == specialty;
          final count = specialty == 'All'
              ? allDoctors.length
              : allDoctors
                  .where((d) =>
                      d['specialization'] == specialty ||
                      d['specialty'] == specialty)
                  .length;

          return ChoiceChip(
            label: Text('$specialty ($count)'),
            selected: selected,
            showCheckmark: false,
            selectedColor: primaryTeal,
            backgroundColor: Colors.white,
            side: BorderSide(color: selected ? primaryTeal : cardBorder),
            labelStyle: TextStyle(
              color: selected ? Colors.white : textDark,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
            onSelected: (_) {
              setState(() => _selectedSpecialty = specialty);
            },
          );
        },
      ),
    );
  }

  // ------------------------------------------------------------
  // 4. RESULTS HEADER & SORT
  // ------------------------------------------------------------
  Widget _buildResultsHeader(int resultCount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Available Doctors ($resultCount)',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: textDark,
          ),
        ),
        PopupMenuButton<String>(
          tooltip: 'Sort doctors',
          initialValue: _sortBy,
          onSelected: (value) => setState(() => _sortBy = value),
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'Recommended', child: Text('Recommended')),
            PopupMenuItem(
                value: 'Most experienced', child: Text('Most experienced')),
            PopupMenuItem(value: 'Lowest fee', child: Text('Lowest fee')),
            PopupMenuItem(value: 'Doctor name', child: Text('Doctor name (A-Z)')),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: cardBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.tune_rounded, size: 16, color: primaryTeal),
                const SizedBox(width: 6),
                Text(
                  _sortBy,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // 5. DOCTOR CARD
  // ------------------------------------------------------------
  Widget _buildDoctorCard(BuildContext context, Map<String, dynamic> doctor) {
    final name = doctor['name'] as String? ?? 'Doctor';
    final specialty = doctor['specialty'] as String? ?? 'General Medicine';
    final hospital = doctor['hospital'] as String? ?? 'City Hospital';
    final experience = doctor['experienceYears'] as num? ?? 0;
    final fee = doctor['consultationFee'] as num? ?? 500;
    final isDemo = doctor['isDemo'] == true;
    final location = doctor['location'] as String? ?? '';
    final doctorId = doctor['doctorId'] as String? ?? '';

    final initial = name.replaceAll('Dr.', '').trim().isNotEmpty
        ? name.replaceAll('Dr.', '').trim()[0].toUpperCase()
        : 'D';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _showDoctorDetailsSheet(context, doctor),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Avatar + Info + Demo Profile Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: lightTealSurface,
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: primaryTeal,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Flexible(
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    color: textDark,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isDemo)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                        color: const Color(0xFFFDE68A)),
                                  ),
                                  child: const Text(
                                    'Demo Profile',
                                    style: TextStyle(
                                      color: Color(0xFF92400E),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            specialty,
                            style: const TextStyle(
                              color: primaryTeal,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            location.isNotEmpty
                                ? '$hospital • $location'
                                : hospital,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(height: 1, color: cardBorder),
                const SizedBox(height: 12),

                // Meta Row: Experience + Fee + Actions
                Row(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.work_outline_rounded,
                            size: 15, color: textMuted),
                        const SizedBox(width: 4),
                        Text(
                          '$experience yrs exp',
                          style: const TextStyle(
                            color: textDark,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Row(
                      children: [
                        const Icon(Icons.currency_rupee_rounded,
                            size: 15, color: textMuted),
                        Text(
                          '$fee',
                          style: const TextStyle(
                            color: textDark,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),

                    // Action: View Profile
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () =>
                          _showDoctorDetailsSheet(context, doctor),
                      child: const Text(
                        'Details',
                        style: TextStyle(
                          color: textDark,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Action: Direct Book Visit
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: primaryTeal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () {
                        context.push(
                          '${RoutePaths.patientBookAppointment}?doctorId=$doctorId',
                          extra: doctorId,
                        );
                      },
                      child: const Text(
                        'Book Visit',
                        style: TextStyle(
                            fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // 6. DOCTOR DETAILS BOTTOM SHEET
  // ------------------------------------------------------------
  void _showDoctorDetailsSheet(
      BuildContext context, Map<String, dynamic> doctor) {
    final name = doctor['name'] as String? ?? 'Doctor';
    final specialty = doctor['specialty'] as String? ?? 'Specialist';
    final hospital = doctor['hospital'] as String? ?? 'City Hospital';
    final qualifications =
        doctor['qualifications'] as String? ?? 'Medical Practitioner';
    final experience = doctor['experienceYears'] as num? ?? 0;
    final fee = doctor['consultationFee'] as num? ?? 500;
    final isDemo = doctor['isDemo'] == true;
    final location = doctor['location'] as String? ?? 'Not specified';
    final bio = doctor['bio'] as String? ?? '';
    final languages = doctor['languages'] as List? ?? ['English', 'Hindi'];
    final history = doctor['professionalHistory'] as List? ?? [];
    final doctorId = doctor['doctorId'] as String? ?? '';

    final initial = name.replaceAll('Dr.', '').trim().isNotEmpty
        ? name.replaceAll('Dr.', '').trim()[0].toUpperCase()
        : 'D';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return SafeArea(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: cardBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Demo Profile Academic Notice (Section 6 Requirements)
                  if (isDemo) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline_rounded,
                              color: Color(0xFFB45309), size: 18),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Demo Profile — This profile contains sample academic demonstration data for HomeDoc AI. Not a verified medical credential.',
                              style: TextStyle(
                                color: Color(0xFF92400E),
                                fontSize: 11.5,
                                height: 1.4,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Doctor Profile Header
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundColor: lightTealSurface,
                        child: Text(
                          initial,
                          style: const TextStyle(
                            color: primaryTeal,
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: textDark,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              specialty,
                              style: const TextStyle(
                                color: primaryTeal,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              qualifications,
                              style: const TextStyle(
                                color: textMuted,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: cardBorder),
                  const SizedBox(height: 12),

                  // Quick Stats Grid (Experience, Hospital, Fee, Location)
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailStat(
                          label: 'Experience',
                          value: '$experience Years',
                          icon: Icons.work_outline_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildDetailStat(
                          label: 'Consultation Fee',
                          value: '₹$fee',
                          icon: Icons.currency_rupee_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailStat(
                          label: 'Hospital / Clinic',
                          value: hospital,
                          icon: Icons.local_hospital_outlined,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildDetailStat(
                          label: 'Location',
                          value: location,
                          icon: Icons.location_on_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Languages
                  if (languages.isNotEmpty) ...[
                    const Text(
                      'Languages Spoken',
                      style: TextStyle(
                        color: textDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final lang in languages)
                          Chip(
                            label: Text(lang.toString(),
                                style: const TextStyle(fontSize: 12)),
                            backgroundColor: lightTealSurface,
                            side: BorderSide.none,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Bio / About
                  if (bio.isNotEmpty) ...[
                    const Text(
                      'About Doctor',
                      style: TextStyle(
                        color: textDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      bio,
                      style: const TextStyle(
                        color: textDark,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Professional Experience History
                  if (history.isNotEmpty) ...[
                    const Text(
                      'Professional Background',
                      style: TextStyle(
                        color: textDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final item in history)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_circle_outline_rounded,
                                size: 16, color: primaryTeal),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item.toString(),
                                style: const TextStyle(
                                  color: textDark,
                                  fontSize: 12.5,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),
                  ],

                  // One-Click Book Appointment CTA
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: primaryTeal,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        context.push(
                          '${RoutePaths.patientBookAppointment}?doctorId=$doctorId',
                          extra: doctorId,
                        );
                      },
                      icon: const Icon(Icons.calendar_today_rounded, size: 18),
                      label: Text(
                        'Book Consultation with $name',
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailStat({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: primaryTeal),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: textMuted, fontSize: 10.5),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // 7. EMPTY SEARCH STATE
  // ------------------------------------------------------------
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: lightTealSurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                color: primaryTeal,
                size: 44,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No matching doctors found',
              style: TextStyle(
                color: textDark,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              'Try adjusting your search keywords or switching specialty filter.',
              style: TextStyle(color: textMuted, fontSize: 13, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: cardBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                _searchController.clear();
                setState(() => _selectedSpecialty = 'All');
              },
              child: const Text('Reset search & filters'),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // 8. BOTTOM NAVIGATION BAR
  // ------------------------------------------------------------
  Widget _buildBottomNavigationBar(BuildContext context,
      {required int selectedIndex}) {
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

// ─── Reusable private widget ─────────────────────────────────────────────────

class _ExploreService {
  const _ExploreService({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.colors,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> colors;
  final VoidCallback onTap;
}

class _ExploreServiceCard extends StatelessWidget {
  const _ExploreServiceCard({
    required this.service,
  });

  final _ExploreService service;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: service.onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: service.colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: service.colors.first.withValues(alpha: 0.16),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.20),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    service.icon,
                    color: Colors.white,
                    size: 23,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      service.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}