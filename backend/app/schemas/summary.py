from pydantic import BaseModel


class PeriodSummary(BaseModel):
    total_sessions: int
    avg_knee_angle: float | None = None
    avg_stability: float | None = None
    avg_symmetry: float | None = None
    safe_session_rate: float | None = None
    rom_improvement: float | None = None
    message: str


class SummaryResponse(BaseModel):
    user_id: str
    total_sessions: int
    avg_knee_angle: float | None = None
    best_knee_angle: float | None = None
    rom_improvement: float | None = None
    symmetry_trend: float | None = None
    stability_trend: float | None = None
    speed_trend: float | None = None
    coordination_trend: float | None = None
    safe_session_rate: float | None = None
    weekly_summary: PeriodSummary | None = None
    monthly_summary: PeriodSummary | None = None
    message: str
