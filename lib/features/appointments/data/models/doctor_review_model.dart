import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// A patient review for a completed appointment.
///
/// Stored at: `doctor_reviews/{reviewId}`
/// Indexed at: `doctor_public_profiles/{doctorId}` → aggregated rating fields
/// (aggregation is backend's responsibility).
class DoctorReviewModel extends Equatable {
  const DoctorReviewModel({
    required this.id,
    required this.doctorId,
    required this.patientId,
    required this.patientName,
    required this.appointmentId,
    required this.rating,
    this.comment = '',
    required this.createdAt,
  });

  final String id;
  final String doctorId;
  final String patientId;
  final String patientName;
  final String appointmentId;

  /// 1–5 star rating.
  final int rating;
  final String comment;
  final DateTime createdAt;

  factory DoctorReviewModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return DoctorReviewModel(
      id: doc.id,
      doctorId: d['doctorId'] as String? ?? '',
      patientId: d['patientId'] as String? ?? '',
      patientName: d['patientName'] as String? ?? 'Patient',
      appointmentId: d['appointmentId'] as String? ?? '',
      rating: (d['rating'] as num?)?.toInt() ?? 3,
      comment: d['comment'] as String? ?? '',
      createdAt: d['createdAt'] is Timestamp
          ? (d['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'doctorId': doctorId,
        'patientId': patientId,
        'patientName': patientName,
        'appointmentId': appointmentId,
        'rating': rating,
        'comment': comment,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  @override
  List<Object?> get props =>
      [id, doctorId, patientId, appointmentId, rating, comment, createdAt];
}
