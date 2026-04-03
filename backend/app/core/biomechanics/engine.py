import numpy as np


def calculate_angle(a: list, b: list, c: list) -> float:
    va = np.array([a[0] - b[0], a[1] - b[1]], dtype=np.float32)
    vc = np.array([c[0] - b[0], c[1] - b[1]], dtype=np.float32)
    dot = np.dot(va, vc)
    norma = np.linalg.norm(va)
    normc = np.linalg.norm(vc)
    if norma < 1e-6 or normc < 1e-6:
        return 0.0
    cosang = float(np.clip(dot / (norma * normc), -1.0, 1.0))
    return float(np.degrees(np.arccos(cosang)))


def _joint_pos(landmarks: list, idx: int) -> list[float]:
    return [landmarks[idx]["x"], landmarks[idx]["y"]]


def _shoulder_midpoint(landmarks: list) -> np.ndarray:
    left_shoulder = np.array(_joint_pos(landmarks, 5), dtype=np.float32)
    right_shoulder = np.array(_joint_pos(landmarks, 6), dtype=np.float32)
    return (left_shoulder + right_shoulder) / 2.0


def _frame_knee_proxy(landmarks: list) -> tuple[float, float, float]:
    left_hip = _joint_pos(landmarks, 11)
    right_hip = _joint_pos(landmarks, 12)
    left_knee = _joint_pos(landmarks, 13)
    right_knee = _joint_pos(landmarks, 14)
    left_ankle = _joint_pos(landmarks, 15)
    right_ankle = _joint_pos(landmarks, 16)
    left_angle = calculate_angle(left_hip, left_knee, left_ankle)
    right_angle = calculate_angle(right_hip, right_knee, right_ankle)
    return left_angle, right_angle, (left_angle + right_angle) / 2.0


def _frame_hip_proxy(landmarks: list) -> float:
    left_shoulder = _joint_pos(landmarks, 5)
    right_shoulder = _joint_pos(landmarks, 6)
    left_hip = _joint_pos(landmarks, 11)
    right_hip = _joint_pos(landmarks, 12)
    left_knee = _joint_pos(landmarks, 13)
    right_knee = _joint_pos(landmarks, 14)
    left_angle = calculate_angle(left_shoulder, left_hip, left_knee)
    right_angle = calculate_angle(right_shoulder, right_hip, right_knee)
    return (left_angle + right_angle) / 2.0


def _frame_shoulder_angle(landmarks: list) -> float:
    left_shoulder = _joint_pos(landmarks, 5)
    left_elbow = _joint_pos(landmarks, 7)
    left_wrist = _joint_pos(landmarks, 9)
    right_shoulder = _joint_pos(landmarks, 6)
    right_elbow = _joint_pos(landmarks, 8)
    right_wrist = _joint_pos(landmarks, 10)
    left_angle = calculate_angle(left_elbow, left_shoulder, left_wrist)
    right_angle = calculate_angle(right_elbow, right_shoulder, right_wrist)
    return (left_angle + right_angle) / 2.0


def _frame_back_angle(landmarks: list) -> float:
    root = np.array(_joint_pos(landmarks, 0), dtype=np.float32)
    shoulder_mid = _shoulder_midpoint(landmarks)
    vertical_reference = [float(root[0]), float(root[1] + 1.0)]
    return calculate_angle(shoulder_mid.tolist(), root.tolist(), vertical_reference)


