import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Represents a registered dependent or family member under the patient's account (Prompt §10).
class FamilyMemberModel extends Equatable {
  const FamilyMemberModel({
    required this.id,
    required this.name,
    required this.relationship,
    this.dateOfBirth,
    this.gender = 'Other',
    this.bloodGroup,
    this.allergies = const [],
    this.chronicConditions = const [],
    this.isEmergencyContact = false,
    this.emergencyPhone,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String relationship; // 'Self', 'Spouse', 'Child', 'Parent', 'Sibling', 'Other'
  final DateTime? dateOfBirth;
  final String gender;
  final String? bloodGroup;
  final List<String> allergies;
  final List<String> chronicConditions;
  final bool isEmergencyContact;
  final String? emergencyPhone;
  final DateTime createdAt;

  int? get ageYears {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month || (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  factory FamilyMemberModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return FamilyMemberModel.fromMap(data, doc.id);
  }

  factory FamilyMemberModel.fromMap(Map<String, dynamic> data, [String? docId]) {
    DateTime? dob;
    final rawDob = data['dateOfBirth'];
    if (rawDob is Timestamp) {
      dob = rawDob.toDate();
    } else if (rawDob is String) {
      dob = DateTime.tryParse(rawDob);
    }

    DateTime createdTime = DateTime.now();
    final rawCreated = data['createdAt'];
    if (rawCreated is Timestamp) {
      createdTime = rawCreated.toDate();
    } else if (rawCreated is String) {
      createdTime = DateTime.tryParse(rawCreated) ?? DateTime.now();
    }

    final rawAllergies = data['allergies'];
    final allergies = rawAllergies is List ? rawAllergies.map((e) => e.toString()).toList() : <String>[];

    final rawConditions = data['chronicConditions'];
    final conditions = rawConditions is List ? rawConditions.map((e) => e.toString()).toList() : <String>[];

    return FamilyMemberModel(
      id: docId ?? (data['id'] ?? '').toString(),
      name: (data['name'] ?? 'Family Member').toString(),
      relationship: (data['relationship'] ?? 'Self').toString(),
      dateOfBirth: dob,
      gender: (data['gender'] ?? 'Other').toString(),
      bloodGroup: data['bloodGroup'] as String?,
      allergies: allergies,
      chronicConditions: conditions,
      isEmergencyContact: data['isEmergencyContact'] as bool? ?? false,
      emergencyPhone: data['emergencyPhone'] as String?,
      createdAt: createdTime,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'relationship': relationship,
        if (dateOfBirth != null) 'dateOfBirth': Timestamp.fromDate(dateOfBirth!),
        'gender': gender,
        if (bloodGroup != null) 'bloodGroup': bloodGroup,
        'allergies': allergies,
        'chronicConditions': chronicConditions,
        'isEmergencyContact': isEmergencyContact,
        if (emergencyPhone != null) 'emergencyPhone': emergencyPhone,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  FamilyMemberModel copyWith({
    String? id,
    String? name,
    String? relationship,
    DateTime? dateOfBirth,
    String? gender,
    String? bloodGroup,
    List<String>? allergies,
    List<String>? chronicConditions,
    bool? isEmergencyContact,
    String? emergencyPhone,
    DateTime? createdAt,
  }) {
    return FamilyMemberModel(
      id: id ?? this.id,
      name: name ?? this.name,
      relationship: relationship ?? this.relationship,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      allergies: allergies ?? this.allergies,
      chronicConditions: chronicConditions ?? this.chronicConditions,
      isEmergencyContact: isEmergencyContact ?? this.isEmergencyContact,
      emergencyPhone: emergencyPhone ?? this.emergencyPhone,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        relationship,
        dateOfBirth,
        gender,
        bloodGroup,
        allergies,
        chronicConditions,
        isEmergencyContact,
        emergencyPhone,
        createdAt,
      ];
}
