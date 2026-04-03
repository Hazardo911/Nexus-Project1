from fastapi import APIRouter
from app.schemas.summary import SummaryResponse
from app.services.summary_service import summary_service

router = APIRouter()

@router.get("/", response_model=SummaryResponse)
def summary(user_id: str):
    return SummaryResponse.model_validate(summary_service(user_id))
