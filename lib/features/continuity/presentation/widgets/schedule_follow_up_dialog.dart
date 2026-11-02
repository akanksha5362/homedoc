import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/follow_up_reminder_model.dart';
import '../providers/follow_up_provider.dart';

const Color primaryTeal = Color(0xFF007A8A);
const Color textDark = Color(0xFF0F172A);
const Color textMuted = Color(0xFF64748B);

class ScheduleFollowUpDialog extends ConsumerStatefulWidget {
  const ScheduleFollowUpDialog({
    super.key,
    required this.doctorId,
    required this.doctorName,
    required this.doctorSpecialty,
    this.doctorPhotoUrl,
    required this.relatedAppointmentId,
    this.initialTargetDate,
    this.isDoctorRecommended = false,
    this.initialReason = '',
  });

  final String doctorId;
  final String doctorName;
  final String doctorSpecialty;
  final String? doctorPhotoUrl;
  final String relatedAppointmentId;
  final DateTime? initialTargetDate;
  final bool isDoctorRecommended;
  final String initialReason;

  @override
  ConsumerState<ScheduleFollowUpDialog> createState() =>
      _ScheduleFollowUpDialogState();
}

class _ScheduleFollowUpDialogState
    extends ConsumerState<ScheduleFollowUpDialog> {
  late DateTime _selectedDate;
  int _remindBeforeDays = 1;
  late TextEditingController _reasonController;
  RecurringInterval _recurringInterval = RecurringInterval.none;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialTargetDate ??
        DateTime.now().add(const Duration(days: 14));
    _reasonController = TextEditingController(text: widget.initialReason);
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Select Follow-up Consultation Date',
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _save() async {
    final reminderDateTime = _selectedDate
        .subtract(Duration(days: _remindBeforeDays))
        .copyWith(hour: 9, minute: 0);

    await ref.read(followUpRemindersProvider.notifier).scheduleFollowUp(
          doctorId: widget.doctorId,
          doctorName: widget.doctorName,
          doctorSpecialty: widget.doctorSpecialty,
          doctorPhotoUrl: widget.doctorPhotoUrl,
          relatedAppointmentId: widget.relatedAppointmentId,
          targetDate: _selectedDate,
          reminderDateTime: reminderDateTime,
          isDoctorRecommended: widget.isDoctorRecommended,
          reason: _reasonController.text.trim(),
          recurringInterval: _recurringInterval,
        );

    if (mounted) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Follow-up reminder set for ${DateFormat('d MMM yyyy').format(_selectedDate)}',
          ),
          backgroundColor: primaryTeal,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F7F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.event_repeat_rounded,
                      color: primaryTeal, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Set Follow-Up Reminder',
                        style: TextStyle(
                          color: textDark,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        widget.doctorName,
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
            const SizedBox(height: 18),

            // Target Date Selection
            const Text(
              'Follow-up Consultation Date',
              style: TextStyle(
                color: textDark,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('EEEE, d MMMM yyyy').format(_selectedDate),
                      style: const TextStyle(
                        color: textDark,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const Icon(Icons.calendar_today_rounded,
                        color: primaryTeal, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Remind Before Option
            const Text(
              'Notify Me Before',
              style: TextStyle(
                color: textDark,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [0, 1, 2, 3].map((days) {
                final isSelected = _remindBeforeDays == days;
                final label = days == 0 ? 'Same Day' : '$days day${days > 1 ? 's' : ''} prior';
                return ChoiceChip(
                  label: Text(label),
                  selected: isSelected,
                  selectedColor: const Color(0xFFE6F7F6),
                  labelStyle: TextStyle(
                    color: isSelected ? primaryTeal : textDark,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  onSelected: (selected) {
                    if (selected) setState(() => _remindBeforeDays = days);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Recurring Schedule Option
            const Text(
              'Recurring Healthcare Plan (Optional)',
              style: TextStyle(
                color: textDark,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<RecurringInterval>(
              initialValue: _recurringInterval,
              decoration: InputDecoration(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: RecurringInterval.none,
                  child: Text('One-time follow up'),
                ),
                DropdownMenuItem(
                  value: RecurringInterval.weekly,
                  child: Text('Weekly review schedule'),
                ),
                DropdownMenuItem(
                  value: RecurringInterval.monthly,
                  child: Text('Monthly checkup schedule'),
                ),
                DropdownMenuItem(
                  value: RecurringInterval.quarterly,
                  child: Text('Quarterly routine consultation'),
                ),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _recurringInterval = val);
              },
            ),
            const SizedBox(height: 16),

            // Clinical Note / Reason
            const Text(
              'Clinical Follow-Up Notes',
              style: TextStyle(
                color: textDark,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _reasonController,
              decoration: InputDecoration(
                hintText: 'e.g. Check blood pressure after medication course',
                hintStyle: const TextStyle(color: textMuted, fontSize: 13),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel', style: TextStyle(color: textDark)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: primaryTeal,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Save Reminder',
                        style: TextStyle(fontWeight: FontWeight.w700)),
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
