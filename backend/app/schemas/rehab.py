from pydantic import BaseModel, Field


class RehabRequest(BaseModel):
    user_id: str
    selected_exercise: str
    injury: str
    stage: str = "early"
    frame_jpeg: bytes
    fps: int = Field(default=30, gt=0)
    window_seconds: float = Field(default=3.33, gt=0.0)
    session_id: str | None = None


class RehabResponse(BaseModel):
    status: str
    score: int | float | None = None
    is_safe: bool | None = None
    warnings: list[str] = Field(default_factory=list)
    feedback: str | None = None
    allowed_exercises: list[str] = Field(default_factory=list)
    model: dict | None = None
    features: dict = Field(default_factory=dict)
    message: str | None = None
    frames: int | None = None
    needed: int | None = None
    selected_exercise: str | None = None
    form_status: str | None = None
    error_categories: list[str] = Field(default_factory=list)
    model_agreement: str | None = None
    stage_focus: str | None = None
