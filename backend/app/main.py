from __future__ import annotations

from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.routes import agent, auth, doctors
from app.core.config import settings
from app.core.errors import register_exception_handlers
from app.core.logging import get_logger
from app.database.session import init_db

logger = get_logger("homedoc.main")


@asynccontextmanager
async def _lifespan(app: FastAPI):
    init_db()
    logger.info(
        "HomeDoc backend starting | environment=%s | real_llm=%s | db=%s",
        settings.environment.value,
        settings.uses_real_llm,
        settings.database_url,
    )
    yield


app = FastAPI(
    title="HomeDoc AI Backend",
    version="0.1.0-day3.2",
    description="Foundation build — see backend/README.md for scope and limitations.",
    lifespan=_lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=list(settings.cors_origins),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

register_exception_handlers(app)

app.include_router(auth.router)
app.include_router(doctors.router)
app.include_router(agent.router)


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}
