import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/appointment_model.dart';
import '../../../../shared/providers/appointment_provider.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/services/notification_service.dart';
import '../../../../shared/providers/doctor_provider.dart';
import '../../../family/data/models/family_member_model.dart';
import '../../../family/presentation/providers/family_provider.dart';

class BookAppointmentPage extends ConsumerStatefulWidget {
  const BookAppointmentPage({super.key, this.initialDoctorId});

  final String? initialDoctorId;

  @override
  ConsumerState<BookAppointmentPage> createState() =>
      _BookAppointmentPageState();
}

class _BookAppointmentPageState extends ConsumerState<BookAppointmentPage> {
  static const Color teal = Color(0xFF007A8A);
  static const Color primaryTeal = Color(0xFF14B8A6);
  static const Color lightTeal = Color(0xFFE6F7F6);
  static const Color darkText = Color(0xFF1F2937);
  static const Color mutedText = Color(0xFF6B7280);

  final List<String> _timeSlots = [
    '09:00 AM',
    '10:00 AM',
    '11:00 AM',
    '12:00 PM',
    '02:00 PM',
    '03:00 PM',
    '04:00 PM',
    '05:00 PM',
  ];

  final List<String> _consultationTypes = [
    'Clinic Visit',
    'Home Visit',
    'Video Consultation',
  ];

  String? _selectedDoctorId;
  FamilyMemberModel? _selectedFamilyMember;

  @override
  void initState() {
    super.initState();
    _selectedDoctorId = widget.initialDoctorId;
  }
  DateTime _selectedDate = DateUtils.dateOnly(
    DateTime.now().add(const Duration(days: 1)),
  );
  String? _selectedTime;
  String _selectedType = 'Clinic Visit';
  bool _isBooking = false;

