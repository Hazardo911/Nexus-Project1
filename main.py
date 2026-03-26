import subprocess
import sys
import time
import json
import os
import tempfile

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="AI Fitness Coach API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://127.0.0.1:3000"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# ----------------------------------------------------------------
# STATE FILE
# realtime.py writes its state to this JSON file every frame.
# main.py reads it on every /session request.
# This replaces the broken multiprocessing.Manager approach where
# realtime.py (a subprocess) had no reference to shared_state at all.
# ----------------------------------------------------------------
STATE_FILE = os.path.join(tempfile.gettempdir(), "nexus_session_state.json")

_DEFAULT_STATE = {
    "exercise":    None,
    "reps":        0,
    "goal":        None,
    "stage":       None,
    "feedback":    [],
    "accuracy":    0.0,
    "angles":      {},
    "done":        False,
    "started_at":  None,
}

_process: subprocess.Popen | None = None
_started_at: float | None = None


def _read_state() -> dict:
    """Read latest state written by realtime.py. Returns default if file missing."""
    try:
        with open(STATE_FILE, "r") as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return dict(_DEFAULT_STATE)


def _clear_state():
    """Write a clean default state to the file."""
    state = dict(_DEFAULT_STATE)
    state["started_at"] = time.time()
    try:
        with open(STATE_FILE, "w") as f:
            json.dump(state, f)
    except OSError:
        pass


# ================================================================
# ROUTES
# ================================================================

@app.get("/")
def home():
    return {
        "message": "AI Fitness Coach API is running",
        "endpoints": [
            "GET  /exercises       — list supported exercises",
            "POST /start           — launch realtime.py",
            "POST /stop            — stop realtime.py",
            "GET  /status          — is session running?",
            "GET  /session         — live session snapshot",
            "GET  /summary         — final session summary",
            "POST /session/reset   — reset counters without stopping camera",
        ]
    }


@app.get("/exercises")
def list_exercises():
    """Return all supported exercise names (matches engine.py exercise_map)."""
    return {
        "exercises": [
            "squat",
            "pushup",
            "lunges",
            "jumpingjack",
            "pullup",
            "wallpushup",
            "benchpress",
        ]
    }


@app.post("/start")
def start_session():
    """
    Launch realtime.py as a subprocess.
    Returns 409 if a session is already running.
    """
    global _process, _started_at

    if _process is not None and _process.poll() is None:
        raise HTTPException(status_code=409, detail="Session already running")

    _clear_state()
    _started_at = time.time()

    # FIX: Pass STATE_FILE path as an argument so realtime.py knows where to write.
    # Also use stdout=None so subprocess output goes to terminal — avoids pipe buffer blocking.
    _process = subprocess.Popen(
        [sys.executable, "realtime.py", "--state-file", STATE_FILE],
        stdout=None,
        stderr=None,
    )
    return {"status": "started", "pid": _process.pid}


@app.post("/stop")
def stop_session():
    """Gracefully terminate the realtime process."""
    global _process

    if _process is None or _process.poll() is not None:
        raise HTTPException(status_code=404, detail="No session is running")

    _process.terminate()
    try:
        _process.wait(timeout=5)
    except subprocess.TimeoutExpired:
        _process.kill()

    _process = None
    return {"status": "stopped"}


@app.get("/status")
def get_status():
    """Is a session running? If so, for how long?"""
    running = _process is not None and _process.poll() is None
    elapsed = None
    if running and _started_at:
        elapsed = round(time.time() - _started_at, 1)
    return {
        "running":          running,
        "elapsed_seconds":  elapsed,
        "pid":              _process.pid if running else None,
    }


@app.get("/session")
def get_session():
    """
    Latest snapshot of the live session.
    Poll this from a frontend at ~500ms intervals.
    Returns 404 if no session has been started yet.
    """
    state = _read_state()
    if state.get("exercise") is None:
        raise HTTPException(
            status_code=404,
            detail="No session data yet — call POST /start first"
        )
    return state


@app.get("/summary")
def get_summary():
    """
    Final session summary — available once 'done' is True.
    Returns 404 if session hasn't completed yet.
    """
    state = _read_state()
    if not state.get("done"):
        raise HTTPException(
            status_code=404,
            detail="Session not complete yet — keep going!"
        )
    return {
        "exercise":   state.get("exercise"),
        "total_reps": state.get("reps", 0),
        "goal":       state.get("goal"),
        "accuracy":   state.get("accuracy", 0.0),
        "done":       True,
    }


@app.post("/session/reset")
def reset_session():
    """
    Reset rep counters and state without stopping the realtime process.
    Useful for multi-set workouts where the camera stays open.
    """
    _clear_state()
    return {"status": "reset"}