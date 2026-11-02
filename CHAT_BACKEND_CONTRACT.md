# HomeDoc AI — Live Patient-Doctor Chat Backend Contract

> **Target Audience:** FastAPI & Firebase Backend Engineers  
> **Status:** Flutter Frontend Implemented & Verified • Awaiting Backend Firestore Security Rules & Webhook Integration

---

## 1. Architecture Overview

Patient-Doctor messaging in HomeDoc AI uses real-time Cloud Firestore subscriptions client-side (`snapshots()`), backed by Firebase Cloud Storage for protected attachments (clinical images, lab report PDFs, and digital prescriptions).

```
Flutter Client (Doctor & Patient)
       │
       ├── Reads/Writes: Cloud Firestore (`conversations/{convId}/messages/{msgId}`)
       │
       └── Uploads/Downloads: Cloud Storage (`chat_attachments/{convId}/{file}`)
```

---

## 2. Firestore Collection Schema

### A. Conversations Collection: `conversations/{conversationId}`

* `id` (`string`): Document ID format `conv_{patientUid}_{doctorUid}`
* `patientId` (`string`): Patient Firebase Auth UID
* `patientName` (`string`): Patient display name
* `patientPhotoUrl` (`string` | null): Patient avatar URL
* `doctorId` (`string`): Doctor Firebase Auth UID
* `doctorName` (`string`): Doctor full name
* `doctorSpecialty` (`string`): Medical specialty
* `doctorPhotoUrl` (`string` | null): Doctor profile photo
* `isDoctorOnline` (`boolean`): Presence state
* `participantIds` (`array of strings`): `[patientId, doctorId]` (used for security rules & array-contains queries)
* `appointmentId` (`string` | null): Optional linked appointment ID
* `appointmentStatus` (`string` | null): e.g. "Confirmed", "In Consultation"
* `lastMessage` (`string`): Text snippet of latest message
* `lastMessageAt` (`timestamp`): Timestamp of latest message
* `lastSenderId` (`string`): UID of the sender
* `unreadCountPatient` (`number`): Unread messages for the patient
* `unreadCountDoctor` (`number`): Unread messages for the doctor
* `createdAt` (`timestamp`): Initial creation timestamp

### B. Messages Subcollection: `conversations/{conversationId}/messages/{messageId}`

* `id` (`string`): Message UID (e.g. `msg_{timestamp}`)
* `conversationId` (`string`): Parent conversation ID
* `senderId` (`string`): UID of the author
* `senderName` (`string`): Display name of the author
* `senderRole` (`string`): `"patient"` or `"doctor"`
* `content` (`string`): Text content
* `type` (`string`): `"text"` | `"image"` | `"pdf"` | `"prescription"` | `"appointmentNotice"`
* `attachmentUrl` (`string` | null): Secure storage download URL
* `attachmentFileName` (`string` | null): e.g. "Blood_Report.pdf"
* `attachmentSizeBytes` (`number` | null): File size in bytes
* `status` (`string`): `"sending"` | `"sent"` | `"delivered"` | `"read"` | `"failed"`
* `sentAt` (`timestamp`): Send timestamp
* `readAt` (`timestamp` | null): Read receipt timestamp
* `relatedAppointmentId` (`string` | null): Optional appointment reference

---

## 3. Required Firestore Security Rules

To ensure medical privacy and prevent unauthorized access:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /conversations/{conversationId} {
      // Only authenticated participants can view or query the conversation
      allow read: if request.auth != null && 
        (request.auth.uid in resource.data.participantIds || request.auth.uid in request.resource.data.participantIds);
      
      // Creating or updating conversation
      allow create, update: if request.auth != null &&
        request.auth.uid in request.resource.data.participantIds;

      // Messages subcollection
      match /messages/{messageId} {
        allow read: if request.auth != null && 
          request.auth.uid in get(/databases/$(database)/documents/conversations/$(conversationId)).data.participantIds;
        
        allow create: if request.auth != null && 
          request.auth.uid in get(/databases/$(database)/documents/conversations/$(conversationId)).data.participantIds &&
          request.resource.data.senderId == request.auth.uid;

        allow update: if request.auth != null &&
          request.auth.uid in get(/databases/$(database)/documents/conversations/$(conversationId)).data.participantIds;
      }
    }
  }
}
```

---

## 4. Optional FastAPI REST Fallback Endpoints

If direct client Firestore writes are disabled by security policy, FastAPI must implement:

### `POST /api/v1/chat/conversations/{id}/messages`
#### Request Body:
```json
{
  "content": "Doctor, can I take this after lunch?",
  "type": "text",
  "related_appointment_id": "APT_00123"
}
```
#### Response (201 Created):
```json
{
  "message_id": "msg_1730502938",
  "sent_at": "2026-11-02T01:30:00Z",
  "status": "delivered"
}
```
