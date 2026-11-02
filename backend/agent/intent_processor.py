"""
Intent Processor — converts natural-language patient messages into structured
ExtractedIntent objects using the existing AIGateway (Gemini Flash or Mock).

Design rules enforced here:
- The LLM output is PARSED into a fixed schema, never trusted as-is.
- Emergency detection is double-layered: keyword rules fire BEFORE any LLM
  call so a network failure can never suppress an emergency signal.
- Tool selection is NOT done by the LLM — it extracts intent + entities only.
  The orchestrator maps intents to tools deterministically in code.

[INTEGRATION POINT: Pass existing Gemini Flash chatbot output to this processor
 instead of re-calling Gemini — if the chatbot has already extracted intent and
 entities for this turn, pass them via ExtractedIntent directly to the
 orchestrator's handle_execute(), bypassing extract().]
"""
from __future__ import annotations

import json
import re
from typing import Any

from app.ai.gateway.gateway import AIGateway
from app.core.logging import get_logger

from agent.schemas import AgentIntent, ExtractedIntent

logger = get_logger("homedoc.agent.intent_processor")

# ---------------------------------------------------------------------------
# Emergency keyword set — code-level check, never solely LLM-driven.
# This runs BEFORE the Gemini call so a model failure cannot suppress it.
# ---------------------------------------------------------------------------
_EMERGENCY_KEYWORDS: frozenset[str] = frozenset({
    "chest pain", "heart attack", "can't breathe", "cannot breathe",
    "not breathing", "severe bleeding", "unconscious", "unresponsive",
    "stroke", "suicide", "kill myself", "overdose", "seizure",
    "anaphylaxis", "allergic reaction", "choking",
})

# ---------------------------------------------------------------------------
# Specialty keyword hints — used by both mock and real providers
# ---------------------------------------------------------------------------
_SPECIALTY_HINTS: dict[str, str] = {
    "cardio": "Cardiology",
    "heart": "Cardiology",
    "cardiac": "Cardiology",
    "skin": "Dermatology",
    "derma": "Dermatology",
    "rash": "Dermatology",
    "child": "Pediatrics",
    "kid": "Pediatrics",
    "baby": "Pediatrics",
    "paediatric": "Pediatrics",
    "pediatric": "Pediatrics",
    "neuro": "Neurology",
    "brain": "Neurology",
    "headache": "Neurology",
    "migraine": "Neurology",
    "bone": "Orthopedics",
    "joint": "Orthopedics",
    "ortho": "Orthopedics",
    "fracture": "Orthopedics",
    "fever": "General Physician",
    "cold": "General Physician",
    "cough": "General Physician",
    "flu": "General Physician",
    "general": "General Physician",
}

_CONSULTATION_HINTS: dict[str, str] = {
    "home": "home_visit",
    "visit": "home_visit",
    "home visit": "home_visit",
    "video": "video",
    "online": "video",
    "virtual": "video",
    "tele": "video",
    "clinic": "clinic",
    "in-person": "clinic",
    "in person": "clinic",
}

_DOCTOR_SEARCH_KEYWORDS: frozenset[str] = frozenset({
    "doctor", "physician", "specialist", "consult", "appointment",
    "find", "search", "book", "see a", "need a", "want a",
    "sick", "unwell", "ill", "pain", "ache",
})

_AVAILABILITY_KEYWORDS: frozenset[str] = frozenset({
    "available", "availability", "slot", "slots", "when", "schedule",
    "time", "free", "open",
})

_BOOKING_KEYWORDS: frozenset[str] = frozenset({
    "book", "confirm", "schedule", "reserve", "set up",
})

_RECORDS_KEYWORDS: frozenset[str] = frozenset({
    "record", "records", "history", "medical history", "my file",
    "past visit", "previous",
})

_PRESCRIPTION_KEYWORDS: frozenset[str] = frozenset({
    "prescription", "prescriptions", "medicine", "medication",
    "drug", "tablet", "pill", "refill",
})

_FOLLOWUP_KEYWORDS: frozenset[str] = frozenset({
    "reminder", "remind", "follow up", "followup", "follow-up",
    "next visit", "check-in", "check in",
})

# ---------------------------------------------------------------------------
# Gemini system prompt for structured intent extraction
# ---------------------------------------------------------------------------
_INTENT_SYSTEM_PROMPT = """\
You are an intent classifier for HomeDoc, a healthcare coordination app.
Given a user message, respond with ONLY a JSON object of this exact shape, nothing else:
{
  "intent": "<one of: doctor_search | check_availability | book_appointment | get_patient_records | get_prescriptions | schedule_followup | emergency | unknown>",
  "entities": {
    "specialty": "<medical specialty or omit>",
    "date": "<YYYY-MM-DD or omit>",
    "consultation_type": "<home_visit | video | clinic or omit>",
    "doctor_id": "<doctor ID if mentioned or omit>",
    "reminder_time": "<HH:MM or omit>",
    "location": "<city/area or omit>"
  },
  "confidence": <0.0 to 1.0>,
  "emergency_signal": <true | false>
}

Rules:
- Set emergency_signal=true ONLY for clear emergency language (chest pain, can't breathe, unconscious, severe bleeding, heart attack, stroke, seizure).
- NEVER diagnose, prescribe, or give medical advice.
- NEVER include any text outside the JSON object.
- If unsure about intent, use "unknown".
"""


