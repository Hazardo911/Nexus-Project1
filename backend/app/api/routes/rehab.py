import base64
import cv2
import numpy as np
from fastapi import APIRouter, HTTPException
from app.schemas.rehab import RehabRequest, RehabResponse
from app.services.rehab_service import rehab_service
from app.utils.temporal_buffer import TemporalBuffer

router = APIRouter()

def _decode_frame(frame_jpeg):
    if isinstance(frame_jpeg, str):
        try:
            frame_bytes = base64.b64decode(frame_jpeg)
        except Exception:
            raise HTTPException(status_code=400, detail="frame_jpeg must be base64-encoded bytes")
    elif isinstance(frame_jpeg, (bytes, bytearray)):
        frame_bytes = bytes(frame_jpeg)
    else:
        raise HTTPException(status_code=400, detail="frame_jpeg must be a base64 string or bytes")

    arr = np.frombuffer(frame_bytes, np.uint8)
    frame = cv2.imdecode(arr, cv2.IMREAD_COLOR)
    if frame is None:
        raise HTTPException(status_code=400, detail="Unable to decode frame_jpeg into image")
    return frame

@router.post("/", response_model=RehabResponse)
def rehab(request: RehabRequest):
    buffer = TemporalBuffer(fps=request.fps, window_seconds=request.window_seconds)
    frame = _decode_frame(request.frame_jpeg)
    return RehabResponse.model_validate(
        rehab_service(frame, buffer, request.user_id, request.injury, request.stage, request.selected_exercise, session_id=request.session_id)
    )
