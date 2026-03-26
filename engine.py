from exercise_logic import (
    ExerciseState,
    squat_logic,
    pushup_logic,
    lunges_logic,
    jumpingjack_logic,
    pullup_logic,
    wallpushup_logic,
    benchpress_logic,
)


# ----------------------------------------------------------------
# ALIAS MAP
# ----------------------------------------------------------------
# ----------------------------------------------------------------
# MODEL FALLBACK MAP
# The AI model can predict labels that don't have logic functions
# (cleanandjerk, handstandpushup, wallpushup from label_map.json).
# Instead of crashing, map them to the closest supported exercise.
# This never changes what's in label_map.json — only how the engine
# handles those predictions internally.
# ----------------------------------------------------------------
MODEL_FALLBACK: dict[str, str] = {
    "cleanandjerk":    "squat",       # full-body compound → squat
    "handstandpushup": "pushup",      # push pattern → pushup
    "wallpushup":      "pushup",      # push pattern → pushup
    "benchpress":      "pushup",      # push pattern → pushup
}

# Exercises the MODEL can predict but we have no logic for yet.
# set_exercise() will return False for these → realtime.py asks user to pick manually.
UNSUPPORTED = {"cleanandjerk", "handstandpushup"}

ALIASES: dict[str, str] = {
    "squat":             "squat",
    "squats":            "squat",

    "pushup":            "pushup",
    "pushups":           "pushup",
    "push up":           "pushup",
    "push ups":          "pushup",
    "push-up":           "pushup",
    "push-ups":          "pushup",

    "lunge":             "lunges",
    "lunges":            "lunges",

    "jumpingjack":       "jumpingjack",
    "jumpingjacks":      "jumpingjack",
    "jumping jack":      "jumpingjack",
    "jumping jacks":     "jumpingjack",
    "jumping-jack":      "jumpingjack",
    "jumping-jacks":     "jumpingjack",

    "pullup":            "pullup",
    "pullups":           "pullup",
    "pull up":           "pullup",
    "pull ups":          "pullup",
    "pull-up":           "pullup",
    "pull-ups":          "pullup",
    "chin up":           "pullup",
    "chin ups":          "pullup",
    "chinup":            "pullup",
    "chinups":           "pullup",

    "wallpushup":        "wallpushup",
    "wall pushup":       "wallpushup",
    "wall push up":      "wallpushup",
    "wall push-up":      "wallpushup",
    "wall-pushup":       "wallpushup",

    "benchpress":        "benchpress",
    "bench press":       "benchpress",
    "bench-press":       "benchpress",
    "bench":             "benchpress",
}


def normalize(name: str) -> str | None:
    cleaned = name.lower().strip().replace("_", " ").replace("-", " ")
    cleaned = " ".join(cleaned.split())
    return ALIASES.get(cleaned)


