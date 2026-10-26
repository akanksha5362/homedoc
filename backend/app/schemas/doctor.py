from __future__ import annotations

from pydantic import BaseModel


class DoctorOut(BaseModel):
    id: str
    name: str
    specialty: str
    verified: bool
    rating: float
    experience_years: int
    supports_home_visit: bool
    supports_video: bool

    model_config = {"from_attributes": True}