def compute_features(landmarks: list, exercise: str, buffer_frames: list | None = None) -> dict:
    history = buffer_frames or ([] if landmarks is None else [landmarks])
    if not history:
        return {
            "avg_knee_angle": 0.0,
            "min_knee_angle": 0.0,
            "max_knee_angle": 0.0,
            "hip_angle_avg": 0.0,
            "back_angle": 0.0,
            "symmetry_score": 1.0,
            "speed": 0.0,
            "stability": 1.0,
            "depth": 0.0,
            "coordination_score": 1.0,
            "shoulder_angle": 0.0,
        }

    knee_angles = []
    hip_angles = []
    back_angles = []
    sym_scores = []
    shoulder_angles = []

    for frame in history:
        try:
            _, _, knee_mean = _frame_knee_proxy(frame)
            knee_angles.append(knee_mean)
            hip_angles.append(_frame_hip_proxy(frame))
            back_angles.append(_frame_back_angle(frame))
            shoulder_angles.append(_frame_shoulder_angle(frame))

            left_shoulder = np.array(_joint_pos(frame, 5), dtype=np.float32)
            right_shoulder = np.array(_joint_pos(frame, 6), dtype=np.float32)
            root = np.array(_joint_pos(frame, 0), dtype=np.float32)
            left_wrist = np.array(_joint_pos(frame, 9), dtype=np.float32)
            right_wrist = np.array(_joint_pos(frame, 10), dtype=np.float32)

            left_reach = np.linalg.norm(left_shoulder - left_wrist)
            right_reach = np.linalg.norm(right_shoulder - right_wrist)
            lateral_balance = abs((left_shoulder[0] - root[0]) - (root[0] - right_shoulder[0]))
            if left_reach + right_reach > 1e-6:
                parity = 1.0 - abs(left_reach - right_reach) / (left_reach + right_reach)
                symmetry = max(0.0, min(1.0, parity * (1.0 / (1.0 + lateral_balance))))
                sym_scores.append(float(symmetry))
            else:
                sym_scores.append(1.0)
        except Exception:
            continue

    coords = np.array(
        [[[point["x"], point["y"]] for point in frame] for frame in history],
        dtype=np.float32,
    )
    if len(coords) > 1:
        speed = float(np.mean(np.linalg.norm(np.diff(coords, axis=0), axis=2)))
    else:
        speed = 0.0

    allpos = coords.reshape(-1, 2)
    var = float(np.var(allpos)) if allpos.size else 0.0
    stability = float(1.0 / (1.0 + var))

    avg_knee = float(np.mean(knee_angles)) if knee_angles else 0.0
    min_knee = float(np.min(knee_angles)) if knee_angles else 0.0
    max_knee = float(np.max(knee_angles)) if knee_angles else 0.0
    hip_angle_avg = float(np.mean(hip_angles)) if hip_angles else 0.0
    back_angle = float(np.mean(back_angles)) if back_angles else 0.0
    symmetry_score = float(np.mean(sym_scores)) if sym_scores else 1.0
    shoulder_angle = float(np.mean(shoulder_angles)) if shoulder_angles else 0.0
    depth = float(max(0.0, min(1.0, 1.0 - avg_knee / 180.0)))

    jerk = 0.0
    if len(coords) > 3:
        velocity = np.diff(coords, axis=0)
        acceleration = np.diff(velocity, axis=0)
        if len(acceleration) > 1:
            jerk = float(np.mean(np.linalg.norm(np.diff(acceleration, axis=0), axis=2)))
    coordination_score = float(max(0.0, min(1.0, 1.0 - jerk)))

    return {
        "avg_knee_angle": avg_knee,
        "min_knee_angle": min_knee,
        "max_knee_angle": max_knee,
        "hip_angle_avg": hip_angle_avg,
        "back_angle": back_angle,
        "symmetry_score": symmetry_score,
        "speed": speed,
        "stability": stability,
        "depth": depth,
        "coordination_score": coordination_score,
        "shoulder_angle": shoulder_angle,
    }


def motion_summary(history: list) -> dict:
    if not history or len(history) < 2:
        return {
            "motion_score": 0.0,
            "knee_rom": 0.0,
            "hip_rom": 0.0,
            "shoulder_rom": 0.0,
            "has_meaningful_motion": False,
        }

    coords = np.array(
        [[[point["x"], point["y"]] for point in frame] for frame in history],
        dtype=np.float32,
    )
    frame_motion = np.linalg.norm(np.diff(coords, axis=0), axis=2)
    motion_score = float(np.mean(frame_motion)) if frame_motion.size else 0.0

    knee_angles = []
    hip_angles = []
    shoulder_angles = []
    for frame in history:
        try:
            _, _, knee_mean = _frame_knee_proxy(frame)
            knee_angles.append(knee_mean)
            hip_angles.append(_frame_hip_proxy(frame))
            shoulder_angles.append(_frame_shoulder_angle(frame))
        except Exception:
            continue

    knee_rom = float(np.max(knee_angles) - np.min(knee_angles)) if len(knee_angles) > 1 else 0.0
    hip_rom = float(np.max(hip_angles) - np.min(hip_angles)) if len(hip_angles) > 1 else 0.0
    shoulder_rom = float(np.max(shoulder_angles) - np.min(shoulder_angles)) if len(shoulder_angles) > 1 else 0.0

    has_meaningful_motion = (
        motion_score > 0.012
        or knee_rom > 20.0
        or hip_rom > 18.0
        or shoulder_rom > 28.0
    )

    return {
        "motion_score": motion_score,
        "knee_rom": knee_rom,
        "hip_rom": hip_rom,
        "shoulder_rom": shoulder_rom,
        "has_meaningful_motion": has_meaningful_motion,
    }


def risk_flags(features: dict, exercise: str) -> list[str]:
    flags = []
    avg_knee = features.get("avg_knee_angle", 0.0)
    min_knee = features.get("min_knee_angle", 0.0)
    back = features.get("back_angle", 0.0)
    sym = features.get("symmetry_score", 1.0)
    stability = features.get("stability", 1.0)
    depth = features.get("depth", 0.0)
    coord = features.get("coordination_score", 1.0)

    skip_knee = exercise in ["WallPushups", "PushUps", "HandstandPushups"]
    skip_depth = exercise in ["BenchPress", "PullUps"]
    knee_intensive = exercise in ["BodyWeightSquats", "Lunges", "CleanAndJerk", "JumpingJack"]

    if not skip_knee and knee_intensive and (avg_knee > 90 or min_knee < 20):
        flags.append("knee_overload")
    if back > 45:
        flags.append("back_strain")
    if sym < 0.7:
        flags.append("imbalance")
    if stability < 0.5:
        flags.append("instability")
    if not skip_depth and depth < 0.3 and exercise in ["BodyWeightSquats", "Lunges", "CleanAndJerk"]:
        flags.append("poor_depth")
    if coord < 0.5:
        flags.append("coordination_issue")

    return flags
