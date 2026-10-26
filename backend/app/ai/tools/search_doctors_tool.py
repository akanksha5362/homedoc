"""
The one tool that's fully real end-to-end (Day 3.2 §26 first working
flow). Goes through the same repository the /doctors REST endpoint uses —
no separate "AI data path" that could drift from the real one.
"""
from __future__ import annotations

from typing import Any

from app.ai.tools.base import AgentTool, ToolContext, ToolResult
from app.database.repositories.doctor_repository import DoctorRepository


class SearchDoctorsTool(AgentTool):
    name = "search_doctors"
    description = "Search for doctors by specialty and consultation type."

    async def run(self, *, context: ToolContext, arguments: dict[str, Any]) -> ToolResult:
        repo = DoctorRepository(context.db_session)
        repo.seed_if_empty()  # foundation-stage convenience, see repository docstring
        doctors = repo.search(specialty=arguments.get("specialty"), limit=5)
        return ToolResult(
            success=True,
            data={
                "doctors": [
                    {
                        "id": d.id,
                        "name": d.name,
                        "specialty": d.specialty,
                        "verified": d.verified,
                        "rating": d.rating,
                        "experience_years": d.experience_years,
                        "supports_home_visit": d.supports_home_visit,
                        "supports_video": d.supports_video,
                    }
                    for d in doctors
                ]
            },
        )
