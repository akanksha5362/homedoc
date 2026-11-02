import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../shared/models/appointment_model.dart';
import '../../../../shared/providers/appointment_provider.dart';
import '../../data/models/health_record_model.dart';
import '../providers/health_records_provider.dart';

// Unified timeline event merging health records + completed visits.
enum _TimelineEventType { visit, healthRecord }

class _TimelineEvent {
  const _TimelineEvent({
    required this.type,
    required this.date,
    this.healthRecord,
    this.appointment,
  });

  final _TimelineEventType type;
  final DateTime date;
  final HealthRecordModel? healthRecord;
  final Map<String, dynamic>? appointment;

  String get title {
    if (type == _TimelineEventType.visit) {
      return appointment?['doctor']?.toString() ?? 'Doctor Visit';
    }
    return healthRecord?.title ?? 'Health Record';
  }

  String get subtitle {
    if (type == _TimelineEventType.visit) {
      return '${appointment?['specialty'] ?? ''} • ${appointment?['type'] ?? ''}';
    }
    return healthRecord?.doctorOrClinic ?? '';
  }
}

enum _ViewMode { records, timeline }

/// Digital Health Records Vault for HomeDoc AI.
class HealthPage extends ConsumerStatefulWidget {
  const HealthPage({super.key});

  @override
  ConsumerState<HealthPage> createState() => _HealthPageState();
}

