import 'package:equatable/equatable.dart';

/// A location update received from the tracking service.
/// Coordinates are only populated from an actual service response.
class DoctorTrackingUpdate extends Equatable {
  const DoctorTrackingUpdate({
    required this.appointmentId,
    required this.doctorId,
    required this.latitude,
    required this.longitude,
    required this.locationUpdatedAt,
    required this.trackingStatus,
    this.etaMinutes,
    this.estimatedArrivalAt,
    this.routePolyline,
    this.accuracyMeters,
  });

  final String appointmentId;
  final String doctorId;
  final double latitude;
  final double longitude;
  final DateTime locationUpdatedAt;
  final String trackingStatus;
  final int? etaMinutes;
  final DateTime? estimatedArrivalAt;
  final String? routePolyline;
  final double? accuracyMeters;

  factory DoctorTrackingUpdate.fromJson(Map<String, dynamic> json) {
    double number(dynamic value, String field) {
      if (value is num) return value.toDouble();
      throw FormatException('Missing or invalid $field');
    }

    DateTime date(dynamic value, String field) {
      if (value is DateTime) return value;
      if (value is String) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) return parsed;
      }
      throw FormatException('Missing or invalid $field');
    }

    final eta = json['etaMinutes'];
    final estimated = json['estimatedArrivalAt'];
    return DoctorTrackingUpdate(
      appointmentId: (json['appointmentId'] ?? '').toString(),
      doctorId: (json['doctorId'] ?? '').toString(),
      latitude: number(json['latitude'] ?? json['lat'], 'latitude'),
      longitude: number(json['longitude'] ?? json['lng'], 'longitude'),
      locationUpdatedAt: date(json['locationUpdatedAt'], 'locationUpdatedAt'),
      trackingStatus: (json['trackingStatus'] ?? 'unavailable').toString(),
      etaMinutes: eta is num ? eta.round() : null,
      estimatedArrivalAt: estimated == null
          ? null
          : date(estimated, 'estimatedArrivalAt'),
      routePolyline: json['routePolyline'] as String?,
      accuracyMeters: json['accuracy'] is num
          ? (json['accuracy'] as num).toDouble()
          : null,
    );
  }

  bool get hasValidCoordinates =>
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180 &&
      !(latitude == 0 && longitude == 0);

  bool isStale({
    DateTime? now,
    Duration threshold = const Duration(minutes: 3),
  }) {
    final reference = now ?? DateTime.now();
    final age = reference.isBefore(locationUpdatedAt)
        ? locationUpdatedAt.difference(reference)
        : reference.difference(locationUpdatedAt);
    return age > threshold;
  }

  String get formattedEta {
    if (etaMinutes == null || etaMinutes! < 0) return 'ETA unavailable';
    if (etaMinutes == 0) return 'Arriving now';
    if (etaMinutes! == 1) return '1 min';
    if (etaMinutes! < 60) return '$etaMinutes mins';
    final hours = etaMinutes! ~/ 60;
    final minutes = etaMinutes! % 60;
    return minutes == 0 ? '${hours}h' : '${hours}h ${minutes}m';
  }

  @override
  List<Object?> get props => [
    appointmentId,
    doctorId,
    latitude,
    longitude,
    locationUpdatedAt,
    trackingStatus,
    etaMinutes,
    estimatedArrivalAt,
    routePolyline,
    accuracyMeters,
  ];
}
