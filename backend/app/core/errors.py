"""
Standardized error taxonomy — mirrors the Flutter client's AppException
hierarchy (core/errors/app_exception.dart) so status codes and shapes are
predictable end-to-end.
"""
from __future__ import annotations

from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse


class HomeDocError(Exception):
    status_code: int = 500
    code: str = "unknown_error"

    def __init__(self, message: str, *, debug_details: str | None = None):
        super().__init__(message)
        self.message = message
        self.debug_details = debug_details


class ValidationAppError(HomeDocError):
    status_code = 422
    code = "validation_error"


class AuthenticationAppError(HomeDocError):
    status_code = 401
    code = "authentication_error"


class AuthorizationAppError(HomeDocError):
    status_code = 403
    code = "authorization_error"


class NotFoundAppError(HomeDocError):
    status_code = 404
    code = "not_found"


class RateLimitAppError(HomeDocError):
    status_code = 429
    code = "rate_limited"


class AIServiceAppError(HomeDocError):
    """Mirrors the Flutter client's AIServiceException — anything in the
    AI Gateway/Agent/Tool pipeline that fails in a way the user should see
    as "care guidance temporarily unavailable" rather than a raw 500.
    """
    status_code = 503
    code = "ai_service_error"


class ToolPermissionError(HomeDocError):
    """Raised when the agent attempts a tool call that permission checks
    deny (Day 3.2 §15). Never exposes *why* in detail to the client beyond
    a generic message — the reasoning stays in the audit log.
    """
    status_code = 403
    code = "tool_permission_denied"


def register_exception_handlers(app: FastAPI) -> None:
    @app.exception_handler(HomeDocError)
    async def _handle_homedoc_error(request: Request, exc: HomeDocError) -> JSONResponse:
        # debug_details is intentionally never included in the response —
        # it exists for server-side logs only.
        return JSONResponse(
            status_code=exc.status_code,
            content={"code": exc.code, "message": exc.message},
        )

    @app.exception_handler(Exception)
    async def _handle_unexpected(request: Request, exc: Exception) -> JSONResponse:
        # Never leak a raw stack trace or exception message to the client.
        return JSONResponse(
            status_code=500,
            content={"code": "unknown_error", "message": "Something went wrong. Please try again."},
        )
