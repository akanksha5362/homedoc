
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../shared/providers/auth_provider.dart';

class DoctorProfilePage extends ConsumerStatefulWidget {
  const DoctorProfilePage({super.key});

  @override
  ConsumerState<DoctorProfilePage> createState() =>
      _DoctorProfilePageState();
}

class _DoctorProfilePageState
    extends ConsumerState<DoctorProfilePage> {
  static const Color teal = Color(0xFF078B8B);
  static const Color darkTeal = Color(0xFF075D63);
  static const Color lightTeal = Color(0xFFE8F7F6);
  static const Color pageBackground = Color(0xFFF6FAFB);

  bool _isSigningOut = false;
  bool _isUploadingPhoto = false;

  User? get _firebaseUser => FirebaseAuth.instance.currentUser;

  String _value(
      dynamic value, [
        String fallback = 'Not provided',
      ]) {
    if (value == null || value.toString().trim().isEmpty) {
      return fallback;
    }
    return value.toString();
  }

  // EDIT PROFESSIONAL PROFILE

  Future<void> _editProfile(Map<String, dynamic> data) async {
    final nameController = TextEditingController(
      text: _value(data['displayName'], ''),
    );
    final specialtyController = TextEditingController(
      text: _value(data['specialization'], ''),
    );
    final phoneController = TextEditingController(
      text: _value(data['phone'], _firebaseUser?.phoneNumber ?? ''),
    );
    final qualificationController = TextEditingController(
      text: _value(data['qualifications'], ''),
    );
    final hospitalController = TextEditingController(
      text: _value(data['hospital'], ''),
    );

    final formKey = GlobalKey<FormState>();

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Professional Profile'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _editField(
                  nameController,
                  'Full name',
                  required: true,
                ),
                _editField(
                  specialtyController,
                  'Specialization',
                ),
                _editField(
                  phoneController,
                  'Phone number',
                ),
                _editField(
                  qualificationController,
                  'Qualifications',
                ),
                _editField(
                  hospitalController,
                  'Clinic / Hospital',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: teal,
            ),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Save changes'),
          ),
        ],
      ),
    );

    if (shouldSave != true || !mounted) {
      nameController.dispose();
      specialtyController.dispose();
      phoneController.dispose();
      qualificationController.dispose();
      hospitalController.dispose();
      return;
    }

    try {
      final uid = _firebaseUser?.uid;

      if (uid == null) {
        throw Exception('No signed-in user found.');
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({
        'displayName': nameController.text.trim(),
        'specialization': specialtyController.text.trim(),
        'phone': phoneController.text.trim(),
        'qualifications': qualificationController.text.trim(),
        'hospital': hospitalController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully.'),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not update profile: $error'),
          ),
        );
      }
    } finally {
      nameController.dispose();
      specialtyController.dispose();
      phoneController.dispose();
      qualificationController.dispose();
      hospitalController.dispose();
    }
  }

  // PICK AND UPLOAD DOCTOR PROFILE PHOTO

  Future<void> _pickAndUploadPhoto() async {
    if (_isUploadingPhoto) return;

    final firebaseUser = _firebaseUser;

    if (firebaseUser == null) {
      _showMessage('Please sign in again.');
      return;
    }

    try {
      // Verify that this is an active doctor account.
      final profileRef = FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid);

      final profileSnapshot = await profileRef.get();
      final profile = profileSnapshot.data();

      if (!profileSnapshot.exists ||
          profile == null ||
          profile['role'] != 'doctor' ||
          profile['isActive'] != true) {
        throw Exception(
          'An active doctor account is required.',
        );
      }

      final picker = ImagePicker();

      final pickedImage = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      // The user cancelled the picker.
      if (pickedImage == null) return;

      final Uint8List bytes = await pickedImage.readAsBytes();

      if (bytes.lengthInBytes > 5 * 1024 * 1024) {
        throw Exception(
          'Please choose an image smaller than 5 MB.',
        );
      }

      final mimeType = pickedImage.mimeType ??
          _mimeTypeFromName(pickedImage.name);

      const allowedMimeTypes = [
        'image/jpeg',
        'image/png',
        'image/webp',
      ];

      if (!allowedMimeTypes.contains(mimeType)) {
        throw Exception(
          'Please select a JPEG, PNG, or WebP image.',
        );
      }

      if (!mounted) return;

      setState(() => _isUploadingPhoto = true);

      final extension = switch (mimeType) {
        'image/png' => 'png',
        'image/webp' => 'webp',
        _ => 'jpg',
      };

      final storageRef = FirebaseStorage.instance
          .ref()
          .child(
        'doctor_profile_photos/'
            '${firebaseUser.uid}/profile.$extension',
      );

      await storageRef.putData(
        bytes,
        SettableMetadata(
          contentType: mimeType,
        ),
      );

      final downloadUrl = await storageRef.getDownloadURL();

      // Save the download URL to the doctor's Firestore profile.
      await profileRef.update({
        'photoUrl': downloadUrl,
        'photoUpdatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Profile photo updated successfully.',
          ),
        ),
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Photo upload failed: '
                '${error.message ?? error.code}',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

  String _mimeTypeFromName(String name) {
    final lowerName = name.toLowerCase();

    if (lowerName.endsWith('.png')) {
      return 'image/png';
    }

    if (lowerName.endsWith('.webp')) {
      return 'image/webp';
    }

    if (lowerName.endsWith('.jpg') ||
        lowerName.endsWith('.jpeg')) {
      return 'image/jpeg';
    }

    return 'application/octet-stream';
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // REUSABLE EDIT FIELD

  Widget _editField(
      TextEditingController controller,
      String label, {
        bool required = false,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        validator: required
            ? (value) =>
        value == null || value.trim().isEmpty
            ? 'Please enter $label'
            : null
            : null,
      ),
    );
  }

  // SIGN OUT

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'Are you sure you want to sign out of HomeDoc AI?',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: darkTeal,
            ),
            onPressed: () =>
                Navigator.pop(dialogContext, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isSigningOut = true);

    try {
      await ref.read(authStateProvider.notifier).signOut();

      if (mounted) {
        context.go(RoutePaths.roleSelection);
      }
    } catch (_) {
      if (!mounted) return;

      setState(() => _isSigningOut = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to sign out. Please try again.',
          ),
        ),
      );
    }
  }

  // MAIN PROFILE PAGE

  @override
  Widget build(BuildContext context) {
    final firebaseUser = _firebaseUser;

    if (firebaseUser == null) {
      return Scaffold(
        body: Center(
          child: FilledButton(
            onPressed: () =>
                context.go(RoutePaths.roleSelection),
            child: const Text('Return to welcome'),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: pageBackground,
      body: StreamBuilder<
          DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUser.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to load your profile.\n'
                      '${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                color: teal,
              ),
            );
          }

          final data = snapshot.data!.data() ?? {};

          final name = _value(
            data['displayName'],
            firebaseUser.displayName ?? 'Doctor',
          );

          final specialty = _value(
            data['specialization'],
            'Specialization not set',
          );

          final email = _value(
            data['email'],
            firebaseUser.email ?? 'Not provided',
          );

          final phone = _value(
            data['phone'],
            firebaseUser.phoneNumber ?? 'Not provided',
          );

          final qualifications = _value(
            data['qualifications'],
          );

          final hospital = _value(data['hospital']);
          final location = _value(data['location']);
          final registration = _value(
            data['medicalRegistration'],
          );

          final isActive = data['isActive'] == true;
          final isVerified = data['isVerified'] == true;

          final photoUrl = data['photoUrl'] is String
              ? data['photoUrl'] as String
              : null;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _profileHeader(
                  name,
                  specialty,
                  isActive,
                  photoUrl,
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  18,
                  18,
                  18,
                  28,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _statsCard(data),
                    const SizedBox(height: 20),
                    _professionalCard(
                      email: email,
                      phone: phone,
                      qualifications: qualifications,
                      hospital: hospital,
                      location: location,
                      registration: registration,
                      onEdit: () => _editProfile(data),
                    ),
                    const SizedBox(height: 16),
                    _scheduleCard(data),
                    const SizedBox(height: 16),
                    _menuCard(
                      icon: Icons.verified_user_outlined,
                      title: 'Professional Verification',
                      subtitle: isVerified
                          ? 'Verified professional'
                          : 'Verification status not confirmed',
                      trailing: Icon(
                        isVerified
                            ? Icons.verified
                            : Icons.chevron_right,
                        color: isVerified
                            ? Colors.green
                            : Colors.blueGrey,
                      ),
                      onTap: () => _showInfo(
                        'Professional Verification',
                        isVerified
                            ? 'Your profile is marked as verified.'
                            : 'Your verification status has not '
                            'been confirmed. Contact your '
                            'administrator to verify your '
                            'credentials.',
                      ),
                    ),
                    const SizedBox(height: 10),
                    _menuCard(
                      icon: Icons.notifications_none_rounded,
                      title: 'Notifications',
                      subtitle: 'Manage your alerts',
                      onTap: () => _showInfo(
                        'Notifications',
                        'Notification preferences will be '
                            'available here.',
                      ),
                    ),
                    const SizedBox(height: 10),
                    _menuCard(
                      icon: Icons.lock_outline_rounded,
                      title: 'Account & Security',
                      subtitle: 'Account and sign-in settings',
                      onTap: () => _showInfo(
                        'Account & Security',
                        'Signed in with '
                            '${firebaseUser.email ?? 'your Firebase account'}.',
                      ),
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed:
                      _isSigningOut ? null : _signOut,
                      icon: _isSigningOut
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                          : const Icon(Icons.logout_rounded),
                      label: Text(
                        _isSigningOut
                            ? 'Signing out...'
                            : 'Sign Out',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: darkTeal,
                        side: const BorderSide(color: teal),
                        minimumSize:
                        const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'HomeDoc AI • Doctor Portal',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.blueGrey),
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: _bottomNavigation(),
    );
  }

  // PROFILE HEADER AND PHOTO

  Widget _profileHeader(
      String name,
      String specialty,
      bool isActive,
      String? photoUrl,
      ) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        22,
        MediaQuery.of(context).padding.top + 16,
        22,
        30,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [darkTeal, teal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(34),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () =>
                    context.go(RoutePaths.doctorToday),
                color: Colors.white,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const Expanded(
                child: Text(
                  'My Profile',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _showInfo(
                  'Settings',
                  'Account settings will be available here.',
                ),
                color: Colors.white,
                icon: const Icon(Icons.settings_outlined),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              GestureDetector(
                onTap: _isUploadingPhoto
                    ? null
                    : _pickAndUploadPhoto,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        backgroundColor: lightTeal,
                        backgroundImage:
                        photoUrl != null &&
                            photoUrl.isNotEmpty
                            ? NetworkImage(photoUrl)
                            : null,
                        child: photoUrl == null ||
                            photoUrl.isEmpty
                            ? const Icon(
                          Icons.medical_services_outlined,
                          size: 46,
                          color: teal,
                        )
                            : null,
                      ),
                    ),
                    Positioned(
                      right: -3,
                      bottom: 2,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: teal,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                        child: _isUploadingPhoto
                            ? const Padding(
                          padding: EdgeInsets.all(7),
                          child:
                          CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Icon(
                          Icons.camera_alt_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      specialty,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.circle,
                            size: 9,
                            color: isActive
                                ? Colors.green
                                : Colors.red,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isActive
                                ? 'Active Account'
                                : 'Inactive Account',
                            style: TextStyle(
                              color: isActive
                                  ? darkTeal
                                  : Colors.red.shade700,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Tap photo to change',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // PROFILE STATISTICS

  Widget _statsCard(Map<String, dynamic> data) {
    String stat(String key) {
      final value = data[key];
      return value == null ? '—' : value.toString();
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 20,
        horizontal: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: darkTeal.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          _statItem(
            Icons.calendar_month_rounded,
            stat('totalConsultations'),
            'Consultations',
          ),
          _statItem(
            Icons.star_rounded,
            stat('rating'),
            'Rating',
          ),
          _statItem(
            Icons.people_alt_outlined,
            stat('totalPatients'),
            'Patients',
          ),
        ],
      ),
    );
  }

  Widget _statItem(
      IconData icon,
      String value,
      String label,
      ) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: teal, size: 25),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: Color(0xFF172B3A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.blueGrey,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // PROFESSIONAL INFORMATION

  Widget _professionalCard({
    required String email,
    required String phone,
    required String qualifications,
    required String hospital,
    required String location,
    required String registration,
    required VoidCallback onEdit,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: darkTeal.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.medical_information_outlined,
                color: teal,
                size: 26,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Professional Information',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 17,
                ),
                label: const Text('Edit'),
                style: TextButton.styleFrom(
                  foregroundColor: teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _detailRow(Icons.email_outlined, 'Email Address', email),
          _detailRow(Icons.phone_outlined, 'Phone Number', phone),
          _detailRow(
            Icons.school_outlined,
            'Qualifications',
            qualifications,
          ),
          _detailRow(
            Icons.local_hospital_outlined,
            'Clinic / Hospital',
            hospital,
          ),
          _detailRow(
            Icons.location_on_outlined,
            'Location',
            location,
          ),
          _detailRow(
            Icons.badge_outlined,
            'Medical Registration',
            registration,
          ),
        ],
      ),
    );
  }

  Widget _detailRow(
      IconData icon,
      String label,
      String value,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 17),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: lightTeal,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: teal, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.blueGrey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF172B3A),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // CONSULTATION SCHEDULE

  Widget _scheduleCard(Map<String, dynamic> data) {
    final schedule = data['workingHours'];

    final scheduleText =
    schedule is String && schedule.trim().isNotEmpty
        ? schedule
        : 'Set your consultation hours';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: darkTeal.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: lightTeal,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: teal,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Availability & Schedule',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  scheduleText,
                  style: const TextStyle(
                    color: Colors.blueGrey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: Colors.blueGrey,
          ),
        ],
      ),
    );
  }

  // MENU CARDS

  Widget _menuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 15,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: lightTeal,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: teal, size: 23),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.blueGrey,
                      ),
                    ),
                  ],
                ),
              ),
              trailing ??
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.blueGrey,
                  ),
            ],
          ),
        ),
      ),
    );
  }

  // BOTTOM NAVIGATION

  Widget _bottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.blueGrey.withValues(alpha: 0.12),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _navItem(
              Icons.home_outlined,
              'Today',
              false,
                  () => context.go(RoutePaths.doctorToday),
            ),
            _navItem(
              Icons.person_rounded,
              'Profile',
              true,
                  () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem(
      IconData icon,
      String label,
      bool selected,
      VoidCallback onTap,
      ) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: selected ? teal : Colors.blueGrey,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: selected ? teal : Colors.blueGrey,
                  fontWeight: selected
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
              ),
              if (selected)
                Container(
                  margin: const EdgeInsets.only(top: 5),
                  width: 34,
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

  // INFORMATION DIALOG

  void _showInfo(String title, String message) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
