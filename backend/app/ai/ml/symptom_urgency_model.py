"""
Symptom/Urgency "model" — Day 3.2 §18 explicitly permits (and prefers,
absent real clinical data) a documented rules/prototype baseline over a
fake trained model presented as clinically validated. This is exactly
that: a small, transparent rule set, not a machine-learned classifier.

LIMITATIONS (documented per Day 3.2 §18):
- Not trained on any clinical dataset.
- Not validated by a medical professional.
- Covers only a handful of hardcoded keyword patterns.
- Intended purely to prove the ML-service *architecture* (interface,
  registry, is_prototype flagging, agent routing) works end-to-end — NOT
  to make real triage decisions. A real model (trained, evaluated, and
  clinically reviewed) is Day 4+ scope; when it exists, it registers under
  the same `ModelRegistry` key and nothing else in the app changes.
"""
from __future__ import annotations

from typing import Any

from app.ai.ml.base import MLModelProvider, MLPrediction

_HIGH_URGENCY_KEYWORDS = {"severe pain", "high fever", "difficulty breathing", "persistent vomiting"}
_MODERATE_URGENCY_KEYWORDS = {"fever", "headache", "sore throat", "cough", "body ache"}


class SymptomUrgencyModel(MLModelProvider):
    model_name = "symptom_urgency_baseline"
    model_version = "v0-rule-prototype"

    def predict(self, features: dict[str, Any]) -> MLPrediction:
        text = str(features.get("symptom_text", "")).lower()

        if any(kw in text for kw in _HIGH_URGENCY_KEYWORDS):
            output = "HIGH"
        elif any(kw in text for kw in _MODERATE_URGENCY_KEYWORDS):
            output = "MODERATE"
        else:
            output = "LOW"

        return MLPrediction(
            model_name=self.model_name,
            model_version=self.model_version,
            output=output,
            is_prototype=True,
            confidence=None,  # a rule set has no calibrated confidence — don't fake one
        )
