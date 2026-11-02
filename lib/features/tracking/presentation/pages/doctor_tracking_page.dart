import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../shared/models/appointment_model.dart';
import '../../../../shared/providers/doctor_provider.dart';
import '../providers/doctor_tracking_provider.dart';
import '../../data/models/doctor_tracking_model.dart';

class DoctorTrackingPage extends ConsumerStatefulWidget {
  const DoctorTrackingPage({super.key, required this.appointment});

  final Map<String, dynamic> appointment;

  @override
  ConsumerState<DoctorTrackingPage> createState() => _DoctorTrackingPageState();
}

class _DoctorTrackingPageState extends ConsumerState<DoctorTrackingPage> {
  GoogleMapController? _mapController;

  String get _appointmentId => (widget.appointment['id'] ?? '').toString();
  String get _doctorId => (widget.appointment['doctorId'] ?? '').toString();
  AppointmentStatus get _status =>
      widget.appointment['lifecycleStatus'] is AppointmentStatus
      ? widget.appointment['lifecycleStatus'] as AppointmentStatus
      : AppointmentStatus.booked;

  bool get _terminal =>
      _status == AppointmentStatus.cancelled ||
      _status == AppointmentStatus.rejected ||
      _status == AppointmentStatus.completed;

  @override
  void dispose() {
    _mapController = null;
    super.dispose();
  }

