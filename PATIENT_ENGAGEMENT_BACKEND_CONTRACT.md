# Patient Engagement & Notifications — Backend Contract

**Phase:** 8  
**Frontend status:** Complete (local notifications wired, UI entry points connected)  
**Backend status:** Required — see sections below

---

## 1. Local Notification Architecture (Frontend-only — DONE)

The Flutter app schedules **local device notifications** via `flutter_local_notifications`
(`lib/shared/services/notification_service.dart`).

### Channels

| Channel ID | Name | Purpose |
|---|---|---|
| `homedoc_medication_reminders` | Medication Reminders | Daily medication alarm at user-set time |
| `homedoc_follow_up_reminders` | Follow-Up Reminders | Follow-up consultation scheduled alerts |
| `homedoc_appointment_reminders` | Appointment Reminders | 24h + 1h before appointment start |

### Appointment reminder IDs

Given an appointment Firestore document ID `apptId`:

```dart
base = (apptId.hashCode.abs() % 10_000_000) * 10
24h reminder ID = base + 0
 1h reminder ID = base + 1
```

Reminders are scheduled immediately after a successful Firestore appointment write
(`book_appointment_page.dart`) and cancelled when the patient cancels
(`appointments_page.dart → _cancelAppointment`).

---

## 2. Push Notifications — Backend Required

Local notifications only fire on the device where the appointment was booked.
For cross-device delivery (e.g., doctor's device, patient reinstalling the app),
**Firebase Cloud Messaging (FCM) is required**.

### FCM tokens

The frontend must store the FCM token in Firestore when the user signs in.

**Backend must implement:**

```
PATCH /users/{uid}/fcm_token
Body: { "fcmToken": "<device_fcm_token>", "platform": "android|ios" }
```

**Frontend will call this on:**
1. First sign-in
2. Token refresh (FirebaseMessaging.onTokenRefresh)

**Firestore write (frontend alternative if no API):**

```
users/{uid}
  fcmTokens: [{ token: string, platform: string, updatedAt: Timestamp }]
```

### Appointment confirmation push (backend)

When a **doctor confirms** an appointment (status → `doctorConfirmed`), the backend
should send an FCM push to the patient:

```json
{
  "to": "<patient_fcm_token>",
  "notification": {
    "title": "Appointment Confirmed ✅",
    "body": "Dr. {doctorName} confirmed your {consultationType} on {date}."
  },
  "data": {
    "type": "appointment_confirmed",
    "appointmentId": "<id>"
  }
}
```

### Chat message push (backend)

When a new chat message arrives, the backend should notify the recipient:

```json
{
  "to": "<recipient_fcm_token>",
  "notification": {
    "title": "{senderName}",
    "body": "{messagePreview}"
  },
  "data": {
    "type": "chat_message",
    "conversationId": "<id>",
    "senderId": "<id>"
  }
}
```

### Doctor arriving push (backend)

When a doctor's tracking status changes to `onTheWay` or `arriving`:

```json
{
  "to": "<patient_fcm_token>",
  "notification": {
    "title": "Your doctor is on the way 🚗",
    "body": "Dr. {doctorName} has started heading to your location."
  },
  "data": {
    "type": "doctor_arriving",
    "appointmentId": "<id>"
  }
}
```

---

## 3. In-App Notification Centre — Frontend Stub Available

A notification centre screen has NOT been built yet (Phase 8 scope).
The frontend will implement once the backend provides the notification history API.

**Required API:**

```
GET /patients/{uid}/notifications?limit=50&after={cursor}

Response 200:
{
  "notifications": [
    {
      "id": "string",
      "type": "appointment_confirmed | chat_message | doctor_arriving | medication_missed | follow_up_due",
      "title": "string",
      "body": "string",
      "read": false,
      "createdAt": "ISO8601",
      "data": { ... type-specific ... }
    }
  ],
  "nextCursor": "string | null"
}

PATCH /patients/{uid}/notifications/{notificationId}/read
PATCH /patients/{uid}/notifications/read-all
```

**Firestore alternative** (if no REST API):

```
notifications/{notificationId}
  recipientId: string
  type: string
  title: string
  body: string
  read: bool
  createdAt: Timestamp
  data: map
```

Security rule: `recipientId == request.auth.uid`

---

## 4. Notification Settings Sync

The patient profile stores notification preferences locally in Firestore:

```
users/{uid}
  notificationSettings: {
    appointmentReminders: true,
    medicationAlarms: true,
    chatMessages: true,
    healthTips: false
  }
```

**Frontend behaviour:**
- Before scheduling any local notification, the patient profile provider is NOT
  yet consulted (Phase 8 keeps it simple: schedule always).
- **TODO Phase 9:** Read `notificationSettings.appointmentReminders` before
  calling `NotificationService.scheduleAppointmentReminders()`.

**Backend requirement:**
- When sending FCM pushes, check `notificationSettings` to respect opt-outs.

---

## 5. Care Page AI Entry Points (Frontend-only — DONE)

Two AI tool cards are now rendered in `care_page.dart` above the doctor list:

| Card | Route | Backend |
|---|---|---|
| Symptom Checker | `RoutePaths.patientAiCare` | Existing AI care endpoint |
| AI Health Search | `RoutePaths.patientAiSearch` | Existing AI search endpoint |

No new backend API is required for these entry points.

---

## 6. Frontend Files Changed (Phase 8)

| File | Change |
|---|---|
| `lib/shared/services/notification_service.dart` | Added `scheduleAppointmentReminders()`, `cancelAppointmentReminders()`, `appointmentIdBase()`, `_apptDetails` channel |
| `lib/features/appointments/presentation/pages/book_appointment_page.dart` | Calls `scheduleAppointmentReminders()` after successful booking |
| `lib/features/appointments/presentation/pages/appointments_page.dart` | Calls `cancelAppointmentReminders()` after successful cancellation; fixed `unawaited_futures` and `use_build_context_synchronously` |
| `lib/features/care/presentation/pages/care_page.dart` | Added `_buildAiToolsStrip()` + `_AiToolCard` widget |
| `lib/features/auth/presentation/pages/login_page.dart` | Fixed `prefer_const_constructors` |
| `lib/features/auth/presentation/pages/splash_page.dart` | Fixed `prefer_const_constructors` |
| `test/unit/notification_service_test.dart` | 10 new unit tests |
