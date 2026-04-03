from app.core.pipeline.orchestrator import run_pipeline
from app.core.decision.fitness import fitness_decision
from app.services.session_service import log_session
from datetime import datetime


def analysis_service(frame_bgr, buffer, user_id: str, selected_exercise: str | None = None) -> dict:
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

    return decision
