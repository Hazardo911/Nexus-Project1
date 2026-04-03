import logging
from app.core.pose.feature_extractor import extract_landmarks
from app.core.pose.normaliser import joint0_centre_normalise
from app.core.ai.inference import model_predict
from app.core.biomechanics.engine import compute_features, motion_summary, risk_flags
from app.core.decision.interpreter import (
    FAMILY_DISPLAY_NAMES,
    movement_family_for_exercise,
    reconcile_model_output,
    validate_selected_exercise,
)
from app.utils.smoothing import reset_smoothing, smooth_values


def _pose_visible_for_exercise(landmarks: list, selected_exercise: str | None) -> bool:
    if not landmarks:
        return False

    family = movement_family_for_exercise(selected_exercise)
    def visibility(idx: int) -> float:
        return float(landmarks[idx].get("visibility", 0.0) or 0.0)

    core_indices = [5, 6, 11, 12]
    core_visibilities = [visibility(idx) for idx in core_indices]
    if max(core_visibilities) < 0.20 or (sum(core_visibilities) / len(core_visibilities)) < 0.35:
        return False

    if family in {"squat", "lunge", "dynamic"}:
        knee_visibilities = [visibility(13), visibility(14)]
        if max(knee_visibilities) < 0.08:
            return False
        ankle_bonus = max(visibility(15), visibility(16)) >= 0.10
    elif family in {"push", "pull"}:
        arm_visibilities = [visibility(7), visibility(8), visibility(9), visibility(10)]
        if max(arm_visibilities) < 0.10 or (sum(arm_visibilities) / len(arm_visibilities)) < 0.20:
            return False
        ankle_bonus = False
    else:
        ankle_bonus = False

    xs = [float(point.get("x", 0.0) or 0.0) for point in landmarks]
    ys = [float(point.get("y", 0.0) or 0.0) for point in landmarks]
    width = max(xs) - min(xs)
    height = max(ys) - min(ys)

    if family in {"squat", "lunge", "dynamic"} and height < 0.06:
        return False
    if family in {"push", "pull"} and max(width, height) < 0.08:
        return False
    return True


def run_pipeline(frame_bgr, buffer, selected_exercise: str | None = None):
    try:
        payload = extract_landmarks(frame_bgr)
        if payload is None:
            return {"status": "no_detection"}
        landmarks = payload["landmarks"]
        if not _pose_visible_for_exercise(landmarks, selected_exercise):
            return {
                "status": "pose_partial",
                "message": "Pose detected, but the camera view is still limited. Try a small step back or a slight camera tilt for better analysis.",
                "selected_exercise": selected_exercise,
                "landmarks": landmarks,
                "connections": payload.get("connections", []),
            }

        normalised = joint0_centre_normalise(landmarks)

        buffer.add(normalised)
        if not buffer.is_ready():
            return {
                "status": "buffering",
                "frames": len(buffer.buffer),
                "needed": buffer._maxlen,
                "selected_exercise": selected_exercise,
                "landmarks": landmarks,
                "connections": payload.get("connections", []),
            }

        tensor = buffer.to_tensor()
        history = list(buffer.buffer)
        motion = motion_summary(history)
        if not motion.get("has_meaningful_motion"):
            buffer.prediction_history.clear()
            reset_smoothing()
            return {
                "status": "waiting_for_movement",
                "message": "Pose detected. Start the selected exercise to begin analysis.",
                "selected_exercise": selected_exercise,
                "motion": motion,
                "landmarks": landmarks,
                "connections": payload.get("connections", []),
            }

        if selected_exercise:
            family = movement_family_for_exercise(selected_exercise)
            model_output = {
                "class_id": None,
                "exercise": selected_exercise,
                "raw_exercise": None,
                "raw_family": family,
                "confidence": None,
                "top_k": [],
                "movement_family": family,
                "movement_family_label": FAMILY_DISPLAY_NAMES.get(family, "Unknown Pattern"),
                "inferred_family": family,
                "history_family": family,
                "confidence_status": "manual",
                "is_override": False,
                "source": "selected_exercise",
            }
            validation = {
                "selected_exercise": selected_exercise,
                "selected_family": family,
                "selected_family_label": FAMILY_DISPLAY_NAMES.get(family, "Unknown Pattern"),
                "model_suggested_exercise": selected_exercise,
                "model_suggested_family": family,
                "model_agreement": "manual",
                "exercise_match": True,
                "family_match": True,
            }
            target_exercise = selected_exercise
        else:
            raw_model_output = model_predict(tensor)
            buffer.add_prediction(raw_model_output)
            target_exercise = raw_model_output["exercise"]
            model_output = reconcile_model_output(
                raw_model_output,
                compute_features(landmarks, target_exercise, buffer_frames=history),
                history=list(buffer.prediction_history),
            )
            validation = validate_selected_exercise(selected_exercise, model_output)

        features = compute_features(landmarks, target_exercise, buffer_frames=history)
        risks = risk_flags(features, target_exercise)
        smoothed = smooth_values(features)

        return {
            "status": "ok",
            "model": model_output,
            "selected_exercise": selected_exercise,
            "validation": validation,
            "features": smoothed,
            "motion": motion,
            "risks": risks,
            "landmarks": landmarks,
            "connections": payload.get("connections", []),
        }
    except Exception as e:
        logging.exception("pipeline error")
        return {"status": "error", "message": str(e)}
