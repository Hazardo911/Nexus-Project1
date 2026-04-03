SUPPORTED_REHAB_EXERCISES = [
    "WallPushups",
    "PushUps",
    "BenchPress",
    "PullUps",
    "BodyWeightSquats",
    "Lunges",
    "CleanAndJerk",
]


INJURY_CONSTRAINTS = {
    "ACL": {
        "early": {
            "max_knee_angle": 60,
            "allowed_exercises": [
                "WallPushups",
                "PushUps",
                "BenchPress",
                "PullUps",
            ],
            "stage_focus": "Protect knee flexion, maintain upper-body strength, and avoid deep loaded lower-body patterns.",
        },
        "mid": {
            "max_knee_angle": 75,
            "allowed_exercises": [
                "WallPushups",
                "PushUps",
                "BenchPress",
                "PullUps",
                "Lunges",
            ],
            "stage_focus": "Reintroduce controlled unilateral knee work while keeping range limited.",
        },
        "late": {
            "max_knee_angle": 95,
            "allowed_exercises": [
                "Lunges",
                "BodyWeightSquats",
                "WallPushups",
                "PushUps",
                "BenchPress",
                "PullUps",
                "CleanAndJerk",
            ],
            "stage_focus": "Progress toward full lower-body patterns with better depth and controlled power work.",
        },
    },
    "Back": {
        "early": {
            "max_back_angle": 20,
            "allowed_exercises": [
                "WallPushups",
                "PushUps",
            ],
            "stage_focus": "Minimize trunk flexion and focus on bracing with low spinal load.",
        },
        "mid": {
            "max_back_angle": 35,
            "allowed_exercises": [
                "WallPushups",
                "PushUps",
                "BenchPress",
                "BodyWeightSquats",
            ],
            "stage_focus": "Build tolerance to upright compound patterns while keeping the spine organized.",
        },
        "late": {
            "max_back_angle": 45,
            "allowed_exercises": [
                "WallPushups",
                "PushUps",
                "BenchPress",
                "BodyWeightSquats",
                "Lunges",
                "PullUps",
            ],
            "stage_focus": "Return to fuller compound training with careful trunk control and pacing.",
        },
    },
    "Shoulder": {
        "early": {
            "max_shoulder_angle": 60,
            "allowed_exercises": [
                "BodyWeightSquats",
                "Lunges",
            ],
            "stage_focus": "Reduce shoulder elevation and let the lower body carry most of the session.",
        },
        "mid": {
            "max_shoulder_angle": 90,
            "allowed_exercises": [
                "BodyWeightSquats",
                "Lunges",
                "WallPushups",
                "BenchPress",
            ],
            "stage_focus": "Gradually restore pressing tolerance without aggressive overhead demand.",
        },
        "late": {
            "max_shoulder_angle": 120,
            "allowed_exercises": [
                "BodyWeightSquats",
                "Lunges",
                "WallPushups",
                "PushUps",
                "BenchPress",
                "PullUps",
            ],
            "stage_focus": "Return to mixed upper- and lower-body training with shoulder range monitored.",
        },
    },
    "Knee": {
        "early": {
            "max_knee_angle": 55,
            "allowed_exercises": [
                "WallPushups",
                "PushUps",
                "BenchPress",
            ],
            "stage_focus": "Keep knee bend shallow and shift emphasis to upper-body work.",
        },
        "mid": {
            "max_knee_angle": 70,
            "allowed_exercises": [
                "WallPushups",
                "PushUps",
                "BenchPress",
                "BodyWeightSquats",
            ],
            "stage_focus": "Bring back controlled squatting with a conservative knee range.",
        },
        "late": {
            "max_knee_angle": 90,
            "allowed_exercises": [
                "BodyWeightSquats",
                "Lunges",
                "WallPushups",
                "PushUps",
                "BenchPress",
                "PullUps",
            ],
            "stage_focus": "Restore lower-body loading symmetry and depth tolerance.",
        },
    },
    "Ankle": {
        "early": {
            "max_knee_angle": 50,
            "allowed_exercises": [
                "WallPushups",
                "PushUps",
                "BenchPress",
            ],
            "stage_focus": "Keep ankle travel small and avoid deep or explosive lower-body patterns.",
        },
        "mid": {
            "max_knee_angle": 65,
            "allowed_exercises": [
                "WallPushups",
                "PushUps",
                "BenchPress",
                "BodyWeightSquats",
            ],
            "stage_focus": "Reintroduce controlled dorsiflexion with stable squat mechanics.",
        },
        "late": {
            "max_knee_angle": 85,
            "allowed_exercises": [
                "BodyWeightSquats",
                "Lunges",
                "WallPushups",
                "PushUps",
                "BenchPress",
                "PullUps",
                "CleanAndJerk",
            ],
            "stage_focus": "Build confidence for deeper and more dynamic lower-body patterns.",
        },
    },
}


def _sanitize_allowed_exercises(values: list[str]) -> list[str]:
    ordered = []
    seen = set()
    for exercise in values:
        if exercise in SUPPORTED_REHAB_EXERCISES and exercise not in seen:
            ordered.append(exercise)
            seen.add(exercise)
    return ordered


def get_constraints(injury: str, stage: str) -> dict:
    stage_key = stage if stage in ["early", "mid", "late"] else "early"
    normalized_injury = injury if injury in INJURY_CONSTRAINTS else "ACL"
    selected = dict(INJURY_CONSTRAINTS[normalized_injury].get(stage_key, INJURY_CONSTRAINTS[normalized_injury]["early"]))
    selected["injury"] = normalized_injury
    selected["stage"] = stage_key
    selected["allowed_exercises"] = _sanitize_allowed_exercises(selected.get("allowed_exercises", []))
    return selected
