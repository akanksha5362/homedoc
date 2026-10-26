"""
ML service abstraction (Day 3.2 §18/§19). Separate from the LLM Gateway
on purpose — urgency classification, doctor recommendation, no-show
prediction, and ETA prediction are decision-support SIGNALS, not
conversation, and the LLM must never be allowed to fabricate one of these
outputs itself (Day 3.2 §20: "The LLM should not hallucinate an ML
classification").
"""
from __future__ import annotations

from abc import ABC, abstractmethod
from dataclasses import dataclass
from typing import Any


@dataclass
class MLPrediction:
    model_name: str
    model_version: str
    output: Any
    # Explicit, unmissable flag — every prediction must self-report
    # whether it came from a real trained model or a rules-based
    # prototype (Day 3.2 §18: "Do NOT train fake clinical models and
    # present them as medically validated").
    is_prototype: bool
    confidence: float | None = None


class MLModelProvider(ABC):
    model_name: str
    model_version: str

    @abstractmethod
    def predict(self, features: dict[str, Any]) -> MLPrediction:
        raise NotImplementedError


class ModelRegistry:
    """Maps a model name to its currently-active implementation. Swapping
    `SymptomUrgencyModel` v1 (rules) for a real trained v2 classifier later
    is a one-line change here — nothing else in the codebase should
    import a concrete model class directly.
    """

    def __init__(self) -> None:
        self._models: dict[str, MLModelProvider] = {}

    def register(self, model: MLModelProvider) -> None:
        self._models[model.model_name] = model

    def get(self, model_name: str) -> MLModelProvider | None:
        return self._models.get(model_name)
