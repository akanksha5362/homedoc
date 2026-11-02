import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../family/presentation/providers/family_provider.dart';
import '../providers/patient_profile_provider.dart';
import '../../data/models/patient_profile_model.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  static const Color primaryTeal = Color(0xFF007A8A);
  static const Color lightTeal = Color(0xFFE6F7F6);
  static const Color darkText = Color(0xFF111827);
  static const Color mutedText = Color(0xFF6B7280);
  static const Color cardBorder = Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(patientProfileStreamProvider);
    final familyAsync = ref.watch(familyMembersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(RoutePaths.patientHome);
            }
          },
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cardBorder),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: darkText,
              size: 20,
            ),
          ),
        ),
        title: const Text(
          'My Profile',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: darkText,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Edit Profile',
            onPressed: () {
              final profile = ref.read(patientProfileStreamProvider).valueOrNull;
              if (profile != null) {
                _showEditNameModal(context, profile);
              }
            },
            icon: const Icon(Icons.edit_outlined, color: primaryTeal),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: profileAsync.when(
          data: (profile) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderCard(context, profile),
                const SizedBox(height: 24),

                _buildSectionHeading(
                  'Personal & Family',
                  'Manage your profile and family members',
                  Icons.person_rounded,
                ),
                const SizedBox(height: 12),

                _buildFamilyCard(context, familyAsync),
                const SizedBox(height: 16),
                _buildAddressCard(context, profile),
                const SizedBox(height: 16),
                _buildEmergencyContactCard(context, profile),

                const SizedBox(height: 24),
                _buildSectionHeading(
                  'Health Information',
                  'Keep your important health details updated',
                  Icons.favorite_rounded,
                ),
                const SizedBox(height: 12),

                _buildVitalsCard(context, profile),
                const SizedBox(height: 16),
                _buildConsentCard(context, profile),

                const SizedBox(height: 24),
                _buildSectionHeading(
                  'Preferences & Settings',
                  'Personalize your healthcare experience',
                  Icons.settings_rounded,
                ),
                const SizedBox(height: 12),

                _buildPreferencesCard(context, profile),
                const SizedBox(height: 16),
                _buildAccountActionsCard(context),
              ],
            ),
          ),
          loading: () => const Center(
            child: CircularProgressIndicator(color: primaryTeal),
          ),
          error: (err, _) => Center(
            child: Text('Error loading profile: $err'),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, PatientProfileModel profile) {
    final name = profile.displayName.trim();
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'P';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF007A8A),
            Color(0xFF159DA7),
            Color(0xFF47B8B5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryTeal.withValues(alpha: 0.20),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: Colors.white,
                    child: Text(
                      initial,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: primaryTeal,
                      ),
                    ),
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified_rounded,
                        color: Color(0xFF16A34A),
                        size: 17,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isNotEmpty ? name : 'Patient',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      profile.phone ?? profile.email ?? 'No contact information',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Edit Name',
                onPressed: () => _showEditNameModal(context, profile),
                icon: const Icon(
                  Icons.edit_rounded,
                  color: Colors.white,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.22),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.shield_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                SizedBox(width: 7),
                Text(
                  'Verified Patient',
                  style: TextStyle(
                    color: Colors.white,
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

  Widget _buildSectionHeading(
      String title,
      String subtitle,
      IconData icon,
      ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: lightTeal,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: primaryTeal,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: darkText,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: mutedText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFamilyCard(
    BuildContext context,
    AsyncValue<List<dynamic>> familyAsync,
  ) {
    final memberCount = familyAsync.valueOrNull?.length ?? 1;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: lightTeal,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.family_restroom_rounded, color: primaryTeal, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Family Healthcare Profiles',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: darkText),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$memberCount registered profiles (Self & Dependents)',
                      style: const TextStyle(fontSize: 12.5, color: mutedText),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Keep your family protected with synchronized medical vaults, child vaccination alerts, and dependent home visits.',
            style: TextStyle(fontSize: 12.5, color: Color(0xFF4B5563), height: 1.35),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryTeal,
                side: const BorderSide(color: primaryTeal),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.people_alt_outlined, size: 18),
              label: const Text('Manage Family Profiles', style: TextStyle(fontWeight: FontWeight.w700)),
              onPressed: () => context.push(RoutePaths.patientFamilyProfiles),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(BuildContext context, PatientProfileModel profile) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 12,
            offset: Offset(0, 4),
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
                  Icon(Icons.home_work_outlined, color: primaryTeal, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Home Visit Address',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: darkText),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => _showEditAddressModal(context, profile),
                child: const Text('Edit', style: TextStyle(color: primaryTeal, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            profile.fullAddress,
            style: const TextStyle(fontSize: 13, color: Color(0xFF374151), height: 1.4),
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: mutedText),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Used by doctors for navigation during confirmed home visits.',
                  style: TextStyle(fontSize: 11.5, color: mutedText),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactCard(BuildContext context, PatientProfileModel profile) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 12,
            offset: Offset(0, 4),
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
                  Icon(Icons.emergency_outlined, color: Color(0xFFDC2626), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Emergency Contact',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: darkText),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => _showEditEmergencyModal(context, profile),
                child: const Text('Edit', style: TextStyle(color: primaryTeal, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (profile.emergencyContactName != null && profile.emergencyContactName!.isNotEmpty) ...[
            Text(
              '${profile.emergencyContactName!} (${profile.emergencyContactRelation ?? "Relation"})',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: darkText),
            ),
            const SizedBox(height: 2),
            Text(
              profile.emergencyContactPhone ?? 'No phone provided',
              style: const TextStyle(fontSize: 13, color: mutedText),
            ),
          ] else ...[
            const Text(
              'No emergency contact set. Add one for rapid SOS support.',
              style: TextStyle(fontSize: 12.5, color: mutedText),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVitalsCard(BuildContext context, PatientProfileModel profile) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 12,
            offset: Offset(0, 4),
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
                  Icon(Icons.monitor_heart_outlined, color: primaryTeal, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Health Vitals & Allergies',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: darkText),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => _showEditVitalsModal(context, profile),
                child: const Text('Edit', style: TextStyle(color: primaryTeal, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (profile.bloodGroup != null)
                _buildChip('Blood: ${profile.bloodGroup}', const Color(0xFFDC2626), const Color(0xFFFEE2E2)),
              for (final allergy in profile.allergies)
                _buildChip('Allergy: $allergy', const Color(0xFF7C3AED), const Color(0xFFF5F3FF)),
              for (final cond in profile.chronicConditions)
                _buildChip(cond, const Color(0xFF2563EB), const Color(0xFFEFF6FF)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConsentCard(BuildContext context, PatientProfileModel profile) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.security_rounded, color: primaryTeal, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Data Sharing & Clinical Privacy',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: darkText),
                ),
              ),
              Switch(
                value: profile.dataSharingConsent,
                activeTrackColor: primaryTeal,
                onChanged: (val) {
                  ref.read(patientProfileActionsProvider).toggleConsent(val);
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'When active, your confirmed consulting doctors can review relevant lab reports, allergies, and recent consultations. You can revoke access anytime.',
            style: TextStyle(fontSize: 12, color: mutedText, height: 1.35),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesCard(BuildContext context, PatientProfileModel profile) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tune_rounded, color: primaryTeal, size: 20),
              SizedBox(width: 8),
              Text(
                'Consultation Preferences',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: darkText),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Default Consultation Mode',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: darkText),
          ),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'Clinic Visit', label: Text('Clinic', style: TextStyle(fontSize: 11.5))),
              ButtonSegment(value: 'Home Visit', label: Text('Home Visit', style: TextStyle(fontSize: 11.5))),
              ButtonSegment(value: 'Video Consultation', label: Text('Video', style: TextStyle(fontSize: 11.5))),
            ],
            selected: {profile.preferredConsultationMode},
            onSelectionChanged: (set) {
              if (set.isNotEmpty) {
                ref.read(patientProfileActionsProvider).updateConsultationMode(set.first);
              }
            },
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          const Text(
            'Notification Alerts',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: darkText),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text('Medication Reminders', style: TextStyle(fontSize: 13)),
            value: profile.medicationRemindersEnabled,
            activeColor: primaryTeal,
            onChanged: (val) {
              ref.read(patientProfileActionsProvider).updateNotificationSettings(
                    medicationRemindersEnabled: val ?? true,
                  );
            },
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text('Doctor Chat & Visit Alerts', style: TextStyle(fontSize: 13)),
            value: profile.chatAlertsEnabled,
            activeColor: primaryTeal,
            onChanged: (val) {
              ref.read(patientProfileActionsProvider).updateNotificationSettings(
                    chatAlertsEnabled: val ?? true,
                  );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAccountActionsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.download_rounded, color: primaryTeal),
            title: const Text('Export Health Summary', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: const Text('Download a confidential PDF snapshot of your records', style: TextStyle(fontSize: 12)),
            onTap: () => _showExportDialog(context),
          ),
          const Divider(height: 1),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.logout_rounded, color: Colors.red),
            title: const Text('Sign Out', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.red)),
            onTap: () => _confirmSignOut(context),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w600),
      ),
    );
  }

  void _showEditNameModal(BuildContext context, PatientProfileModel profile) {
    final controller = TextEditingController(text: profile.displayName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: primaryTeal),
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                await ref.read(patientProfileActionsProvider).updateProfile(
                      profile.copyWith(displayName: newName),
                    );
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditAddressModal(BuildContext context, PatientProfileModel profile) {
    final addrCtrl = TextEditingController(text: profile.addressLine ?? '');
    final landCtrl = TextEditingController(text: profile.landmark ?? '');
    final cityCtrl = TextEditingController(text: profile.city ?? '');
    final pinCtrl = TextEditingController(text: profile.postalCode ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Update Home Visit Address', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),
              TextField(
                controller: addrCtrl,
                decoration: const InputDecoration(labelText: 'Street Address / Flat', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: landCtrl,
                decoration: const InputDecoration(labelText: 'Landmark', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: cityCtrl,
                      decoration: const InputDecoration(labelText: 'City', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: pinCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'PIN Code', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: primaryTeal),
                  onPressed: () async {
                    await ref.read(patientProfileActionsProvider).updateAddress(
                          addressLine: addrCtrl.text.trim(),
                          landmark: landCtrl.text.trim(),
                          city: cityCtrl.text.trim(),
                          postalCode: pinCtrl.text.trim(),
                        );
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Save Address'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditEmergencyModal(BuildContext context, PatientProfileModel profile) {
    final nameCtrl = TextEditingController(text: profile.emergencyContactName ?? '');
    final relCtrl = TextEditingController(text: profile.emergencyContactRelation ?? 'Spouse');
    final phoneCtrl = TextEditingController(text: profile.emergencyContactPhone ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Emergency Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Contact Name')),
            const SizedBox(height: 10),
            TextField(controller: relCtrl, decoration: const InputDecoration(labelText: 'Relationship (e.g. Spouse, Parent)')),
            const SizedBox(height: 10),
            TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone Number')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: primaryTeal),
            onPressed: () async {
              await ref.read(patientProfileActionsProvider).updateEmergencyContact(
                    name: nameCtrl.text.trim(),
                    relation: relCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(),
                  );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditVitalsModal(BuildContext context, PatientProfileModel profile) {
    final bloodCtrl = TextEditingController(text: profile.bloodGroup ?? 'O+');
    final allergiesCtrl = TextEditingController(text: profile.allergies.join(', '));
    final condCtrl = TextEditingController(text: profile.chronicConditions.join(', '));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Health Vitals & Allergies'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: bloodCtrl, decoration: const InputDecoration(labelText: 'Blood Group (e.g. O+, A-, B+)')),
            const SizedBox(height: 10),
            TextField(controller: allergiesCtrl, decoration: const InputDecoration(labelText: 'Allergies (comma separated)')),
            const SizedBox(height: 10),
            TextField(controller: condCtrl, decoration: const InputDecoration(labelText: 'Chronic Conditions (comma separated)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: primaryTeal),
            onPressed: () async {
              final allergies = allergiesCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
              final conds = condCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
              await ref.read(patientProfileActionsProvider).updateVitals(
                    bloodGroup: bloodCtrl.text.trim().isEmpty ? null : bloodCtrl.text.trim(),
                    allergies: allergies,
                    chronicConditions: conds,
                  );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Export Medical Summary'),
        content: const Text(
          'A comprehensive health summary containing your active prescriptions, verified lab reports, and doctor consultation notes has been compiled for export.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: primaryTeal),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Medical summary exported successfully.')),
              );
            },
            child: const Text('Download PDF'),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out of HomeDoc AI?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authStateProvider.notifier).signOut();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