  void _recenter(DoctorTrackingUpdate update) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(update.latitude, update.longitude), 15),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tracking = ref.watch(
      doctorTrackingProvider((
        appointmentId: _appointmentId,
        doctorId: _doctorId,
      )),
    );
    final doctors = ref.watch(verifiedDoctorsProvider).valueOrNull ?? [];
    final matchingDoctors = doctors.where(
      (item) => item['doctorId'] == _doctorId,
    );
    final doctor = matchingDoctors.isEmpty ? null : matchingDoctors.first;
    final doctorName =
        (doctor?['name'] ?? widget.appointment['doctor'] ?? 'Doctor')
            .toString();
    final specialty =
        (doctor?['specialty'] ??
                widget.appointment['specialty'] ??
                'Medical professional')
            .toString();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Doctor tracking'),
        actions: [
          IconButton(
            tooltip: 'Tracking information',
            onPressed: _showPrivacyInfo,
            icon: const Icon(Icons.info_outline_rounded),
          ),
        ],
      ),
      body: _terminal
          ? _messageState(
              icon: Icons.location_disabled_outlined,
              title: 'Tracking has ended',
              message: _status == AppointmentStatus.completed
                  ? 'This appointment is completed.'
                  : 'This appointment is no longer active.',
            )
          : tracking.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _messageState(
                icon: Icons.wifi_off_rounded,
                title: 'Tracking connection unavailable',
                message:
                    'We could not connect to the tracking service. '
                    'Please try again later.',
                retry: () => ref.invalidate(
                  doctorTrackingProvider((
                    appointmentId: _appointmentId,
                    doctorId: _doctorId,
                  )),
                ),
              ),
              data: (update) {
                if (update == null) {
                  return _pendingState(doctorName, specialty, doctor);
                }
                if (update.appointmentId != _appointmentId ||
                    update.doctorId != _doctorId ||
                    !update.hasValidCoordinates) {
                  return _messageState(
                    icon: Icons.location_searching_rounded,
                    title: 'Doctor location unavailable',
                    message:
                        'A valid location update for this appointment '
                        'has not been received.',
                  );
                }
                if (update.isStale()) {
                  return _staleState(update, doctorName, specialty, doctor);
                }
                return _liveState(update, doctorName, specialty, doctor);
              },
            ),
    );
  }

  Widget _pendingState(
    String name,
    String specialty,
    Map<String, dynamic>? doctor,
  ) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        _statusBanner(
          icon: Icons.hourglass_top_rounded,
          title: 'Live tracking is not connected yet',
          subtitle:
              'Your appointment is saved. Doctor location sharing '
              'will appear here when the tracking service is enabled.',
          color: AppColors.warning,
        ),
        const SizedBox(height: 16),
        _doctorCard(name, specialty, doctor, null),
        const SizedBox(height: 16),
        _waitingMap(
          title: 'Waiting for doctor location',
          subtitle:
              'The map is ready. The doctor will appear here after a real '
              'location update is received.',
        ),
        const SizedBox(height: 16),
        _timeline(_status),
        const SizedBox(height: 12),
        const Text(
          'Backend integration pending. No sample coordinates or estimated '
          'arrival time are displayed.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
      ],
    );
  }

  Widget _liveState(
    DoctorTrackingUpdate update,
    String name,
    String specialty,
    Map<String, dynamic>? doctor,
  ) {
    final position = LatLng(update.latitude, update.longitude);
    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('doctor'),
        position: position,
        infoWindow: InfoWindow(title: name, snippet: 'Doctor location'),
      ),
    };
    final routePoints = _decodePolyline(update.routePolyline);
    final polylines = routePoints.length > 1
        ? <Polyline>{
            Polyline(
              polylineId: const PolylineId('doctor_route'),
              points: routePoints,
              color: AppColors.primary,
              width: 5,
            ),
          }
        : <Polyline>{};
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        _statusBanner(
          icon: Icons.location_on_rounded,
          title: update.formattedEta,
          subtitle: 'Last updated ${_timeAgo(update.locationUpdatedAt)}',
          color: AppColors.success,
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: SizedBox(
            height: 300,
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: position,
                    zoom: 15,
                  ),
                  markers: markers,
                  polylines: polylines,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  onMapCreated: (controller) => _mapController = controller,
                ),
                Positioned(
                  right: 14,
                  bottom: 14,
                  child: FloatingActionButton.small(
                    heroTag: 'tracking_recenter',
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    onPressed: () => _recenter(update),
                    child: const Icon(Icons.my_location_rounded),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _doctorCard(name, specialty, doctor, update),
        const SizedBox(height: 16),
        _timeline(_status),
      ],
    );
  }

  Widget _staleState(
    DoctorTrackingUpdate update,
    String name,
    String specialty,
    Map<String, dynamic>? doctor,
  ) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        _statusBanner(
          icon: Icons.update_rounded,
          title: 'Location update is delayed',
          subtitle:
              'Last update ${_timeAgo(update.locationUpdatedAt)}. '
              'The displayed position may no longer be current.',
          color: AppColors.warning,
        ),
        const SizedBox(height: 16),
        _doctorCard(name, specialty, doctor, update),
        const SizedBox(height: 16),
        _waitingMap(
          title: 'Waiting for a fresh location',
          subtitle: 'We hide outdated map positions to avoid misleading you.',
        ),
        const SizedBox(height: 16),
        _timeline(_status),
      ],
    );
  }

  Widget _doctorCard(
    String name,
    String specialty,
    Map<String, dynamic>? doctor,
    DoctorTrackingUpdate? update,
  ) {
    final photo = doctor?['photoUrl']?.toString() ?? '';
    final experience = doctor?['experienceYears']?.toString();
    final qualifications = doctor?['qualifications']?.toString();
    final hospital = doctor?['hospital']?.toString();
    final scheduledAt = widget.appointment['date'];
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 27,
                backgroundColor: AppColors.primaryContainer,
                backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                child: photo.isEmpty
                    ? const Icon(Icons.person_rounded, color: AppColors.primary)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      specialty,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.verified_user_outlined,
                color: AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (qualifications != null && qualifications.isNotEmpty)
            _detail(Icons.school_outlined, qualifications),
          if (experience != null && experience != 'null')
            _detail(Icons.work_outline_rounded, '$experience years experience'),
          if (hospital != null && hospital.isNotEmpty)
            _detail(Icons.local_hospital_outlined, hospital),
          const Divider(height: 22),
          _detail(Icons.home_outlined, 'Home visit'),
          if (scheduledAt is DateTime)
            _detail(
              Icons.calendar_month_outlined,
              '${scheduledAt.day}/${scheduledAt.month}/${scheduledAt.year} · '
              '${widget.appointment['time'] ?? ''}',
            ),
          if (update != null)
            _detail(Icons.schedule_rounded, 'ETA: ${update.formattedEta}'),
          _detail(Icons.info_outline_rounded, _statusLabel(_status)),
        ],
      ),
    );
  }

  Widget _detail(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Row(
      children: [
        Icon(icon, size: 17, color: AppColors.primary),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ),
      ],
    ),
  );

  Widget _timeline(AppointmentStatus status) {
    const stages = [
      ('Appointment confirmed', AppointmentStatus.doctorConfirmed),
      ('Doctor preparing', AppointmentStatus.preparing),
      ('On the way', AppointmentStatus.onTheWay),
      ('Arriving', AppointmentStatus.arriving),
      ('Arrived', AppointmentStatus.arrived),
    ];
    final active = switch (status) {
      AppointmentStatus.booked => -1,
      AppointmentStatus.doctorConfirmed => 0,
      AppointmentStatus.preparing => 1,
      AppointmentStatus.onTheWay => 2,
      AppointmentStatus.arriving => 3,
      AppointmentStatus.arrived ||
      AppointmentStatus.inConsultation ||
      AppointmentStatus.completed => 4,
      _ => -1,
    };
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Appointment progress',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < stages.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 13),
              child: Row(
                children: [
                  Icon(
                    i <= active
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: i <= active ? AppColors.success : AppColors.border,
                    size: 20,
                  ),
                  const SizedBox(width: 11),
                  Text(
                    stages[i].$1,
                    style: TextStyle(
                      color: i <= active
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                      fontWeight: i == active
                          ? FontWeight.w800
                          : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _statusBanner({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .09),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: color.withValues(alpha: .25)),
    ),
    child: Row(
      children: [
        Icon(icon, color: color, size: 27),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _waitingMap({required String title, required String subtitle}) =>
      ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(
          height: 245,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              GoogleMap(
                // Neutral India overview used only to render map tiles.
                // This is NOT the patient's or doctor's location.
                initialCameraPosition: const CameraPosition(
                  target: LatLng(22.9734, 78.6569),
                  zoom: 4.5,
                ),
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                compassEnabled: false,
                markers: const <Marker>{},
                polylines: const <Polyline>{},
                onMapCreated: (controller) => _mapController = controller,
              ),
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 22),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_searching_rounded,
                        color: AppColors.primary,
                        size: 30,
                      ),
                      const SizedBox(height: 9),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _messageState({
    required IconData icon,
    required String title,
    required String message,
    VoidCallback? retry,
  }) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 52, color: AppColors.textMuted),
          const SizedBox(height: 15),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textMuted, height: 1.5),
          ),
          if (retry != null) ...[
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: retry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ],
      ),
    ),
  );

  List<LatLng> _decodePolyline(String? encoded) {
    if (encoded == null || encoded.isEmpty) return const [];
    final points = <LatLng>[];
    var index = 0;
    var latitude = 0;
    var longitude = 0;
    try {
      while (index < encoded.length) {
        var shift = 0;
        var result = 0;
        int byte;
        do {
          byte = encoded.codeUnitAt(index++) - 63;
          result |= (byte & 0x1f) << shift;
          shift += 5;
        } while (byte >= 0x20);
        latitude += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

        shift = 0;
        result = 0;
        do {
          byte = encoded.codeUnitAt(index++) - 63;
          result |= (byte & 0x1f) << shift;
          shift += 5;
        } while (byte >= 0x20);
        longitude += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
        points.add(LatLng(latitude / 1e5, longitude / 1e5));
      }
    } catch (_) {
      return const [];
    }
    return points;
  }

  String _statusLabel(AppointmentStatus status) => switch (status) {
    AppointmentStatus.booked => 'Booking requested',
    AppointmentStatus.doctorConfirmed => 'Appointment confirmed',
    AppointmentStatus.rejected => 'Rejected',
    AppointmentStatus.preparing => 'Doctor preparing',
    AppointmentStatus.onTheWay => 'Doctor on the way',
    AppointmentStatus.arriving => 'Doctor arriving',
    AppointmentStatus.arrived => 'Doctor arrived',
    AppointmentStatus.inConsultation => 'Consultation in progress',
    AppointmentStatus.completed => 'Completed',
    AppointmentStatus.cancelled => 'Cancelled',
  };

  String _timeAgo(DateTime time) {
    final difference = DateTime.now().difference(time);
    if (difference.inSeconds < 60) return 'just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
    return '${difference.inHours} hr ago';
  }

  void _showPrivacyInfo() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location privacy'),
        content: const Text(
          'The map displays only location updates shared by the doctor for '
          'this appointment. Tracking stops when the appointment is '
          'cancelled or completed. Your device location is not used as a '
          'substitute for the doctor location.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
