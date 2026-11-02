
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> seedDemoDoctors() async {
  final firestore = FirebaseFirestore.instance;
  // Avoid inserting the demo doctors again on every app launch.
  final markerRef =
  firestore.collection('app_metadata').doc('demo_doctors_seeded');

  final markerSnapshot = await markerRef.get();

  if (markerSnapshot.exists) {
    return;
  }
  final batch = firestore.batch();

  final doctors = [
    {
      'id': 'demo_doctor_001',
      'displayName': 'Dr. Aarav Sharma',
      'specialization': 'Cardiologist',
      'qualifications': 'MBBS, MD Cardiology',
      'hospital': 'City Heart Care',
      'experienceYears': 12,
      'location': 'Gwalior, Madhya Pradesh',
      'bio': 'Demo cardiologist profile for HomeDoc AI.',
      'professionalHistory': [
        'Senior Cardiologist - City Heart Care',
        'Cardiology Resident - Central Medical Institute',
      ],
      'languages': ['English', 'Hindi'],
      'consultationFee': 600,
    },
    {
      'id': 'demo_doctor_002',
      'displayName': 'Dr. Ananya Verma',
      'specialization': 'Dermatologist',
      'qualifications': 'MBBS, MD Dermatology',
      'hospital': 'SkinCare Clinic',
      'experienceYears': 9,
      'location': 'Gwalior, Madhya Pradesh',
      'bio': 'Demo dermatologist profile for HomeDoc AI.',
      'professionalHistory': [
        'Consultant Dermatologist - SkinCare Clinic',
        'Resident - Department of Dermatology',
      ],
      'languages': ['English', 'Hindi'],
      'consultationFee': 500,
    },
    {
      'id': 'demo_doctor_003',
      'displayName': 'Dr. Rohan Mehta',
      'specialization': 'Pediatrician',
      'qualifications': 'MBBS, MD Pediatrics',
      'hospital': 'ChildCare Hospital',
      'experienceYears': 11,
      'location': 'Gwalior, Madhya Pradesh',
      'bio': 'Demo pediatrician profile for HomeDoc AI.',
      'professionalHistory': [
        'Consultant Pediatrician - ChildCare Hospital',
        'Pediatric Resident - Medical College',
      ],
      'languages': ['English', 'Hindi'],
      'consultationFee': 450,
    },
    {
      'id': 'demo_doctor_004',
      'displayName': 'Dr. Priya Singh',
      'specialization': 'Gynecologist',
      'qualifications': 'MBBS, MS Obstetrics and Gynaecology',
      'hospital': "Women's Health Centre",
      'experienceYears': 10,
      'location': 'Gwalior, Madhya Pradesh',
      'bio': 'Demo gynecology profile for HomeDoc AI.',
      'professionalHistory': [
        "Consultant - Women's Health Centre",
        'Resident - Obstetrics and Gynaecology Department',
      ],
      'languages': ['English', 'Hindi'],
      'consultationFee': 550,
    },
    {
      'id': 'demo_doctor_005',
      'displayName': 'Dr. Kabir Malhotra',
      'specialization': 'Orthopedic',
      'qualifications': 'MBBS, MS Orthopedics',
      'hospital': 'OrthoPlus Hospital',
      'experienceYears': 14,
      'location': 'Gwalior, Madhya Pradesh',
      'bio': 'Demo orthopedic profile for HomeDoc AI.',
      'professionalHistory': [
        'Consultant Orthopedic - OrthoPlus Hospital',
        'Orthopedic Surgeon - General Medical Centre',
      ],
      'languages': ['English', 'Hindi'],
      'consultationFee': 650,
    },
    {
      'id': 'demo_doctor_006',
      'displayName': 'Dr. Meera Joshi',
      'specialization': 'Ophthalmologist',
      'qualifications': 'MBBS, MS Ophthalmology',
      'hospital': 'Vision Eye Centre',
      'experienceYears': 8,
      'location': 'Gwalior, Madhya Pradesh',
      'bio': 'Demo ophthalmology profile for HomeDoc AI.',
      'professionalHistory': [
        'Consultant Ophthalmologist - Vision Eye Centre',
        'Eye Specialist - Medical College',
      ],
      'languages': ['English', 'Hindi'],
      'consultationFee': 400,
    },
    {
      'id': 'demo_doctor_007',
      'displayName': 'Dr. Vikram Patel',
      'specialization': 'Neurologist',
      'qualifications': 'MBBS, DM Neurology',
      'hospital': 'NeuroCare Hospital',
      'experienceYears': 13,
      'location': 'Gwalior, Madhya Pradesh',
      'bio': 'Demo neurologist profile for HomeDoc AI.',
      'professionalHistory': [
        'Consultant Neurologist - NeuroCare Hospital',
        'Neurology Specialist - Medical Institute',
      ],
      'languages': ['English', 'Hindi'],
      'consultationFee': 700,
    },
    {
      'id': 'demo_doctor_008',
      'displayName': 'Dr. Nisha Kapoor',
      'specialization': 'Psychiatrist',
      'qualifications': 'MBBS, MD Psychiatry',
      'hospital': 'MindWell Clinic',
      'experienceYears': 7,
      'location': 'Gwalior, Madhya Pradesh',
      'bio': 'Demo psychiatry profile for HomeDoc AI.',
      'professionalHistory': [
        'Consultant Psychiatrist - MindWell Clinic',
        'Psychiatry Resident - Medical College',
      ],
      'languages': ['English', 'Hindi'],
      'consultationFee': 500,
    },
    {
      'id': 'demo_doctor_009',
      'displayName': 'Dr. Aditya Rao',
      'specialization': 'General Physician',
      'qualifications': 'MBBS, MD General Medicine',
      'hospital': 'HealthFirst Clinic',
      'experienceYears': 6,
      'location': 'Gwalior, Madhya Pradesh',
      'bio': 'Demo general physician profile for HomeDoc AI.',
      'professionalHistory': [
        'General Physician - HealthFirst Clinic',
        'Medical Officer - Community Health Centre',
      ],
      'languages': ['English', 'Hindi'],
      'consultationFee': 350,
    },
    {
      'id': 'demo_doctor_010',
      'displayName': 'Dr. Sneha Gupta',
      'specialization': 'ENT Specialist',
      'qualifications': 'MBBS, MS ENT',
      'hospital': 'City ENT Hospital',
      'experienceYears': 9,
      'location': 'Gwalior, Madhya Pradesh',
      'bio': 'Demo ENT specialist profile for HomeDoc AI.',
      'professionalHistory': [
        'Consultant ENT - City ENT Hospital',
        'ENT Resident - Medical College',
      ],
      'languages': ['English', 'Hindi'],
      'consultationFee': 450,
    },
  ];

  for (final doctor in doctors) {
    final id = doctor['id'] as String;

    final doctorRef =
    firestore.collection('doctor_public_profiles').doc(id);

    batch.set(doctorRef, {
      'doctorId': id,
      'displayName': doctor['displayName'],
      'specialization': doctor['specialization'],
      'qualifications': doctor['qualifications'],
      'hospital': doctor['hospital'],
      'experienceYears': doctor['experienceYears'],
      'location': doctor['location'],
      'bio': doctor['bio'],
      'professionalHistory': doctor['professionalHistory'],
      'languages': doctor['languages'],
      'consultationFee': doctor['consultationFee'],
      'photoUrl': '',
      'profileType': 'demo',
      'isVerified': true,
      'isActive': true,
      'isDiscoverable': true,
      'availability': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  batch.set(markerRef, {
    'seededAt': FieldValue.serverTimestamp(),
  });
  await batch.commit();
}
