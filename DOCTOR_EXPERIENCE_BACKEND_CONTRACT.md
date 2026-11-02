# HomeDoc AI — Complete Doctor Experience Backend Contract

**Document Version:** 1.0  
**Domain:** Doctor Portal, Appointment Lifecycle, GPS Broadcasting & Availability  
**Author:** Flutter Frontend Team  
**Audience:** Backend Engineers, Cloud Functions Team, Database Administrators  

---

## 1. Overview & Responsibilities

In accordance with **Master Handover Prompt §2 & §11**:
- **Flutter Frontend:** Provides clinician dashboards, queue filtering (pending, confirmed, home visits, completed), accept/decline dialogs, live device GPS broadcasting with user consent, weekly schedule/time pickers, fee configuration, and follow-up recommendation workflows.
- **Backend / Firebase:** Validates doctor RBAC roles, persists appointment status updates, routes real-time doctor GPS streams, triggers notification events on appointment acceptance/rejection, and enforces Firestore security rules.

---

## 2. Firestore Document Schemas

### 2.1 Private Doctor User Profile (`users/{uid}`)
```json
{
  "uid": "doc_xyz789",
  "role": "doctor",
  "displayName": "Dr. Ananya Sharma",
  "phone": "+919876543210",
  "specialization": "Neurologist",
  "qualifications": "MBBS, MD (Neurology), DM",
  "hospital": "Apex Neuro Institute",
  "registrationNumber": "MCI-2016-92841",
  "experienceYears": 12,
  "location": "South Delhi, Delhi",
  "isVerified": true,
  "isActive": true,
  "availability": {
    "isAvailable": true,
    "days": {
      "Monday": true,
      "Tuesday": true,
      "Wednesday": true,
      "Thursday": true,
      "Friday": true,
      "Saturday": false,
      "Sunday": false
    },
    "startTime": "09:00 AM",
    "endTime": "05:00 PM"
  },
  "consultationModes": {
    "clinicVisit": true,
    "homeVisit": true,
    "video": true
  },
  "consultationFee": 800,
  "homeVisitFee": 1500,
  "videoFee": 700,
  "homeVisitRadiusKm": 15.0,
  "photoUrl": "https://res.cloudinary.com/demo/image/upload/doctor.jpg",
  "updatedAt": "2026-11-02T02:00:00Z"
}
```

### 2.2 Public Discoverable Doctor Profile (`doctor_public_profiles/{uid}`)
Synchronized automatically when the doctor saves their profile or availability.
```json
{
  "doctorId": "doc_xyz789",
  "displayName": "Dr. Ananya Sharma",
  "specialization": "Neurologist",
  "qualifications": "MBBS, MD (Neurology), DM",
  "hospital": "Apex Neuro Institute",
  "location": "South Delhi, Delhi",
  "registrationNumber": "MCI-2016-92841",
  "experienceYears": 12,
  "isVerified": true,
  "isActive": true,
  "isDiscoverable": true,
  "isAvailable": true,
  "consultationModes": {
    "clinicVisit": true,
    "homeVisit": true,
    "video": true
  },
  "consultationFee": 800,
  "homeVisitFee": 1500,
  "videoFee": 700,
  "homeVisitRadiusKm": 15.0,
  "photoUrl": "https://res.cloudinary.com/demo/image/upload/doctor.jpg",
  "rating": 4.9,
  "languages": ["English", "Hindi"],
  "updatedAt": "2026-11-02T02:00:00Z"
}
```

---

## 3. Live GPS Location Broadcasting Contract

### 3.1 Tracking Document (`active_tracking/{appointmentId}`)
During active home visits, the doctor's device broadcasts coordinates periodically:

```json
{
  "appointmentId": "appt_home_101",
  "doctorId": "doc_xyz789",
  "latitude": 28.5355,
  "longitude": 77.3910,
  "locationUpdatedAt": "2026-11-02T02:15:30Z",
  "trackingStatus": "onTheWay",
  "accuracy": 8.5
}
```

#### Status Values:
- `onTheWay` — Doctor is currently en route.
- `stopped` — Doctor or system has terminated tracking.

#### Safety & Consent Rules:
1. **Explicit Doctor Consent:** Location broadcast cannot be started without doctor consent.
2. **Appointment Scope:** Broadcaster only pushes coordinates for the active home visit.
3. **Automatic Termination:** Marking the appointment `completed`, `rejected`, or `cancelled` automatically stops broadcasting.

---

## 4. Doctor Appointment Management Lifecycle

```
[Patient Books] ──► booked
                       │
          ┌────────────┴────────────┐
          ▼                         ▼
   doctorConfirmed               rejected
          │
          ├─────────────────────────┬─────────────────────────┐
          ▼                         ▼                         ▼
     [Home Visit]             [Video Consult]           [Clinic Visit]
          │                         │                         │
      onTheWay                 inConsultation              arrived
          │                         │                         │
       arrived                      │                         ▼
          │                         │                   inConsultation
          ▼                         │                         │
    inConsultation ◄────────────────┘                         │
          │                                                   ▼
          └─────────────────────────────────────────────► completed
```

### Supported Statuses:
- `booked` — Initial state awaiting doctor acceptance.
- `doctorConfirmed` — Doctor accepted visit.
- `rejected` — Doctor declined request with optional reason.
- `preparing` — Doctor preparing medical kit / equipment.
- `onTheWay` — Doctor traveling to patient home (triggers live GPS broadcast).
- `arriving` — Doctor within 1 km or 5 mins of patient location.
- `arrived` — Doctor has arrived at patient premises / clinic check-in.
- `inConsultation` — Active consultation in progress (in-person or video room).
- `completed` — Consultation successfully completed.
- `cancelled` — Visit cancelled by patient or administrative staff.
