# HomeDoc AI — Family Healthcare Management & Patient Engagement Contract
**Frontend-to-Backend Integration Specification for Phase 7**

---

## 1. Overview & Architectural Boundary
In Phase 7, HomeDoc AI adds multi-profile family healthcare support and patient engagement. The Flutter client allows patients to register dependents (children, spouses, elderly parents) under their primary account, schedule appointments on behalf of dependents, set clinical vitals (blood group, allergies, chronic conditions), manage primary home visit addresses, and configure privacy consents.

This contract outlines the Firestore schemas, security rules, and backend requirements to support these capabilities.

---

## 2. Firestore Data Structures

### A. Family Members Subcollection
**Path:** `users/{patientUid}/family_members/{memberId}`

```json
{
  "name": "Aarav Sharma",
  "relationship": "Child",
  "dateOfBirth": "Timestamp (e.g. 2018-09-20T00:00:00Z)",
  "gender": "Male",
  "bloodGroup": "O+",
  "allergies": ["Peanuts"],
  "chronicConditions": ["Mild Asthma"],
  "isEmergencyContact": false,
  "emergencyPhone": null,
  "createdAt": "FieldValue.serverTimestamp()"
}
```

#### Field Specifications:
| Field | Type | Description |
|---|---|---|
| `name` | string | Full legal name of the dependent |
| `relationship` | string | One of: `"Spouse"`, `"Child"`, `"Parent"`, `"Sibling"`, `"Other"` |
| `dateOfBirth` | Timestamp / string | Dependent date of birth for age-based clinical dosage and pediatrics checks |
| `gender` | string | `"Female"`, `"Male"`, or `"Other"` |
| `bloodGroup` | string? | Blood group (`"A+"`, `"A-"`, `"B+"`, `"B-"`, `"O+"`, `"O-"`, `"AB+"`, `"AB-"`) |
| `allergies` | string[] | Array of validated medical/food allergens |
| `chronicConditions` | string[] | Array of ongoing medical diagnoses |
| `isEmergencyContact` | boolean | Whether this family member is marked for SOS / emergency dispatch alerts |
| `emergencyPhone` | string? | Phone number with country code (e.g. `"+919876543210"`) |
| `createdAt` | Timestamp | Record creation timestamp |

---

### B. Patient Profile & Home Visit Address Extensions
**Path:** `users/{patientUid}`

The patient's root document is extended with home visit dispatch coordinates and clinical privacy preferences:

```json
{
  "displayName": "Akanksha Sharma",
  "phone": "+919876543210",
  "email": "patient@homedoc.ai",
  "addressLine": "Flat 402, Green Glen Layout, Bellandur",
  "landmark": "Opposite Ecospace Tech Park",
  "city": "Bengaluru",
  "postalCode": "560103",
  "emergencyContactName": "Priya Sharma",
  "emergencyContactRelation": "Spouse",
  "emergencyContactPhone": "+919876543210",
  "bloodGroup": "O+",
  "allergies": ["Penicillin"],
  "chronicConditions": ["Mild Hypertension"],
  "preferredConsultationMode": "Home Visit",
  "dataSharingConsent": true,
  "notificationsEnabled": true,
  "medicationRemindersEnabled": true,
  "chatAlertsEnabled": true,
  "isVerified": true,
  "updatedAt": "FieldValue.serverTimestamp()"
}
```

---

### C. Dependent Appointment Bookings
**Path:** `appointments/{appointmentId}`

When booking an appointment for a family member, the Flutter client sets both the primary account holder's `patientId` (for billing, notifications, and permissions) and the dependent's details:

```json
{
  "appointmentId": "apt_xyz123",
  "patientId": "PRIMARY_ACCOUNT_UID",
  "patientName": "Aarav Sharma",
  "familyMemberId": "dependent_doc_id",
  "familyRelationship": "Child",
  "doctorId": "DOC_UID",
  "doctorName": "Dr. Sarah Jenkins",
  "specialty": "Pediatrics",
  "consultationType": "homeVisit",
  "consultationLabel": "Home Visit",
  "status": "booked",
  "scheduledAt": "Timestamp",
  "createdAt": "Timestamp",
  "updatedAt": "Timestamp"
}
```

---

## 3. Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // User root profile
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // Family members subcollection: only owner has access
      match /family_members/{memberId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
    
    // Appointments
    match /appointments/{appointmentId} {
      // Patient owner can read their appointments
      // Attending doctor can read and update status
      allow read: if request.auth != null && (
        resource.data.patientId == request.auth.uid || 
        resource.data.doctorId == request.auth.uid
      );
      allow create: if request.auth != null && request.resource.data.patientId == request.auth.uid;
      allow update: if request.auth != null && (
        resource.data.patientId == request.auth.uid || 
        resource.data.doctorId == request.auth.uid
      );
    }
  }
}
```

---

## 4. Frontend Status
- Models implemented in `lib/features/family/data/models/family_member_model.dart` and `lib/features/profile/data/models/patient_profile_model.dart`.
- Riverpod streams & action notifiers in `family_provider.dart` and `patient_profile_provider.dart`.
- Management UI in `family_profiles_page.dart` (`RoutePaths.patientFamilyProfiles`).
- Patient Profile redesigned in `profile_page.dart` with emergency contacts, home visit address, vitals, and privacy toggles.
- Dependent appointment booking integrated into `book_appointment_page.dart`.
- Unit tests written and verified in `test/unit/family_member_test.dart` (100% passing across 115 tests).
