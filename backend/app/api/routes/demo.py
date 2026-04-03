import os
import tempfile
from pathlib import Path

import cv2
from fastapi import APIRouter, File, Form, UploadFile
from fastapi.responses import HTMLResponse
from app.db.crud import insert_movement_metric, insert_rehab_session, insert_training_session
from app.db.database import SessionLocal
from app.core.decision.fitness import fitness_decision
from app.core.decision.rehab import rehab_decision
from app.core.pipeline.orchestrator import run_pipeline
from app.services.session_service import create_db_session, log_session
from app.utils.temporal_buffer import TemporalBuffer


router = APIRouter()


def _persist_upload_result(
    *,
    user_id: str,
    mode: str,
    selected_exercise: str,
    injury: str,
    stage: str,
    result: dict,
    decision: dict,
) -> None:
    log_session(
        user_id,
        {
            "timestamp": None,
            **result.get("features", {}),
            **decision,
            "selected_exercise": selected_exercise,
            "exercise": selected_exercise or decision.get("selected_exercise") or result.get("model", {}).get("exercise"),
            "injury": injury if mode == "rehab" else "None",
            "stage": stage if mode == "rehab" else "None",
            "features": result.get("features"),
        },
    )

    session_mode = "rehab" if mode == "rehab" else "training"
    session_id = create_db_session(user_id, session_mode)
    if not session_id:
        return

    db = SessionLocal()
    try:
        features = result.get("features", {})
        if mode == "rehab":
            safety_val = 1.0 if decision.get("status") == "safe" else 0.0
            insert_rehab_session(
                db,
                session_id,
                injury_type=injury,
                stage=stage,
                score=float(decision.get("score", 0) or 0),
                safety=safety_val,
                rom=float(features.get("avg_knee_angle", 0) or 0),
                stability=float(features.get("stability", 0) or 0),
                decision=str(decision.get("feedback", "No feedback")),
                feedback=str(decision.get("feedback", "")),
            )
        else:
            insert_training_session(
                db,
                session_id,
                score=float(decision.get("score", 0) or 0),
                symmetry=float(decision.get("symmetry_score", 0) or 0),
                stability=float(decision.get("stability", 0) or 0),
                speed=float(decision.get("speed", 0) or 0),
                feedback=", ".join(decision.get("feedback", [])),
            )

        insert_movement_metric(
            db,
            session_id,
            joint_name="knee",
            angle=float(features.get("avg_knee_angle", 0) or 0),
            velocity=0.0,
            acceleration=0.0,
        )
    except Exception:
        pass
    finally:
        db.close()


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
        final_pipeline_result = None
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
                final_pipeline_result = result
                final_result["selected_exercise"] = selected_exercise
                successful_windows += 1
                if successful_windows >= 2 or analyzed_frames >= max_analyzed_frames:
                    break
        finally:
            capture.release()

        if final_result.get("status") not in {"error", "buffering", "waiting_for_movement", "pose_partial", "no_detection"}:
            _persist_upload_result(
                user_id=user_id,
                mode=mode,
                selected_exercise=selected_exercise,
                injury=injury,
                stage=stage,
                result=final_pipeline_result or {},
                decision=final_result,
            )

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
