import 'package:flutter_test/flutter_test.dart';
import 'package:homedoc/features/family/data/models/family_member_model.dart';
import 'package:homedoc/features/profile/data/models/patient_profile_model.dart';
import 'package:homedoc/shared/models/appointment_model.dart';

void main() {
  group('FamilyMemberModel Tests', () {
    test('Calculates age correctly from dateOfBirth', () {
      final dob = DateTime.now().subtract(const Duration(days: 365 * 10 + 3));
      final member = FamilyMemberModel(
        id: 'child-1',
        name: 'Aarav Sharma',
        relationship: 'Child',
        dateOfBirth: dob,
        gender: 'Male',
        createdAt: DateTime.now(),
      );

      expect(member.ageYears, isNotNull);
      expect(member.ageYears, equals(10));
    });

    test('Serializes to and from Firestore map properly', () {
      final now = DateTime(2025, 1, 15, 10, 30);
      final member = FamilyMemberModel(
        id: 'spouse-1',
        name: 'Priya Sharma',
        relationship: 'Spouse',
        gender: 'Female',
        bloodGroup: 'B+',
        allergies: const ['Penicillin'],
        chronicConditions: const ['Asthma'],
        isEmergencyContact: true,
        emergencyPhone: '+919876543210',
        createdAt: now,
      );

      final firestoreMap = member.toFirestore();
      expect(firestoreMap['name'], equals('Priya Sharma'));
      expect(firestoreMap['relationship'], equals('Spouse'));
      expect(firestoreMap['bloodGroup'], equals('B+'));
      expect(firestoreMap['isEmergencyContact'], isTrue);
      expect(firestoreMap['emergencyPhone'], equals('+919876543210'));

      final restored = FamilyMemberModel.fromMap(firestoreMap, 'spouse-1');
      expect(restored.id, equals('spouse-1'));
      expect(restored.name, equals('Priya Sharma'));
      expect(restored.relationship, equals('Spouse'));
      expect(restored.allergies, contains('Penicillin'));
      expect(restored.chronicConditions, contains('Asthma'));
    });

    test('copyWith produces updated instance with equality check', () {
      final original = FamilyMemberModel(
        id: 'parent-1',
        name: 'Rajesh Sharma',
        relationship: 'Parent',
        createdAt: DateTime.now(),
      );

      final updated = original.copyWith(
        bloodGroup: 'AB+',
        chronicConditions: ['Hypertension'],
      );

      expect(updated.id, equals('parent-1'));
      expect(updated.bloodGroup, equals('AB+'));
      expect(updated.chronicConditions, contains('Hypertension'));
      expect(updated, isNot(equals(original)));
    });
  });

  group('PatientProfileModel Tests', () {
    test('Constructs full address properly from components', () {
      final profileWithFull = PatientProfileModel(
        id: 'p-1',
        displayName: 'John Doe',
        addressLine: 'Flat 402, Green Glen Layout',
        landmark: 'Opp Ecospace',
        city: 'Bengaluru',
        postalCode: '560103',
        createdAt: DateTime(2025, 1, 1),
      );

      expect(
        profileWithFull.fullAddress,
        equals('Flat 402, Green Glen Layout, Opp Ecospace, Bengaluru, 560103'),
      );

      final profileEmpty = PatientProfileModel(
        id: 'p-2',
        displayName: 'Jane Doe',
        createdAt: DateTime(2025, 1, 1),
      );

      expect(
        profileEmpty.fullAddress,
        equals('No primary home address configured'),
      );
    });

    test('Serializes and deserializes patient profile accurately', () {
      final profile = PatientProfileModel(
        id: 'patient-123',
        displayName: 'Akanksha Sharma',
        phone: '+919988776655',
        email: 'akanksha@example.com',
        addressLine: '123 Palm Grove',
        city: 'Bengaluru',
        postalCode: '560034',
        bloodGroup: 'O+',
        allergies: const ['Peanuts'],
        chronicConditions: const [],
        preferredConsultationMode: 'Home Visit',
        dataSharingConsent: true,
        createdAt: DateTime(2025, 2, 1),
      );

      final map = profile.toFirestore();
      expect(map['displayName'], equals('Akanksha Sharma'));
      expect(map['city'], equals('Bengaluru'));
      expect(map['preferredConsultationMode'], equals('Home Visit'));
      expect(map['dataSharingConsent'], isTrue);

      final restored = PatientProfileModel.fromMap(map, 'patient-123');
      expect(restored.displayName, equals('Akanksha Sharma'));
      expect(restored.bloodGroup, equals('O+'));
      expect(restored.allergies, contains('Peanuts'));
      expect(restored.preferredConsultationMode, equals('Home Visit'));
    });
  });

  group('AppointmentModel Dependent Booking Tests', () {
    test('Supports family member dependent booking fields', () {
      final appointment = AppointmentModel(
        id: 'apt-100',
        patientId: 'primary-patient-uid',
        patientName: 'Aarav Sharma',
        familyMemberId: 'dependent-child-id',
        familyRelationship: 'Child',
        doctorId: 'doc-1',
        doctorName: 'Dr. Sarah Jenkins',
        specialty: 'Pediatrics',
        type: ConsultationType.homeVisit,
        status: AppointmentStatus.booked,
        scheduledAt: DateTime(2025, 3, 10, 14, 0),
      );

      expect(appointment.patientName, equals('Aarav Sharma'));
      expect(appointment.familyMemberId, equals('dependent-child-id'));
      expect(appointment.familyRelationship, equals('Child'));
      expect(appointment.type, equals(ConsultationType.homeVisit));
    });
  });
}
