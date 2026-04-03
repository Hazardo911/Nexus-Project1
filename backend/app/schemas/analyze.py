from pydantic import BaseModel, Field


class AnalyzeRequest(BaseModel):
    user_id: str
    selected_exercise: str
    frame_jpeg: bytes
    fps: int = Field(default=30, gt=0)
    window_seconds: float = Field(default=3.33, gt=0.0)


class AnalyzeResponse(BaseModel):
    status: str
    score: int | None = None
    feedback: list[str] = Field(default_factory=list)
    model: dict | None = None
    risk_flags: list[str] = Field(default_factory=list)
    message: str | None = None
    frames: int | None = None
    needed: int | None = None
    selected_exercise: str | None = None
    form_status: str | None = None
    error_categories: list[str] = Field(default_factory=list)
    model_agreement: str | None = None
    movement_family: str | None = None
    movement_family_label: str | None = None
    avg_knee_angle: float | None = None
    min_knee_angle: float | None = None
    max_knee_angle: float | None = None
    hip_angle_avg: float | None = None
    back_angle: float | None = None
    symmetry_score: float | None = None
    speed: float | None = None
    stability: float | None = None
    depth: float | None = None
    coordination_score: float | None = None
