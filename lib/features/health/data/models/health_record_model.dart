import 'package:cloud_firestore/cloud_firestore.dart';

enum HealthRecordCategory {
  prescription,
  labReport,
  vaccine,
  clinicalNote,
  other,
}

extension HealthRecordCategoryExt on HealthRecordCategory {
  String get label {
    switch (this) {
      case HealthRecordCategory.prescription:
        return 'Prescription';
      case HealthRecordCategory.labReport:
        return 'Lab Report';
      case HealthRecordCategory.vaccine:
        return 'Vaccine';
      case HealthRecordCategory.clinicalNote:
        return 'Clinical Note';
      case HealthRecordCategory.other:
        return 'Other Record';
    }
  }
}

class PrescriptionMedicine {
  const PrescriptionMedicine({
    required this.name,
    this.dosage = '',
    this.frequency = '',
    this.duration = '',
    this.instructions,
    this.isReminderSet = false,
  });

  final String name;
  final String dosage;
  final String frequency;
  final String duration;
  final String? instructions;
  final bool isReminderSet;

  factory PrescriptionMedicine.fromMap(Map<String, dynamic> map) {
    return PrescriptionMedicine(
      name: map['name'] as String? ?? '',
      dosage: map['dosage'] as String? ?? '',
      frequency: map['frequency'] as String? ?? '',
      duration: map['duration'] as String? ?? '',
      instructions: map['instructions'] as String?,
      isReminderSet: map['isReminderSet'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'dosage': dosage,
        'frequency': frequency,
        'duration': duration,
        if (instructions != null) 'instructions': instructions,
        'isReminderSet': isReminderSet,
      };

  PrescriptionMedicine copyWith({
    String? name,
    String? dosage,
    String? frequency,
    String? duration,
    String? instructions,
    bool? isReminderSet,
  }) {
    return PrescriptionMedicine(
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      duration: duration ?? this.duration,
      instructions: instructions ?? this.instructions,
      isReminderSet: isReminderSet ?? this.isReminderSet,
    );
  }
}

class HealthRecordModel {
  const HealthRecordModel({
    required this.id,
    required this.title,
    required this.category,
    required this.doctorOrClinic,
    required this.date,
    this.notes = '',
    this.fileUrl,
    this.fileName,
    this.medicines = const [],
    required this.createdAt,
  });

  final String id;
  final String title;
  final HealthRecordCategory category;
  final String doctorOrClinic;
  final DateTime date;
  final String notes;
  final String? fileUrl;
  final String? fileName;
  final List<PrescriptionMedicine> medicines;
  final DateTime createdAt;

  factory HealthRecordModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final categoryString = data['category'] as String? ?? 'other';
    final category = HealthRecordCategory.values.firstWhere(
      (c) => c.name == categoryString,
      orElse: () => HealthRecordCategory.other,
    );

    DateTime recordDate = DateTime.now();
    if (data['date'] is Timestamp) {
      recordDate = (data['date'] as Timestamp).toDate();
    } else if (data['date'] is String) {
      recordDate = DateTime.tryParse(data['date'] as String) ?? DateTime.now();
    }

    DateTime createdDate = DateTime.now();
    if (data['createdAt'] is Timestamp) {
      createdDate = (data['createdAt'] as Timestamp).toDate();
    }

    final rawMedicines = data['medicines'];
    List<PrescriptionMedicine> medicinesList = [];
    if (rawMedicines is List) {
      medicinesList = rawMedicines
          .whereType<Map<String, dynamic>>()
          .map(PrescriptionMedicine.fromMap)
          .toList();
    }

    return HealthRecordModel(
      id: doc.id,
      title: data['title'] as String? ?? 'Medical Document',
      category: category,
      doctorOrClinic: data['doctorOrClinic'] as String? ?? 'Healthcare Provider',
      date: recordDate,
      notes: data['notes'] as String? ?? '',
      fileUrl: data['fileUrl'] as String?,
      fileName: data['fileName'] as String?,
      medicines: medicinesList,
      createdAt: createdDate,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'title': title,
        'category': category.name,
        'doctorOrClinic': doctorOrClinic,
        'date': Timestamp.fromDate(date),
        'notes': notes,
        if (fileUrl != null) 'fileUrl': fileUrl,
        if (fileName != null) 'fileName': fileName,
        'medicines': medicines.map((m) => m.toMap()).toList(),
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
