import os
import tempfile
from pathlib import Path

import cv2
from fastapi import APIRouter, File, Form, UploadFile
from fastapi.responses import HTMLResponse
from app.core.decision.fitness import fitness_decision
from app.core.decision.rehab import rehab_decision
from app.core.pipeline.orchestrator import run_pipeline
from app.utils.temporal_buffer import TemporalBuffer


router = APIRouter()


@router.get("/demo/stream", response_class=HTMLResponse)
def stream_demo() -> HTMLResponse:
    html_path = Path(__file__).resolve().parents[2] / "static" / "stream_demo.html"
    return HTMLResponse(html_path.read_text(encoding="utf-8"))


@router.post("/demo/analyze-video")
async def analyze_uploaded_video(
    file: UploadFile = File(...),
    mode: str = Form("fitness"),
    user_id: str = Form("test_user"),
    selected_exercise: str = Form("BodyWeightSquats"),
    injury: str = Form("ACL"),
    stage: str = Form("early"),
    fps: int = Form(30),
    window_seconds: float = Form(3.33),
):
    suffix = Path(file.filename or "upload.mp4").suffix or ".mp4"
    tmp_path = None
    try:
        with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as tmp:
            tmp.write(await file.read())
            tmp_path = tmp.name

        capture = cv2.VideoCapture(tmp_path)
        if not capture.isOpened():
            return {"status": "error", "message": "Unable to open uploaded video."}

        buffer = TemporalBuffer(fps=fps, window_seconds=window_seconds)
        final_result = {"status": "error", "message": "No frames processed."}
        frame_count = 0

        try:
            while True:
                ok, frame = capture.read()
                if not ok:
                    break
                frame_count += 1
                result = run_pipeline(frame, buffer, selected_exercise=selected_exercise)
                if result.get("status") != "ok":
                    final_result = result
                    continue

                if mode == "rehab":
                    decision = rehab_decision(
                        result["features"],
                        result["risks"],
                        result["model"],
                        injury,
                        stage,
                        result.get("validation"),
                    )
                else:
                    decision = fitness_decision(
                        result["features"],
                        result["risks"],
                        result["model"],
                        result.get("validation"),
                    )

                decision["landmarks"] = result.get("landmarks")
                decision["connections"] = result.get("connections", [])
                final_result = decision
        finally:
            capture.release()

        final_result["processed_frames"] = frame_count
        final_result["mode"] = mode
        final_result["user_id"] = user_id
        return final_result
    finally:
        if tmp_path and os.path.exists(tmp_path):
            try:
                os.remove(tmp_path)
            except OSError:
                pass
