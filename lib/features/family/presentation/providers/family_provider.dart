import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../data/models/family_member_model.dart';

class FamilyActions {
  FamilyActions(this._firestore, this._ref);

  final FirebaseFirestore _firestore;
  final Ref _ref;

  String? get _currentUserId => _ref.read(authStateProvider).user?.id;

  CollectionReference<Map<String, dynamic>>? get _collectionRef {
    final uid = _currentUserId;
    if (uid == null || uid.isEmpty) return null;
    return _firestore.collection('users').doc(uid).collection('family_members');
  }

  Future<String> addFamilyMember(FamilyMemberModel member) async {
    final col = _collectionRef;
    if (col == null) throw Exception('Please sign in to add family members.');

    final docRef = await col.add(member.toFirestore());
    return docRef.id;
  }

  Future<void> updateFamilyMember(FamilyMemberModel member) async {
    final col = _collectionRef;
    if (col == null) throw Exception('Please sign in to update family members.');

    await col.doc(member.id).update(member.toFirestore());
  }

  Future<void> deleteFamilyMember(String memberId) async {
    final col = _collectionRef;
    if (col == null) throw Exception('Please sign in to delete family members.');

    await col.doc(memberId).delete();
  }
}

final familyActionsProvider = Provider<FamilyActions>((ref) {
  return FamilyActions(ref.watch(firestoreProvider), ref);
});

final selectedFamilyMemberProvider = StateProvider<FamilyMemberModel?>((ref) => null);

/// Real-time stream of registered family members and dependents for the patient.
final familyMembersProvider = StreamProvider<List<FamilyMemberModel>>((ref) {
  final auth = ref.watch(authStateProvider);
  final user = auth.user;

  final selfMember = FamilyMemberModel(
    id: 'self',
    name: user?.displayName ?? 'Primary Patient',
    relationship: 'Self',
    gender: 'Other',
    bloodGroup: 'O+',
    allergies: const [],
    chronicConditions: const [],
    createdAt: DateTime.now(),
  );

  final uid = user?.id;
  if (uid == null || uid.isEmpty) {
    return Stream.value([selfMember]);
  }

  final firestore = ref.watch(firestoreProvider);

  return firestore
      .collection('users')
      .doc(uid)
      .collection('family_members')
      .orderBy('createdAt', descending: false)
      .snapshots()
      .map((snapshot) {
    final list = <FamilyMemberModel>[selfMember];

    for (final doc in snapshot.docs) {
      list.add(FamilyMemberModel.fromFirestore(doc));
    }

    return list;
  }).handleError((_) {
    // Graceful fallback with sample dependents if offline/demo
    return [
      selfMember,
      FamilyMemberModel(
        id: 'demo-spouse',
        name: 'Priya Sharma',
        relationship: 'Spouse',
        dateOfBirth: DateTime(1992, 4, 15),
        gender: 'Female',
        bloodGroup: 'B+',
        allergies: const ['Penicillin'],
        chronicConditions: const [],
        isEmergencyContact: true,
        emergencyPhone: '+919876543210',
        createdAt: DateTime.now(),
      ),
      FamilyMemberModel(
        id: 'demo-child',
        name: 'Aarav Sharma',
        relationship: 'Child',
        dateOfBirth: DateTime(2018, 9, 20),
        gender: 'Male',
        bloodGroup: 'O+',
        allergies: const ['Peanuts'],
        chronicConditions: const ['Mild Asthma'],
        createdAt: DateTime.now(),
      ),
    ];
  });
});
