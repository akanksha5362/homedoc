import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// An emergency contact stored under `users/{uid}/emergency_contacts`.
class EmergencyContactModel extends Equatable {
  const EmergencyContactModel({
    required this.id,
    required this.name,
    required this.phone,
    this.relationship = '',
    required this.createdAt,
  });

  final String id;
  final String name;
  final String phone;
  final String relationship;
  final DateTime createdAt;

  factory EmergencyContactModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    DateTime created = DateTime.now();
    if (data['createdAt'] is Timestamp) {
      created = (data['createdAt'] as Timestamp).toDate();
    }
    return EmergencyContactModel(
      id: doc.id,
      name: data['name'] as String? ?? 'Emergency Contact',
      phone: data['phone'] as String? ?? '',
      relationship: data['relationship'] as String? ?? '',
      createdAt: created,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'phone': phone,
        'relationship': relationship,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  EmergencyContactModel copyWith({
    String? name,
    String? phone,
    String? relationship,
  }) =>
      EmergencyContactModel(
        id: id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        relationship: relationship ?? this.relationship,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props => [id, name, phone, relationship, createdAt];
}
