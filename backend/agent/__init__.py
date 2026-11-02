"""
HomeDoc AI — Standalone Care Coordination Agent package.

This package lives at backend/agent/ and is independent from the existing
foundation agent at backend/app/ai/agent/. It extends the architecture with
the full set of coordination tools, multi-step workflows, and confirmation
handling required for the complete care-coordination feature.

Reuses (read-only):
    - app.core.config.settings      — environment and Gemini key config
    - app.core.security.UserRole    — role-based access control
    - app.core.errors               — shared error taxonomy
    - app.core.logging              — structured logging
    - app.ai.gateway.*              — AIGateway / GeminiProvider / MockLLMProvider

Does NOT modify any of the above. Does NOT import from app.ai.agent.* or
app.api.*  — those remain the existing foundation layer.
"""
