import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../shared/providers/auth_provider.dart';

class DoctorLocationState extends Equatable {
  const DoctorLocationState({
    this.isSharing = false,
    this.activeAppointmentId,
    this.latitude,
    this.longitude,
    this.lastUpdated,
    this.errorMessage,
  });

  final bool isSharing;
  final String? activeAppointmentId;
  final double? latitude;
  final double? longitude;
  final DateTime? lastUpdated;
  final String? errorMessage;

  DoctorLocationState copyWith({
    bool? isSharing,
    String? activeAppointmentId,
    double? latitude,
    double? longitude,
    DateTime? lastUpdated,
    String? errorMessage,
  }) {
    return DoctorLocationState(
      isSharing: isSharing ?? this.isSharing,
      activeAppointmentId: activeAppointmentId ?? this.activeAppointmentId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        isSharing,
        activeAppointmentId,
        latitude,
        longitude,
        lastUpdated,
        errorMessage,
      ];
}

class DoctorLocationNotifier extends StateNotifier<DoctorLocationState> {
  DoctorLocationNotifier(this._firestore) : super(const DoctorLocationState());

  final FirebaseFirestore _firestore;
  StreamSubscription<Position>? _positionSubscription;

  Future<bool> startBroadcasting({
    required String appointmentId,
    required String doctorId,
  }) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        state = state.copyWith(
          errorMessage: 'Device location services are disabled. Please enable GPS in device settings.',
        );
        return false;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          state = state.copyWith(
            errorMessage: 'Location permission was denied. Cannot broadcast GPS for home visits.',
          );
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        state = state.copyWith(
          errorMessage: 'Location permissions are permanently denied. Please enable them in app settings.',
        );
        return false;
      }

      // Initial position
      final initialPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      final now = DateTime.now();
      await _firestore.collection('active_tracking').doc(appointmentId).set({
        'appointmentId': appointmentId,
        'doctorId': doctorId,
        'latitude': initialPosition.latitude,
        'longitude': initialPosition.longitude,
        'locationUpdatedAt': now.toIso8601String(),
        'trackingStatus': 'onTheWay',
        'accuracy': initialPosition.accuracy,
      });

      // Update appointment status to onTheWay
      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': 'onTheWay',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      state = DoctorLocationState(
        isSharing: true,
        activeAppointmentId: appointmentId,
        latitude: initialPosition.latitude,
        longitude: initialPosition.longitude,
        lastUpdated: now,
      );

      // Subscribe to periodic position stream
      await _positionSubscription?.cancel();
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 20, // update every 20 meters
        ),
      ).listen(
        (pos) async {
          final time = DateTime.now();
          await _firestore.collection('active_tracking').doc(appointmentId).set({
            'appointmentId': appointmentId,
            'doctorId': doctorId,
            'latitude': pos.latitude,
            'longitude': pos.longitude,
            'locationUpdatedAt': time.toIso8601String(),
            'trackingStatus': 'onTheWay',
            'accuracy': pos.accuracy,
          }, SetOptions(merge: true));

          state = state.copyWith(
            latitude: pos.latitude,
            longitude: pos.longitude,
            lastUpdated: time,
          );
        },
        onError: (err) {
          state = state.copyWith(errorMessage: 'Location stream error: $err');
        },
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Could not start location broadcasting: $e',
      );
      return false;
    }
  }

  Future<void> stopBroadcasting() async {
    final appointmentId = state.activeAppointmentId;
    await _positionSubscription?.cancel();
    _positionSubscription = null;

    if (appointmentId != null) {
      try {
        await _firestore.collection('active_tracking').doc(appointmentId).set({
          'trackingStatus': 'stopped',
          'locationUpdatedAt': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));
      } catch (_) {}
    }

    state = const DoctorLocationState(isSharing: false);
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }
}

final doctorLocationProvider =
    StateNotifierProvider<DoctorLocationNotifier, DoctorLocationState>((ref) {
  return DoctorLocationNotifier(ref.watch(firestoreProvider));
});
