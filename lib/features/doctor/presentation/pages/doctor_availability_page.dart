
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DoctorAvailabilityPage extends StatefulWidget {
  const DoctorAvailabilityPage({super.key});

  @override
  State<DoctorAvailabilityPage> createState() =>
      _DoctorAvailabilityPageState();
}

class _DoctorAvailabilityPageState
    extends State<DoctorAvailabilityPage> {
  static const Color teal = Color(0xFF078B8B);
  static const Color darkTeal = Color(0xFF075D63);
  static const Color lightTeal = Color(0xFFE8F7F6);
  static const Color pageBackground = Color(0xFFF6FAFB);

  final List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  final Map<String, bool> _selectedDays = {
    'Monday': true,
    'Tuesday': true,
    'Wednesday': true,
    'Thursday': true,
    'Friday': true,
    'Saturday': false,
    'Sunday': false,
  };

  TimeOfDay _startTime = const TimeOfDay(
    hour: 9,
    minute: 0,
  );

  TimeOfDay _endTime = const TimeOfDay(
    hour: 17,
    minute: 0,
  );

  bool _isAvailable = true;
  bool _isLoading = true;
  bool _isSaving = false;

  bool _clinicEnabled = true;
  bool _homeVisitEnabled = true;
  bool _videoEnabled = true;

  final TextEditingController _clinicFeeController = TextEditingController(text: '500');
  final TextEditingController _homeVisitFeeController = TextEditingController(text: '1200');
  final TextEditingController _videoFeeController = TextEditingController(text: '700');
  double _coverageRadius = 15.0;

  @override
  void dispose() {
    _clinicFeeController.dispose();
    _homeVisitFeeController.dispose();
    _videoFeeController.dispose();
    super.dispose();
  }

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  DocumentReference<Map<String, dynamic>>? get _profileRef {
    final uid = _uid;
    if (uid == null) return null;

    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid);
  }

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    try {
      final ref = _profileRef;

      if (ref == null) {
        throw Exception('Please sign in again.');
      }

      final snapshot = await ref.get();
      final profile = snapshot.data();

      if (profile == null || profile['role'] != 'doctor') {
        throw Exception('Doctor profile not found.');
      }

      final availability = profile['availability'];

      if (availability is Map) {
        if (!mounted) return;

        setState(() {
          _isAvailable =
              availability['isAvailable'] as bool? ?? true;

          final savedDays = availability['days'];

          if (savedDays is Map) {
            for (final day in _days) {
              _selectedDays[day] =
                  savedDays[day] as bool? ?? false;
            }
          }

          _startTime = _parseTime(
            availability['startTime']?.toString(),
            const TimeOfDay(hour: 9, minute: 0),
          );

          _endTime = _parseTime(
            availability['endTime']?.toString(),
            const TimeOfDay(hour: 17, minute: 0),
          );

          final modes = profile['consultationModes'];
          if (modes is Map) {
            _clinicEnabled = modes['clinicVisit'] as bool? ?? true;
            _homeVisitEnabled = modes['homeVisit'] as bool? ?? true;
            _videoEnabled = modes['video'] as bool? ?? true;
          }

          if (profile['consultationFee'] != null) {
            _clinicFeeController.text = profile['consultationFee'].toString();
          }
          if (profile['homeVisitFee'] != null) {
            _homeVisitFeeController.text = profile['homeVisitFee'].toString();
          }
          if (profile['videoFee'] != null) {
            _videoFeeController.text = profile['videoFee'].toString();
          }
          if (profile['homeVisitRadiusKm'] != null) {
            _coverageRadius = (profile['homeVisitRadiusKm'] as num).toDouble();
          }

          _isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() => _isLoading = false);
      }
    } catch (error) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not load availability: $error'),
        ),
      );
    }
  }

  TimeOfDay _parseTime(String? value, TimeOfDay fallback) {
    if (value == null) return fallback;

    try {
      final parts = value.split(' ');
      final timeParts = parts[0].split(':');

      int hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      if (parts.length > 1) {
        final period = parts[1].toUpperCase();

        if (period == 'PM' && hour != 12) {
          hour += 12;
        } else if (period == 'AM' && hour == 12) {
          hour = 0;
        }
      }

      return TimeOfDay(hour: hour, minute: minute);
    } catch (_) {
      return fallback;
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0
        ? 12
        : time.hourOfPeriod;

    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';

    return '$hour:$minute $period';
  }

  Future<void> _selectTime({required bool isStart}) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: teal,
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selected == null || !mounted) return;

    setState(() {
      if (isStart) {
        _startTime = selected;
      } else {
        _endTime = selected;
      }
    });
  }

  Future<void> _saveAvailability() async {
    if (_isSaving) return;

    final ref = _profileRef;

    if (ref == null) {
      _showMessage('Please sign in again.');
      return;
    }

    final selectedDays = _selectedDays.values
        .where((selected) => selected)
        .length;

    if (_isAvailable && selectedDays == 0) {
      _showMessage('Please select at least one available day.');
      return;
    }

    final startMinutes =
        _startTime.hour * 60 + _startTime.minute;
    final endMinutes =
        _endTime.hour * 60 + _endTime.minute;

    if (_isAvailable && endMinutes <= startMinutes) {
      _showMessage(
        'End time must be later than start time.',
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final snapshot = await ref.get();
      final profile = snapshot.data();

      if (profile == null ||
          profile['role'] != 'doctor' ||
          profile['isActive'] != true) {
        throw Exception('An active doctor account is required.');
      }

      final clinicFee = int.tryParse(_clinicFeeController.text.trim()) ?? 500;
      final homeFee = int.tryParse(_homeVisitFeeController.text.trim()) ?? 1200;
      final videoFee = int.tryParse(_videoFeeController.text.trim()) ?? 700;

      final availabilityData = {
        'isAvailable': _isAvailable,
        'days': Map<String, bool>.from(_selectedDays),
        'startTime': _formatTime(_startTime),
        'endTime': _formatTime(_endTime),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final consultationModesData = {
        'clinicVisit': _clinicEnabled,
        'homeVisit': _homeVisitEnabled,
        'video': _videoEnabled,
      };

      // 1. Update private doctor profile
      await ref.update({
        'availability': availabilityData,
        'consultationModes': consultationModesData,
        'consultationFee': clinicFee,
        'homeVisitFee': homeFee,
        'videoFee': videoFee,
        'homeVisitRadiusKm': _coverageRadius,
      });

      // 2. Sync to public doctor discovery profile
      final uid = _uid;
      if (uid != null) {
        final publicRef = FirebaseFirestore.instance.collection('doctor_public_profiles').doc(uid);
        await publicRef.set({
          'isAvailable': _isAvailable,
          'availability': availabilityData,
          'consultationModes': consultationModesData,
          'consultationFee': clinicFee,
          'homeVisitFee': homeFee,
          'videoFee': videoFee,
          'homeVisitRadiusKm': _coverageRadius,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Availability and consultation settings saved!'),
          backgroundColor: teal,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      _showMessage('Could not save availability: $error');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: pageBackground,
        body: Center(
          child: CircularProgressIndicator(color: teal),
        ),
      );
    }

    return Scaffold(
      backgroundColor: pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusCard(),
                    const SizedBox(height: 25),
                    _buildSectionTitle(
                      'Consultation Modes & Fees',
                      'Configure supported visit formats, fees, and coverage.',
                    ),
                    const SizedBox(height: 15),
                    _buildConsultationModesCard(),
                    const SizedBox(height: 25),
                    _buildSectionTitle(
                      'Available Days',
                      'Select the days you accept appointments.',
                    ),
                    const SizedBox(height: 15),
                    _buildDaysCard(),
                    const SizedBox(height: 25),
                    _buildSectionTitle(
                      'Working Hours',
                      'Set your daily consultation timings.',
                    ),
                    const SizedBox(height: 15),
                    _buildTimeCard(),
                    const SizedBox(height: 25),
                    _buildNoteCard(),
                    const SizedBox(height: 28),
                    _buildSaveButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 20, 25),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [darkTeal, teal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
            ),
          ),
          const Expanded(
            child: Text(
              'Availability & Schedule',
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Icon(
            Icons.calendar_month_rounded,
            color: Colors.white,
            size: 26,
          ),
        ],
      ),
    );
  }

  Widget _buildConsultationModesCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Clinic Visits
          _buildModeRow(
            icon: Icons.local_hospital_outlined,
            title: 'Clinic Consultations',
            subtitle: 'In-person visits at your hospital or clinic',
            isEnabled: _clinicEnabled,
            onChanged: (val) => setState(() => _clinicEnabled = val),
            feeController: _clinicFeeController,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),

          // 2. Home Visits
          _buildModeRow(
            icon: Icons.home_outlined,
            title: 'Home Doctor Visits',
            subtitle: 'In-home examinations within coverage area',
            isEnabled: _homeVisitEnabled,
            onChanged: (val) => setState(() => _homeVisitEnabled = val),
            feeController: _homeVisitFeeController,
          ),
          if (_homeVisitEnabled) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.near_me_outlined, size: 16, color: darkTeal),
                const SizedBox(width: 8),
                Text(
                  'Travel Radius: ${_coverageRadius.toInt()} km',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: darkTeal),
                ),
              ],
            ),
            Slider(
              value: _coverageRadius,
              min: 5,
              max: 50,
              divisions: 9,
              activeColor: teal,
              inactiveColor: lightTeal,
              label: '${_coverageRadius.toInt()} km',
              onChanged: (val) => setState(() => _coverageRadius = val),
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),

          // 3. Video Consultation
          _buildModeRow(
            icon: Icons.videocam_outlined,
            title: 'Video Consultations',
            subtitle: 'Secure live telehealth appointments',
            isEnabled: _videoEnabled,
            onChanged: (val) => setState(() => _videoEnabled = val),
            feeController: _videoFeeController,
          ),
        ],
      ),
    );
  }

  Widget _buildModeRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isEnabled,
    required ValueChanged<bool> onChanged,
    required TextEditingController feeController,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: lightTeal, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: teal, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF172B3A))),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
                ],
              ),
            ),
            Switch(
              value: isEnabled,
              activeThumbColor: Colors.white,
              activeTrackColor: teal,
              onChanged: onChanged,
            ),
          ],
        ),
        if (isEnabled) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 50),
            child: Row(
              children: [
                const Text('Fee: ₹', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF172B3A))),
                const SizedBox(width: 4),
                SizedBox(
                  width: 90,
                  height: 36,
                  child: TextField(
                    controller: feeController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('per consultation', style: TextStyle(fontSize: 11, color: Colors.blueGrey)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: darkTeal.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: lightTeal,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.event_available_rounded,
              color: teal,
              size: 25,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Accepting Appointments',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _isAvailable
                      ? 'You are currently available'
                      : 'You are currently unavailable',
                  style: const TextStyle(
                    color: Colors.blueGrey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isAvailable,
            activeThumbColor: Colors.white,
            activeTrackColor: teal,
            onChanged: (value) {
              setState(() => _isAvailable = value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF172B3A),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.blueGrey,
          ),
        ),
      ],
    );
  }

  Widget _buildDaysCard() {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: _cardDecoration(),
      child: Column(
        children: _days.map((day) {
          final selected = _selectedDays[day] ?? false;

          return Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                setState(() {
                  _selectedDays[day] = !selected;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: selected ? lightTeal : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected
                        ? teal.withValues(alpha: 0.35)
                        : const Color(0xFFE9EFF1),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      selected
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      color: selected ? teal : Colors.blueGrey,
                      size: 21,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        day,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: const Color(0xFF263B48),
                        ),
                      ),
                    ),
                    Text(
                      selected ? 'Available' : 'Off',
                      style: TextStyle(
                        fontSize: 12,
                        color: selected ? teal : Colors.blueGrey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTimeCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _timeTile(
            icon: Icons.wb_sunny_outlined,
            title: 'Start Time',
            time: _formatTime(_startTime),
            onTap: () => _selectTime(isStart: true),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1),
          ),
          _timeTile(
            icon: Icons.nights_stay_outlined,
            title: 'End Time',
            time: _formatTime(_endTime),
            onTap: () => _selectTime(isStart: false),
          ),
        ],
      ),
    );
  }

  Widget _timeTile({
    required IconData icon,
    required String title,
    required String time,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: lightTeal,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: teal),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.blueGrey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF172B3A),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.access_time_rounded,
            color: teal,
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: lightTeal,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: darkTeal,
            size: 21,
          ),
          SizedBox(width: 11),
          Expanded(
            child: Text(
              'Your availability helps patients know when '
                  'they can request an appointment with you. '
                  'Remember to save your changes.',
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: darkTeal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        onPressed: _isSaving ? null : _saveAvailability,
        style: FilledButton.styleFrom(
          backgroundColor: teal,
          disabledBackgroundColor: teal.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: _isSaving
            ? const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.save_rounded),
            SizedBox(width: 9),
            Text(
              'Save Availability',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: darkTeal.withValues(alpha: 0.05),
          blurRadius: 16,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }
}
