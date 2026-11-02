import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/auth_provider.dart';
import '../../data/models/emergency_contact_model.dart';

/// Live stream of the current patient's emergency contacts.
final emergencyContactsProvider =
    StreamProvider<List<EmergencyContactModel>>((ref) {
  final auth = ref.watch(authStateProvider);
  final uid = auth.user?.id;
  if (uid == null || uid.isEmpty) return Stream.value([]);

  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('users')
      .doc(uid)
      .collection('emergency_contacts')
      .orderBy('createdAt')
      .snapshots()
      .map((snap) =>
          snap.docs.map(EmergencyContactModel.fromFirestore).toList());
});

/// Actions: add, update, delete emergency contacts.
class EmergencyContactActions {
  EmergencyContactActions(this._ref);
  final Ref _ref;

  FirebaseFirestore get _fs => _ref.read(firestoreProvider);
  String? get _uid => _ref.read(authStateProvider).user?.id;

  CollectionReference<Map<String, dynamic>> get _col =>
      _fs.collection('users').doc(_uid!).collection('emergency_contacts');

  Future<void> add({
    required String name,
    required String phone,
    required String relationship,
  }) async {
    if (_uid == null || _uid!.isEmpty) {
      throw Exception('Patient not authenticated.');
    }
    await _col.add({
      'name': name.trim(),
      'phone': phone.trim(),
      'relationship': relationship.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> update(EmergencyContactModel contact) async {
    if (_uid == null) return;
    await _col.doc(contact.id).update({
      'name': contact.name.trim(),
      'phone': contact.phone.trim(),
      'relationship': contact.relationship.trim(),
    });
  }

  Future<void> delete(String contactId) async {
    if (_uid == null) return;
    await _col.doc(contactId).delete();
  }
}

final emergencyContactActionsProvider =
    Provider<EmergencyContactActions>((ref) => EmergencyContactActions(ref));
