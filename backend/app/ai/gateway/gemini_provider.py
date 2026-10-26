"""
Real Gemini integration (Day 3.2 §12), isolated behind LLMProvider so
nothing else in the app knows this vendor exists.

IMPORTANT — NOT EXERCISED IN THIS SANDBOX: this module was written and
reviewed for correctness against Gemini's public REST API shape, but this
authoring environment has no network path to
`generativelanguage.googleapis.com` (its egress allowlist covers package
registries only — see the project README's "Verification status"
section). It has NOT been run against a real API key. Test it for real
the first time you set GEMINI_API_KEY and run the backend outside this
sandbox — see backend/README.md.
"""
from __future__ import annotations

import json

import httpx

from app.ai.agent.intents import IntentExtraction
from app.ai.gateway.llm_provider import LLMProvider, LLMResult
from app.core.errors import AIServiceAppError
from app.core.logging import log_ai_event

_GEMINI_BASE_URL = "https://generativelanguage.googleapis.com/v1beta/models"

_INTENT_SYSTEM_PROMPT = """You are an intent classifier for a healthcare \
coordination app. Given a user's message, respond with ONLY a JSON object \
of this exact shape, nothing else:
{"intent": "doctor_search" | "symptom_check" | "unknown", \
"entities": {"specialty": "<string or omit>"}, "confidence": <0-1 float>, \
"emergency_signal": <true|false>}
Set emergency_signal true ONLY for clear emergency language (e.g. chest \
pain, can't breathe, unconscious, severe bleeding). Never invent a medical \
diagnosis. Never include any text outside the JSON object."""


class GeminiProvider(LLMProvider):
    def __init__(self, *, api_key: str, model: str):
        self._api_key = api_key
        self._model = model

    async def generate(self, *, system_prompt: str, user_message: str) -> LLMResult:
        text = await self._call(system_prompt=system_prompt, user_message=user_message)
        return LLMResult(text=text, model_name=self._model, used_real_model=True)

    async def extract_intent(self, *, user_message: str) -> IntentExtraction:
        raw = await self._call(system_prompt=_INTENT_SYSTEM_PROMPT, user_message=user_message)
        try:
            parsed = json.loads(raw)
            return IntentExtraction(
                intent=parsed.get("intent", "unknown"),
                entities=parsed.get("entities", {}) or {},
                confidence=float(parsed.get("confidence", 0.0)),
                emergency_signal=bool(parsed.get("emergency_signal", False)),
            )
        except (json.JSONDecodeError, ValueError, TypeError) as exc:
            # Malformed model output must never crash the request or be
            # silently treated as "safe" — fail closed into AIServiceAppError
            # so the orchestrator's caller shows "temporarily unavailable"
            # rather than proceeding on a guess.
            log_ai_event("gemini_malformed_response", model=self._model, error=str(exc))
            raise AIServiceAppError("AI response could not be parsed.") from exc

    async def _call(self, *, system_prompt: str, user_message: str) -> str:
        url = f"{_GEMINI_BASE_URL}/{self._model}:generateContent?key={self._api_key}"
        body = {
            "systemInstruction": {"parts": [{"text": system_prompt}]},
            "contents": [{"role": "user", "parts": [{"text": user_message}]}],
        }
        try:
            async with httpx.AsyncClient(timeout=15.0) as client:
                response = await client.post(url, json=body)
                response.raise_for_status()
                data = response.json()
                return data["candidates"][0]["content"]["parts"][0]["text"].strip()
        except (httpx.HTTPError, KeyError, IndexError) as exc:
            log_ai_event("gemini_call_failed", model=self._model, error_type=type(exc).__name__)
            raise AIServiceAppError("Care guidance is temporarily unavailable.") from exc
