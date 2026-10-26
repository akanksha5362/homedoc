"""
Deterministic LLM stand-in (Day 3.2 §35: don't require a real model key
just to prove the architecture). Used automatically when GEMINI_API_KEY is
unset, and always used in tests — real-model nondeterminism has no place
in a test suite that's supposed to prove the *orchestration* logic works.

This is intentionally simple keyword matching, not a real NLU model. It's
enough to prove the end-to-end flow (Day 3.2 §26) without overclaiming
LLM capability that isn't actually wired up in this sandbox (no network
path to a real Gemini endpoint here — see README "AI Gateway" section).
"""
from __future__ import annotations

from app.ai.agent.intents import IntentExtraction
from app.ai.gateway.llm_provider import LLMProvider, LLMResult

_EMERGENCY_KEYWORDS = {
    "chest pain", "can't breathe", "cannot breathe", "severe bleeding",
    "unconscious", "suicide", "heart attack", "stroke", "not breathing",
}

_DOCTOR_SEARCH_KEYWORDS = {"doctor", "physician", "consult", "appointment", "fever", "sick", "unwell"}

_SPECIALTY_HINTS = {
    "fever": "General Physician",
    "cold": "General Physician",
    "cough": "General Physician",
    "child": "Pediatrics",
    "kid": "Pediatrics",
    "baby": "Pediatrics",
    "skin": "Dermatology",
}


class MockLLMProvider(LLMProvider):
    model_name = "mock-rule-based-v1"

    async def generate(self, *, system_prompt: str, user_message: str) -> LLMResult:
        # A plain, safe, template response — never fabricates medical content.
        text = (
            "Here's what I found based on what you shared. "
            "This is general guidance, not a diagnosis — please confirm "
            "anything important with a doctor."
        )
        return LLMResult(text=text, model_name=self.model_name, used_real_model=False)

    async def extract_intent(self, *, user_message: str) -> IntentExtraction:
        lower = user_message.lower()

        emergency = any(kw in lower for kw in _EMERGENCY_KEYWORDS)

        entities: dict[str, str] = {}
        for hint, specialty in _SPECIALTY_HINTS.items():
            if hint in lower:
                entities["specialty"] = specialty
                break

        if any(kw in lower for kw in _DOCTOR_SEARCH_KEYWORDS) or "specialty" in entities:
            intent = "doctor_search"
            confidence = 0.7
        else:
            intent = "unknown"
            confidence = 0.2

        return IntentExtraction(
            intent=intent,
            entities=entities,
            confidence=confidence,
            emergency_signal=emergency,
        )
