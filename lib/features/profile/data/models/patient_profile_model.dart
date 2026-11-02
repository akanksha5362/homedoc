import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Patient Profile details for appointments, home visits, and emergency contacts (Master Prompt §10).
class PatientProfileModel extends Equatable {
  const PatientProfileModel({
    required this.id,
    required this.displayName,
    this.phone,
    this.email,
    this.addressLine,
    this.landmark,
    this.city,
    this.postalCode,
    this.emergencyContactName,
    this.emergencyContactRelation,
    this.emergencyContactPhone,
    this.bloodGroup,
    this.allergies = const [],
    this.chronicConditions = const [],
    this.preferredConsultationMode = 'Clinic Visit',
    this.dataSharingConsent = true,
    this.notificationsEnabled = true,
    this.medicationRemindersEnabled = true,
    this.chatAlertsEnabled = true,
    this.isVerified = true,
    required this.createdAt,
  });

  final String id;
  final String displayName;
  final String? phone;
  final String? email;

  // Primary Address for Doctor Home Visits & Deliveries
  final String? addressLine;
  final String? landmark;
  final String? city;
  final String? postalCode;

  // Emergency Contact
  final String? emergencyContactName;
  final String? emergencyContactRelation;
  final String? emergencyContactPhone;

  // Clinical Vitals & Attributes
  final String? bloodGroup;
  final List<String> allergies;
  final List<String> chronicConditions;

  // Preferences & Consents
  final String preferredConsultationMode;
  final bool dataSharingConsent;
  final bool notificationsEnabled;
  final bool medicationRemindersEnabled;
  final bool chatAlertsEnabled;
  final bool isVerified;
  final DateTime createdAt;

  String get fullAddress {
    final parts = [addressLine, landmark, city, postalCode]
        .where((p) => p != null && p.trim().isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'No primary home address configured';
    return parts.join(', ');
  }

  factory PatientProfileModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return PatientProfileModel.fromMap(data, doc.id);
  }

  factory PatientProfileModel.fromMap(Map<String, dynamic> data, [String? docId]) {
    DateTime created = DateTime.now();
    final rawCreated = data['createdAt'];
    if (rawCreated is Timestamp) {
      created = rawCreated.toDate();
    } else if (rawCreated is String) {
      created = DateTime.tryParse(rawCreated) ?? DateTime.now();
    }

    final rawAllergies = data['allergies'];
    final allergies = rawAllergies is List ? rawAllergies.map((e) => e.toString()).toList() : <String>[];

    final rawConditions = data['chronicConditions'];
    final conditions = rawConditions is List ? rawConditions.map((e) => e.toString()).toList() : <String>[];

    return PatientProfileModel(
      id: docId ?? (data['id'] ?? '').toString(),
      displayName: (data['displayName'] ?? data['name'] ?? 'Primary Patient').toString(),
      phone: data['phone'] as String?,
      email: data['email'] as String?,
      addressLine: data['addressLine'] as String?,
      landmark: data['landmark'] as String?,
      city: data['city'] as String?,
      postalCode: data['postalCode'] as String?,
      emergencyContactName: data['emergencyContactName'] as String?,
      emergencyContactRelation: data['emergencyContactRelation'] as String?,
      emergencyContactPhone: data['emergencyContactPhone'] as String?,
      bloodGroup: data['bloodGroup'] as String?,
      allergies: allergies,
      chronicConditions: conditions,
      preferredConsultationMode: (data['preferredConsultationMode'] ?? 'Clinic Visit').toString(),
      dataSharingConsent: data['dataSharingConsent'] as bool? ?? true,
      notificationsEnabled: data['notificationsEnabled'] as bool? ?? true,
      medicationRemindersEnabled: data['medicationRemindersEnabled'] as bool? ?? true,
      chatAlertsEnabled: data['chatAlertsEnabled'] as bool? ?? true,
      isVerified: data['isVerified'] as bool? ?? true,
      createdAt: created,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'displayName': displayName,
        if (phone != null) 'phone': phone,
        if (email != null) 'email': email,
        if (addressLine != null) 'addressLine': addressLine,
        if (landmark != null) 'landmark': landmark,
        if (city != null) 'city': city,
        if (postalCode != null) 'postalCode': postalCode,
        if (emergencyContactName != null) 'emergencyContactName': emergencyContactName,
        if (emergencyContactRelation != null) 'emergencyContactRelation': emergencyContactRelation,
        if (emergencyContactPhone != null) 'emergencyContactPhone': emergencyContactPhone,
        if (bloodGroup != null) 'bloodGroup': bloodGroup,
        'allergies': allergies,
        'chronicConditions': chronicConditions,
        'preferredConsultationMode': preferredConsultationMode,
        'dataSharingConsent': dataSharingConsent,
        'notificationsEnabled': notificationsEnabled,
        'medicationRemindersEnabled': medicationRemindersEnabled,
        'chatAlertsEnabled': chatAlertsEnabled,
        'isVerified': isVerified,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  PatientProfileModel copyWith({
    String? id,
    String? displayName,
    String? phone,
    String? email,
    String? addressLine,
    String? landmark,
    String? city,
    String? postalCode,
    String? emergencyContactName,
    String? emergencyContactRelation,
    String? emergencyContactPhone,
    String? bloodGroup,
    List<String>? allergies,
    List<String>? chronicConditions,
    String? preferredConsultationMode,
    bool? dataSharingConsent,
    bool? notificationsEnabled,
    bool? medicationRemindersEnabled,
    bool? chatAlertsEnabled,
    bool? isVerified,
    DateTime? createdAt,
  }) {
    return PatientProfileModel(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      addressLine: addressLine ?? this.addressLine,
      landmark: landmark ?? this.landmark,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactRelation: emergencyContactRelation ?? this.emergencyContactRelation,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      allergies: allergies ?? this.allergies,
      chronicConditions: chronicConditions ?? this.chronicConditions,
      preferredConsultationMode: preferredConsultationMode ?? this.preferredConsultationMode,
      dataSharingConsent: dataSharingConsent ?? this.dataSharingConsent,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      medicationRemindersEnabled: medicationRemindersEnabled ?? this.medicationRemindersEnabled,
      chatAlertsEnabled: chatAlertsEnabled ?? this.chatAlertsEnabled,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        displayName,
        phone,
        email,
        addressLine,
        landmark,
        city,
        postalCode,
        emergencyContactName,
        emergencyContactRelation,
        emergencyContactPhone,
        bloodGroup,
        allergies,
        chronicConditions,
        preferredConsultationMode,
        dataSharingConsent,
        notificationsEnabled,
        medicationRemindersEnabled,
        chatAlertsEnabled,
        isVerified,
        createdAt,
      ];
}
