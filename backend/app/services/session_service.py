import json
import logging
from datetime import datetime
from pathlib import Path

from app.db.crud import create_session as db_create_session
from app.db.database import SessionLocal
import uuid


_active_sessions = {}


def create_db_session(user_id: str, mode: str):
    db = SessionLocal()
    try:
        try:
            uid = uuid.UUID(user_id)
        except ValueError:
            uid = uuid.uuid5(uuid.NAMESPACE_DNS, user_id)

        session = db_create_session(db, uid, mode)
        _active_sessions[user_id] = {
            "session_id": session.id,
            "mode": mode,
            "start_time": datetime.utcnow().isoformat(),
            "last_record": None,
        }
        return session.id
    except Exception as e:
        logging.warning(f"Failed to create DB session for {user_id}: {e}")
        return None
    finally:
        db.close()


def get_active_session(user_id: str):
    return _active_sessions.get(user_id)


def stop_session(user_id: str):
    if user_id in _active_sessions:
        del _active_sessions[user_id]
        return True
    return False


def log_session(user_id: str, record: dict) -> None:
    try:
        if user_id in _active_sessions:
            _active_sessions[user_id]["last_record"] = record

        path = Path("sessions")
        path.mkdir(parents=True, exist_ok=True)
        file_path = path / f"{user_id}.json"

        existing = []
        if file_path.exists():
            with file_path.open("r", encoding="utf-8") as f:
                try:
                    existing = json.load(f)
                except Exception:
                    existing = []

        entry = {
            "timestamp": record.get("timestamp") or datetime.utcnow().isoformat(),
            "exercise": record.get("exercise"),
            "selected_exercise": record.get("selected_exercise"),
            "avg_knee_angle": record.get("avg_knee_angle"),
            "min_knee_angle": record.get("min_knee_angle"),
            "max_knee_angle": record.get("max_knee_angle"),
            "hip_angle_avg": record.get("hip_angle_avg"),
            "back_angle": record.get("back_angle"),
            "symmetry_score": record.get("symmetry_score"),
            "speed": record.get("speed"),
            "stability": record.get("stability"),
            "depth": record.get("depth"),
            "coordination_score": record.get("coordination_score"),
            "is_safe": record.get("is_safe"),
            "score": record.get("score"),
            "injury": record.get("injury"),
            "stage": record.get("stage"),
            "status": record.get("status"),
            "form_status": record.get("form_status"),
            "error_categories": record.get("error_categories"),
            "model_agreement": record.get("model_agreement"),
            "risk_flags": record.get("risk_flags"),
            "warnings": record.get("warnings"),
            "feedback": record.get("feedback"),
            "allowed_exercises": record.get("allowed_exercises"),
            "model": record.get("model"),
            "features": record.get("features"),
            "user_id": user_id,
        }
        existing.append(entry)

        with file_path.open("w", encoding="utf-8") as f:
            json.dump(existing, f, indent=2)
    except Exception as e:
        logging.warning(f"Failed to log session for {user_id}: {e}")
