from app.core.rehab.constraints import get_constraints


def rehab_decision(features: dict, risks: list,
                   model_output: dict,
                   injury: str, stage: str,
                   validation: dict | None = None) -> dict:
    constraints = get_constraints(injury, stage)
    allowed = constraints.get("allowed_exercises", [])
    stage_focus = constraints.get("stage_focus")
    is_safe = True
    score = 100
    warnings = []
    user_reasons = []
    next_steps = []
    validation = validation or {}

    exercise = validation.get("selected_exercise") or model_output.get("exercise")
    if exercise not in allowed:
        is_safe = False
        score -= 30
        warnings.append("Exercise not permitted at this recovery stage.")
        user_reasons.append(f"{exercise} is not recommended during {stage} {injury} recovery.")
        if allowed:
            next_steps.append(f"Try a safer option such as {', '.join(allowed[:3])}.")
    if model_output.get("confidence_status") == "low":
        score -= 10
        warnings.append("Exercise classification confidence is low. Review movement manually.")
        user_reasons.append("The movement pattern is not fully clear from this video.")
    if validation.get("selected_exercise") and not validation.get("family_match") and not validation.get("exercise_match"):
        score -= 12
        warnings.append("Observed motion does not match the selected rehab exercise closely.")
        user_reasons.append("The movement in the video does not closely match the exercise you selected.")

    # clinical hard overrides
    if injury == "ACL":
        max_knee = constraints.get("max_knee_angle", 0)
        if features.get("avg_knee_angle", 0) > max_knee:
            is_safe = False
            score -= 25
            warnings.append(f"Knee flexion exceeds safe limit for {stage} ACL recovery.")
            user_reasons.append("Your knee is bending deeper than the safe limit for your current ACL recovery stage.")
            next_steps.append("Reduce the squat depth and keep the movement smaller for now.")

    if injury == "Back":
        max_back = constraints.get("max_back_angle", 0)
        if features.get("back_angle", 0) > max_back:
            is_safe = False
            score -= 25
            warnings.append(f"Spinal flexion exceeds safe limit for {stage} back recovery.")
            user_reasons.append("Your back is bending too much for the current stage of back recovery.")
            next_steps.append("Keep your chest more upright and reduce forward bending.")

    if injury == "Shoulder":
        max_shoulder = constraints.get("max_shoulder_angle", 0)
        if features.get("shoulder_angle", 0) > max_shoulder:
            is_safe = False
            score -= 25
            warnings.append(f"Shoulder range exceeds safe limit for {stage} recovery.")
            user_reasons.append("Your shoulder is moving beyond the safe range for this recovery stage.")
            next_steps.append("Reduce the shoulder range and stay within a smaller motion arc.")

    if "instability" in risks:
        score -= 12
        warnings.append("High instability - reduce movement speed.")
        user_reasons.append("The movement looks unstable.")
        next_steps.append("Slow the movement down and focus on balance.")
    if "imbalance" in risks:
        score -= 10
        warnings.append("Asymmetric movement detected. Focus on weaker side.")
        user_reasons.append("Your movement is uneven between the left and right sides.")
        next_steps.append("Repeat the exercise with more balanced control on both sides.")

    score = max(0, min(100, score))
    status = "safe" if is_safe else "danger"
    if is_safe:
        feedback = f"This movement looks safe for {stage} {injury} rehab."
        if allowed:
            feedback += f" Recommended options at this stage include {', '.join(allowed[:4])}."
        if stage_focus:
            feedback += f" Focus: {stage_focus}"
    else:
        summary_reason = user_reasons[0] if user_reasons else "This movement is not safe for your current rehab stage."
        summary_step = next_steps[0] if next_steps else "Choose a gentler exercise and reduce the movement range."
        feedback = f"Not safe right now: {summary_reason} {summary_step}"

    return {
        "score": score,
        "is_safe": is_safe,
        "warnings": warnings,
        "feedback": feedback,
        "status": status,
        "form_status": "correct" if not risks and is_safe else "incorrect",
        "error_categories": risks,
        "selected_exercise": validation.get("selected_exercise"),
        "model_agreement": validation.get("model_agreement"),
        "allowed_exercises": allowed,
        "stage_focus": stage_focus,
        "model": model_output,
        "features": features
    }
