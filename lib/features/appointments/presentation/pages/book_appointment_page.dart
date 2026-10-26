import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/appointment_model.dart';
import '../../../../shared/providers/appointment_provider.dart';

class BookAppointmentPage extends ConsumerStatefulWidget {
  const BookAppointmentPage({super.key});

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

  final List<Map<String, dynamic>> _doctors = [
    {
      'name': 'Dr. Ananya Sharma',
      'specialty': 'General Physician',
      'fee': 500,
      'rating': '4.9',
    },
    {
      'name': 'Dr. Rahul Verma',
      'specialty': 'Cardiologist',
      'fee': 800,
      'rating': '4.8',
    },
    {
      'name': 'Dr. Priya Mehta',
      'specialty': 'Dermatologist',
      'fee': 600,
      'rating': '4.9',
    },
    {
      'name': 'Dr. Karan Patel',
      'specialty': 'Orthopedic',
      'fee': 700,
      'rating': '4.7',
    },
    {
      'name': 'Dr. Neha Gupta',
      'specialty': 'Pediatrician',
      'fee': 550,
      'rating': '4.8',
    },
  ];

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

  late Map<String, dynamic> _selectedDoctor;
  DateTime _selectedDate = DateUtils.dateOnly(
    DateTime.now().add(const Duration(days: 1)),
  );
  String? _selectedTime;
  String _selectedType = 'Clinic Visit';
  bool _isBooking = false;

  @override
  void initState() {
    super.initState();
    _selectedDoctor = _doctors.first;
  }

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
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an appointment time.')),
      );
      return;
    }

    setState(() => _isBooking = true);

    await Future<void>.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    // Combine the selected date and time into one DateTime.
    final parsedTime = DateFormat('hh:mm a').parse(_selectedTime!);

    final scheduledAt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      parsedTime.hour,
      parsedTime.minute,
    );

    // Your existing enum doesn't include Clinic Visit.
    // Keep the actual selected label separately for correct display.
    final ConsultationType modelType = _selectedType == 'Home Visit'
        ? ConsultationType.homeVisit
        : ConsultationType.video;

    final appointment = AppointmentModel(
      id: 'APT-${DateTime.now().microsecondsSinceEpoch}',
      doctorName: _selectedDoctor['name'] as String,
      specialty: _selectedDoctor['specialty'] as String,
      type: modelType,
      status: AppointmentStatus.booked,
      scheduledAt: scheduledAt,
    );

    // Add the appointment to shared in-memory state.
    ref
        .read(appointmentProvider.notifier)
        .addAppointment(
          AppointmentEntry(
            appointment: appointment,
            consultationLabel: _selectedType,
          ),
        );

    setState(() => _isBooking = false);

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
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
              '${_selectedDoctor['name']}\n'
              '${DateFormat('EEE, d MMM yyyy').format(scheduledAt)}\n'
              '$_selectedTime · $_selectedType',
              textAlign: TextAlign.center,
              style: const TextStyle(height: 1.7, color: mutedText),
            ),
            const SizedBox(height: 12),
            const Text(
              'Saved in this running app session only. '
              'No server request or payment has been made.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: mutedText),
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
  }

  @override
  Widget build(BuildContext context) {
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
            _sectionTitle('1. Select Doctor'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: _fieldDecoration(),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Map<String, dynamic>>(
                  value: _selectedDoctor,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down, color: teal),
                  items: _doctors.map((doctor) {
                    return DropdownMenuItem<Map<String, dynamic>>(
                      value: doctor,
                      child: Text(
                        '${doctor['name']} · ${doctor['specialty']}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                    );
                  }).toList(),
                  onChanged: (doctor) {
                    if (doctor != null) {
                      setState(() => _selectedDoctor = doctor);
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
                          _selectedDoctor['name'] as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: darkText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedDoctor['specialty'] as String,
                          style: const TextStyle(
                            fontSize: 13,
                            color: mutedText,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 17,
                              color: Color(0xFFF5A623),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              _selectedDoctor['rating'] as String,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '₹${_selectedDoctor['fee']}',
                    style: const TextStyle(
                      color: teal,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _sectionTitle('2. Consultation Type'),
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
            _sectionTitle('3. Choose Date'),
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
            _sectionTitle('4. Select Time'),
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
                  _summaryRow('Doctor', _selectedDoctor['name'] as String),
                  _summaryRow('Consultation', _selectedType),
                  _summaryRow(
                    'Date',
                    DateFormat('d MMM yyyy').format(_selectedDate),
                  ),
                  _summaryRow('Time', _selectedTime ?? 'Not selected'),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Consultation fee',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: darkText,
                        ),
                      ),
                      Text(
                        '₹${_selectedDoctor['fee']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
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
