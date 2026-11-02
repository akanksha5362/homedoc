import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../shared/models/appointment_model.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/services/notification_service.dart';

// ─── Colour tokens ────────────────────────────────────────────────────────────
const Color _teal = Color(0xFF007A8A);
const Color _lightTeal = Color(0xFFE6F7F6);
const Color _darkText = Color(0xFF1F2937);
const Color _mutedText = Color(0xFF6B7280);
const Color _cardBorder = Color(0xFFE5E7EB);

/// A modal bottom sheet that lets a patient change the date, time, and
/// consultation type of an existing [booked] or [doctorConfirmed] appointment.
///
/// On success the Firestore document is updated and local notification reminders
/// are cancelled then rescheduled for the new time.  The sheet closes
/// automatically and calls [onRescheduled] if provided.
class RescheduleSheet extends ConsumerStatefulWidget {
  const RescheduleSheet({
    super.key,
    required this.appointment,
    this.onRescheduled,
  });

  /// The raw appointment map as returned by [patientAppointmentsProvider].
  final Map<String, dynamic> appointment;

  /// Optional callback invoked after a successful reschedule (already popped).
  final VoidCallback? onRescheduled;

  @override
  ConsumerState<RescheduleSheet> createState() => _RescheduleSheetState();
}

class _RescheduleSheetState extends ConsumerState<RescheduleSheet> {
  // ── State ────────────────────────────────────────────────────────────────────
  late DateTime _selectedDate;
  String? _selectedTime;
  late String _selectedType;
  bool _isSaving = false;

  static const List<String> _timeSlots = [
    '08:00 AM',
    '09:00 AM',
    '10:00 AM',
    '11:00 AM',
    '12:00 PM',
    '02:00 PM',
    '03:00 PM',
    '04:00 PM',
    '05:00 PM',
    '06:00 PM',
  ];

  static const List<String> _consultationTypes = [
    'Clinic Visit',
    'Home Visit',
    'Video Consultation',
  ];

  // ── Init ─────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    // Prefill with the current appointment values so the patient sees what
    // they are changing FROM.
    final existing = widget.appointment;

    // Date — try to read scheduledAt as DateTime
    final rawDate = existing['date'];
    if (rawDate is DateTime && rawDate.isAfter(DateTime.now())) {
      _selectedDate = DateUtils.dateOnly(rawDate);
    } else {
      _selectedDate = DateUtils.dateOnly(
        DateTime.now().add(const Duration(days: 1)),
      );
    }

    // Consultation type
    final rawType = (existing['type'] ?? existing['consultationType'] ?? '')
        .toString()
        .toLowerCase();
    if (rawType.contains('home')) {
      _selectedType = 'Home Visit';
    } else if (rawType.contains('video')) {
      _selectedType = 'Video Consultation';
    } else {
      _selectedType = 'Clinic Visit';
    }

