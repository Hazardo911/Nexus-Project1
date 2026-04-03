import numpy as np


def joint0_centre_normalise(landmarks: list) -> list:
    if not landmarks or len(landmarks) < 1:
        raise ValueError("landmarks must contain at least one point")

    hip = landmarks[0]
    hx, hy = hip["x"], hip["y"]
    points = np.array([[p["x"], p["y"]] for p in landmarks], dtype=np.float32)
    points = points - np.array([hx, hy], dtype=np.float32)
    scale = np.max(np.abs(points)) + 1e-6
    points = points / scale

    normalized = []
    for i, p in enumerate(points):
        normalized.append({
            "x": float(p[0]),
            "y": float(p[1]),
            "z": float(landmarks[i].get("z", 0.0)),
            "visibility": float(landmarks[i].get("visibility", 1.0))
        })
    return normalized
