import 'package:cloud_firestore/cloud_firestore.dart';

enum DoseStatus {
  taken,
  skipped,
  pending,
}

class MedicationDoseLog {
  const MedicationDoseLog({
    required this.dateString,
    required this.status,
    required this.loggedAt,
  });

  final String dateString; // YYYY-MM-DD
  final DoseStatus status;
  final DateTime loggedAt;

  factory MedicationDoseLog.fromMap(Map<String, dynamic> map) {
    final statusStr = map['status'] as String? ?? 'pending';
    final status = DoseStatus.values.firstWhere(
      (s) => s.name == statusStr,
      orElse: () => DoseStatus.pending,
    );

    DateTime logged = DateTime.now();
    if (map['loggedAt'] is Timestamp) {
      logged = (map['loggedAt'] as Timestamp).toDate();
    } else if (map['loggedAt'] is String) {
      logged = DateTime.tryParse(map['loggedAt'] as String) ?? DateTime.now();
    }

    return MedicationDoseLog(
      dateString: map['dateString'] as String? ?? '',
      status: status,
      loggedAt: logged,
    );
  }

  Map<String, dynamic> toMap() => {
        'dateString': dateString,
        'status': status.name,
        'loggedAt': Timestamp.fromDate(loggedAt),
      };
}

class MedicationReminderModel {
  const MedicationReminderModel({
    required this.id,
    required this.notificationId,
    required this.medicineName,
    required this.dosage,
    this.doctorOrSource = 'Prescription',
    this.instructions = '',
    required this.hour,
    required this.minute,
    this.isEnabled = true,
    this.dosesHistory = const [],
    required this.createdAt,
  });

  final String id;
  final int notificationId;
  final String medicineName;
  final String dosage;
  final String doctorOrSource;
  final String instructions;
  final int hour;
  final int minute;
  final bool isEnabled;
  final List<MedicationDoseLog> dosesHistory;
  final DateTime createdAt;

  String get timeFormatted {
    final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final m = minute < 10 ? '0$minute' : '$minute';
    final period = hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }

  /// Check today's dose status (taken, skipped, or pending).
  DoseStatus get todayStatus {
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    for (final log in dosesHistory) {
      if (log.dateString == todayStr) {
        return log.status;
      }
    }
    return DoseStatus.pending;
  }

  factory MedicationReminderModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    DateTime created = DateTime.now();
    if (data['createdAt'] is Timestamp) {
      created = (data['createdAt'] as Timestamp).toDate();
    }

    final rawHistory = data['dosesHistory'];
    List<MedicationDoseLog> history = [];
    if (rawHistory is List) {
      history = rawHistory
          .whereType<Map<String, dynamic>>()
          .map(MedicationDoseLog.fromMap)
          .toList();
    }

    return MedicationReminderModel(
      id: doc.id,
      notificationId: data['notificationId'] as int? ?? doc.id.hashCode.abs(),
      medicineName: data['medicineName'] as String? ?? 'Prescribed Medicine',
      dosage: data['dosage'] as String? ?? '1 dose',
      doctorOrSource: data['doctorOrSource'] as String? ?? 'Prescription',
      instructions: data['instructions'] as String? ?? '',
      hour: data['hour'] as int? ?? 8,
      minute: data['minute'] as int? ?? 0,
      isEnabled: data['isEnabled'] as bool? ?? true,
      dosesHistory: history,
      createdAt: created,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'notificationId': notificationId,
        'medicineName': medicineName,
        'dosage': dosage,
        'doctorOrSource': doctorOrSource,
        'instructions': instructions,
        'hour': hour,
        'minute': minute,
        'isEnabled': isEnabled,
        'dosesHistory': dosesHistory.map((d) => d.toMap()).toList(),
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