class _HealthPageState extends ConsumerState<HealthPage> {
  final TextEditingController _searchController = TextEditingController();
  HealthRecordCategory? _selectedCategory; // null = All
  _ViewMode _viewMode = _ViewMode.records;

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
    final recordsAsync = ref.watch(patientHealthRecordsProvider);
    final vitalsAsync = ref.watch(patientVitalsProvider);
    final appointmentsAsync = ref.watch(patientAppointmentsProvider);

    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: _buildAppBar(context),
      bottomNavigationBar: _buildBottomNavigationBar(context, selectedIndex: 3),
      floatingActionButton: _viewMode == _ViewMode.records
          ? FloatingActionButton.extended(
              backgroundColor: primaryTeal,
              foregroundColor: Colors.white,
              elevation: 3,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Record', style: TextStyle(fontWeight: FontWeight.w600)),
              onPressed: () => _showAddRecordSheet(context),
            )
          : null,
      body: SafeArea(
        child: RefreshIndicator(
          color: primaryTeal,
          onRefresh: () async {
            ref.invalidate(patientHealthRecordsProvider);
            ref.invalidate(patientVitalsProvider);
            ref.invalidate(patientAppointmentsProvider);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              // 1. Patient Medical Profile Summary
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _buildVitalsCard(context, vitalsAsync),
                ),
              ),

              // 2. Medication Alarms Quick Banner
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: _buildRemindersBanner(context),
                ),
              ),

              // 3. View Mode Toggle (Records / Timeline)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _buildViewModeToggle(),
                ),
              ),

              if (_viewMode == _ViewMode.records) ...[
                // 4. Search & Category Filters (Records mode only)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                    child: Column(
                      children: [
                        _buildSearchBar(),
                        const SizedBox(height: 12),
                        _buildCategoryFilterRow(recordsAsync.valueOrNull ?? []),
                      ],
                    ),
                  ),
                ),

                // 5. Health Records List or Empty State
                recordsAsync.when(
                  data: (records) {
                    final query = _searchController.text.trim().toLowerCase();
                    final filtered = records.where((r) {
                      final matchesCategory = _selectedCategory == null || r.category == _selectedCategory;
                      final matchesQuery = query.isEmpty ||
                          r.title.toLowerCase().contains(query) ||
                          r.doctorOrClinic.toLowerCase().contains(query) ||
                          r.notes.toLowerCase().contains(query);
                      return matchesCategory && matchesQuery;
                    }).toList();

                    if (filtered.isEmpty) {
                      return SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildEmptyState(context, hasRecords: records.isNotEmpty),
                      );
                    }

                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final record = filtered[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildRecordCard(context, record),
                            );
                          },
                          childCount: filtered.length,
                        ),
                      ),
                    );
                  },
                  loading: () => const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(color: primaryTeal, strokeWidth: 2.5),
                    ),
                  ),
                  error: (error, _) => const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Failed to load health records. Please try again.',
                          style: TextStyle(color: textMuted, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                // 6. Unified Health Timeline
                _buildTimeline(context, recordsAsync, appointmentsAsync),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // VIEW MODE TOGGLE: Records <-> Timeline
  // ------------------------------------------------------------
  Widget _buildViewModeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        children: [
          _buildToggleTab(
            icon: Icons.folder_outlined,
            label: 'Records',
            isSelected: _viewMode == _ViewMode.records,
            onTap: () => setState(() => _viewMode = _ViewMode.records),
          ),
          _buildToggleTab(
            icon: Icons.timeline_rounded,
            label: 'Timeline',
            isSelected: _viewMode == _ViewMode.timeline,
            onTap: () => setState(() => _viewMode = _ViewMode.timeline),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleTab({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? primaryTeal : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? Colors.white : textMuted),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // UNIFIED HEALTH TIMELINE
  // ------------------------------------------------------------
  Widget _buildTimeline(
    BuildContext context,
    AsyncValue<List<HealthRecordModel>> recordsAsync,
    AsyncValue<List<Map<String, dynamic>>> appointmentsAsync,
  ) {
    final records = recordsAsync.valueOrNull ?? [];
    final appointments = appointmentsAsync.valueOrNull ?? [];

    // Build unified event list
    final events = <_TimelineEvent>[];

    // Add completed visits
    for (final apt in appointments) {
      final status = apt['lifecycleStatus'] as AppointmentStatus?;
      if (status == AppointmentStatus.completed) {
        final date = apt['date'] as DateTime?;
        if (date != null) {
          events.add(_TimelineEvent(
            type: _TimelineEventType.visit,
            date: date,
            appointment: apt,
          ));
        }
      }
    }

    // Add all health records
    for (final record in records) {
      events.add(_TimelineEvent(
        type: _TimelineEventType.healthRecord,
        date: record.date,
        healthRecord: record,
      ));
    }

    // Sort newest first
    events.sort((a, b) => b.date.compareTo(a.date));

    if (events.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(color: Color(0xFFE8F7F6), shape: BoxShape.circle),
                  child: const Icon(Icons.timeline_rounded, color: primaryTeal, size: 48),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Your Health Timeline is Empty',
                  style: TextStyle(color: textDark, fontSize: 17, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Completed doctor visits and uploaded health records will appear here in chronological order.',
                  style: TextStyle(color: textMuted, fontSize: 13, height: 1.45),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final event = events[index];
            final isFirst = index == 0;
            final isLast = index == events.length - 1;

            // Date separator — show if previous event was a different month/year
            final showDateHeader = isFirst ||
                !_isSameMonth(events[index - 1].date, event.date);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showDateHeader) _buildTimelineDateHeader(event.date),
                _buildTimelineEventRow(context, event, isLast: isLast),
              ],
            );
          },
          childCount: events.length,
        ),
      ),
    );
  }

  bool _isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  Widget _buildTimelineDateHeader(DateTime date) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: primaryTeal,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              DateFormat('MMMM yyyy').format(date),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
        ],
      ),
    );
  }

  Widget _buildTimelineEventRow(BuildContext context, _TimelineEvent event, {required bool isLast}) {
    final isVisit = event.type == _TimelineEventType.visit;
    final record = event.healthRecord;

    final (iconData, iconColor, iconBg) = isVisit
        ? (Icons.medical_services_rounded, const Color(0xFF059669), const Color(0xFFECFDF5))
        : _recordIconConfig(record?.category ?? HealthRecordCategory.other);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: timeline spine + dot
          SizedBox(
            width: 36,
            child: Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  margin: const EdgeInsets.only(top: 14),
                  decoration: BoxDecoration(
                    color: iconColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [BoxShadow(color: iconColor.withValues(alpha: 0.35), blurRadius: 5)],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: cardBorder,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Right: event card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: isVisit
                    ? null
                    : () => _showRecordDetailsSheet(context, record!),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: cardBorder),
                    boxShadow: const [
                      BoxShadow(color: Color(0x04000000), blurRadius: 6, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: iconBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(iconData, color: iconColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    event.title,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: textDark,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: iconBg,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isVisit ? 'Visit' : (record?.category.label ?? 'Record'),
                                    style: TextStyle(
                                      color: iconColor,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (event.subtitle.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                event.subtitle,
                                style: const TextStyle(fontSize: 12, color: textMuted),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.access_time_rounded, size: 12, color: textMuted),
                                const SizedBox(width: 4),
                                Text(
                                  DateFormat('d MMM y').format(event.date),
                                  style: const TextStyle(fontSize: 11.5, color: textMuted),
                                ),
                                if (!isVisit && record != null && record.notes.isNotEmpty) ...[
                                  const SizedBox(width: 10),
                                  const Icon(Icons.notes_rounded, size: 12, color: textMuted),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      record.notes,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 11.5, color: textMuted),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  (IconData, Color, Color) _recordIconConfig(HealthRecordCategory cat) {
    return switch (cat) {
      HealthRecordCategory.prescription => (
          Icons.medication_rounded,
          const Color(0xFF7C3AED),
          const Color(0xFFF5F3FF),
        ),
      HealthRecordCategory.labReport => (
          Icons.biotech_rounded,
          const Color(0xFF2563EB),
          const Color(0xFFEFF6FF),
        ),
      HealthRecordCategory.vaccine => (
          Icons.vaccines_rounded,
          const Color(0xFF059669),
          const Color(0xFFECFDF5),
        ),
      HealthRecordCategory.clinicalNote => (
          Icons.note_alt_rounded,
          const Color(0xFFD97706),
          const Color(0xFFFFFBEB),
        ),
      HealthRecordCategory.other => (
          Icons.description_rounded,
          primaryTeal,
          lightTealSurface,
        ),
    };
  }

  // ------------------------------------------------------------
  // 1. APP BAR
  // ------------------------------------------------------------
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleSpacing: 20,
      title: const Row(
        children: [
          Icon(Icons.shield_rounded, color: primaryTeal, size: 24),
          SizedBox(width: 10),
          Text(
            'Health Vault',
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
          tooltip: _viewMode == _ViewMode.records ? 'Switch to Timeline' : 'Switch to Records',
          icon: Icon(
            _viewMode == _ViewMode.records ? Icons.timeline_rounded : Icons.folder_outlined,
            color: primaryTeal,
            size: 22,
          ),
          onPressed: () => setState(() {
            _viewMode = _viewMode == _ViewMode.records ? _ViewMode.timeline : _ViewMode.records;
          }),
        ),
        IconButton(
          tooltip: 'Vault Security',
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Your health records are encrypted and protected by role-based privacy.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          icon: const Icon(Icons.lock_outline_rounded, color: primaryTeal, size: 22),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ------------------------------------------------------------
  // 2. VITALS & EMERGENCY MEDICAL PROFILE CARD
  // ------------------------------------------------------------
  Widget _buildVitalsCard(BuildContext context, AsyncValue<Map<String, String>> vitalsAsync) {
    final vitals = vitalsAsync.valueOrNull ?? {
      'bloodGroup': 'Not set',
      'allergies': 'None known',
      'chronicConditions': 'None reported',
    };

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.favorite_rounded, color: Color(0xFFE11D48), size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Medical Emergency Profile',
                    style: TextStyle(
                      color: textDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _showEditVitalsDialog(context, vitals),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Text(
                    'Edit',
                    style: TextStyle(
                      color: primaryTeal,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildVitalPill(
                  label: 'Blood Group',
                  value: vitals['bloodGroup'] ?? 'Not set',
                  icon: Icons.water_drop_outlined,
                  color: const Color(0xFFE11D48),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildVitalPill(
                  label: 'Allergies',
                  value: vitals['allergies'] ?? 'None known',
                  icon: Icons.warning_amber_rounded,
                  color: const Color(0xFFD97706),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildVitalPill(
            label: 'Chronic Conditions',
            value: vitals['chronicConditions'] ?? 'None reported',
            icon: Icons.medical_information_outlined,
            color: primaryTeal,
          ),
        ],
      ),
    );
  }

  Widget _buildRemindersBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: lightTealSurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.alarm_rounded, color: primaryTeal, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Medication Reminders',
                  style: TextStyle(
                      color: textDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5),
                ),
                SizedBox(height: 1),
                Text(
                  'Set alarms for prescribed doses & track daily intake',
                  style: TextStyle(color: textMuted, fontSize: 11.5),
                ),
              ],
            ),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              backgroundColor: lightTealSurface,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => context.push(RoutePaths.patientReminders),
            child: const Text('Manage',
                style: TextStyle(
                    color: primaryTeal,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalPill({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: textMuted, fontSize: 10, fontWeight: FontWeight.w500),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
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
  // 3. SEARCH & CATEGORY FILTER ROW
  // ------------------------------------------------------------
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Search prescriptions, tests, doctors...',
          hintStyle: const TextStyle(color: textMuted, fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded, color: primaryTeal, size: 20),
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildCategoryFilterRow(List<HealthRecordModel> allRecords) {
    final categories = [
      null, // All
      HealthRecordCategory.prescription,
      HealthRecordCategory.labReport,
      HealthRecordCategory.vaccine,
      HealthRecordCategory.clinicalNote,
    ];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = _selectedCategory == cat;
          final title = cat == null ? 'All Records' : cat.label;
          final count = cat == null
              ? allRecords.length
              : allRecords.where((r) => r.category == cat).length;

          return ChoiceChip(
            label: Text('$title ($count)'),
            selected: isSelected,
            selectedColor: primaryTeal,
            backgroundColor: Colors.white,
            side: BorderSide(
              color: isSelected ? primaryTeal : cardBorder,
            ),
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : textDark,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
            showCheckmark: false,
            onSelected: (_) {
              setState(() => _selectedCategory = cat);
            },
          );
        },
      ),
    );
  }

  // ------------------------------------------------------------
  // 4. RECORD CARD WIDGET
  // ------------------------------------------------------------
  Widget _buildRecordCard(BuildContext context, HealthRecordModel record) {
    final (icon, iconColor, bgSurface) = switch (record.category) {
      HealthRecordCategory.prescription => (
          Icons.medication_rounded,
          const Color(0xFF7C3AED),
          const Color(0xFFF5F3FF),
        ),
      HealthRecordCategory.labReport => (
          Icons.biotech_rounded,
          const Color(0xFF2563EB),
          const Color(0xFFEFF6FF),
        ),
      HealthRecordCategory.vaccine => (
          Icons.vaccines_rounded,
          const Color(0xFF059669),
          const Color(0xFFECFDF5),
        ),
      HealthRecordCategory.clinicalNote => (
          Icons.note_alt_rounded,
          const Color(0xFFD97706),
          const Color(0xFFFFFBEB),
        ),
      HealthRecordCategory.other => (
          Icons.description_rounded,
          primaryTeal,
          lightTealSurface,
        ),
    };

    final dateFormatted = DateFormat('MMM d, yyyy').format(record.date);

    return Container(
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showRecordDetailsSheet(context, record),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: bgSurface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: iconColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  record.title,
                                  style: const TextStyle(
                                    color: textDark,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: bgSurface,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  record.category.label,
                                  style: TextStyle(
                                    color: iconColor,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            record.doctorOrClinic,
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
                const SizedBox(height: 10),
                const Divider(height: 1, color: cardBorder),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 13, color: textMuted),
                        const SizedBox(width: 5),
                        Text(
                          dateFormatted,
                          style: const TextStyle(color: textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                    if (record.category == HealthRecordCategory.prescription &&
                        record.medicines.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.medication_outlined, size: 13, color: primaryTeal),
                          const SizedBox(width: 4),
                          Text(
                            '${record.medicines.length} medicines',
                            style: const TextStyle(
                              color: primaryTeal,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    else if (record.notes.isNotEmpty)
                      Flexible(
                        child: Text(
                          record.notes,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: textMuted, fontSize: 11.5),
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
  // 5. EMPTY STATE
  // ------------------------------------------------------------
  Widget _buildEmptyState(BuildContext context, {required bool hasRecords}) {
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
                Icons.folder_shared_outlined,
                color: primaryTeal,
                size: 48,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              hasRecords ? 'No matching records found' : 'Your Health Vault is Empty',
              style: const TextStyle(
                color: textDark,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              hasRecords
                  ? 'Try selecting a different filter or clearing your search term.'
                  : 'Securely upload your prescriptions, lab reports, and vaccination certificates to keep all your medical documents in one place.',
              style: const TextStyle(
                color: textMuted,
                fontSize: 13,
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (!hasRecords)
              FilledButton.icon(
                onPressed: () => _showAddRecordSheet(context),
                style: FilledButton.styleFrom(
                  backgroundColor: primaryTeal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                icon: const Icon(Icons.upload_file_rounded, size: 18),
                label: const Text('Add your first record'),
              ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // 6. RECORD DETAILS MODAL SHEET
  // ------------------------------------------------------------
  void _showRecordDetailsSheet(BuildContext context, HealthRecordModel record) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return SafeArea(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
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

                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: lightTealSurface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          record.category.label,
                          style: const TextStyle(
                            color: primaryTeal,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                        tooltip: 'Delete Record',
                        onPressed: () => _confirmDeleteRecord(context, sheetContext, record.id),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Text(
                    record.title,
                    style: const TextStyle(
                      color: textDark,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${record.doctorOrClinic} • ${DateFormat('MMMM d, yyyy').format(record.date)}',
                    style: const TextStyle(color: textMuted, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: cardBorder),
                  const SizedBox(height: 12),

                  // Prescribed Medicines (Feature 2 & 3)
                  if (record.category == HealthRecordCategory.prescription &&
                      record.medicines.isNotEmpty) ...[
                    const Text(
                      'Prescribed Medicines',
                      style: TextStyle(
                        color: textDark,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final med in record.medicines)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: backgroundLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: cardBorder),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.medication_liquid_rounded, color: primaryTeal, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    med.name,
                                    style: const TextStyle(
                                      color: textDark,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${med.dosage} • ${med.frequency} • ${med.duration}',
                                    style: const TextStyle(color: textMuted, fontSize: 12),
                                  ),
                                  if (med.instructions != null && med.instructions!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Note: ${med.instructions}',
                                      style: const TextStyle(
                                        color: primaryTeal,
                                        fontSize: 11.5,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () {
                                Navigator.pop(sheetContext);
                                context.push(
                                  '${RoutePaths.patientReminders}?medicine=${Uri.encodeComponent(med.name)}&dosage=${Uri.encodeComponent(med.dosage)}&doctor=${Uri.encodeComponent(record.doctorOrClinic)}',
                                );
                              },
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 4),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.alarm_add_rounded,
                                        size: 14, color: primaryTeal),
                                    SizedBox(width: 4),
                                    Text(
                                      'Set Alarm',
                                      style: TextStyle(
                                        color: primaryTeal,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Order Medicines Workflow (Feature 3)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: primaryTeal,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        onPressed: () => _showOrderMedicinesSheet(context, record),
                        icon: const Icon(Icons.local_shipping_outlined, size: 18),
                        label: const Text('Order Prescribed Medicines', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Notes & Summary
                  if (record.notes.isNotEmpty) ...[
                    const Text(
                      'Clinical Notes & Summary',
                      style: TextStyle(
                        color: textDark,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: backgroundLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cardBorder),
                      ),
                      child: Text(
                        record.notes,
                        style: const TextStyle(color: textDark, fontSize: 13, height: 1.4),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Share / Print Action
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: cardBorder),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Prescription sharing / print ready.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.share_outlined, size: 18, color: textDark),
                    label: const Text('Share or Print Document', style: TextStyle(color: textDark)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ------------------------------------------------------------
  // 7. ORDER MEDICINES MODAL SHEET (Feature 3)
  // ------------------------------------------------------------
  void _showOrderMedicinesSheet(BuildContext context, HealthRecordModel record) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Order Prescribed Medicines',
                    style: TextStyle(color: textDark, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(sheetContext),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Prescription by ${record.doctorOrClinic}',
                style: const TextStyle(color: textMuted, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: lightTealSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_pharmacy_rounded, color: primaryTeal, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${record.medicines.length} medicines will be verified with partner pharmacy for home delivery.',
                        style: const TextStyle(color: primaryTeal, fontSize: 12.5, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Delivery Address',
                style: TextStyle(color: textDark, fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 6),
              const TextField(
                decoration: InputDecoration(
                  hintText: 'Enter home delivery address',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: primaryTeal,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Medicine order requested! Partner pharmacy will verify and dispatch.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: const Text('Confirm Medicine Delivery Request'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------
  // 8. ADD HEALTH RECORD MODAL SHEET
  // ------------------------------------------------------------
  void _showAddRecordSheet(BuildContext context) {
    final titleController = TextEditingController();
    final doctorController = TextEditingController();
    final notesController = TextEditingController();
    HealthRecordCategory category = HealthRecordCategory.prescription;
    DateTime selectedDate = DateTime.now();
    final medicines = <PrescriptionMedicine>[];
    String? pickedFileName;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (dialogContext, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(dialogContext).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Add Medical Record',
                          style: TextStyle(
                            color: textDark,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(sheetContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Document Title
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Document Title *',
                        hintText: 'e.g. Cardiologist Consultation, Blood Test',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Category Selector
                    DropdownButtonFormField<HealthRecordCategory>(
                      initialValue: category,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      items: HealthRecordCategory.values.map((cat) {
                        return DropdownMenuItem(
                          value: cat,
                          child: Text(cat.label),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => category = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // Doctor or Facility
                    TextField(
                      controller: doctorController,
                      decoration: const InputDecoration(
                        labelText: 'Doctor or Clinic / Lab Name',
                        hintText: 'e.g. Dr. Aarav Sharma or City Pathology',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Date Picker
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Record Date', style: TextStyle(fontSize: 14, color: textDark)),
                      subtitle: Text(DateFormat('MMMM d, yyyy').format(selectedDate)),
                      trailing: const Icon(Icons.calendar_today_rounded, color: primaryTeal, size: 20),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setModalState(() => selectedDate = picked);
                        }
                      },
                    ),
                    const Divider(color: cardBorder),

                    // Add Medicine (if prescription)
                    if (category == HealthRecordCategory.prescription) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Medicines in Prescription',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textDark),
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.add, size: 16, color: primaryTeal),
                            label: const Text('Add Drug', style: TextStyle(color: primaryTeal)),
                            onPressed: () => _showAddMedicineDialog(context, (med) {
                              setModalState(() => medicines.add(med));
                            }),
                          ),
                        ],
                      ),
                      for (final med in medicines)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Chip(
                            backgroundColor: lightTealSurface,
                            label: Text('${med.name} (${med.dosage})'),
                            onDeleted: () {
                              setModalState(() => medicines.remove(med));
                            },
                          ),
                        ),
                      const SizedBox(height: 8),
                    ],

                    // Notes
                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Notes & Instructions',
                        hintText: 'Doctor instructions, lab findings, or notes...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // File upload attachment (using image_picker)
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: cardBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        final picker = ImagePicker();
                        final image = await picker.pickImage(source: ImageSource.gallery);
                        if (image != null) {
                          setModalState(() => pickedFileName = image.name);
                        }
                      },
                      icon: const Icon(Icons.attach_file_rounded, size: 18, color: primaryTeal),
                      label: Text(
                        pickedFileName != null ? 'Attached: $pickedFileName' : 'Attach Document or Prescription Image',
                        style: const TextStyle(fontSize: 12.5),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Submit
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: primaryTeal,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          final title = titleController.text.trim();
                          if (title.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter a document title.')),
                            );
                            return;
                          }

                          Navigator.pop(sheetContext);

                          try {
                            await ref.read(healthRecordsActionsProvider).addRecord(
                                  title: title,
                                  category: category,
                                  doctorOrClinic: doctorController.text.trim().isNotEmpty
                                      ? doctorController.text.trim()
                                      : 'Healthcare Provider',
                                  date: selectedDate,
                                  notes: notesController.text.trim(),
                                  fileName: pickedFileName,
                                  medicines: medicines,
                                );

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Medical record saved successfully.'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error saving record: $e'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
                        child: const Text('Save Record to Vault', style: TextStyle(fontWeight: FontWeight.w600)),
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

  void _showAddMedicineDialog(BuildContext context, ValueChanged<PrescriptionMedicine> onAdd) {
    final nameController = TextEditingController();
    final dosageController = TextEditingController();
    final freqController = TextEditingController();
    final durController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text('Add Medicine', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Medicine Name *')),
                TextField(controller: dosageController, decoration: const InputDecoration(labelText: 'Dosage (e.g. 500mg, 1 tab)')),
                TextField(controller: freqController, decoration: const InputDecoration(labelText: 'Frequency (e.g. 2 times daily)')),
                TextField(controller: durController, decoration: const InputDecoration(labelText: 'Duration (e.g. 5 days)')),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: primaryTeal),
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                onAdd(PrescriptionMedicine(
                  name: name,
                  dosage: dosageController.text.trim(),
                  frequency: freqController.text.trim(),
                  duration: durController.text.trim(),
                ));
                Navigator.pop(dialogCtx);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  // ------------------------------------------------------------
  // 9. EDIT VITALS & EMERGENCY PROFILE DIALOG
  // ------------------------------------------------------------
  void _showEditVitalsDialog(BuildContext context, Map<String, String> currentVitals) {
    final bloodController = TextEditingController(text: currentVitals['bloodGroup'] == 'Not set' ? '' : currentVitals['bloodGroup']);
    final allergiesController = TextEditingController(text: currentVitals['allergies'] == 'None known' ? '' : currentVitals['allergies']);
    final conditionsController = TextEditingController(text: currentVitals['chronicConditions'] == 'None reported' ? '' : currentVitals['chronicConditions']);

    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('Edit Emergency Medical Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: bloodController,
                  decoration: const InputDecoration(labelText: 'Blood Group', hintText: 'e.g. O+, A+, B-, AB+'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: allergiesController,
                  decoration: const InputDecoration(labelText: 'Known Allergies', hintText: 'e.g. Penicillin, Peanuts, Sulfa'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: conditionsController,
                  decoration: const InputDecoration(labelText: 'Chronic Conditions', hintText: 'e.g. Hypertension, Diabetes, Asthma'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: primaryTeal),
              onPressed: () async {
                Navigator.pop(dialogCtx);
                try {
                  await ref.read(healthRecordsActionsProvider).updateVitals(
                        bloodGroup: bloodController.text.trim().isEmpty ? 'Not set' : bloodController.text.trim(),
                        allergies: allergiesController.text.trim().isEmpty ? 'None known' : allergiesController.text.trim(),
                        chronicConditions: conditionsController.text.trim().isEmpty ? 'None reported' : conditionsController.text.trim(),
                      );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Medical profile updated.'), behavior: SnackBarBehavior.floating),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error updating vitals: $e'), behavior: SnackBarBehavior.floating),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // ------------------------------------------------------------
  // 10. DELETE RECORD CONFIRMATION
  // ------------------------------------------------------------
  Future<void> _confirmDeleteRecord(BuildContext context, BuildContext sheetContext, String recordId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Record'),
        content: const Text('Are you sure you want to remove this record from your vault?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (sheetContext.mounted) {
        Navigator.pop(sheetContext);
      }
      await ref.read(healthRecordsActionsProvider).deleteRecord(recordId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Record deleted.'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  // ------------------------------------------------------------
  // 11. BOTTOM NAVIGATION BAR
  // ------------------------------------------------------------
  Widget _buildBottomNavigationBar(BuildContext context, {required int selectedIndex}) {
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
