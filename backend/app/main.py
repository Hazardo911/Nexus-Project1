import logging
import os
from datetime import datetime
from contextlib import asynccontextmanager
import json
from pathlib import Path

from fastapi import FastAPI
from fastapi import Query

from app.core.ai.inference import get_model
from app.core.ai.model import CLASS_NAMES
from app.api.routes import analyze, demo, latest, rehab, summary, stream
from app.services.session_service import get_active_session, stop_session


@asynccontextmanager
async def lifespan(app: FastAPI):
    if os.getenv("CI") == "true":
        logging.info("CI mode: skipping model load")
    else:
        get_model()
        logging.info("Nexus model ready.")
    yield

app = FastAPI(title="Nexus AI Backend", version="2.0.0", lifespan=lifespan)

app.include_router(analyze.router, prefix="/analyze")
app.include_router(rehab.router, prefix="/rehab")
app.include_router(summary.router, prefix="/summary")
app.include_router(latest.router, prefix="/latest-result")
app.include_router(stream.router)
app.include_router(demo.router)


@app.get("/health")
def health():
    return {"status": "running", "model": "nexus_stgcn_v2", "classes": list(CLASS_NAMES.values())}


@app.get("/status")
def get_status(user_id: str = Query("anonymous")):
    active = get_active_session(user_id)
    return {
        "running": active is not None,
        "elapsed_seconds": 0 if not active else (datetime.utcnow() - datetime.fromisoformat(active["start_time"])).total_seconds(),
    }


@app.get("/session")
def get_session(user_id: str = Query("anonymous")):
    active = get_active_session(user_id)
    if not active:
        return {"status": "error", "message": "No active session"}

    last_record = active.get("last_record", {})
    return {
        "exercise": last_record.get("exercise"),
        "reps": 0,
        "goal": 10,
        "feedback": last_record.get("feedback", []),
        "done": False,
    }


@app.post("/stop")
def stop_user_session(user_id: str = Query("anonymous")):
    success = stop_session(user_id)
    return {"status": "success" if success else "not_found"}


@app.post("/start")
def start_session(user_id: str = Query("anonymous"), mode: str = Query("training")):
    from app.services.session_service import create_db_session

    session_id = create_db_session(user_id, mode)
    return {"status": "success", "session_id": session_id}


@app.get("/sessions")
def get_sessions(user_id: str = Query("anonymous"), limit: int = Query(20, ge=1, le=100)):
    file_path = Path("sessions") / f"{user_id}.json"
    if not file_path.exists():
        return {"user_id": user_id, "sessions": [], "total": 0}

    try:
        with file_path.open("r", encoding="utf-8") as f:
            records = json.load(f)
    except Exception:
        records = []

    if not isinstance(records, list):
        records = []

    trimmed = list(reversed(records))[:limit]
    return {
        "user_id": user_id,
        "sessions": trimmed,
        "total": len(records),
    }
