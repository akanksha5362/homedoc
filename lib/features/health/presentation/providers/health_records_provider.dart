import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/auth_provider.dart';
import '../../data/models/health_record_model.dart';

/// Live stream of health records for the current patient.
final patientHealthRecordsProvider =
    StreamProvider<List<HealthRecordModel>>((ref) {
  final auth = ref.watch(authStateProvider);
  final patientId = auth.user?.id;

  if (patientId == null || patientId.isEmpty) {
    return Stream.value([]);
  }

  final firestore = ref.watch(firestoreProvider);

  return firestore
      .collection('users')
      .doc(patientId)
      .collection('health_records')
      .orderBy('date', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs
        .map(HealthRecordModel.fromFirestore)
        .toList();
  });
});

/// Live stream of patient emergency vitals (blood group, allergies, conditions).
final patientVitalsProvider = StreamProvider<Map<String, String>>((ref) {
  final auth = ref.watch(authStateProvider);
  final patientId = auth.user?.id;

  if (patientId == null || patientId.isEmpty) {
    return Stream.value({
      'bloodGroup': 'Not set',
      'allergies': 'None known',
      'chronicConditions': 'None reported',
    });
  }

  final firestore = ref.watch(firestoreProvider);

  return firestore
      .collection('users')
      .doc(patientId)
      .snapshots()
      .map((doc) {
    final data = doc.data() ?? {};
    return {
      'bloodGroup': data['bloodGroup'] as String? ?? 'Not set',
      'allergies': data['allergies'] as String? ?? 'None known',
      'chronicConditions': data['chronicConditions'] as String? ?? 'None reported',
    };
  });
});

/// Actions for creating and managing health records.
class HealthRecordsActions {
  HealthRecordsActions(this._ref);

  final Ref _ref;

  Future<void> addRecord({
    required String title,
    required HealthRecordCategory category,
    required String doctorOrClinic,
    required DateTime date,
    required String notes,
    String? fileUrl,
    String? fileName,
    List<PrescriptionMedicine> medicines = const [],
  }) async {
    final auth = _ref.read(authStateProvider);
    final patientId = auth.user?.id;

    if (patientId == null || patientId.isEmpty) {
      throw Exception('Patient not authenticated.');
    }

    final firestore = _ref.read(firestoreProvider);
    final collection = firestore
        .collection('users')
        .doc(patientId)
        .collection('health_records');

    await collection.add({
      'title': title.trim(),
      'category': category.name,
      'doctorOrClinic': doctorOrClinic.trim(),
      'date': Timestamp.fromDate(date),
      'notes': notes.trim(),
      'fileUrl': ?fileUrl,
      'fileName': ?fileName,
      'medicines': medicines.map((m) => m.toMap()).toList(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteRecord(String recordId) async {
    final auth = _ref.read(authStateProvider);
    final patientId = auth.user?.id;

    if (patientId == null || patientId.isEmpty) {
      throw Exception('Patient not authenticated.');
    }

    final firestore = _ref.read(firestoreProvider);
    await firestore
        .collection('users')
        .doc(patientId)
        .collection('health_records')
        .doc(recordId)
        .delete();
  }

  Future<void> updateVitals({
    required String bloodGroup,
    required String allergies,
    required String chronicConditions,
  }) async {
    final auth = _ref.read(authStateProvider);
    final patientId = auth.user?.id;

    if (patientId == null || patientId.isEmpty) {
      throw Exception('Patient not authenticated.');
    }

    final firestore = _ref.read(firestoreProvider);
    await firestore.collection('users').doc(patientId).set({
      'bloodGroup': bloodGroup.trim(),
      'allergies': allergies.trim(),
      'chronicConditions': chronicConditions.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

final healthRecordsActionsProvider = Provider<HealthRecordsActions>((ref) {
  return HealthRecordsActions(ref);
});
