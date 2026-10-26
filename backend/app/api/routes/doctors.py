from __future__ import annotations

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api.deps import get_current_user, get_db
from app.core.security import DecodedToken
from app.database.repositories.doctor_repository import DoctorRepository
from app.schemas.doctor import DoctorOut

router = APIRouter(prefix="/doctors", tags=["doctors"])


@router.get("", response_model=list[DoctorOut])
def search_doctors(
    specialty: str | None = None,
    db: Session = Depends(get_db),
    _user: DecodedToken = Depends(get_current_user),
) -> list[DoctorOut]:
    repo = DoctorRepository(db)
    repo.seed_if_empty()
    doctors = repo.search(specialty=specialty)
    return [DoctorOut.model_validate(d) for d in doctors]