  Future<void> _chooseDate() async {
    final today = DateUtils.dateOnly(DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 90)),
      helpText: 'Select appointment date',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: teal,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: darkText,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedTime = null;
      });
    }
  }


  Future<void> _confirmBooking() async {
    final doctors = ref.read(verifiedDoctorsProvider).valueOrNull ?? [];

    final selectedDoctor = doctors.firstWhere(
          (doctor) => doctor['doctorId'] == _selectedDoctorId,
      orElse: () => <String, dynamic>{},
    );

    if (selectedDoctor.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an available doctor.')),
      );
      return;
    }

    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an appointment time.')),
      );
      return;
    }

    final auth = ref.read(authStateProvider);
    final patientId = auth.user?.id;
    final primaryPatientName = auth.user?.displayName ?? '';

    if (patientId == null || patientId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to book an appointment.')),
      );
      return;
    }

    final isDependent = _selectedFamilyMember != null && _selectedFamilyMember!.id != 'self';
    final effectivePatientName = isDependent ? _selectedFamilyMember!.name : primaryPatientName;
    final effectiveFamilyMemberId = isDependent ? _selectedFamilyMember!.id : null;
    final effectiveRelationship = isDependent ? _selectedFamilyMember!.relationship : 'Self';

    setState(() => _isBooking = true);

    try {
      final parsedTime = DateFormat('hh:mm a').parse(_selectedTime!);

      final scheduledAt = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        parsedTime.hour,
        parsedTime.minute,
      );

      final ConsultationType modelType = switch (_selectedType) {
        'Clinic Visit' => ConsultationType.clinicVisit,
        'Home Visit' => ConsultationType.homeVisit,
        'Video Consultation' => ConsultationType.video,
        _ => ConsultationType.clinicVisit,
      };

      final firestore = ref.read(firestoreProvider);
      final appointmentRef = firestore.collection('appointments').doc();

      final appointment = AppointmentModel(
        id: appointmentRef.id,
        patientId: patientId,
        patientName: effectivePatientName,
        familyMemberId: effectiveFamilyMemberId,
        familyRelationship: effectiveRelationship,
        doctorId: selectedDoctor['doctorId'] as String,
        doctorName: selectedDoctor['name'] as String,
        specialty: selectedDoctor['specialty'] as String,
        type: modelType,
        status: AppointmentStatus.booked,
        scheduledAt: scheduledAt,
      );

      // Save the appointment permanently in Firestore.
      await appointmentRef.set({
        'appointmentId': appointmentRef.id,
        'patientId': patientId,
        'patientName': effectivePatientName,
        'familyMemberId': effectiveFamilyMemberId,
        'familyRelationship': effectiveRelationship,
        'doctorId': selectedDoctor['doctorId'],
        'doctorName': selectedDoctor['name'],
        'specialty': selectedDoctor['specialty'],
        'consultationType': modelType.name,
        'consultationLabel': _selectedType,
        'status': 'booked',
        'scheduledAt': Timestamp.fromDate(scheduledAt),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Schedule local appointment reminders (24 h + 1 h before).
      // Request permissions first; failures are silently swallowed inside
      // NotificationService so booking always succeeds even without permission.
      await NotificationService.instance.requestPermissions();
      await NotificationService.instance.scheduleAppointmentReminders(
        appointmentId: appointmentRef.id,
        doctorName: selectedDoctor['name'] as String? ?? 'Your Doctor',
        specialty: selectedDoctor['specialty'] as String? ?? '',
        consultationType: modelType.name,
        scheduledAt: scheduledAt,
      );

      if (!mounted) return;

      // Update local Riverpod state only after Firestore succeeds.
      ref.read(appointmentProvider.notifier).addAppointment(
        AppointmentEntry(
          appointment: appointment,
          consultationLabel: _selectedType,
        ),
      );

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: const BoxDecoration(
                  color: lightTeal,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: teal,
                  size: 48,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Booking Successful!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: darkText,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${selectedDoctor['name']}\n'
                    '${DateFormat('EEE, d MMM yyyy').format(scheduledAt)}\n'
                    '$_selectedTime · $_selectedType',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  height: 1.7,
                  color: mutedText,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your appointment has been saved.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: mutedText,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: teal),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking failed: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isBooking = false);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final doctorsAsync = ref.watch(verifiedDoctorsProvider);
    final currentDoctors = doctorsAsync.valueOrNull ?? [];

    final selectedDoctor = currentDoctors
        .cast<Map<String, dynamic>?>()
        .firstWhere(
          (doctor) => doctor?['doctorId'] == _selectedDoctorId,
          orElse: () => currentDoctors.isNotEmpty ? currentDoctors.first : null,
        );
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFA),
      appBar: AppBar(
        title: const Text(
          'Book Appointment',
          style: TextStyle(color: darkText, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: darkText),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [teal, primaryTeal],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.calendar_month_outlined,
                    color: Colors.white,
                    size: 38,
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your health comes first',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Choose a doctor and find a convenient time.',
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _sectionTitle('1. Who is this visit for?'),
            const SizedBox(height: 10),
            _buildPatientSelector(),
            const SizedBox(height: 24),
            _sectionTitle('2. Select Doctor'),
            const SizedBox(height: 10),

            doctorsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(25),
                  child: CircularProgressIndicator(color: teal),
                ),
              ),

              error: (error, stackTrace) => Container(
                padding: const EdgeInsets.all(16),
                decoration: _fieldDecoration(),
                child: const Text(
                  'Unable to load doctors. Please try again later.',
                  style: TextStyle(color: Colors.red),
                ),
              ),

              data: (doctors) {
                if (doctors.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: _fieldDecoration(),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.medical_services_outlined,
                          size: 40,
                          color: mutedText,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'No verified doctors available',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: darkText,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Please check again later.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: mutedText, fontSize: 13),
                        ),
                      ],
                    ),
                  );
                }

                final selectedDoctor = doctors.firstWhere(
                  (doctor) => doctor['doctorId'] == _selectedDoctorId,
                  orElse: () => doctors.first,
                );

                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                      decoration: _fieldDecoration(),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedDoctor['doctorId'] as String,
                          isExpanded: true,
                          icon: const Icon(
                            Icons.keyboard_arrow_down,
                            color: teal,
                          ),
                          items: doctors.map((doctor) {
                            return DropdownMenuItem<String>(
                              value: doctor['doctorId'] as String,
                              child: Text(
                                '${doctor['name']} · ${doctor['specialty']}',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13),
                              ),
                            );
                          }).toList(),
                          onChanged: (doctorId) {
                            if (doctorId != null) {
                              setState(() => _selectedDoctorId = doctorId);
                            }
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: _fieldDecoration(),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: lightTeal,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.person_outline,
                              color: teal,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selectedDoctor['name'] as String,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: darkText,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  selectedDoctor['specialty'] as String,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: mutedText,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  selectedDoctor['hospital']?.toString() ??
                                      'Hospital not added',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: mutedText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),
            _sectionTitle('3. Consultation Type'),
            const SizedBox(height: 10),
            ..._consultationTypes.map((type) {
              final selected = _selectedType == type;
              final icon = switch (type) {
                'Clinic Visit' => Icons.local_hospital_outlined,
                'Home Visit' => Icons.home_outlined,
                _ => Icons.videocam_outlined,
              };

              return Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: InkWell(
                  borderRadius: BorderRadius.circular(15),
                  onTap: () => setState(() => _selectedType = type),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: selected ? lightTeal : Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: selected ? primaryTeal : const Color(0xFFE5EEEE),
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(icon, color: teal, size: 23),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            type,
                            style: const TextStyle(
                              color: darkText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Icon(
                          selected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          color: selected ? teal : Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
            _sectionTitle('4. Choose Date'),
            const SizedBox(height: 10),
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _chooseDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: _fieldDecoration(),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: lightTeal,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.calendar_today_outlined,
                        color: teal,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Appointment date',
                            style: TextStyle(fontSize: 12, color: mutedText),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            DateFormat(
                              'EEEE, d MMM yyyy',
                            ).format(_selectedDate),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: darkText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.edit_calendar_outlined, color: teal),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _sectionTitle('5. Select Time'),
            const SizedBox(height: 6),
            const Text(
              'Choose your preferred time slot.',
              style: TextStyle(color: mutedText, fontSize: 13),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _timeSlots.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.7,
              ),
              itemBuilder: (context, index) {
                final time = _timeSlots[index];
                final selected = _selectedTime == time;

                return InkWell(
                  borderRadius: BorderRadius.circular(13),
                  onTap: () => setState(() => _selectedTime = time),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? teal : Colors.white,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: selected ? teal : const Color(0xFFDDE8E8),
                      ),
                    ),
                    child: Text(
                      time,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : darkText,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            _sectionTitle('Booking Summary'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _fieldDecoration(),
              child: Column(
                children: [
                  _summaryRow(
                    'Patient',
                    _selectedFamilyMember != null && _selectedFamilyMember!.id != 'self'
                        ? '${_selectedFamilyMember!.name} (${_selectedFamilyMember!.relationship})'
                        : '${ref.watch(authStateProvider).user?.displayName ?? "Primary Patient"} (Self)',
                  ),
                  _summaryRow(
                    'Doctor',
                    selectedDoctor?['name']?.toString() ?? 'No doctor selected',
                  ),
                  _summaryRow('Consultation', _selectedType),
                  _summaryRow(
                    'Date',
                    DateFormat('d MMM yyyy').format(_selectedDate),
                  ),
                  _summaryRow('Time', _selectedTime ?? 'Not selected'),
                  const Divider(height: 24),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Consultation fee',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: darkText,
                        ),
                      ),
                      Text(
                        'To be confirmed',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: teal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 54,
              child: FilledButton(
                onPressed: _isBooking ? null : _confirmBooking,
                style: FilledButton.styleFrom(
                  backgroundColor: teal,
                  disabledBackgroundColor: Colors.grey.shade400,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: _isBooking
                    ? const SizedBox(
                        height: 23,
                        width: 23,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline),
                          SizedBox(width: 9),
                          Text(
                            'Confirm Booking',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Demo only · No real appointment or payment will be created.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: mutedText),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientSelector() {
    final familyAsync = ref.watch(familyMembersProvider);

    return familyAsync.when(
      data: (members) {
        if (members.isEmpty) return const SizedBox.shrink();
        final currentSelection = _selectedFamilyMember ?? members.first;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: members.map((member) {
              final isSelected = member.id == currentSelection.id;
              final isSelf = member.id == 'self';

              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: ChoiceChip(
                  avatar: CircleAvatar(
                    backgroundColor: isSelected
                        ? Colors.white
                        : (isSelf ? lightTeal : const Color(0xFFF1F5F9)),
                    foregroundColor: isSelected
                        ? teal
                        : (isSelf ? teal : const Color(0xFF475569)),
                    child: Icon(
                      isSelf
                          ? Icons.person_rounded
                          : (member.relationship == 'Child'
                              ? Icons.child_care_rounded
                              : (member.relationship == 'Parent'
                                  ? Icons.elderly_rounded
                                  : Icons.family_restroom_rounded)),
                      size: 16,
                    ),
                  ),
                  label: Text(
                    isSelf ? 'Myself' : '${member.name} (${member.relationship})',
                    style: TextStyle(
                      color: isSelected ? Colors.white : darkText,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: teal,
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected ? teal : const Color(0xFFE5EEEE),
                    ),
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedFamilyMember = member);
                    }
                  },
                ),
              );
            }).toList(),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.bold,
        color: darkText,
      ),
    );
  }

  BoxDecoration _fieldDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE5EEEE)),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: mutedText, fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: darkText,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
