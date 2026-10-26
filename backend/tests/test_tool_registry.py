from __future__ import annotations

import pytest

from app.ai.tools.base import ToolContext
from app.ai.tools.registry import ToolRegistry
from app.core.errors import ToolPermissionError
from app.core.security import UserRole


@pytest.mark.asyncio
async def test_search_doctors_succeeds_for_patient(db_session):
    registry = ToolRegistry()
    context = ToolContext(user_id="u1", role=UserRole.patient, db_session=db_session)

    result = await registry.execute(tool_name="search_doctors", context=context, arguments={})

    assert result.success is True
    assert "doctors" in result.data


@pytest.mark.asyncio
async def test_unknown_tool_raises_permission_error(db_session):
    registry = ToolRegistry()
    context = ToolContext(user_id="u1", role=UserRole.patient, db_session=db_session)

    with pytest.raises(ToolPermissionError):
        await registry.execute(tool_name="delete_everything", context=context, arguments={})


@pytest.mark.asyncio
async def test_role_not_permitted_raises_permission_error(db_session):
    """get_patient_profile is patient-only — a doctor calling it must be
    denied by the registry itself, before the tool body ever runs.
    """
    registry = ToolRegistry()
    context = ToolContext(user_id="doc1", role=UserRole.doctor, db_session=db_session)

    with pytest.raises(ToolPermissionError):
        await registry.execute(tool_name="get_patient_profile", context=context, arguments={})


@pytest.mark.asyncio
async def test_stub_tool_returns_honest_not_implemented(db_session):
    registry = ToolRegistry()
    context = ToolContext(user_id="p1", role=UserRole.patient, db_session=db_session)

    result = await registry.execute(tool_name="get_patient_profile", context=context, arguments={})

    assert result.success is False
    assert result.error == "not_implemented"
