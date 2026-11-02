# HomeDoc AI — Video Consultation (Telehealth) Backend Contract

> **Target Audience:** FastAPI Backend Engineers  
> **Status:** Frontend Implemented & Verified • Awaiting Backend Agora Token Endpoint

---

## 1. Executive Summary

The Flutter frontend for **Feature 6: Video Consultation** has been implemented using `agora_rtc_engine: ^6.5.4` and Riverpod state management. 

To transition from the current client-side verified simulated preview to live production video calling between patients and doctors, the backend needs to provide an endpoint that generates RTC tokens for authenticated users.

---

## 2. Required Backend Endpoints

### `POST /api/v1/telehealth/token`

Generates an Agora RTC token for a patient or doctor entering an appointment's video room.

#### Request Headers
```http
Authorization: Bearer <Firebase_ID_Token>
Content-Type: application/json
```

#### Request Body
```json
{
  "appointment_id": "APT_0012398",
  "role": "publisher"
}
```

#### Expected Response (200 OK)
```json
{
  "app_id": "YOUR_AGORA_APP_ID",
  "channel_name": "consultation_APT_0012398",
  "token": "007eJxTYGg4W3l378H0Wf0P7r6e... (RTC Token)",
  "uid": 1029384,
  "expires_in_seconds": 3600,
  "doctor": {
    "doctor_id": "doc_demo_1",
    "name": "Dr. Sarah Mitchell",
    "specialty": "Cardiologist",
    "hospital": "HomeDoc Medical Center"
  }
}
```

#### Validation & Security Rules
1. Verify Firebase Auth UID from Bearer token matches either the appointment's `patientId` or `doctorId`.
2. Reject unauthorized callers with `403 Forbidden`.
3. Verify that the appointment status in Firestore is active (`doctorConfirmed`, `preparing`, or `inConsultation`).
4. Generate Agora RTC Token using Agora's Python SDK:
   ```python
   from agora_token_builder import RtcTokenBuilder, Role_Publisher
   token = RtcTokenBuilder.buildTokenWithUid(
       appId=AGORA_APP_ID,
       appCertificate=AGORA_APP_CERTIFICATE,
       channelName=channel_name,
       uid=uid,
       role=Role_Publisher,
       privilegeExpiredTs=int(time.time()) + 3600
   )
   ```

---

## 3. Webhook / Event Signals (Optional but Recommended)

### `POST /api/v1/telehealth/events`
When a consultation completes, the client signals conclusion. The backend updates the appointment in Firestore:
- `lifecycleStatus`: `completed`
- `consultationEndedAt`: Timestamp
- `consultationDurationSeconds`: Integer

---

## 4. Frontend Integration Points

- **Service / Notifier:** `lib/features/consultation/presentation/providers/video_consultation_provider.dart`
- **Main Screen:** `lib/features/consultation/presentation/pages/video_consultation_page.dart`
- **Views:**
  - `WaitingRoomView`: Device check, camera & mic test, queue position.
  - `ActiveCallView`: Agora `AgoraVideoView` / remote doctor feed, floating PiP, media controls.
  - `ConsultationCompletedView`: Duration summary, prescription deposit notice, follow-up links.
- **Dart Define for Agora App ID:**
  ```bash
  flutter run --dart-define=AGORA_APP_ID=YOUR_APP_ID
  ```