# ----------------------------------------------------------------
# ENGINE
# ----------------------------------------------------------------
class FitnessEngine:

    # FIX: Penalties are softer — reps always count, just score lower.
    # Minimum score per rep is 0.4 so accuracy never hits 0%.
    PENALTIES: list[tuple[str, float]] = [
        ("❌",          0.20),
        ("Go lower",    0.15),
        ("Too low",     0.10),
        ("Keep back",   0.15),
        ("Misaligned",  0.15),
        ("Unstable",    0.10),
        ("Too fast",    0.08),
        ("Too slow",    0.08),
        ("⚠",           0.08),
    ]

    # Minimum quality score per rep — ensures accuracy never shows 0%
    MIN_REP_SCORE = 0.40

    def __init__(self):
        self._exercise_map: dict[str, callable] = {
            "squat":       squat_logic,
            "pushup":      pushup_logic,
            "lunges":      lunges_logic,
            "jumpingjack": jumpingjack_logic,
            "pullup":      pullup_logic,
            "wallpushup":  wallpushup_logic,
            "benchpress":  benchpress_logic,
        }

        self.current_exercise: str = "squat"
        self._logic_fn: callable   = squat_logic

        self._ex_state: ExerciseState = ExerciseState()
        self._rep_state: dict         = self._blank_rep_state()

        self.goal:           int | None = None
        self.good_reps:      float      = 0.0
        self.bad_reps:       float      = 0.0
        self.session_active: bool       = True

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------

    def set_exercise(self, raw_name: str) -> bool:
        canonical = normalize(raw_name)

        # Model may predict exercises we have no biomechanics logic for yet.
        # Return False so realtime.py can prompt the user to pick manually.
        if canonical in UNSUPPORTED:
            print(f"[Engine] '{raw_name}' detected by model but not yet supported — ask user to pick manually.")
            return False

        if canonical is None:
            known = sorted(set(ALIASES.values()) - UNSUPPORTED)
            print(f"[Engine] Unknown exercise: '{raw_name}'")
            print(f"[Engine] Supported: {', '.join(known)}")
            return False

        self.current_exercise = canonical
        self._logic_fn        = self._exercise_map[canonical]

        self._ex_state  = ExerciseState()
        self._rep_state = self._blank_rep_state()

        self.goal           = None
        self.good_reps      = 0.0
        self.bad_reps       = 0.0
        self.session_active = True
        return True

    def set_goal(self, goal: int):
        self.goal           = goal
        self.good_reps      = 0.0
        self.bad_reps       = 0.0
        self.session_active = True

    def get_supported_exercises(self) -> list[str]:
        return sorted(self._exercise_map.keys())

    # ------------------------------------------------------------------
    # Main loop
    # ------------------------------------------------------------------

    def process(self, landmarks) -> dict:
        if not self.session_active:
            return self._done_result()

        prev_reps = self._rep_state["counter"]

        # FIX: logic functions now return 4 values (added angles_display)
        self._rep_state, feedback, angle, angles_display = self._logic_fn(
            landmarks, self._rep_state, self._ex_state
        )

        new_reps      = self._rep_state["counter"]
        rep_completed = new_reps > prev_reps

        if rep_completed:
            score           = self._score_rep(feedback)
            self.good_reps += score
            self.bad_reps  += (1.0 - score)

        done = False
        if self.goal is not None and new_reps >= self.goal:
            done                = True
            self.session_active = False

        return {
            "exercise":      self.current_exercise,
            "reps":          new_reps,
            "goal":          self.goal,
            "stage":         self._rep_state["stage"],
            "feedback":      feedback if feedback else ["Tracking..."],
            "primary_angle": angle,
            "angles":        angles_display,   # NEW — dict of joint_name → angle
            "done":          done,
        }

    def get_summary(self) -> dict:
        total    = self._rep_state["counter"]
        # FIX: Accuracy floor at 40% — never show 0% to discourage user
        if total > 0:
            raw_accuracy = self.good_reps / total * 100
            accuracy     = round(max(raw_accuracy, 40.0), 1)
        else:
            accuracy = 0.0
        return {
            "exercise":   self.current_exercise,
            "total_reps": total,
            "good_reps":  round(self.good_reps, 2),
            "bad_reps":   round(self.bad_reps, 2),
            "accuracy":   accuracy,
        }

    # ------------------------------------------------------------------
    # Private helpers
    # ------------------------------------------------------------------

    @staticmethod
    def _blank_rep_state() -> dict:
        return {
            "stage":      None,
            "counter":    0,
            "start_time": None,
            "last_rep":   0,
        }

    def _done_result(self) -> dict:
        return {
            "exercise":      self.current_exercise,
            "reps":          self._rep_state["counter"],
            "goal":          self.goal,
            "stage":         self._rep_state["stage"],
            "feedback":      ["Session complete ✅"],
            "primary_angle": None,
            "angles":        {},
            "done":          True,
        }

    def _score_rep(self, feedback: list[str]) -> float:
        """
        Score one rep 0.0–1.0 based on feedback messages.
        FIX: Minimum score is MIN_REP_SCORE so accuracy never hits 0%.
        """
        score = 1.0
        for msg in feedback:
            msg_lower = msg.lower()
            for keyword, penalty in self.PENALTIES:
                if keyword.lower() in msg_lower:
                    score -= penalty
                    break
        return max(score, self.MIN_REP_SCORE)