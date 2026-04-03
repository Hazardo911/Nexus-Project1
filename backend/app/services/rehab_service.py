from app.core.pipeline.orchestrator import run_pipeline
from app.core.decision.rehab import rehab_decision
from app.services.session_service import log_session
from datetime import datetime
from app.db.database import SessionLocal
from app.db.crud import insert_rehab_session, insert_movement_metric


def rehab_service(frame_bgr, buffer, user_id: str, injury: str, stage: str, selected_exercise: str | None = None, session_id: str | None = None) -> dict:
    result = run_pipeline(frame_bgr, buffer, selected_exercise=selected_exercise)
    if result.get("status") != "ok" and result.get("status") != "success":
        return result

    decision = rehab_decision(
        result["features"], result["risks"], result["model"], injury, stage, result.get("validation")
    )
    decision["landmarks"] = result.get("landmarks")
    decision["connections"] = result.get("connections", [])

    log_session(user_id, {
        "timestamp": datetime.utcnow().isoformat(),
        **result["features"],
        **decision,
        "exercise": selected_exercise or result["model"]["exercise"],
        "injury": injury,
        "stage": stage
    })

    if session_id:
        db = SessionLocal()
        try:
            # safety is double precision in schema, let's use 1.0 for safe, 0.0 for caution/warning
            safety_val = 1.0 if decision.get("status") == "safe" else 0.0
            insert_rehab_session(
                db,
                session_id,
                injury_type=injury,
                stage=stage,
                score=float(decision.get("score", 0)),
                safety=safety_val,
                rom=float(result["features"].get("knee_angle", 0)),
                stability=float(decision.get("stability", 0)),
                decision=str(decision.get("feedback", ["No feedback"])[0]),
                feedback=", ".join(decision.get("feedback", []))
            )
            # Optional: insert knee metric
            insert_movement_metric(
                db,
                session_id,
                joint_name="knee",
                angle=float(result["features"].get("knee_angle", 0)),
                velocity=0.0,
                acceleration=0.0
            )
        except Exception as e:
            import logging
            logging.warning(f"Failed to insert rehab data for session {session_id}: {e}")
        finally:
            db.close()

    return decision
