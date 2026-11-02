# HomeDoc AI — Doctor tracking frontend patch

## Included
- `lib/features/tracking/data/models/doctor_tracking_model.dart`
- `lib/features/tracking/data/repositories/doctor_tracking_repository.dart`
- `lib/features/tracking/presentation/providers/doctor_tracking_provider.dart`
- `lib/features/tracking/presentation/pages/doctor_tracking_page.dart`
- Router registration and a home-visit-only entry point from appointment details
- `test/unit/doctor_tracking_model_test.dart`

## Current integration state
The supplied Flutter source contains Google Maps, Geolocator, Dio, Riverpod and the existing appointment status enum. It does not contain a documented live doctor-location endpoint, location stream, route geometry endpoint, or ETA contract. Therefore the default `PendingDoctorTrackingRepository` emits `null` and the UI displays an explicit pending/unavailable state. It does not fabricate a doctor position, route, ETA, or patient position.

When the backend contract is ready, implement `DoctorTrackingRepository.watchTracking` with the agreed API/stream. Emit `DoctorTrackingUpdate` only for real updates. The model currently accepts:
- `appointmentId` (string)
- `doctorId` (string)
- `latitude` and `longitude` (numbers; also accepts `lat`/`lng`)
- `locationUpdatedAt` (ISO-8601 string or DateTime)
- `trackingStatus` (string)
- optional `etaMinutes` (number)
- optional `estimatedArrivalAt` (ISO-8601 string or DateTime)
- optional `routePolyline` (encoded Google polyline)
- optional `accuracy` (number)

The frontend verifies appointment/doctor IDs, rejects invalid coordinates, hides stale map positions (>3 minutes), and stops subscribing when the page is disposed. The tracking stream provider is scoped to the appointment/doctor pair.

## Google Maps platform setup still required
`google_maps_flutter: ^2.18.0` is already in the supplied `pubspec.yaml`.
- Android manifest currently has INTERNET permission, but no `com.google.android.geo.API_KEY` metadata.
- iOS Info.plist has no Google Maps API key entry.
- Add platform-restricted Google Maps API keys in the native platform projects before expecting map tiles to load. No key was included in the upload, so this patch does not invent or insert one.
- This screen does not request the patient's location permission. It only displays a doctor location supplied by the tracking service.

## Scope
No backend files, Firestore rules, indexes, Cloud Functions, server auth, environment secrets, or deployment settings are included or modified.
