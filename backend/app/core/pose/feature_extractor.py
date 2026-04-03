import logging

import numpy as np

try:
    import mediapipe as mp
    mp_pose = mp.solutions.pose

    def _create_pose():
        return mp_pose.Pose(
            # Recreate a fresh detector for each frame to avoid stale ghost tracking
            # in cramped webcam demos and side-angle exercises.
            static_image_mode=True,
            model_complexity=0,
            min_detection_confidence=0.35,
            min_tracking_confidence=0.35,
        )

    MEDIAPIPE_AVAILABLE = True
except Exception as e:
    MEDIAPIPE_AVAILABLE = False
    logging.warning(f"MediaPipe unavailable: {e}. Using mock fallback.")


MEDIAPIPE_CONNECTIONS = [
    (0, 1), (0, 2), (1, 3), (2, 4),
    (5, 6), (5, 7), (7, 9),
    (6, 8), (8, 10),
    (5, 11), (6, 12),
    (11, 12), (11, 13), (13, 15),
    (12, 14), (14, 16),
]


def _midpoint(a, b) -> dict:
    return {
        "x": float((a.x + b.x) / 2.0),
        "y": float((a.y + b.y) / 2.0),
        "z": float((a.z + b.z) / 2.0),
        "visibility": float((a.visibility + b.visibility) / 2.0),
    }


def _build_mock_landmarks() -> dict:
    return {
        "landmarks": [{"x": 0.5, "y": 0.5, "z": 0.0, "visibility": 1.0} for _ in range(17)],
        "connections": MEDIAPIPE_CONNECTIONS,
    }


def extract_landmarks(frame_bgr: np.ndarray) -> dict | None:
    if frame_bgr is None or not isinstance(frame_bgr, np.ndarray):
        return None
    if not MEDIAPIPE_AVAILABLE:
        return _build_mock_landmarks()
    try:
        frame_rgb = frame_bgr[:, :, ::-1]
        with _create_pose() as pose:
            results = pose.process(frame_rgb)
        if not results.pose_landmarks:
            return None
        lm = results.pose_landmarks.landmark
        # Match the YOLO/COCO 17-keypoint order used to create the training .npy files.
        extracted = [
            {"x": float(lm[0].x), "y": float(lm[0].y), "z": float(lm[0].z), "visibility": float(lm[0].visibility)},   # 0 nose
            {"x": float(lm[2].x), "y": float(lm[2].y), "z": float(lm[2].z), "visibility": float(lm[2].visibility)},   # 1 left eye
            {"x": float(lm[5].x), "y": float(lm[5].y), "z": float(lm[5].z), "visibility": float(lm[5].visibility)},   # 2 right eye
            {"x": float(lm[7].x), "y": float(lm[7].y), "z": float(lm[7].z), "visibility": float(lm[7].visibility)},   # 3 left ear
            {"x": float(lm[8].x), "y": float(lm[8].y), "z": float(lm[8].z), "visibility": float(lm[8].visibility)},   # 4 right ear
            {"x": float(lm[11].x), "y": float(lm[11].y), "z": float(lm[11].z), "visibility": float(lm[11].visibility)}, # 5 left shoulder
            {"x": float(lm[12].x), "y": float(lm[12].y), "z": float(lm[12].z), "visibility": float(lm[12].visibility)}, # 6 right shoulder
            {"x": float(lm[13].x), "y": float(lm[13].y), "z": float(lm[13].z), "visibility": float(lm[13].visibility)}, # 7 left elbow
            {"x": float(lm[14].x), "y": float(lm[14].y), "z": float(lm[14].z), "visibility": float(lm[14].visibility)}, # 8 right elbow
            {"x": float(lm[15].x), "y": float(lm[15].y), "z": float(lm[15].z), "visibility": float(lm[15].visibility)}, # 9 left wrist
            {"x": float(lm[16].x), "y": float(lm[16].y), "z": float(lm[16].z), "visibility": float(lm[16].visibility)}, # 10 right wrist
            {"x": float(lm[23].x), "y": float(lm[23].y), "z": float(lm[23].z), "visibility": float(lm[23].visibility)}, # 11 left hip
            {"x": float(lm[24].x), "y": float(lm[24].y), "z": float(lm[24].z), "visibility": float(lm[24].visibility)}, # 12 right hip
            {"x": float(lm[25].x), "y": float(lm[25].y), "z": float(lm[25].z), "visibility": float(lm[25].visibility)}, # 13 left knee
            {"x": float(lm[26].x), "y": float(lm[26].y), "z": float(lm[26].z), "visibility": float(lm[26].visibility)}, # 14 right knee
            {"x": float(lm[27].x), "y": float(lm[27].y), "z": float(lm[27].z), "visibility": float(lm[27].visibility)}, # 15 left ankle
            {"x": float(lm[28].x), "y": float(lm[28].y), "z": float(lm[28].z), "visibility": float(lm[28].visibility)}, # 16 right ankle
        ]
        return {"landmarks": extracted, "connections": MEDIAPIPE_CONNECTIONS}
    except Exception as e:
        logging.warning(f"extract_landmarks exception: {e}")
        return None
