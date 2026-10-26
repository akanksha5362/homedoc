import 'package:equatable/equatable.dart';

class DoctorModel extends Equatable {
  const DoctorModel({
    required this.id,
    required this.name,
    required this.specialty,
    required this.verified,
    required this.rating,
    required this.experienceYears,
    this.supportsHomeVisit = true,
    this.supportsVideo = true,
    this.photoUrl,
  });

  final String id;
  final String name;
  final String specialty;
  final bool verified;
  final double rating;
  final int experienceYears;
  final bool supportsHomeVisit;
  final bool supportsVideo;
  final String? photoUrl;

  /// FIXED: previously read camelCase keys (`experienceYears`) that the
  /// real backend never sends — it uses snake_case (`experience_years`,
  /// matching FastAPI/Python convention), so `experienceYears` silently
  /// defaulted to 0 for every real doctor. Caught only once this model
  /// was actually fed real backend data for the first time (via the AI
  /// Assistant's SHOW_DOCTORS action) — DoctorModel had no real caller
  /// before that. Also adds `supports_home_visit`/`supports_video`, which
  /// the backend sends and this model previously dropped entirely.
  factory DoctorModel.fromJson(Map<String, dynamic> json) => DoctorModel(
        id: json['id'] as String,
        name: json['name'] as String,
        specialty: json['specialty'] as String,
        verified: json['verified'] as bool? ?? false,
        rating: (json['rating'] as num?)?.toDouble() ?? 0,
        experienceYears: json['experience_years'] as int? ?? 0,
        supportsHomeVisit: json['supports_home_visit'] as bool? ?? true,
        supportsVideo: json['supports_video'] as bool? ?? true,
        photoUrl: json['photo_url'] as String?,
      );

  @override
  List<Object?> get props =>
      [id, name, specialty, verified, rating, experienceYears, supportsHomeVisit, supportsVideo, photoUrl];
}
