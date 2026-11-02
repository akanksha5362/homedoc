import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../shared/services/notification_service.dart';
import '../../data/models/medication_reminder_model.dart';
import '../providers/reminders_provider.dart';

/// Prescription Reminders and Medication Alarms Page (Feature 2).
class MedicationRemindersPage extends ConsumerStatefulWidget {
  const MedicationRemindersPage({
    super.key,
    this.initialMedicineName,
    this.initialDosage,
    this.initialDoctor,
  });

  final String? initialMedicineName;
  final String? initialDosage;
  final String? initialDoctor;

  @override
  ConsumerState<MedicationRemindersPage> createState() =>
      _MedicationRemindersPageState();
}

class _MedicationRemindersPageState
    extends ConsumerState<MedicationRemindersPage> {
  static const Color primaryTeal = Color(0xFF007A8A);
  static const Color lightTealSurface = Color(0xFFE8F7F6);
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color textDark = Color(0xFF111827);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color cardBorder = Color(0xFFE5E7EB);

  @override
  void initState() {
    super.initState();
    // If opened with initial medicine from a prescription, prompt to set alarm
    if (widget.initialMedicineName != null &&
        widget.initialMedicineName!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showAddReminderSheet(
          context,
          prefillMedicine: widget.initialMedicineName,
          prefillDosage: widget.initialDosage,
          prefillDoctor: widget.initialDoctor,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final remindersAsync = ref.watch(patientRemindersProvider);

    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: _buildAppBar(context),
      bottomNavigationBar: _buildBottomNavigationBar(context, selectedIndex: 3),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryTeal,
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.add_alarm_rounded),
        label: const Text('Add Alarm',
            style: TextStyle(fontWeight: FontWeight.w600)),
        onPressed: () => _showAddReminderSheet(context),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: primaryTeal,
          onRefresh: () async {
            ref.invalidate(patientRemindersProvider);
          },
          child: remindersAsync.when(
            data: (reminders) {
              final activeReminders =
                  reminders.where((r) => r.isEnabled).toList();

              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics()),
                slivers: [
                  // 1. Header & Today's Dose Tracker
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Medication Alarms',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: textDark,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Receive notifications for prescribed doses and track daily intake.',
                            style: TextStyle(fontSize: 13.5, color: textMuted),
                          ),
                          const SizedBox(height: 16),

                          // Today's Dose Tracker Card
                          _buildTodayTrackerCard(context, activeReminders),
                          const SizedBox(height: 20),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Scheduled Alarms (${reminders.length})',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: textDark,
                                ),
                              ),
                              if (reminders.isNotEmpty)
                                TextButton.icon(
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  onPressed: () =>
                                      _showDoseHistorySheet(context, reminders),
                                  icon: const Icon(Icons.history_rounded,
                                      size: 16, color: primaryTeal),
                                  label: const Text('Dose History',
                                      style: TextStyle(
                                          color: primaryTeal,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),

                  // 2. Alarms List or Empty State
                  if (reminders.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(context),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final reminder = reminders[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildReminderCard(context, reminder),
                            );
                          },
                          childCount: reminders.length,
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
                child: Text('Error loading alarms: $err',
                    style: const TextStyle(color: textMuted)),
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
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleSpacing: 20,
      title: const Row(
        children: [
          Icon(Icons.alarm_rounded, color: primaryTeal, size: 24),
          SizedBox(width: 10),
          Text(
            'Prescription Alarms',
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
          tooltip: 'Test Notification Sound',
          onPressed: () async {
            await NotificationService.instance.showTestNotification(
              title: '💊 HomeDoc AI Medication Alarm',
              body: 'Notification permissions and alarms are working properly!',
            );
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Test notification delivered to system tray!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          icon: const Icon(Icons.notifications_active_outlined,
              color: primaryTeal),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ------------------------------------------------------------
  // 2. TODAY'S DOSE TRACKER CARD
  // ------------------------------------------------------------
  Widget _buildTodayTrackerCard(
      BuildContext context, List<MedicationReminderModel> activeReminders) {
    if (activeReminders.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cardBorder),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle_outline_rounded,
                color: primaryTeal, size: 22),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'No medication alarms scheduled for today.',
                style: TextStyle(
                    color: textDark, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    final takenCount = activeReminders
        .where((r) => r.todayStatus == DoseStatus.taken)
        .length;

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
                  Icon(Icons.calendar_today_rounded,
                      color: primaryTeal, size: 18),
                  SizedBox(width: 8),
                  Text(
                    "Today's Doses",
                    style: TextStyle(
                      color: textDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: lightTealSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$takenCount / ${activeReminders.length} Taken',
                  style: const TextStyle(
                    color: primaryTeal,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // List of doses for today
          for (final reminder in activeReminders)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildDoseItem(context, reminder),
            ),
        ],
      ),
    );
  }

  Widget _buildDoseItem(BuildContext context, MedicationReminderModel reminder) {
    final status = reminder.todayStatus;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: status == DoseStatus.taken
                  ? const Color(0xFFDCFCE7)
                  : (status == DoseStatus.skipped
                      ? const Color(0xFFFEE2E2)
                      : lightTealSurface),
              shape: BoxShape.circle,
            ),
            child: Icon(
              status == DoseStatus.taken
                  ? Icons.check_rounded
                  : (status == DoseStatus.skipped
                      ? Icons.close_rounded
                      : Icons.medication_rounded),
              color: status == DoseStatus.taken
                  ? const Color(0xFF16A34A)
                  : (status == DoseStatus.skipped
                      ? const Color(0xFFDC2626)
                      : primaryTeal),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.medicineName,
                  style: const TextStyle(
                    color: textDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${reminder.dosage} • ${reminder.timeFormatted}',
                  style: const TextStyle(color: textMuted, fontSize: 12),
                ),
              ],
            ),
          ),

          // Actions: Taken / Skipped / Done
          if (status == DoseStatus.pending) ...[
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                side: const BorderSide(color: Color(0xFFD1D5DB)),
              ),
              onPressed: () {
                ref
                    .read(remindersActionsProvider)
                    .logDose(reminder, DoseStatus.skipped);
              },
              child: const Text('Skip',
                  style: TextStyle(fontSize: 11.5, color: textMuted)),
            ),
            const SizedBox(width: 6),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () {
                ref
                    .read(remindersActionsProvider)
                    .logDose(reminder, DoseStatus.taken);
              },
              child: const Text('Taken',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
            ),
          ] else if (status == DoseStatus.taken) ...[
            const Text(
              'Taken ✓',
              style: TextStyle(
                color: Color(0xFF16A34A),
                fontWeight: FontWeight.bold,
                fontSize: 12.5,
              ),
            ),
          ] else ...[
            const Text(
              'Skipped',
              style: TextStyle(
                color: Color(0xFFDC2626),
                fontWeight: FontWeight.bold,
                fontSize: 12.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // 3. SCHEDULED REMINDER CARD
  // ------------------------------------------------------------
  Widget _buildReminderCard(
      BuildContext context, MedicationReminderModel reminder) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: reminder.isEnabled
                  ? lightTealSurface
                  : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.alarm_on_rounded,
              color: reminder.isEnabled ? primaryTeal : textMuted,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      reminder.timeFormatted,
                      style: TextStyle(
                        color: reminder.isEnabled ? textDark : textMuted,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Switch(
                      value: reminder.isEnabled,
                      activeTrackColor: primaryTeal,
                      onChanged: (val) {
                        ref
                            .read(remindersActionsProvider)
                            .toggleReminder(reminder, val);
                      },
                    ),
                  ],
                ),
                Text(
                  reminder.medicineName,
                  style: TextStyle(
                    color: reminder.isEnabled ? textDark : textMuted,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${reminder.dosage} • ${reminder.doctorOrSource}',
                  style: const TextStyle(color: textMuted, fontSize: 12.5),
                ),
                if (reminder.instructions.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Note: ${reminder.instructions}',
                    style: const TextStyle(
                      color: primaryTeal,
                      fontSize: 11.5,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _confirmDeleteReminder(context, reminder),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded,
                                size: 16, color: Colors.red),
                            SizedBox(width: 4),
                            Text(
                              'Delete Alarm',
                              style: TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // 4. EMPTY STATE
  // ------------------------------------------------------------
  Widget _buildEmptyState(BuildContext context) {
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
                Icons.alarm_add_rounded,
                color: primaryTeal,
                size: 44,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No Medication Alarms Set',
              style: TextStyle(
                color: textDark,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              'Never miss a prescription dose. Schedule daily reminders with custom times and dosages.',
              style: TextStyle(color: textMuted, fontSize: 13, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: primaryTeal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: () => _showAddReminderSheet(context),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add your first alarm'),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // 5. ADD REMINDER MODAL SHEET
  // ------------------------------------------------------------
  void _showAddReminderSheet(
    BuildContext context, {
    String? prefillMedicine,
    String? prefillDosage,
    String? prefillDoctor,
  }) {
    final medController =
        TextEditingController(text: prefillMedicine ?? '');
    final doseController =
        TextEditingController(text: prefillDosage ?? '1 tablet');
    final doctorController =
        TextEditingController(text: prefillDoctor ?? 'Prescription');
    final noteController = TextEditingController();
    TimeOfDay selectedTime = const TimeOfDay(hour: 8, minute: 0);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final formattedTime = selectedTime.format(context);

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
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
                          'Set Medication Reminder',
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
                    const SizedBox(height: 14),

                    // Medicine Name
                    TextField(
                      controller: medController,
                      decoration: const InputDecoration(
                        labelText: 'Medicine Name *',
                        hintText: 'e.g. Amoxicillin, Paracetamol, Metformin',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Dosage
                    TextField(
                      controller: doseController,
                      decoration: const InputDecoration(
                        labelText: 'Prescribed Dosage',
                        hintText: 'e.g. 500mg, 1 tablet, 5ml syrup',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Time of Day Picker
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Reminder Alarm Time',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: Text(formattedTime,
                          style: const TextStyle(
                              color: primaryTeal,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      trailing: const Icon(Icons.access_time_rounded,
                          color: primaryTeal),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (picked != null) {
                          setModalState(() => selectedTime = picked);
                        }
                      },
                    ),
                    const Divider(color: cardBorder),

                    // Prescribed by
                    TextField(
                      controller: doctorController,
                      decoration: const InputDecoration(
                        labelText: 'Prescribed By / Doctor',
                        hintText: 'e.g. Dr. Aarav Sharma',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Instructions
                    TextField(
                      controller: noteController,
                      decoration: const InputDecoration(
                        labelText: 'Instructions',
                        hintText: 'e.g. Take after breakfast with water',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Save Alarm CTA
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: primaryTeal,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          final name = medController.text.trim();
                          if (name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Please enter the medicine name.')),
                            );
                            return;
                          }

                          Navigator.pop(sheetContext);

                          try {
                            await ref
                                .read(remindersActionsProvider)
                                .addReminder(
                                  medicineName: name,
                                  dosage: doseController.text.trim().isNotEmpty
                                      ? doseController.text.trim()
                                      : '1 dose',
                                  hour: selectedTime.hour,
                                  minute: selectedTime.minute,
                                  doctorOrSource: doctorController.text.trim(),
                                  instructions: noteController.text.trim(),
                                );

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Alarm scheduled for $name at $formattedTime daily.'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Error saving alarm: $e')),
                              );
                            }
                          }
                        },
                        child: const Text('Schedule Daily Alarm',
                            style: TextStyle(fontWeight: FontWeight.w700)),
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

  // ------------------------------------------------------------
  // 6. DOSE HISTORY MODAL SHEET
  // ------------------------------------------------------------
  void _showDoseHistorySheet(
      BuildContext context, List<MedicationReminderModel> reminders) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Medication History',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(sheetContext),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    children: [
                      for (final reminder in reminders)
                        for (final log in reminder.dosesHistory)
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: backgroundLight,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: cardBorder),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  log.status == DoseStatus.taken
                                      ? Icons.check_circle_rounded
                                      : Icons.cancel_outlined,
                                  color: log.status == DoseStatus.taken
                                      ? const Color(0xFF16A34A)
                                      : Colors.red,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        reminder.medicineName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13.5,
                                          color: textDark,
                                        ),
                                      ),
                                      Text(
                                        'Date: ${log.dateString} • Status: ${log.status.name.toUpperCase()}',
                                        style: const TextStyle(
                                            color: textMuted, fontSize: 11.5),
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
              ],
            ),
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------
  // 7. CONFIRM DELETE REMINDER
  // ------------------------------------------------------------
  Future<void> _confirmDeleteReminder(
      BuildContext context, MedicationReminderModel reminder) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Alarm'),
        content: Text(
            'Are you sure you want to delete the alarm for ${reminder.medicineName}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(remindersActionsProvider).deleteReminder(reminder);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Alarm deleted.'),
              behavior: SnackBarBehavior.floating),
        );
      }
    }
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
