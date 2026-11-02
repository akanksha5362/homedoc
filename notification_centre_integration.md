# Notification Centre integration

The Flutter Notification Centre is implemented against the endpoint contract in
`PATIENT_ENGAGEMENT_BACKEND_CONTRACT.md`. The uploaded source contained the
Flutter `lib/` tree, `pubspec.yaml`, and contract, but no backend repository or
running API was available to verify these calls against a server. The UI does
not insert sample notifications or claim that the list is empty when the API
fails.

## Frontend behavior

- Loads the first 50 notifications for the signed-in Firebase UID.
- Uses the response cursor to load additional pages.
- Shows loading, empty, error, and retry states.
- Shows unread counts in the patient home bell and visually marks unread rows.
- Supports marking one item read, marking all read, and pull-to-refresh.
- Opens the relevant existing chat, appointment, or medication/follow-up area
  for the known notification types. Doctor-arriving notifications open the
  appointments list because the existing tracking route requires a full
  appointment object, which the notification contract does not provide.

## Backend dependencies

Implement and document these exact routes from the supplied contract:

```http
GET   /patients/{uid}/notifications?limit=50&after={cursor}
PATCH /patients/{uid}/notifications/{notificationId}/read
PATCH /patients/{uid}/notifications/read-all
```

The GET response must be an object with `notifications` and `nextCursor`. Each
notification must include `id`, `type`, `title`, `body`, boolean `read`,
ISO-8601 `createdAt`, and optional type-specific `data`. The frontend sends the
Firebase UID and the existing API client attaches the current bearer token.
The backend must authenticate the request, authorize that the caller can only
read or update their own notifications, define the PATCH success response, and
return stable opaque cursors for pagination. The existing API client maps HTTP
failures to the app's safe error types; the UI exposes a retry action.

No Firestore collection or security rules were added. If REST routes are not
available, the supplied contract describes a Firestore alternative, but it
requires a separate frontend decision and backend/security review before use.
