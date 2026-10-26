"""
LLM provider abstraction (Day 3.2 §11). Nothing outside app/ai/gateway/
should import a vendor SDK or know Gemini exists — everything talks to
this interface via AIGateway (gateway.py).
"""
from __future__ import annotations

from abc import ABC, abstractmethod
from dataclasses import dataclass

from app.ai.agent.intents import IntentExtraction


@dataclass
class LLMResult:
    text: str
    model_name: str
    # True when a real model call happened; False when a deterministic
    # mock/fallback answered instead. The agent response's `model_used`
    # field surfaces this so nothing pretends a real LLM ran when it didn't.
    used_real_model: bool


class LLMProvider(ABC):
    @abstractmethod
    async def generate(self, *, system_prompt: str, user_message: str) -> LLMResult:
        """Free-form generation — used for explanation/summarization steps,
        never for anything the Safety Engine or Tool Registry needs to
        trust structurally (that's extract_intent, not this).
        """
        raise NotImplementedError

    @abstractmethod
    async def extract_intent(self, *, user_message: str) -> IntentExtraction:
        """Structured extraction: what does the user want. Kept separate
        from `generate` because intent/tool-selection is safety-relevant
        (Day 3.2 §13) and must return a constrained, parseable shape —
        never free text the orchestrator would have to guess at.
        """
        raise NotImplementedError
