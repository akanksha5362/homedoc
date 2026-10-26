"""
Environment configuration (Day 3.2 §8, fixed in Day 4).

Nothing here has a hardcoded secret. Every sensitive value comes from an
environment variable with no committed default for production — local dev
falls back to obviously-fake, clearly-labeled placeholder values so the
app is runnable out of the box for foundation work, but those placeholders
must never be used in staging/production.

FIXED (Day 4): a `.env` file created per `.env.example`/README instructions
previously had NO EFFECT — nothing in the codebase loaded it into the
process environment; `os.getenv()` only sees variables actually exported
in the shell (or passed via `uvicorn --env-file`, which the README never
told anyone to use). `load_dotenv()` below makes `cp .env.example .env`
+ editing it actually work regardless of how the app is launched.
"""
from __future__ import annotations

import os
from dataclasses import dataclass, field
from enum import Enum

from dotenv import load_dotenv

# Loads backend/.env (if present) into os.environ, without overriding any
# variable already set for real in the actual environment (e.g. by a
# deployment platform) — `override=False` is the default and is what we
# want: real env vars always win over a local .env file.
load_dotenv()


class Environment(str, Enum):
    development = "development"
    staging = "staging"
    production = "production"


@dataclass(frozen=True)
class Settings:
    environment: Environment = field(
        default_factory=lambda: Environment(os.getenv("ENVIRONMENT", "development"))
    )

    # --- Database (Day 3.2 §5 "PostgreSQL connection foundation") ---
    # Defaults to a local SQLite file so the backend is runnable without a
    # running Postgres instance during foundation work. Point DATABASE_URL
    # at a real `postgresql+psycopg2://...` connection string for
    # staging/production — the SQLAlchemy layer above this doesn't care
    # which dialect it's talking to.
    database_url: str = field(
        default_factory=lambda: os.getenv("DATABASE_URL", "sqlite:///./homedoc_dev.db")
    )

    # --- Auth / JWT (Day 3.2 §7) ---
    # NEVER use this default outside local development. There is no
    # committed production value — deployment must set JWT_SECRET_KEY.
    jwt_secret_key: str = field(
        default_factory=lambda: os.getenv(
            "JWT_SECRET_KEY", "dev-only-insecure-secret-do-not-use-in-production"
        )
    )
    jwt_algorithm: str = "HS256"
    jwt_expiry_minutes: int = field(
        default_factory=lambda: int(os.getenv("JWT_EXPIRY_MINUTES", "60"))
    )

    # --- AI Gateway (Day 3.2 §11/§12) ---
    # If unset, the AI Gateway falls back to MockLLMProvider (deterministic,
    # no network call) rather than silently failing or pretending to call
    # a real model. See app/ai/gateway/gateway.py.
    gemini_api_key: str | None = field(
        default_factory=lambda: os.getenv("GEMINI_API_KEY") or None
    )
    gemini_model: str = field(
        default_factory=lambda: os.getenv("GEMINI_MODEL", "gemini-2.0-flash")
    )

    # --- CORS (so the Flutter dev app can call this locally) ---
    cors_origins: tuple[str, ...] = ("*",)  # tighten before any real deployment

    @property
    def is_production(self) -> bool:
        return self.environment == Environment.production

    @property
    def uses_real_llm(self) -> bool:
        return self.gemini_api_key is not None


settings = Settings()
