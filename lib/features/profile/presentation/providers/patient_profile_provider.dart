import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../data/models/patient_profile_model.dart';

class PatientProfileActions {
  PatientProfileActions(this._firestore, this._ref);

  final FirebaseFirestore _firestore;
  final Ref _ref;

  String? get _currentUserId => _ref.read(authStateProvider).user?.id;

  DocumentReference<Map<String, dynamic>>? get _userDocRef {
    final uid = _currentUserId;
    if (uid == null || uid.isEmpty) return null;
    return _firestore.collection('users').doc(uid);
  }

  Future<void> updateProfile(PatientProfileModel profile) async {
    final docRef = _userDocRef;
    if (docRef == null) throw Exception('Please sign in to update profile.');
    await docRef.set(profile.toFirestore(), SetOptions(merge: true));
  }

  Future<void> updateAddress({
    required String addressLine,
    String? landmark,
    required String city,
    required String postalCode,
  }) async {
    final docRef = _userDocRef;
    if (docRef == null) throw Exception('Please sign in to update address.');
    await docRef.set({
      'addressLine': addressLine,
      'landmark': landmark ?? '',
      'city': city,
      'postalCode': postalCode,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateEmergencyContact({
    required String name,
    required String relation,
    required String phone,
  }) async {
    final docRef = _userDocRef;
    if (docRef == null) throw Exception('Please sign in to update emergency contact.');
    await docRef.set({
      'emergencyContactName': name,
      'emergencyContactRelation': relation,
      'emergencyContactPhone': phone,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateVitals({
    String? bloodGroup,
    List<String>? allergies,
    List<String>? chronicConditions,
  }) async {
    final docRef = _userDocRef;
    if (docRef == null) throw Exception('Please sign in to update vitals.');
    final data = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (bloodGroup != null) data['bloodGroup'] = bloodGroup;
    if (allergies != null) data['allergies'] = allergies;
    if (chronicConditions != null) data['chronicConditions'] = chronicConditions;
    await docRef.set(data, SetOptions(merge: true));
  }

  Future<void> toggleConsent(bool consent) async {
    final docRef = _userDocRef;
    if (docRef == null) throw Exception('Please sign in to update consent.');
    await docRef.set({
      'dataSharingConsent': consent,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateConsultationMode(String mode) async {
    final docRef = _userDocRef;
    if (docRef == null) throw Exception('Please sign in to update preferences.');
    await docRef.set({
      'preferredConsultationMode': mode,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateNotificationSettings({
    bool? notificationsEnabled,
    bool? medicationRemindersEnabled,
    bool? chatAlertsEnabled,
  }) async {
    final docRef = _userDocRef;
    if (docRef == null) throw Exception('Please sign in to update notification settings.');
    final data = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (notificationsEnabled != null) data['notificationsEnabled'] = notificationsEnabled;
    if (medicationRemindersEnabled != null) data['medicationRemindersEnabled'] = medicationRemindersEnabled;
    if (chatAlertsEnabled != null) data['chatAlertsEnabled'] = chatAlertsEnabled;
    await docRef.set(data, SetOptions(merge: true));
  }
}

final patientProfileActionsProvider = Provider<PatientProfileActions>((ref) {
  return PatientProfileActions(ref.watch(firestoreProvider), ref);
});

/// Real-time stream of the authenticated patient's profile.
final patientProfileStreamProvider = StreamProvider<PatientProfileModel>((ref) {
  final auth = ref.watch(authStateProvider);
  final user = auth.user;

  final defaultProfile = PatientProfileModel(
    id: user?.id ?? 'patient-default',
    displayName: user?.displayName ?? 'Patient',
    phone: user?.phone ?? '+919876543210',
    email: 'patient@homedoc.ai',
    addressLine: 'Flat 402, Green Glen Layout, Bellandur',
    landmark: 'Opposite Ecospace Tech Park',
    city: 'Bengaluru',
    postalCode: '560103',
    emergencyContactName: 'Priya Sharma',
    emergencyContactRelation: 'Spouse',
    emergencyContactPhone: '+919876543210',
    bloodGroup: 'O+',
    allergies: const ['Penicillin'],
    chronicConditions: const ['Mild Hypertension'],
    preferredConsultationMode: 'Home Visit',
    dataSharingConsent: true,
    notificationsEnabled: true,
    medicationRemindersEnabled: true,
    chatAlertsEnabled: true,
    isVerified: true,
    createdAt: DateTime.now(),
  );

  final uid = user?.id;
  if (uid == null || uid.isEmpty) {
    return Stream.value(defaultProfile);
  }

  final firestore = ref.watch(firestoreProvider);

  return firestore.collection('users').doc(uid).snapshots().map((snapshot) {
    if (!snapshot.exists || snapshot.data() == null) {
      return defaultProfile;
    }
    return PatientProfileModel.fromFirestore(snapshot);
  }).handleError((_) => defaultProfile);
});
