import json
from datetime import datetime, timedelta
from pathlib import Path


def summary_service(user_id: str) -> dict:
    file_path = Path("sessions") / f"{user_id}.json"
    if not file_path.exists():
        return {"user_id": user_id, "message": "No sessions recorded yet.", "total_sessions": 0}

    with file_path.open("r", encoding="utf-8") as f:
        records = json.load(f)

    total_sessions = len(records)
    if total_sessions == 0:
        return {"user_id": user_id, "message": "No sessions recorded yet.", "total_sessions": 0}

    def _parse_timestamp(record: dict) -> datetime | None:
        value = record.get("timestamp")
        if not value:
            return None
        try:
            return datetime.fromisoformat(str(value).replace("Z", "+00:00"))
        except Exception:
            return None

    def _numeric_values(key: str) -> list[float]:
        return [float(r[key]) for r in records if isinstance(r.get(key), (int, float))]

    def _mean(key):
        vals = _numeric_values(key)
        return sum(vals) / len(vals) if vals else None

    avg_knee = _mean("avg_knee_angle")
    best_knee = min(_numeric_values("avg_knee_angle"), default=None)

    first = records[0]
    last = records[-1]
    rom_improvement = None
    if first.get("avg_knee_angle") is not None and last.get("avg_knee_angle") is not None:
        rom_improvement = last.get("avg_knee_angle") - first.get("avg_knee_angle")

    def _trend(key):
        values = _numeric_values(key)
        if not values:
            return None
        window = min(3, len(values))
        first_mean = sum(values[:window]) / window
        last_mean = sum(values[-window:]) / window
        return last_mean - first_mean

    safe_rate = None
    safe_count = len([r for r in records if r.get("is_safe") is True])
    if total_sessions > 0:
        safe_rate = (safe_count / total_sessions) * 100.0

    symmetry_trend = _trend("symmetry_score")
    stability_trend = _trend("stability")
    speed_trend = _trend("speed")
    coordination_trend = _trend("coordination_score")

    if rom_improvement is not None:
        message = f"ROM improved {rom_improvement:.2f} degrees over {total_sessions} sessions."
        if stability_trend is not None:
            message += f" Stability trend {stability_trend * 100:.1f}%."
    else:
        message = "No ROM improvement data available."

    def _period_summary(days: int) -> dict:
        cutoff = datetime.utcnow() - timedelta(days=days)
        period_records = []
        for record in records:
            timestamp = _parse_timestamp(record)
            if timestamp is not None and timestamp.replace(tzinfo=None) >= cutoff:
                period_records.append(record)

        rehab_records = [record for record in period_records if record.get("injury") not in (None, "None")]
        active_records = rehab_records or period_records
        if not active_records:
            return {
                "total_sessions": 0,
                "avg_knee_angle": None,
                "avg_stability": None,
                "avg_symmetry": None,
                "safe_session_rate": None,
                "rom_improvement": None,
                "message": f"No rehab sessions recorded in the last {days} days.",
            }

        def _period_mean(key: str) -> float | None:
            values = [float(r[key]) for r in active_records if isinstance(r.get(key), (int, float))]
            return sum(values) / len(values) if values else None

        first_angle = next((r.get("avg_knee_angle") for r in active_records if isinstance(r.get("avg_knee_angle"), (int, float))), None)
        last_angle = next((r.get("avg_knee_angle") for r in reversed(active_records) if isinstance(r.get("avg_knee_angle"), (int, float))), None)
        rom_delta = (last_angle - first_angle) if first_angle is not None and last_angle is not None else None
        safe_count = len([r for r in active_records if r.get("is_safe") is True])
        safe_rate = (safe_count / len(active_records)) * 100.0 if active_records else None
        label = "Weekly" if days == 7 else "Monthly"
        if rom_delta is not None:
            period_message = f"{label} recovery summary: ROM change {rom_delta:.2f} degrees."
        else:
            period_message = f"{label} recovery summary available."

        return {
            "total_sessions": len(active_records),
            "avg_knee_angle": _period_mean("avg_knee_angle"),
            "avg_stability": _period_mean("stability"),
            "avg_symmetry": _period_mean("symmetry_score"),
            "safe_session_rate": safe_rate,
            "rom_improvement": rom_delta,
            "message": period_message,
        }

    return {
        "user_id": user_id,
        "total_sessions": total_sessions,
        "avg_knee_angle": avg_knee,
        "best_knee_angle": best_knee,
        "rom_improvement": rom_improvement,
        "symmetry_trend": symmetry_trend,
        "stability_trend": stability_trend,
        "speed_trend": speed_trend,
        "coordination_trend": coordination_trend,
        "safe_session_rate": safe_rate,
        "weekly_summary": _period_summary(7),
        "monthly_summary": _period_summary(30),
        "message": message
    }
