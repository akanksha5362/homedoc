import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../shared/providers/auth_provider.dart';

class DoctorProfilePage extends ConsumerStatefulWidget {
  const DoctorProfilePage({super.key});

  @override
  ConsumerState<DoctorProfilePage> createState() => _DoctorProfilePageState();
}

class _DoctorProfilePageState extends ConsumerState<DoctorProfilePage> {
  static const Color navy = Color(0xFF172B46);
  static const Color blue = Color(0xFF4B78A8);
  static const Color lightBlue = Color(0xFFEAF0F7);
  static const Color gold = Color(0xFFC49A63);
  static const Color pageBackground = Color(0xFFF4F6FA);
  static const Color textDark = Color(0xFF1C2939);
  static const Color textMuted = Color(0xFF718096);

  // Keep these aliases so your existing methods continue working.
  static const Color teal = blue;
  static const Color darkTeal = navy;

  bool _isSigningOut = false;
  bool _isUploadingPhoto = false;

  User? get _firebaseUser => FirebaseAuth.instance.currentUser;

  String _value(dynamic value, [String fallback = 'Not provided']) {
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
    final registrationController = TextEditingController(
      text: _value(data['registrationNumber'], ''),
    );
    final experienceController = TextEditingController(
      text: _value(data['experienceYears'], '0'),
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
                _editField(nameController, 'Full name', required: true),
                _editField(
                  specialtyController,
                  'Specialization',
                  required: true,
                ),
                _editField(phoneController, 'Phone number'),
                _editField(qualificationController, 'Qualifications'),
                _editField(hospitalController, 'Clinic / Hospital'),
                _editField(registrationController, 'Medical Council / Reg. No.'),
                _editField(experienceController, 'Years of clinical experience'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: teal),
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
      registrationController.dispose();
      experienceController.dispose();
      return;
    }

    try {
      final uid = _firebaseUser?.uid;

      if (uid == null) {
        throw Exception('No signed-in user found.');
      }

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'displayName': nameController.text.trim(),
        'specialization': specialtyController.text.trim(),
        'phone': phoneController.text.trim(),
        'qualifications': qualificationController.text.trim(),
        'hospital': hospitalController.text.trim(),
        'registrationNumber': registrationController.text.trim(),
        'experienceYears': int.tryParse(experienceController.text.trim()) ?? 0,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _syncPublicDoctorProfile(uid);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update profile: $error')),
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

  Future<void> _syncPublicDoctorProfile(String uid) async {
    final firestore = FirebaseFirestore.instance;

    // Read the latest private doctor profile.
    final privateSnapshot = await firestore.collection('users').doc(uid).get();

    final profile = privateSnapshot.data();

    if (profile == null ||
        profile['role'] != 'doctor' ||
        profile['isActive'] != true) {
      throw Exception('Active doctor profile not found.');
    }

    final name = (profile['displayName'] ?? '').toString().trim();
    final specialization = (profile['specialization'] ?? '').toString().trim();

    final publicRef = firestore.collection('doctor_public_profiles').doc(uid);

    // Do not publish an incomplete professional profile.
    if (name.isEmpty || specialization.isEmpty) {
      await publicRef.delete();
      return;
    }

    // Only professional information is copied.
    await publicRef.set({
      'doctorId': uid,
      'displayName': name,
      'specialization': specialization,
      'qualifications': profile['qualifications'] ?? '',
      'hospital': profile['hospital'] ?? '',
      'location': profile['location'] ?? '',
      'registrationNumber': profile['registrationNumber'] ?? '',
      'experienceYears': profile['experienceYears'] ?? 0,
      'photoUrl': profile['photoUrl'] ?? '',
      'isVerified': profile['isVerified'] == true,
      'isActive': true,
      'isDiscoverable': true,
      'availability': profile['availability'],
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
  // SHOW PROFILE PHOTO PREVIEW

  void _showProfilePhotoPreview(String? photoUrl) {
    // If no profile photo exists, open the gallery instead.
    if (photoUrl == null || photoUrl.isEmpty) {
      _pickAndUploadPhoto();
      return;
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: InteractiveViewer(
                  child: Image.network(
                    photoUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const SizedBox(
                        height: 250,
                        child: Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: Colors.white,
                            size: 45,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(dialogContext),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ],
          ),
        );
      },
    );
  }

  // PICK AND UPLOAD DOCTOR PROFILE PHOTO

  Future<void> _pickAndUploadPhoto() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser == null) {
      return;
    }

    setState(() {
      _isUploadingPhoto = true;
    });

    try {
      // 1. Verify that the logged-in account is an active doctor.
      final profileRef = FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid);

      final profileSnapshot = await profileRef.get();
      final profile = profileSnapshot.data();

      if (profile == null ||
          profile['role'] != 'doctor' ||
          profile['isActive'] != true) {
        throw Exception('Active doctor account not found.');
      }

      // 2. Select an image from the gallery.
      final picker = ImagePicker();

      final pickedImage = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1024,
      );

      if (pickedImage == null) {
        return;
      }

      // 3. Read and validate the selected image.
      final Uint8List imageBytes = await pickedImage.readAsBytes();

      if (imageBytes.length > 5 * 1024 * 1024) {
        throw Exception('Image size must be less than 5 MB.');
      }

      String extension = pickedImage.name.split('.').last.toLowerCase();

      if (!['jpg', 'jpeg', 'png', 'webp'].contains(extension)) {
        throw Exception('Only JPG, PNG and WebP images are allowed.');
      }

      if (extension == 'jpeg') {
        extension = 'jpg';
      }

      // 4. Upload the image to Cloudinary.
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/n3nev8vb/image/upload',
      );

      final request = http.MultipartRequest('POST', uri);

      request.fields['upload_preset'] = 'homedoc';

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: 'profile.$extension',
        ),
      );

      final streamedResponse = await request.send();

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        throw Exception('Cloudinary upload failed: ${response.body}');
      }

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      final String downloadUrl = responseData['secure_url'] as String? ?? '';
      final String publicId = responseData['public_id'] as String? ?? '';

      // 5. Save the Cloudinary URL and public ID in Firestore.
      await profileRef.update({
        'photoUrl': downloadUrl,
        'photoPublicId': publicId,
        'photoUpdatedAt': FieldValue.serverTimestamp(),
      });

      // 6. Synchronize the public doctor profile.
      await _syncPublicDoctorProfile(firebaseUser.uid);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo updated successfully!')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Photo upload failed: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingPhoto = false;
        });
      }
    }
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
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: required
            ? (value) => value == null || value.trim().isEmpty
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
        content: const Text('Are you sure you want to sign out of HomeDoc AI?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: darkTeal),
            onPressed: () => Navigator.pop(dialogContext, true),
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
        const SnackBar(content: Text('Unable to sign out. Please try again.')),
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
            onPressed: () => context.go(RoutePaths.roleSelection),
            child: const Text('Return to welcome'),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: pageBackground,
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
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
            return const Center(child: CircularProgressIndicator(color: teal));
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

          final qualifications = _value(data['qualifications']);

          final hospital = _value(data['hospital']);
          final location = _value(data['location']);
          final registration = _value(data['medicalRegistration']);

          final isActive = data['isActive'] == true;
          final isVerified = data['isVerified'] == true;

          final photoUrl = data['photoUrl'] is String
              ? data['photoUrl'] as String
              : null;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _profileHeader(name, specialty, isActive, photoUrl),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
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
                        isVerified ? Icons.verified : Icons.chevron_right,
                        color: isVerified ? Colors.green : Colors.blueGrey,
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
                      onPressed: _isSigningOut ? null : _signOut,
                      icon: _isSigningOut
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.logout_rounded),
                      label: Text(
                        _isSigningOut ? 'Signing out...' : 'Sign Out',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: darkTeal,
                        side: const BorderSide(color: teal),
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'HomeDoc AI • Doctor Portal',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.blueGrey),
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
        MediaQuery.of(context).padding.top + 12,
        22,
        30,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF14243D), Color(0xFF243F60), Color(0xFF365B7D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(34)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => context.go(RoutePaths.doctorToday),
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
              const Expanded(
                child: Text(
                  'DOCTOR PROFILE',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _showInfo(
                  'Settings',
                  'Account settings will be available here.',
                ),
                icon: const Icon(Icons.settings_outlined, color: Colors.white),
              ),
            ],
          ),

          const SizedBox(height: 25),

          Center(
            child: Column(
              children: [
                // Profile photo
                GestureDetector(
                  onTap: _isUploadingPhoto
                      ? null
                      : () => _showProfilePhotoPreview(photoUrl),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 126,
                        height: 126,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: gold, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 22,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          backgroundColor: lightBlue,
                          backgroundImage:
                              photoUrl != null && photoUrl.isNotEmpty
                              ? NetworkImage(photoUrl)
                              : null,
                          child: photoUrl == null || photoUrl.isEmpty
                              ? const Icon(
                                  Icons.person_rounded,
                                  size: 65,
                                  color: navy,
                                )
                              : null,
                        ),
                      ),

                      Positioned(
                        bottom: 3,
                        right: 1,
                        child: GestureDetector(
                          onTap: _isUploadingPhoto ? null : _pickAndUploadPhoto,
                          child: Container(
                            width: 37,
                            height: 37,
                            decoration: BoxDecoration(
                              color: gold,
                              shape: BoxShape.circle,
                              border: Border.all(color: navy, width: 2),
                            ),
                            child: _isUploadingPhoto
                                ? const Padding(
                                    padding: EdgeInsets.all(8),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.camera_alt_rounded,
                                    color: Colors.white,
                                    size: 19,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 19),

                Text(
                  name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                    height: 1.2,
                  ),
                ),

                const SizedBox(height: 7),

                Text(
                  specialty,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFD4DFEB),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),

                const SizedBox(height: 15),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.circle,
                        size: 9,
                        color: isActive
                            ? const Color(0xFF68D6A0)
                            : const Color(0xFFFF7777),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isActive ? 'Active Account' : 'Inactive Account',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  'Tap photo to preview  •  Camera to change',
                  style: TextStyle(
                    color: Color(0xFFCBD7E4),
                    fontSize: 11,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
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
      padding: const EdgeInsets.symmetric(vertical: 21, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: const Color(0xFFE8EDF3)),
        boxShadow: [
          BoxShadow(
            color: navy.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 5),
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
          _statItem(Icons.star_rounded, stat('rating'), 'Rating'),
          _statItem(
            Icons.people_alt_outlined,
            stat('totalPatients'),
            'Patients',
          ),
        ],
      ),
    );
  }

  Widget _statItem(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: lightBlue,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: blue, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: navy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
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
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: const Color(0xFFE8EDF3)),
        boxShadow: [
          BoxShadow(
            color: navy.withValues(alpha: 0.035),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: lightBlue,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.medical_information_outlined,
                  color: blue,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Professional Details',
                  style: TextStyle(
                    color: navy,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit'),
                style: TextButton.styleFrom(
                  foregroundColor: blue,
                  textStyle: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(color: Color(0xFFEDF0F5)),
          const SizedBox(height: 17),

          _detailRow(Icons.email_outlined, 'Email Address', email),
          _detailRow(Icons.phone_outlined, 'Phone Number', phone),
          _detailRow(Icons.school_outlined, 'Qualifications', qualifications),
          _detailRow(
            Icons.local_hospital_outlined,
            'Clinic / Hospital',
            hospital,
          ),
          _detailRow(Icons.location_on_outlined, 'Location', location),
          _detailRow(
            Icons.badge_outlined,
            'Medical Registration',
            registration,
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 39,
            height: 39,
            decoration: BoxDecoration(
              color: lightBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: blue, size: 19),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    color: textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
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
    final availability = data['availability'];

    String scheduleText = 'Set your consultation hours';
    bool isAvailable = false;

    if (availability is Map) {
      isAvailable = availability['isAvailable'] == true;

      final start = availability['startTime'] ?? '';
      final end = availability['endTime'] ?? '';

      if (!isAvailable) {
        scheduleText = 'Currently unavailable';
      } else if (start.toString().isNotEmpty &&
          end.toString().isNotEmpty) {
        scheduleText = '$start - $end';
      }
    }

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => context.push(RoutePaths.doctorAvailability),
        child: Padding(
          padding: const EdgeInsets.all(19),
          child: Row(
            children: [
              Container(
                width: 49,
                height: 49,
                decoration: BoxDecoration(
                  color: lightBlue,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: blue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Availability & Schedule',
                      style: TextStyle(
                        color: navy,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      scheduleText,
                      style: const TextStyle(
                        color: textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: blue,
                size: 16,
              ),
            ],
          ),
        ),
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
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
          child: Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: lightBlue,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: blue, size: 22),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: navy,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              trailing ??
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: blue,
                    size: 15,
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
        border: const Border(
          top: BorderSide(color: Color(0xFFE8EDF3)),
        ),
        boxShadow: [
          BoxShadow(
            color: navy.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
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
              Icons.chat_bubble_outline_rounded,
              'Chats',
              false,
              () => context.push(RoutePaths.doctorChatList),
            ),
            _navItem(
              Icons.event_available_outlined,
              'Availability',
              false,
              () => context.push(RoutePaths.doctorAvailability),
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
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: selected ? navy : textMuted,
                size: 23,
              ),
              const SizedBox(height: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: selected ? navy : textMuted,
                  fontWeight: selected
                      ? FontWeight.w800
                      : FontWeight.w500,
                ),
              ),
              if (selected)
                Container(
                  margin: const EdgeInsets.only(top: 5),
                  width: 25,
                  height: 3,
                  decoration: BoxDecoration(
                    color: gold,
                    borderRadius: BorderRadius.circular(5),
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
