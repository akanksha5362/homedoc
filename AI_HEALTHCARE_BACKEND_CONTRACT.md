# HomeDoc AI — AI Healthcare Backend Contract & Grounding Specifications

**Document Version:** 1.0  
**Domain:** AI Healthcare, Conversational Symptom Triage & Google Search Grounding  
**Author:** Flutter Frontend Team  
**Audience:** FastAPI Backend Engineers, AI/ML Infrastructure Team

---

## 1. Overview & Architectural Boundaries

In accordance with **Master Handover Prompt §2, §7, and §8**:
- **Flutter Client:** Handles UI dialogues, progressive questioning states, immediate rules-based emergency interception, clinical urgency rendering, citations display, and doctor deep-linking.
- **FastAPI / AI Gateway:** Orchestrates multi-turn agent sessions, rules-engine emergency keyword verification, Gemini Google Search Grounding, and Firestore/SQL doctor matching.

---

## 2. Conversational Symptom Checker & Triage Contract

### 2.1 Multi-Stage Dialogue Contract (`POST /ai/triage/conversational`)
Supports progressive multi-turn clinical inquiry instead of overwhelming static questionnaires.

#### Endpoint
```http
POST /ai/triage/conversational
Authorization: Bearer <JWT_ACCESS_TOKEN>
Content-Type: application/json
```

#### Request Payload
```json
{
  "session_id": "session_uuid_or_null",
  "chief_complaint": "Recurring throbbing headaches with light sensitivity",
  "duration": "About a week",
  "severity": "Moderate (limits daily routines)",
  "associated_symptoms": [
    "Nausea or vomiting",
    "Dizziness"
  ],
  "medical_history": "Hypertension",
  "age_context": 34
}
```

#### Response Payload
```json
{
  "summary": "Your symptoms describe recurrent throbbing headaches with nausea over a one-week duration.",
  "urgency": "urgent",
  "why_assigned": "Recurrent moderate headaches with neurological symptoms (nausea, light sensitivity) warrant clinical evaluation to rule out acute secondary etiologies.",
  "recommendation": "Prompt consultation with a certified Neurologist recommended within 24 to 48 hours.",
  "next_step": "Book a neurological assessment and keep a headache trigger diary.",
  "suggested_specialty": "Neurologist",
  "red_flags": [
    "Sudden explosive or 'thunderclap' headache onset",
    "Stiff neck accompanied by high fever or confusion",
    "Focal weakness, numbness, or loss of vision"
  ],
  "is_uncertain": true,
  "emergency_detected": false,
  "disclaimer": "AI healthcare guidance and triage support, not a definitive diagnosis. Always consult a licensed clinician for medical evaluation."
}
```

### 2.2 Hard Emergency Rules Override
The backend **must never** allow an LLM to override emergency red flags downward:
- Chest pain / pressure / tightness
- Acute respiratory distress / choking
- Focal neurological deficits (facial drooping, slurred speech, sudden paralysis)
- Profuse hemorrhage
- Anaphylaxis signs

If any trigger is detected:
```json
{
  "summary": "Critical health alert: Severe potential emergency symptoms identified.",
  "urgency": "emergency",
  "why_assigned": "Reported symptoms match critical cardiac/neurological emergency thresholds.",
  "recommendation": "Immediate emergency evaluation by paramedics or hospital emergency department.",
  "next_step": "Call emergency services (108 / 911 / 112) immediately.",
  "suggested_specialty": "Emergency Medicine",
  "red_flags": ["Severe chest pain", "Breathlessness"],
  "is_uncertain": false,
  "emergency_detected": true,
  "disclaimer": "Emergency escalation alert. Do not wait for an online consultation."
}
```

---

## 3. Google AI Health Search & Grounding Contract

### 3.1 Search Grounding Endpoint (`POST /ai/search/grounded`)
Grounds natural-language health queries in peer-reviewed medical sources using Gemini with Google Search Grounding.

#### Endpoint
```http
POST /ai/search/grounded
Authorization: Bearer <JWT_ACCESS_TOKEN>
Content-Type: application/json
```

#### Request Payload
```json
{
  "query": "My eyes become blurry after screen usage",
  "patient_location": {
    "latitude": 28.6139,
    "longitude": 77.2090
  }
}
```

#### Response Payload
```json
{
  "query": "My eyes become blurry after screen usage",
  "overview": "Temporary blurred vision following prolonged digital screen usage is commonly associated with Computer Vision Syndrome (asthenopia) and reduced blink rates leading to tear film evaporation.",
  "potential_causes": [
    "Digital eye strain and dry eye syndrome",
    "Uncorrected refractive errors (astigmatism, myopia)",
    "Accommodative fatigue or binocular vision dysfunction"
  ],
  "recommended_specialties": [
    "Ophthalmologist",
    "General Physician"
  ],
  "warning_signs": [
    "Sudden loss or severe darkening in vision in either eye",
    "Halos around lights with intense ocular pain and nausea",
    "Sudden surge of flashing lights or floating specks"
  ],
  "citations": [
    {
      "title": "Computer Vision Syndrome: Diagnosis and Management",
      "source": "American Academy of Ophthalmology",
      "domain": "aao.org",
      "snippet": "Screen use reduces blink rates by up to 50%, exacerbating dry eye and transient visual blur."
    },
    {
      "title": "Eye Strain Causes and Preventive Care",
      "source": "Mayo Clinic",
      "domain": "mayoclinic.org",
      "snippet": "Follow the 20-20-20 rule to relieve ocular accommodation strain during digital device usage."
    }
  ],
  "matched_doctor_ids": [
    "doc_ophthalmology_101",
    "doc_physician_204"
  ],
  "disclaimer": "Grounded medical educational information. Not a medical diagnosis or treatment plan."
}
```

---

## 4. Multi-Turn AI Assistant & Medical Report Explainer Contract

### 4.1 Enhanced Agent Request (`POST /ai/agent`)
Existing endpoint enhanced to support multi-turn memory and medical report interpretation.

#### Request Payload
```json
{
  "message": "Can you explain what an HbA1c result of 6.8% means?",
  "session_id": "session-uuid",
  "context_type": "report_explanation"
}
```

#### Response Payload
```json
{
  "message": "An HbA1c of 6.8% reflects your average blood sugar levels over the past 2 to 3 months. In clinical guidelines, an HbA1c between 5.7% and 6.4% indicates prediabetes, while 6.5% or higher on two separate tests generally indicates diabetes mellitus.\n\nQuestions you may want to ask your doctor:\n1. Does this result confirm a diabetes diagnosis for me?\n2. What dietary modifications or physical activity changes do you recommend?\n3. Would lifestyle changes alone be appropriate, or do I need medication?",
  "intent": "medical_report_explanation",
  "risk_level": "low",
  "requires_confirmation": false,
  "actions": [
    {
      "type": "SHOW_DOCTORS",
      "data": {
        "specialty": "Endocrinologist"
      }
    }
  ],
  "session_id": "session-uuid",
  "tool_used": "search_doctors",
  "model_used": "gemini-1.5-pro"
}
```

---

## 5. Security & Clinical Governance Rules
1. **Never Log Patient Symptoms Verbatim:** Strip free-text symptoms from application log aggregators.
2. **Never Return Prescriptions or Dosages:** AI must not provide specific drug dosing regimens.
3. **No Definitive Diagnosis:** AI responses must strictly utilize advisory framing: *"symptoms may indicate...", "literature suggests...", "recommend clinical evaluation..."*.
4. **Authoritative Emergency Short-Circuit:** The client rules engine and backend policy engine both execute hard keyword stops that immediately return `EMERGENCY` without continuing the questionnaire.
