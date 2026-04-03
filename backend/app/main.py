import logging
import os
from datetime import datetime
from fastapi import FastAPI, Query
from contextlib import asynccontextmanager
from app.core.ai.inference import get_model
from app.core.ai.model import CLASS_NAMES
from app.api.routes import analyze, demo, rehab, summary, stream
from app.services.session_service import get_active_session, stop_session

logging.basicConfig(level=logging.INFO)

@asynccontextmanager
async def lifespan(app: FastAPI):
    if os.getenv("CI") == "true":
        logging.info("⚡ CI mode: skipping model load")
    else:
        get_model()
        logging.info("Nexus model ready.")
    yield


app = FastAPI(title="Nexus AI Backend", version="2.0.0", lifespan=lifespan)

app.include_router(analyze.router, prefix="/analyze")
app.include_router(rehab.router, prefix="/rehab")
app.include_router(summary.router, prefix="/summary")
app.include_router(stream.router)
app.include_router(demo.router)


@app.get("/health")
def health():
    return {
        "status": "running",
        "model": "nexus_stgcn_v2",
        "classes": list(CLASS_NAMES.values()),
    }

@app.get("/status")
def get_status(user_id: str = Query("anonymous")):
    active = get_active_session(user_id)
    return {
        "running": active is not None,
        "elapsed_seconds": 0 if not active else (datetime.utcnow() - datetime.fromisoformat(active["start_time"])).total_seconds()
    }

@app.get("/session")
def get_session(user_id: str = Query("anonymous")):
    active = get_active_session(user_id)
    if not active:
        return {"status": "error", "message": "No active session"}
    
    last_record = active.get("last_record", {})
    return {
        "exercise": last_record.get("exercise"),
        "reps": 0, # Not explicitly tracked in log_session but could be derived
        "goal": 10, # Mock goal
        "feedback": last_record.get("feedback", []),
        "done": False
    }

@app.post("/stop")
def stop_user_session(user_id: str = Query("anonymous")):
    success = stop_session(user_id)
    return {"status": "success" if success else "not_found"}

@app.post("/start")
def start_session(user_id: str = Query("anonymous"), mode: str = Query("training")):
    # This might be redundant if /stream creates it, but good for REST flow
    from app.services.session_service import create_db_session
    session_id = create_db_session(user_id, mode)
    return {"status": "success", "session_id": session_id}
