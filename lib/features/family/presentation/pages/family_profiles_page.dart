import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/family_member_model.dart';
import '../providers/family_provider.dart';

/// Family Healthcare Management Screen (Master Prompt §10).
///
/// Allows patients to manage family member health profiles and dependents
/// for synchronized appointments, health records, and emergency alerts.
class FamilyProfilesPage extends ConsumerStatefulWidget {
  const FamilyProfilesPage({super.key});

  @override
  ConsumerState<FamilyProfilesPage> createState() => _FamilyProfilesPageState();
}

class _FamilyProfilesPageState extends ConsumerState<FamilyProfilesPage> {
  static const Color primaryTeal = Color(0xFF007A8A);
  static const Color lightTeal = Color(0xFFE6F7F6);
  static const Color textDark = Color(0xFF111827);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color cardBorder = Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context) {
    final familyAsync = ref.watch(familyMembersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Family Healthcare Profiles',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded, color: primaryTeal),
            tooltip: 'Add Family Member',
            onPressed: () => _showAddMemberModal(context),
          ),
        ],
      ),
      body: SafeArea(
        child: familyAsync.when(
          data: (members) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: lightTeal,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: primaryTeal.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.family_restroom_rounded, color: primaryTeal, size: 26),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dependents & Family Care',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: textDark,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Easily schedule visits, manage prescriptions, and track vitals for your children and elderly parents.',
                              style: TextStyle(fontSize: 12, color: Color(0xFF4B5563), height: 1.35),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Registered Profiles',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: textDark,
                      ),
                    ),
                    Text(
                      '${members.length} members',
                      style: const TextStyle(fontSize: 13, color: textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                for (final member in members)
                  _buildMemberCard(context, member),
                const SizedBox(height: 16),

                // Add Member Action Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryTeal,
                      side: const BorderSide(color: primaryTeal),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: const Text(
                      'Add Dependent or Family Member',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                    ),
                    onPressed: () => _showAddMemberModal(context),
                  ),
                ),
              ],
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator(color: primaryTeal)),
          error: (err, _) => Center(child: Text('Error loading profiles: $err')),
        ),
      ),
    );
  }

  Widget _buildMemberCard(BuildContext context, FamilyMemberModel member) {
    final isSelf = member.id == 'self';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isSelf ? primaryTeal.withValues(alpha: 0.4) : cardBorder),
        boxShadow: const [
          BoxShadow(color: Color(0x05000000), blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: isSelf ? lightTeal : const Color(0xFFF1F5F9),
                foregroundColor: isSelf ? primaryTeal : const Color(0xFF475569),
                child: Icon(
                  member.relationship == 'Child'
                      ? Icons.child_care_rounded
                      : (member.relationship == 'Parent'
                          ? Icons.elderly_rounded
                          : Icons.person_rounded),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            member.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: textDark,
                            ),
                          ),
                        ),
                        if (isSelf) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: lightTeal,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Primary',
                              style: TextStyle(color: primaryTeal, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${member.relationship} • ${member.gender}${member.ageYears != null ? " • ${member.ageYears}y" : ""}',
                      style: const TextStyle(fontSize: 12.5, color: textMuted),
                    ),
                  ],
                ),
              ),
              if (!isSelf)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: textMuted),
                  onSelected: (val) {
                    if (val == 'edit') {
                      _showEditMemberModal(context, member);
                    } else if (val == 'delete') {
                      _confirmDelete(context, member);
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit Profile')),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete Profile', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Vitals & Health Attributes
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (member.bloodGroup != null)
                _buildTag('Blood: ${member.bloodGroup}', const Color(0xFFDC2626), const Color(0xFFFEE2E2)),
              if (member.isEmergencyContact)
                _buildTag('Emergency Contact', const Color(0xFFD97706), const Color(0xFFFEF3C7)),
              for (final allergy in member.allergies)
                _buildTag('Allergy: $allergy', const Color(0xFF7C3AED), const Color(0xFFF5F3FF)),
              for (final condition in member.chronicConditions)
                _buildTag(condition, const Color(0xFF2563EB), const Color(0xFFEFF6FF)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String label, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  void _showAddMemberModal(BuildContext context) {
    final nameController = TextEditingController();
    final allergiesController = TextEditingController();
    final conditionsController = TextEditingController();
    final phoneController = TextEditingController();
    String relationship = 'Spouse';
    String gender = 'Female';
    String bloodGroup = 'O+';
    bool isEmergency = false;
    DateTime? dob = DateTime(1995, 1, 1);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Add Family Member',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textDark),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: relationship,
                        decoration: const InputDecoration(labelText: 'Relationship', border: OutlineInputBorder()),
                        items: ['Spouse', 'Child', 'Parent', 'Sibling', 'Other']
                            .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => relationship = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: gender,
                        decoration: const InputDecoration(labelText: 'Gender', border: OutlineInputBorder()),
                        items: ['Female', 'Male', 'Other']
                            .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => gender = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: bloodGroup,
                        decoration: const InputDecoration(labelText: 'Blood Group', border: OutlineInputBorder()),
                        items: ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-']
                            .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => bloodGroup = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: dob ?? DateTime(2000, 1, 1),
                            firstDate: DateTime(1920),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setModalState(() => dob = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'Birth Date', border: OutlineInputBorder()),
                          child: Text(dob != null ? DateFormat('d MMM y').format(dob!) : 'Select'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: allergiesController,
                  decoration: const InputDecoration(
                    labelText: 'Known Allergies (comma separated)',
                    hintText: 'e.g. Penicillin, Peanuts, Pollen',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: conditionsController,
                  decoration: const InputDecoration(
                    labelText: 'Chronic Conditions (comma separated)',
                    hintText: 'e.g. Asthma, Diabetes, Hypertension',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Mark as Emergency Contact', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                  value: isEmergency,
                  activeColor: primaryTeal,
                  onChanged: (val) => setModalState(() => isEmergency = val ?? false),
                ),
                if (isEmergency)
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Emergency Phone Number',
                      prefixIcon: Icon(Icons.phone_outlined, size: 20),
                      border: OutlineInputBorder(),
                    ),
                  ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryTeal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      final name = nameController.text.trim();
                      if (name.isEmpty) return;

                      final allergies = allergiesController.text
                          .split(',')
                          .map((e) => e.trim())
                          .where((e) => e.isNotEmpty)
                          .toList();

                      final conditions = conditionsController.text
                          .split(',')
                          .map((e) => e.trim())
                          .where((e) => e.isNotEmpty)
                          .toList();

                      final member = FamilyMemberModel(
                        id: '',
                        name: name,
                        relationship: relationship,
                        gender: gender,
                        bloodGroup: bloodGroup,
                        dateOfBirth: dob,
                        allergies: allergies,
                        chronicConditions: conditions,
                        isEmergencyContact: isEmergency,
                        emergencyPhone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
                        createdAt: DateTime.now(),
                      );

                      await ref.read(familyActionsProvider).addFamilyMember(member);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('Save Family Member', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditMemberModal(BuildContext context, FamilyMemberModel member) {
    final nameController = TextEditingController(text: member.name);
    final allergiesController = TextEditingController(text: member.allergies.join(', '));
    final conditionsController = TextEditingController(text: member.chronicConditions.join(', '));
    final phoneController = TextEditingController(text: member.emergencyPhone ?? '');
    String relationship = member.relationship;
    String gender = member.gender;
    String bloodGroup = member.bloodGroup ?? 'O+';
    bool isEmergency = member.isEmergencyContact;
    DateTime? dob = member.dateOfBirth;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Edit Family Member',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textDark),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: relationship,
                        decoration: const InputDecoration(labelText: 'Relationship', border: OutlineInputBorder()),
                        items: ['Spouse', 'Child', 'Parent', 'Sibling', 'Other']
                            .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => relationship = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: gender,
                        decoration: const InputDecoration(labelText: 'Gender', border: OutlineInputBorder()),
                        items: ['Female', 'Male', 'Other']
                            .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => gender = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: bloodGroup,
                        decoration: const InputDecoration(labelText: 'Blood Group', border: OutlineInputBorder()),
                        items: ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-']
                            .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => bloodGroup = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: dob ?? DateTime(2000, 1, 1),
                            firstDate: DateTime(1920),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setModalState(() => dob = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'Birth Date', border: OutlineInputBorder()),
                          child: Text(dob != null ? DateFormat('d MMM y').format(dob!) : 'Select'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: allergiesController,
                  decoration: const InputDecoration(
                    labelText: 'Known Allergies',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: conditionsController,
                  decoration: const InputDecoration(
                    labelText: 'Chronic Conditions',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Mark as Emergency Contact', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                  value: isEmergency,
                  activeColor: primaryTeal,
                  onChanged: (val) => setModalState(() => isEmergency = val ?? false),
                ),
                if (isEmergency)
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Emergency Phone Number',
                      border: OutlineInputBorder(),
                    ),
                  ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryTeal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      final name = nameController.text.trim();
                      if (name.isEmpty) return;

                      final allergies = allergiesController.text
                          .split(',')
                          .map((e) => e.trim())
                          .where((e) => e.isNotEmpty)
                          .toList();

                      final conditions = conditionsController.text
                          .split(',')
                          .map((e) => e.trim())
                          .where((e) => e.isNotEmpty)
                          .toList();

                      final updated = member.copyWith(
                        name: name,
                        relationship: relationship,
                        gender: gender,
                        bloodGroup: bloodGroup,
                        dateOfBirth: dob,
                        allergies: allergies,
                        chronicConditions: conditions,
                        isEmergencyContact: isEmergency,
                        emergencyPhone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
                      );

                      await ref.read(familyActionsProvider).updateFamilyMember(updated);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, FamilyMemberModel member) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Family Profile'),
        content: Text('Are you sure you want to remove ${member.name} from your registered family members?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await ref.read(familyActionsProvider).deleteFamilyMember(member.id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
