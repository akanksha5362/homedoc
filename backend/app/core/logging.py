"""
Structured logging with mandatory redaction (Day 3.2 §31).

Every log call goes through `get_logger(name)` -> standard library logging,
but AI-specific call sites use `log_ai_event` below so redaction is applied
in exactly one place rather than trusted to every call site individually.
"""
from __future__ import annotations

import logging
import sys
from typing import Any

_REDACTED = "[REDACTED]"

# Fields that must NEVER appear in a log line, even truncated.
_SENSITIVE_KEYS = {
    "password",
    "access_token",
    "refresh_token",
    "jwt",
    "symptoms",          # free-text patient input — never logged verbatim
    "raw_prompt",
    "raw_response",
    "medical_history",
    "allergies",
    "medications",
    "payment_secret",
    "card_number",
    "gemini_api_key",
}

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s: %(message)s",
    stream=sys.stdout,
)


def get_logger(name: str) -> logging.Logger:
    return logging.getLogger(name)


def redact(payload: dict[str, Any]) -> dict[str, Any]:
    """Recursively replaces any sensitive key's value with a redaction marker.
    Used by log_ai_event and anywhere else structured data is logged.
    """
    clean: dict[str, Any] = {}
    for key, value in payload.items():
        if key.lower() in _SENSITIVE_KEYS:
            clean[key] = _REDACTED
        elif isinstance(value, dict):
            clean[key] = redact(value)
        else:
            clean[key] = value
    return clean


_ai_logger = get_logger("homedoc.ai")


def log_ai_event(event: str, **fields: Any) -> None:
    """The single call site AI subsystems use to log events (Day 3.2 §31):
    agent request, intent, selected tool, model, latency, failures, tool
    errors, confirmation, escalation, model version. Never pass raw
    symptom text or medical data in `fields` — it will be redacted, but
    the goal is to never construct the payload with that data at all.
    """
    _ai_logger.info("%s | %s", event, redact(fields))
