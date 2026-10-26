"""
Repository layer (Day 3.2 §5): the only module allowed to write SQLAlchemy
queries against `Doctor`. Services and tools call this, never the ORM
directly — and the AI agent NEVER touches this or the database at all
(Day 3.2 §30) except through the SearchDoctorsTool -> this repository.
"""
from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.database.models import Doctor


class DoctorRepository:
    def __init__(self, db: Session):
        self._db = db

    def search(
        self,
        *,
        specialty: str | None = None,
        home_visit: bool | None = None,
        video: bool | None = None,
        limit: int = 5,
    ) -> list[Doctor]:
        stmt = select(Doctor)
        if specialty:
            stmt = stmt.where(Doctor.specialty.ilike(f"%{specialty}%"))
        if home_visit is not None:
            stmt = stmt.where(Doctor.supports_home_visit == home_visit)
        if video is not None:
            stmt = stmt.where(Doctor.supports_video == video)
        stmt = stmt.order_by(Doctor.rating.desc()).limit(limit)
        return list(self._db.execute(stmt).scalars().all())

    def get(self, doctor_id: str) -> Doctor | None:
        return self._db.get(Doctor, doctor_id)

    def seed_if_empty(self) -> None:
        """Foundation-stage convenience so the one working flow has
        something to search against without a real onboarding pipeline —
        NOT how doctor data will be populated in production (that's the
        doctor-app registration/verification flow from Architecture v1).
        """
        existing = self._db.execute(select(Doctor).limit(1)).first()
        if existing:
            return
        seed = [
            Doctor(name="Dr. Ananya Sharma", specialty="General Physician", verified=True,
                   rating=4.8, experience_years=9, supports_home_visit=True, supports_video=True),
            Doctor(name="Dr. Ravi Iyer", specialty="General Physician", verified=True,
                   rating=4.6, experience_years=6, supports_home_visit=True, supports_video=True),
            Doctor(name="Dr. Fatima Sheikh", specialty="Pediatrics", verified=True,
                   rating=4.9, experience_years=12, supports_home_visit=True, supports_video=False),
        ]
        self._db.add_all(seed)
        self._db.commit()
