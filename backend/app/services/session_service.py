import json
import logging
from datetime import datetime
from pathlib import Path


def log_session(user_id: str, record: dict) -> None:
    try:
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
            "stage": record.get("stage")
        }
        existing.append(entry)

        with file_path.open("w", encoding="utf-8") as f:
            json.dump(existing, f, indent=2)
    except Exception as e:
        logging.warning(f"Failed to log session for {user_id}: {e}")
