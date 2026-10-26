"""
AI Gateway (Day 3.2 §11): the ONLY module that decides which LLMProvider
is active. Everything else (agent orchestrator, tools) depends on
`AIGateway`, never on GeminiProvider/MockLLMProvider directly — swapping
providers, adding retries, or adding cost tracking all happen here without
touching callers.
"""
from __future__ import annotations

import time

from app.ai.agent.intents import IntentExtraction
from app.ai.gateway.gemini_provider import GeminiProvider
from app.ai.gateway.llm_provider import LLMProvider, LLMResult
from app.ai.gateway.mock_provider import MockLLMProvider
from app.core.config import settings
from app.core.logging import log_ai_event


def _build_provider() -> LLMProvider:
    if settings.uses_real_llm:
        return GeminiProvider(api_key=settings.gemini_api_key, model=settings.gemini_model)
    return MockLLMProvider()


class AIGateway:
    def __init__(self, provider: LLMProvider | None = None):
        self._provider = provider or _build_provider()

    async def generate(self, *, system_prompt: str, user_message: str) -> LLMResult:
        started = time.monotonic()
        result = await self._provider.generate(system_prompt=system_prompt, user_message=user_message)
        log_ai_event(
            "llm_generate",
            model=result.model_name,
            used_real_model=result.used_real_model,
            latency_ms=round((time.monotonic() - started) * 1000, 1),
        )
        return result

    async def extract_intent(self, *, user_message: str) -> IntentExtraction:
        started = time.monotonic()
        result = await self._provider.extract_intent(user_message=user_message)
        log_ai_event(
            "llm_extract_intent",
            intent=result.intent,
            confidence=result.confidence,
            emergency_signal=result.emergency_signal,
            latency_ms=round((time.monotonic() - started) * 1000, 1),
        )
        return result
