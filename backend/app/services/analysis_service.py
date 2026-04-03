import logging

from datetime import datetime

from app.core.pipeline.orchestrator import run_pipeline
from app.core.decision.fitness import fitness_decision
from app.db.crud import insert_movement_metric, insert_training_session
from app.db.database import SessionLocal
from app.services.session_service import log_session


def analysis_service(frame_bgr, buffer, user_id: str, selected_exercise: str | None = None, session_id: str | None = None) -> dict:
    result = run_pipeline(frame_bgr, buffer, selected_exercise=selected_exercise)
    if result.get("status") != "ok":
        return result

    decision = fitness_decision(
        result["features"], result["risks"], result["model"], result.get("validation")
    )
    decision["landmarks"] = result.get("landmarks")
    decision["connections"] = result.get("connections", [])

    log_session(user_id, {
        "timestamp": datetime.utcnow().isoformat(),
        **result["features"],
        **decision,
        "exercise": selected_exercise or result["model"]["exercise"],
        "injury": "None",
        "stage": "None"
    })

    if session_id:
        db = SessionLocal()
        try:
            insert_training_session(
                db,
                session_id,
                score=float(decision.get("score", 0)),
                symmetry=float(decision.get("symmetry_score", 0) or 0),
                stability=float(decision.get("stability", 0) or 0),
                speed=float(decision.get("speed", 0) or 0),
                feedback=", ".join(decision.get("feedback", [])),
            )
            insert_movement_metric(
                db,
                session_id,
                joint_name="knee",
                angle=float(result["features"].get("avg_knee_angle", 0) or 0),
                velocity=0.0,
                acceleration=0.0,
            )
        except Exception as e:
            logging.warning(f"Failed to insert training data for session {session_id}: {e}")
        finally:
            db.close()

    return decision
