from app.core.ai.model import CLASS_NAMES


MOVEMENT_FAMILY_MAP = {
    "BenchPress": "push",
    "BodyWeightSquats": "squat",
    "CleanAndJerk": "dynamic",
    "HandstandPushups": "push",
    "JumpingJack": "dynamic",
    "Lunges": "lunge",
    "PullUps": "pull",
    "PushUps": "push",
    "WallPushups": "push",
}

FAMILY_DISPLAY_NAMES = {
    "push": "Push Pattern",
    "pull": "Pull Pattern",
    "squat": "Squat Pattern",
    "lunge": "Lunge Pattern",
    "dynamic": "Dynamic Full-Body Pattern",
    "uncertain": "Uncertain Pattern",
}

FAMILY_EXERCISE_PRIORITY = {
    "push": ["PushUps", "WallPushups", "BenchPress", "HandstandPushups"],
    "pull": ["PullUps"],
    "squat": ["BodyWeightSquats"],
    "lunge": ["Lunges"],
    "dynamic": ["CleanAndJerk", "JumpingJack"],
}


def movement_family_for_exercise(exercise: str | None) -> str:
    if not exercise:
        return "uncertain"
    return MOVEMENT_FAMILY_MAP.get(exercise, "uncertain")


def infer_family_from_features(features: dict) -> str:
    knee = float(features.get("avg_knee_angle", 180.0) or 180.0)
    min_knee = float(features.get("min_knee_angle", knee) or knee)
    max_knee = float(features.get("max_knee_angle", knee) or knee)
    hip = float(features.get("hip_angle_avg", 180.0) or 180.0)
    back = float(features.get("back_angle", 0.0) or 0.0)
    depth = float(features.get("depth", 0.0) or 0.0)
    symmetry = float(features.get("symmetry_score", 0.0) or 0.0)
    speed = float(features.get("speed", 0.0) or 0.0)
    knee_rom = max_knee - min_knee

    if min_knee < 90 and knee_rom > 55 and back < 60:
        if symmetry < 0.72:
            return "lunge"
        return "squat"
    if knee < 125 and depth > 0.32:
        if symmetry < 0.72:
            return "lunge"
        return "squat"
    if hip < 120 and knee < 145 and depth > 0.22:
        return "lunge" if symmetry < 0.78 else "squat"
    if back > 55 and knee > 145:
        return "push"
    if speed > 0.03:
        return "dynamic"
    if symmetry > 0.82 and knee > 145:
        return "push"
    return "uncertain"


def _best_exercise_for_family(family: str, top_k: list[dict]) -> str:
    family_candidates = FAMILY_EXERCISE_PRIORITY.get(family, [])
    for candidate in top_k:
        exercise = candidate.get("exercise")
        if exercise in family_candidates:
            return exercise
    return family_candidates[0] if family_candidates else (top_k[0]["exercise"] if top_k else "Unknown")


def reconcile_model_output(raw_output: dict, features: dict, history: list[int] | None = None) -> dict:
    top_k = list(raw_output.get("top_k", []))
    top_exercise = raw_output.get("exercise")
    top_confidence = float(raw_output.get("confidence", 0.0) or 0.0)
    predicted_family = movement_family_for_exercise(top_exercise)
    inferred_family = infer_family_from_features(features)

    history = history or []
    history_family = "uncertain"
    if history:
        counts: dict[str, int] = {}
        for class_id in history:
            exercise = CLASS_NAMES.get(class_id)
            family = movement_family_for_exercise(exercise) if exercise else "uncertain"
            counts[family] = counts.get(family, 0) + 1
        history_family = max(counts, key=counts.get) if counts else "uncertain"

    final_family = predicted_family
    confidence_status = "high" if top_confidence >= 0.75 else "medium" if top_confidence >= 0.55 else "low"
    if inferred_family != "uncertain" and predicted_family != inferred_family:
        strong_lower_body_signal = (
            float(features.get("min_knee_angle", 180.0) or 180.0) < 90
            and (float(features.get("max_knee_angle", 180.0) or 180.0) - float(features.get("min_knee_angle", 180.0) or 180.0)) > 55
        )
        if top_confidence < 0.88 or predicted_family == "push" or strong_lower_body_signal:
            final_family = inferred_family
    if history_family != "uncertain" and final_family != history_family and top_confidence < 0.70:
        final_family = history_family

    final_exercise = top_exercise
    if final_family != predicted_family:
        final_exercise = _best_exercise_for_family(final_family, top_k)

    model_output = {
        **raw_output,
        "raw_exercise": top_exercise,
        "raw_family": predicted_family,
        "movement_family": final_family,
        "movement_family_label": FAMILY_DISPLAY_NAMES.get(final_family, "Unknown Pattern"),
        "inferred_family": inferred_family,
        "history_family": history_family,
        "confidence_status": confidence_status,
        "exercise": final_exercise,
        "is_override": final_exercise != top_exercise or final_family != predicted_family,
    }
    if top_confidence < 0.45:
        model_output["movement_family"] = inferred_family if inferred_family != "uncertain" else final_family
        model_output["movement_family_label"] = FAMILY_DISPLAY_NAMES.get(model_output["movement_family"], "Unknown Pattern")
        model_output["exercise"] = "Uncertain"
    return model_output


def validate_selected_exercise(selected_exercise: str | None, model_output: dict) -> dict:
    selected_family = movement_family_for_exercise(selected_exercise)
    suggested_exercise = model_output.get("exercise")
    suggested_family = model_output.get("movement_family", "uncertain")
    exact_match = bool(selected_exercise and selected_exercise == suggested_exercise)
    family_match = bool(selected_family != "uncertain" and selected_family == suggested_family)

    if exact_match:
        agreement = "high"
    elif family_match:
        agreement = "medium"
    else:
        agreement = "low"

    return {
        "selected_exercise": selected_exercise,
        "selected_family": selected_family,
        "selected_family_label": FAMILY_DISPLAY_NAMES.get(selected_family, "Unknown Pattern"),
        "model_suggested_exercise": suggested_exercise,
        "model_suggested_family": suggested_family,
        "model_agreement": agreement,
        "exercise_match": exact_match,
        "family_match": family_match,
    }
