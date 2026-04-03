def fitness_decision(features: dict, risks: list, model_output: dict, validation: dict | None = None) -> dict:
    score = 100
    feedback = []
    family = model_output.get("movement_family")
    validation = validation or {}

    for risk in risks:
        score -= 10
        feedback.append(f"Risk detected: {risk}.")

    if model_output.get("is_override"):
        feedback.append(
            f"Movement interpreted as {model_output.get('movement_family_label', 'Unknown Pattern')} after biomechanical consistency checks."
        )
    if model_output.get("confidence_status") == "low":
        feedback.append("Classifier confidence is low, so movement-family reasoning was prioritized.")
    if validation.get("selected_exercise"):
        if validation.get("exercise_match"):
            feedback.append("Observed motion matches the selected exercise.")
        elif validation.get("family_match"):
            feedback.append("Observed motion matches the selected movement family, but exact class differs.")
        else:
            feedback.append("Observed motion does not strongly match the selected exercise.")

    if not risks:
        if features.get("symmetry_score", 0) > 0.85:
            feedback.append("Good symmetry detected.")
        if features.get("stability", 0) > 0.8:
            feedback.append("Stable movement pattern.")
        if features.get("depth", 0) > 0.6:
            feedback.append("Good depth achieved.")
        if family == "pull":
            feedback.append("Upper-body control looks consistent.")
        if family in {"squat", "lunge"} and features.get("depth", 0) > 0.3:
            feedback.append("Lower-body range of motion looks usable.")

    score = max(0, min(100, score))
    status = "ok" if score >= 80 else "warning" if score >= 50 else "danger"
    form_status = "correct" if not risks else "incorrect"

    return {
        "score": score,
        "feedback": feedback,
        "status": status,
        "form_status": form_status,
        "error_categories": risks,
        "selected_exercise": validation.get("selected_exercise"),
        "model_agreement": validation.get("model_agreement"),
        "model": model_output,
        "movement_family": model_output.get("movement_family"),
        "movement_family_label": model_output.get("movement_family_label"),
        "risk_flags": risks,
        "avg_knee_angle": features.get("avg_knee_angle"),
        "min_knee_angle": features.get("min_knee_angle"),
        "max_knee_angle": features.get("max_knee_angle"),
        "hip_angle_avg": features.get("hip_angle_avg"),
        "back_angle": features.get("back_angle"),
        "symmetry_score": features.get("symmetry_score"),
        "speed": features.get("speed"),
        "stability": features.get("stability"),
        "depth": features.get("depth"),
        "coordination_score": features.get("coordination_score"),
    }
