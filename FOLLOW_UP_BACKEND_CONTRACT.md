# HomeDoc AI — Regular Appointments & Follow-Up Reminders Backend Contract

> **Target Audience:** FastAPI & Firebase Backend Engineers  
> **Status:** Flutter Frontend Implemented & Verified • Awaiting Backend Recommendation Ingest & Slot Query Endpoints

---

## 1. Overview

**Feature 6: Regular Appointments & Follow-up Reminders** enables patients to maintain clinical continuity with their preferred doctors through:
1. **One-Tap Rebooking:** Direct rebooking with previously consulted doctors from completed appointments.
2. **Follow-Up Reminders:** Scheduling follow-up reminders, distinguishing doctor-recommended review dates from patient-scheduled check-ups.
3. **Recurring Healthcare Plans:** Supporting proposed review cadences (weekly, monthly, quarterly).

---

## 2. Appointment Model Extensions

When a doctor concludes a consultation, the backend should accept and store follow-up recommendations in the appointment document (`appointments/{appointmentId}`):

```json
{
  "lifecycleStatus": "completed",
  "doctorRecommendation": {
    "followUpRecommended": true,
    "recommendedFollowUpDays": 14,
    "recommendedTargetDate": "2026-11-16T10:00:00Z",
    "clinicalReason": "Review blood pressure readings and adjust Atorvastatin dosage."
  }
}
```

---

## 3. Required Endpoints

### A. Check Genuine Doctor Availability Slots: `GET /api/v1/doctors/{doctorId}/available-slots`

#### Query Parameters:
* `date`: `YYYY-MM-DD`
* `consultation_type`: `"clinicVisit"` | `"homeVisit"` | `"video"`

#### Expected Response (200 OK):
```json
{
  "doctor_id": "doc_101",
  "date": "2026-11-16",
  "available_slots": [
    "09:30 AM",
    "10:00 AM",
    "11:30 AM",
    "02:00 PM",
    "04:30 PM"
  ],
  "consultation_fee": 500
}
```

### B. One-Tap Rebook Appointment: `POST /api/v1/appointments/rebook`

#### Request Body:
```json
{
  "original_appointment_id": "APT_101",
  "doctor_id": "doc_101",
  "scheduled_at": "2026-11-16T10:00:00Z",
  "consultation_type": "clinicVisit",
  "notes": "Follow-up consultation per doctor recommendation"
}
```

#### Expected Response (201 Created):
```json
{
  "appointment_id": "APT_202",
  "status": "booked",
  "scheduled_at": "2026-11-16T10:00:00Z",
  "doctor_name": "Dr. Sarah Mitchell",
  "specialty": "Cardiologist"
}
```

---

## 4. Firestore Schema for Follow-Up Reminders

`users/{userId}/follow_up_reminders/{reminderId}`

* `id` (`string`): Reminder ID
* `patientId` (`string`): User UID
* `doctorId` (`string`): Doctor UID
* `doctorName` (`string`): Doctor full name
* `doctorSpecialty` (`string`): Specialty
* `relatedAppointmentId` (`string`): Completed appointment reference
* `targetDate` (`timestamp`): When consultation is due
* `reminderDateTime` (`timestamp`): When patient wants alert
* `isDoctorRecommended` (`boolean`): Clinician recommendation flag
* `reason` (`string`): Clinical reason
* `status` (`string`): `"pending"` | `"notified"` | `"completed"` | `"dismissed"`
* `recurringInterval` (`string`): `"none"` | `"weekly"` | `"monthly"` | `"quarterly"`
* `createdAt` (`timestamp`): Creation time