class IntentProcessor:
    """
    Converts a raw patient message into a structured ExtractedIntent.

    Uses the AIGateway for Gemini-powered extraction when an API key is
    configured; falls back to deterministic keyword rules otherwise.
    Both paths produce the same ExtractedIntent shape — callers cannot
    tell which path ran.
    """

    def __init__(self, gateway: AIGateway) -> None:
        self._gateway = gateway

    async def extract(self, *, message: str) -> ExtractedIntent:
        """
        Extract structured intent from a patient message.

        Emergency detection always runs FIRST in code, before any LLM call.
        """
        lower = message.lower()

        # Step 1: Emergency keyword check — code level, cannot be overridden
        # by LLM hallucination or network failure.
        if self._has_emergency_signal(lower):
        logger.warning("emergency_keyword_detected message_length=%d", len(message))
            return ExtractedIntent(
                intent=AgentIntent.emergency,
                confidence=1.0,
                emergency_signal=True,
                raw_text=message,
            )

        # Step 2: Try Gemini-powered extraction
        try:
            return await self._extract_via_gateway(message=message)
        except Exception as exc:  # noqa: BLE001
            # Gemini failure must never crash the request — fall back to
            # keyword rules. Log it, but continue.
        logger.warning("intent_extraction_fallback reason=%s message=%s", type(exc).__name__, "Gemini extraction failed, using keyword rules")
            return self._extract_via_keywords(message=message)

    # ------------------------------------------------------------------
    # Private helpers
    # ------------------------------------------------------------------

    @staticmethod
    def _has_emergency_signal(lower: str) -> bool:
        return any(kw in lower for kw in _EMERGENCY_KEYWORDS)

    async def _extract_via_gateway(self, *, message: str) -> ExtractedIntent:
        """Call the gateway's extract_intent and map to our richer schema."""
        # The existing gateway.extract_intent() returns an IntentExtraction
        # (app.ai.agent.intents) with a limited intent vocabulary. We call
        # generate() with our own prompt to get the full entity set needed
        # for care coordination.

        # Use generate() with a structured prompt rather than extract_intent()
        # so we can get our extended entity set (date, consultation_type, etc.)
        result = await self._gateway.generate(
            system_prompt=_INTENT_SYSTEM_PROMPT,
            user_message=message,
        )
        raw = result.text.strip()

        # Strip markdown code fences if the model wrapped the JSON
        raw = re.sub(r"^```(?:json)?\s*", "", raw)
        raw = re.sub(r"\s*```$", "", raw)

        parsed = json.loads(raw)  # raises on malformed output → caller catches

        intent_str = parsed.get("intent", "unknown")
        try:
            intent = AgentIntent(intent_str)
        except ValueError:
            intent = AgentIntent.unknown

        # Validate emergency_signal at code level too — don't trust only LLM
        emergency = bool(parsed.get("emergency_signal", False))
        emergency = emergency or self._has_emergency_signal(message.lower())

        entities: dict[str, Any] = {}
        raw_entities = parsed.get("entities") or {}
        for key in ("specialty", "date", "consultation_type", "doctor_id",
                    "reminder_time", "location"):
            if raw_entities.get(key):
                entities[key] = raw_entities[key]

        return ExtractedIntent(
            intent=intent,
            entities=entities,
            confidence=float(parsed.get("confidence", 0.5)),
            emergency_signal=emergency,
            raw_text=message,
        )

    @staticmethod
    def _extract_via_keywords(*, message: str) -> ExtractedIntent:
        """
        Deterministic keyword-based fallback. Used when:
        - GEMINI_API_KEY is unset (MockLLMProvider is active, but its
          extract_intent() doesn't support our extended entity set)
        - Gemini call fails at runtime

        This is intentionally simple — it proves the orchestration flow
        without overclaiming NLU capability.
        """
        lower = message.lower()
        entities: dict[str, Any] = {}

        # Specialty detection
        for hint, specialty in _SPECIALTY_HINTS.items():
            if hint in lower:
                entities["specialty"] = specialty
                break

        # Consultation type detection
        for hint, ctype in _CONSULTATION_HINTS.items():
            if hint in lower:
                entities["consultation_type"] = ctype
                break

        # Date extraction — simple "tomorrow" / "today" / YYYY-MM-DD pattern
        from datetime import date, timedelta
        if "tomorrow" in lower:
            entities["date"] = (date.today() + timedelta(days=1)).isoformat()
        elif "today" in lower:
            entities["date"] = date.today().isoformat()
        else:
            m = re.search(r"\d{4}-\d{2}-\d{2}", message)
            if m:
                entities["date"] = m.group(0)

        # Intent classification via keyword sets
        if any(kw in lower for kw in _FOLLOWUP_KEYWORDS):
            intent = AgentIntent.schedule_followup
            confidence = 0.75
        elif any(kw in lower for kw in _PRESCRIPTION_KEYWORDS):
            intent = AgentIntent.get_prescriptions
            confidence = 0.80
        elif any(kw in lower for kw in _RECORDS_KEYWORDS):
            intent = AgentIntent.get_patient_records
            confidence = 0.75
        elif any(kw in lower for kw in _BOOKING_KEYWORDS):
            intent = AgentIntent.book_appointment
            confidence = 0.70
        elif any(kw in lower for kw in _AVAILABILITY_KEYWORDS):
            intent = AgentIntent.check_availability
            confidence = 0.70
        elif (any(kw in lower for kw in _DOCTOR_SEARCH_KEYWORDS)
              or "specialty" in entities):
            intent = AgentIntent.doctor_search
            confidence = 0.65
        else:
            intent = AgentIntent.unknown
            confidence = 0.20

        return ExtractedIntent(
            intent=intent,
            entities=entities,
            confidence=confidence,
            emergency_signal=False,
            raw_text=message,
        )
