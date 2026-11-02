import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_provider.dart';

/// Live stream of active, discoverable public doctor profiles from Firestore.
final verifiedDoctorsProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final firestore = ref.watch(firestoreProvider);

  return firestore
      .collection('doctor_public_profiles')
      .where('isActive', isEqualTo: true)
      .where('isVerified', isEqualTo: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data();

      final languagesRaw = data['languages'];
      final languages = languagesRaw is List
          ? languagesRaw.map((e) => e.toString()).toList()
          : <String>['English', 'Hindi'];

      final historyRaw = data['professionalHistory'];
      final professionalHistory = historyRaw is List
          ? historyRaw.map((e) => e.toString()).toList()
          : <String>[];

      final profileType = data['profileType'] as String? ?? 'real';
      final isDemo = profileType == 'demo' || doc.id.startsWith('demo_');

      return {
        ...data,
        'doctorId': doc.id,
        'name': data['displayName'] ?? 'Doctor',
        'displayName': data['displayName'] ?? 'Doctor',
        'specialty': data['specialization'] ?? 'Specialization not added',
        'specialization': data['specialization'] ?? 'Specialization not added',
        'hospital': data['hospital'] ?? 'General Medical Care',
        'qualifications': data['qualifications'] ?? 'Medical Practitioner',
        'experienceYears': data['experienceYears'] ?? 0,
        'consultationFee': data['consultationFee'] ?? 500,
        'location': data['location'] ?? 'Not specified',
        'bio': data['bio'] ?? '',
        'languages': languages,
        'professionalHistory': professionalHistory,
        'profileType': profileType,
        'isDemo': isDemo,
        'photoUrl': data['photoUrl'] as String? ?? '',
        'rating': (data['rating'] as num?)?.toDouble() ?? 4.8,
      };
    }).toList();
  });
});
