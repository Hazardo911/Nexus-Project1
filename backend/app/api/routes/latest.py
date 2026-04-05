from fastapi import APIRouter

from app.services.latest_result_service import latest_result_service

router = APIRouter()


@router.get("/")
def latest_result(user_id: str):
    return latest_result_service(user_id)
