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
    include_visuals: bool = Form(False),
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
        analyzed_frames = 0
        successful_windows = 0

        source_fps = int(capture.get(cv2.CAP_PROP_FPS) or 0)
        target_fps = max(1, int(fps))
        frame_stride = max(1, round(source_fps / target_fps)) if source_fps > 0 else 1
        max_analyzed_frames = max(int(target_fps * max(window_seconds, 4.0)), target_fps * 6)

        try:
            while True:
                ok, frame = capture.read()
                if not ok:
                    break
                frame_count += 1
                if frame_count % frame_stride != 0:
                    continue
                analyzed_frames += 1

                result = run_pipeline(frame, buffer, selected_exercise=selected_exercise)
                if result.get("status") != "ok":
                    final_result = result
                    if analyzed_frames >= max_analyzed_frames:
                        break
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

                if include_visuals:
                    decision["landmarks"] = result.get("landmarks")
                    decision["connections"] = result.get("connections", [])
                final_result = decision
                successful_windows += 1
                if successful_windows >= 2 or analyzed_frames >= max_analyzed_frames:
                    break
        finally:
            capture.release()

        final_result["processed_frames"] = frame_count
        final_result["analyzed_frames"] = analyzed_frames
        final_result["mode"] = mode
        final_result["user_id"] = user_id
        return final_result
    finally:
        if tmp_path and os.path.exists(tmp_path):
            try:
                os.remove(tmp_path)
            except OSError:
                pass