    // Time — try to match existing time to a slot
    final rawTime = existing['time']?.toString() ?? '';
    if (_timeSlots.contains(rawTime)) {
      _selectedTime = rawTime;
    } else {
      _selectedTime = null; // patient must choose new time
    }
  }

  // ── Actions ──────────────────────────────────────────────────────────────────
  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: today.add(const Duration(days: 1)),
      lastDate: today.add(const Duration(days: 90)),
      helpText: 'Select new appointment date',
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _teal,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: _darkText,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
        _selectedTime = null; // reset time when date changes
      });
    }
  }

  Future<void> _save() async {
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a new appointment time.')),
      );
      return;
    }

    final appointmentId = widget.appointment['id'] as String? ?? '';
    if (appointmentId.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      // Parse the new scheduled DateTime
      final parsedTime = DateFormat('hh:mm a').parse(_selectedTime!);
      final newScheduledAt = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        parsedTime.hour,
        parsedTime.minute,
      );

      // Map UI type → model name
      final ConsultationType modelType = switch (_selectedType) {
        'Home Visit' => ConsultationType.homeVisit,
        'Video Consultation' => ConsultationType.video,
        _ => ConsultationType.clinicVisit,
      };

      // Firestore update
      final firestore = ref.read(firestoreProvider);
      await firestore.collection('appointments').doc(appointmentId).update({
        'scheduledAt': Timestamp.fromDate(newScheduledAt),
        'consultationType': modelType.name,
        'consultationLabel': _selectedType,
        'status': 'booked', // reset to booked — doctor must re-confirm
        'rescheduledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Cancel old local reminders and schedule new ones for the updated time
      await NotificationService.instance
          .cancelAppointmentReminders(appointmentId);

      final doctorName = (widget.appointment['doctor'] ??
              widget.appointment['doctorName'] ??
              'Your Doctor')
          .toString();
      final specialty =
          (widget.appointment['specialty'] ?? '').toString();

      await NotificationService.instance.scheduleAppointmentReminders(
        appointmentId: appointmentId,
        doctorName: doctorName,
        specialty: specialty,
        consultationType: modelType.name,
        scheduledAt: newScheduledAt,
      );

      if (!mounted) return;

      // Close sheet
      Navigator.of(context).pop();
      widget.onRescheduled?.call();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Appointment rescheduled to '
            '${DateFormat("EEE, d MMM yyyy").format(newScheduledAt)} '
            'at $_selectedTime.',
          ),
          backgroundColor: _teal,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reschedule: $error')),
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final appointment = widget.appointment;
    final doctorName =
        (appointment['doctor'] ?? appointment['doctorName'] ?? 'Doctor')
            .toString();
    final specialty =
        (appointment['specialty'] ?? 'General Medicine').toString();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 28,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Drag handle ────────────────────────────────────────────────────
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Title ──────────────────────────────────────────────────────────
            const Text(
              'Reschedule Appointment',
              style: TextStyle(
                color: _darkText,
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$doctorName · $specialty',
              style: const TextStyle(color: _teal, fontSize: 13.5),
            ),
            const SizedBox(height: 6),
            const Text(
              'Your appointment will return to "Booked" status and the doctor '
              'will need to re-confirm the new time.',
              style: TextStyle(
                color: _mutedText,
                fontSize: 12,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),

            // ── Date picker row ────────────────────────────────────────────────
            const _SectionLabel(
              icon: Icons.calendar_month_rounded,
              label: 'New Date',
            ),
            const SizedBox(height: 8),
            _DateButton(
              date: _selectedDate,
              onTap: _pickDate,
            ),
            const SizedBox(height: 18),

            // ── Time slot grid ─────────────────────────────────────────────────
            const _SectionLabel(
              icon: Icons.schedule_rounded,
              label: 'New Time',
            ),
            const SizedBox(height: 8),
            _TimeSlotGrid(
              slots: _timeSlots,
              selected: _selectedTime,
              onSelected: (t) => setState(() => _selectedTime = t),
            ),
            const SizedBox(height: 18),

            // ── Consultation type ──────────────────────────────────────────────
            const _SectionLabel(
              icon: Icons.medical_services_outlined,
              label: 'Consultation Type',
            ),
            const SizedBox(height: 8),
            _ConsultationTypePicker(
              types: _consultationTypes,
              selected: _selectedType,
              onSelected: (t) => setState(() => _selectedType = t),
            ),
            const SizedBox(height: 24),

            // ── Save button ────────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _teal,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Confirm Reschedule',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: _mutedText),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Private sub-widgets ──────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _teal),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: _darkText,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({required this.date, required this.onTap});
  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _cardBorder),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.event_rounded, color: _teal, size: 20),
            const SizedBox(width: 10),
            Text(
              DateFormat('EEEE, d MMMM yyyy').format(date),
              style: const TextStyle(
                color: _darkText,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded, color: _mutedText, size: 20),
          ],
        ),
      ),
    );
  }
}

class _TimeSlotGrid extends StatelessWidget {
  const _TimeSlotGrid({
    required this.slots,
    required this.selected,
    required this.onSelected,
  });
  final List<String> slots;
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: slots.map((slot) {
        final isSelected = slot == selected;
        return ChoiceChip(
          label: Text(slot),
          selected: isSelected,
          showCheckmark: false,
          selectedColor: _teal,
          backgroundColor: Colors.white,
          side: BorderSide(color: isSelected ? _teal : _cardBorder),
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : _darkText,
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
          onSelected: (_) => onSelected(slot),
        );
      }).toList(),
    );
  }
}

class _ConsultationTypePicker extends StatelessWidget {
  const _ConsultationTypePicker({
    required this.types,
    required this.selected,
    required this.onSelected,
  });
  final List<String> types;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: types.map((type) {
        final isSelected = type == selected;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () => onSelected(type),
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                color: isSelected ? _lightTeal : Colors.white,
                border:
                    Border.all(color: isSelected ? _teal : _cardBorder),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _typeIcon(type),
                    color: isSelected ? _teal : _mutedText,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      type,
                      style: TextStyle(
                        color: isSelected ? _teal : _darkText,
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check_circle_rounded,
                        color: _teal, size: 18),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _typeIcon(String type) {
    if (type.contains('Home')) return Icons.home_rounded;
    if (type.contains('Video')) return Icons.videocam_rounded;
    return Icons.local_hospital_outlined;
  }
}
