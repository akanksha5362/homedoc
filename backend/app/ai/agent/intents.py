"""
Intent extraction result shape + the foundation-stage extractor
(Day 3.2 §13 "Intent Detection"). Kept as a small, structured dataclass so
the orchestrator never has to parse free text to decide which tool to run
— that decision must be deterministic and auditable, not vibes-based.
"""
from __future__ import annotations

from dataclasses import dataclass, field


@dataclass
class IntentExtraction:
    intent: str                     # e.g. "doctor_search", "symptom_check", "unknown"
    entities: dict[str, str] = field(default_factory=dict)   # e.g. {"specialty": "fever"}
    confidence: float = 0.0
    emergency_signal: bool = False  # set by keyword rules, never solely by the LLM (Day 3.2 §13/§23)
