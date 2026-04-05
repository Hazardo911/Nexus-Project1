import json
from pathlib import Path


def latest_result_service(user_id: str) -> dict:
    file_path = Path("sessions") / f"{user_id}.json"
    if not file_path.exists():
        return {"user_id": user_id, "message": "No analysis recorded yet."}

    try:
        with file_path.open("r", encoding="utf-8") as f:
            records = json.load(f)
    except Exception:
        records = []

    if not records:
        return {"user_id": user_id, "message": "No analysis recorded yet."}

    latest = records[-1]
    latest["user_id"] = latest.get("user_id") or user_id
    return latest
