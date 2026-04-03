INJURY_CONSTRAINTS = {
    "ACL": {
        "early": {
            "max_knee_angle": 60,
            "allowed_exercises": ["WallPushups", "PushUps", "BenchPress"]
        },
        "mid": {
            "max_knee_angle": 75,
            "allowed_exercises": ["Lunges", "WallPushups", "PushUps", "PullUps"]
        },
        "late": {
            "max_knee_angle": 90,
            "allowed_exercises": ["Lunges", "BodyWeightSquats", "PullUps", "WallPushups"]
        }
    },
    "Back": {
        "early": {
            "max_back_angle": 20,
            "allowed_exercises": ["WallPushups", "PullUps"]
        },
        "mid": {
            "max_back_angle": 35,
            "allowed_exercises": ["WallPushups", "PushUps", "PullUps"]
        },
        "late": {
            "max_back_angle": 45,
            "allowed_exercises": ["WallPushups", "Lunges", "PullUps", "BodyWeightSquats"]
        }
    },
    "Shoulder": {
        "early": {
            "max_shoulder_angle": 60,
            "allowed_exercises": ["BodyWeightSquats", "Lunges"]
        },
        "mid": {
            "max_shoulder_angle": 90,
            "allowed_exercises": ["WallPushups", "BodyWeightSquats", "Lunges"]
        },
        "late": {
            "max_shoulder_angle": 120,
            "allowed_exercises": ["WallPushups", "PushUps", "PullUps", "Lunges"]
        }
    }
}


def get_constraints(injury: str, stage: str) -> dict:
    stage_key = stage if stage in ["early", "mid", "late"] else "early"
    if injury not in INJURY_CONSTRAINTS:
        return {}
    return INJURY_CONSTRAINTS[injury].get(stage_key, INJURY_CONSTRAINTS[injury]["early"])
