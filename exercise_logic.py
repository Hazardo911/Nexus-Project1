import numpy as np
import time
from collections import deque


# ================================================================
# EXERCISE STATE
# One instance lives in engine.py per active exercise.
# Passed into every logic function — zero module-level mutable state.
# ================================================================

class ExerciseState:
    """
    Holds smoothing buffers + calibration baselines for one exercise session.
    Creating a new instance is all that's needed to get a clean slate.
    """

    def __init__(self, smooth_len: int = 5, calib_samples: int = 5):
        self._smooth_len    = smooth_len
        self._calib_samples = calib_samples
        self._buffers:   dict[str, deque]        = {}
        self._baselines: dict[str, float | None] = {}
        self._calib_acc: dict[str, list[float]]  = {}

    def _ensure(self, key: str):
        if key not in self._buffers:
            self._buffers[key]   = deque(maxlen=self._smooth_len)
            self._baselines[key] = None
            self._calib_acc[key] = []

    def smooth(self, key: str, value: float) -> float:
        self._ensure(key)
        self._buffers[key].append(value)
        return sum(self._buffers[key]) / len(self._buffers[key])

    def stability(self, key: str) -> float:
        self._ensure(key)
        if len(self._buffers[key]) < 2:
            return 0.0
        return float(np.var(self._buffers[key]))

    def calibrate(self, key: str, value: float) -> bool:
        self._ensure(key)
        if self._baselines[key] is not None:
            return True
        self._calib_acc[key].append(value)
        if len(self._calib_acc[key]) >= self._calib_samples:
            self._baselines[key] = (
                sum(self._calib_acc[key]) / len(self._calib_acc[key])
            )
            return True
        return False

    def is_calibrated(self, key: str) -> bool:
        self._ensure(key)
        return self._baselines[key] is not None

    def baseline(self, key: str) -> float | None:
        self._ensure(key)
        return self._baselines[key]

    def calib_progress(self, key: str) -> int:
        self._ensure(key)
        return len(self._calib_acc[key])

    def reset(self):
        self._buffers.clear()
        self._baselines.clear()
        self._calib_acc.clear()


# ================================================================
# PURE HELPERS
# ================================================================

def calculate_angle(a, b, c) -> float:
    """Angle in degrees at vertex b, formed by points a-b-c. Returns 0-180."""
    a, b, c = np.array(a), np.array(b), np.array(c)
    radians = (np.arctan2(c[1] - b[1], c[0] - b[0])
             - np.arctan2(a[1] - b[1], a[0] - b[0]))
    angle = abs(np.degrees(radians))
    return 360.0 - angle if angle > 180.0 else angle


def check_symmetry(lm) -> str:
    diff = abs(lm[23].y - lm[24].y)
    return "Uneven hips ⚠" if diff > 0.05 else "Balanced ✅"


# FIX: Lowered threshold from 0.5 → 0.3 so landmarks near screen edges
# (wrists raised above head, feet spread wide) don't trigger "body not visible".
def visible(lm, *indices, threshold: float = 0.3) -> bool:
    return all(lm[i].visibility >= threshold for i in indices)


def _pt(lm, i: int) -> list:
    return [lm[i].x, lm[i].y]


# ================================================================
# SQUAT
# FIX: Uses both left AND right knee angles averaged — single-side
# tracking broke when camera was slightly to one side.
# Returns angles dict for joint overlay display.
# ================================================================
def squat_logic(lm, rep_state: dict, ex_state: ExerciseState):
    L_SHOULDER, L_HIP, L_KNEE, L_ANKLE = 11, 23, 25, 27
    R_SHOULDER, R_HIP, R_KNEE, R_ANKLE = 12, 24, 26, 28

    # Try left side first, fall back to right, then accept either
    left_ok  = visible(lm, L_HIP, L_KNEE, L_ANKLE)
    right_ok = visible(lm, R_HIP, R_KNEE, R_ANKLE)

    if not left_ok and not right_ok:
        return rep_state, ["Step back — can't see legs"], 0.0, {}

    angles_display = {}

    # Compute whichever side(s) are visible and average
    knee_raws = []
    if left_ok:
        la = calculate_angle(_pt(lm, L_HIP), _pt(lm, L_KNEE), _pt(lm, L_ANKLE))
        knee_raws.append(la)
        angles_display["L.Knee"] = la
    if right_ok:
        ra = calculate_angle(_pt(lm, R_HIP), _pt(lm, R_KNEE), _pt(lm, R_ANKLE))
        knee_raws.append(ra)
        angles_display["R.Knee"] = ra

    raw_knee   = sum(knee_raws) / len(knee_raws)
    knee_angle = ex_state.smooth("knee", raw_knee)

    # Back angle (use whichever shoulder/hip is visible)
    if left_ok and visible(lm, L_SHOULDER):
        back_angle = calculate_angle(_pt(lm, L_SHOULDER), _pt(lm, L_HIP), _pt(lm, L_KNEE))
        angles_display["L.Back"] = back_angle
    elif right_ok and visible(lm, R_SHOULDER):
        back_angle = calculate_angle(_pt(lm, R_SHOULDER), _pt(lm, R_HIP), _pt(lm, R_KNEE))
        angles_display["R.Back"] = back_angle
    else:
        back_angle = 180.0

    if not ex_state.is_calibrated("knee"):
        ex_state.calibrate("knee", knee_angle)
        n = ex_state.calib_progress("knee")
        return rep_state, [f"Stand straight — calibrating ({n}/5)"], knee_angle, angles_display

    base    = ex_state.baseline("knee")
    down_th = base - 40
    up_th   = base - 10

    feedback     = []
    rep_complete = False

    if knee_angle < down_th:
        if rep_state["stage"] != "down":
            rep_state["stage"]      = "down"
            rep_state["start_time"] = time.time()
    elif knee_angle > up_th and rep_state["stage"] == "down":
        if time.time() - rep_state.get("last_rep", 0) > 0.3:
            rep_state["counter"] += 1
            rep_state["stage"]    = "up"
            rep_state["last_rep"] = time.time()
            rep_complete          = True

    if knee_angle > up_th:
        feedback.append("Go lower ↓")
    elif knee_angle < down_th - 10:
        feedback.append("Too low ⚠")
    else:
        feedback.append("Good depth ✅")

    # Check knee cave only if both visible
    if left_ok and right_ok:
        if abs(lm[L_KNEE].x - lm[L_ANKLE].x) > 0.08:
            feedback.append("Knees caving in ❌")

    if back_angle < 150:
        feedback.append("Keep back straight ⚠")

    feedback.append(check_symmetry(lm))

    if ex_state.stability("knee") > 50:
        feedback.append("Unstable ⚠")

    if rep_complete and rep_state.get("start_time"):
        duration = time.time() - rep_state["start_time"]
        if duration < 1.0:
            feedback.append("Too fast ⚠")
        elif duration > 5.0:
            feedback.append("Too slow ⚠")

    return rep_state, feedback, knee_angle, angles_display


# ================================================================
# PUSHUP
# FIX: Uses both arms, averaged. Returns angles_display dict.
# ================================================================
def pushup_logic(lm, rep_state: dict, ex_state: ExerciseState):
    L_SHOULDER, L_ELBOW, L_WRIST, L_HIP = 11, 13, 15, 23
    R_SHOULDER, R_ELBOW, R_WRIST, R_HIP = 12, 14, 16, 24

    left_ok  = visible(lm, L_SHOULDER, L_ELBOW, L_WRIST)
    right_ok = visible(lm, R_SHOULDER, R_ELBOW, R_WRIST)

    if not left_ok and not right_ok:
        return rep_state, ["Can't see arms — adjust camera"], 0.0, {}

    angles_display = {}
    elbow_raws = []

    if left_ok:
        la = calculate_angle(_pt(lm, L_SHOULDER), _pt(lm, L_ELBOW), _pt(lm, L_WRIST))
        elbow_raws.append(la)
        angles_display["L.Elbow"] = la
    if right_ok:
        ra = calculate_angle(_pt(lm, R_SHOULDER), _pt(lm, R_ELBOW), _pt(lm, R_WRIST))
        elbow_raws.append(ra)
        angles_display["R.Elbow"] = ra

    raw_elbow   = sum(elbow_raws) / len(elbow_raws)
    elbow_angle = ex_state.smooth("elbow", raw_elbow)

    # Body alignment
    hip_ok = visible(lm, L_HIP) or visible(lm, R_HIP)
    if hip_ok:
        hip_pt  = _pt(lm, L_HIP) if visible(lm, L_HIP) else _pt(lm, R_HIP)
        sh_pt   = _pt(lm, L_SHOULDER) if left_ok else _pt(lm, R_SHOULDER)
        body_angle = calculate_angle(sh_pt, hip_pt, [hip_pt[0], hip_pt[1] + 0.1])
        angles_display["Body"] = body_angle
    else:
        body_angle = 180.0

    if not ex_state.is_calibrated("elbow"):
        ex_state.calibrate("elbow", elbow_angle)
        n = ex_state.calib_progress("elbow")
        return rep_state, [f"Hold top position — calibrating ({n}/5)"], elbow_angle, angles_display

    base    = ex_state.baseline("elbow")
    down_th = base - 50
    up_th   = base - 10

    feedback     = []
    rep_complete = False

    if elbow_angle < down_th:
        if rep_state["stage"] != "down":
            rep_state["stage"]      = "down"
            rep_state["start_time"] = time.time()
    elif elbow_angle > up_th and rep_state["stage"] == "down":
        if time.time() - rep_state.get("last_rep", 0) > 0.3:
            rep_state["counter"] += 1
            rep_state["stage"]    = "up"
            rep_state["last_rep"] = time.time()
            rep_complete          = True

    if elbow_angle > up_th:
        feedback.append("Go lower ↓")
    else:
        feedback.append("Good depth ✅")

    if body_angle < 160:
        feedback.append("Keep body straight ⚠")

    if ex_state.stability("elbow") > 40:
        feedback.append("Unstable ⚠")

    if rep_complete and rep_state.get("start_time"):
        duration = time.time() - rep_state["start_time"]
        if duration < 1.0:
            feedback.append("Too fast ⚠")
        elif duration > 5.0:
            feedback.append("Too slow ⚠")

    return rep_state, feedback, elbow_angle, angles_display


# ================================================================
# LUNGES
# FIX: Relaxed down threshold from <80 → <100, up threshold 160→150
# so normal lunges actually register. Uses best available leg.
# ================================================================
def lunges_logic(lm, rep_state: dict, ex_state: ExerciseState):
    L_HIP, L_KNEE, L_ANKLE = 23, 25, 27
    R_HIP, R_KNEE, R_ANKLE = 24, 26, 28

    left_ok  = visible(lm, L_HIP, L_KNEE, L_ANKLE)
    right_ok = visible(lm, R_HIP, R_KNEE, R_ANKLE)

    if not left_ok and not right_ok:
        return rep_state, ["Can't see legs — step back"], 0.0, {}

    angles_display = {}
    knee_raws = []

    if left_ok:
        la = calculate_angle(_pt(lm, L_HIP), _pt(lm, L_KNEE), _pt(lm, L_ANKLE))
        knee_raws.append(la)
        angles_display["L.Knee"] = la
    if right_ok:
        ra = calculate_angle(_pt(lm, R_HIP), _pt(lm, R_KNEE), _pt(lm, R_ANKLE))
        knee_raws.append(ra)
        angles_display["R.Knee"] = ra

    # Use the LOWER angle (the front/bent knee) for lunge detection
    raw   = min(knee_raws)
    angle = ex_state.smooth("knee", raw)

    feedback = []

    # FIX: relaxed thresholds — lunges naturally go to ~90 degrees
    if angle < 100:
        if rep_state["stage"] != "down":
            rep_state["stage"]      = "down"
            rep_state["start_time"] = time.time()
    elif angle > 150 and rep_state["stage"] == "down":
        if time.time() - rep_state.get("last_rep", 0) > 0.3:
            rep_state["counter"] += 1
            rep_state["stage"]    = "up"
            rep_state["last_rep"] = time.time()

    if angle > 150:
        feedback.append("Step forward and lower ↓")
    elif angle < 70:
        feedback.append("Too low — ease up ⚠")
    else:
        feedback.append("Good lunge depth ✅")

    if left_ok and right_ok:
        if abs(lm[L_KNEE].x - lm[L_ANKLE].x) > 0.08:
            feedback.append("Front knee misaligned ❌")

    feedback.append(check_symmetry(lm))

    if ex_state.stability("knee") > 50:
        feedback.append("Unstable ⚠")

    return rep_state, feedback, angle, angles_display


# ================================================================
# JUMPING JACK
# FIX 1: Visibility threshold lowered (inherited from visible()).
# FIX 2: feet_apart threshold relaxed 0.25→0.18 (camera distance varies).
# FIX 3: feet_close threshold relaxed 0.15→0.20.
# FIX 4: Added partial-match counting — if hands OR feet meet condition,
#         still allow the stage transition (less strict sync requirement).
# FIX 5: Also checks elbow angle to show arm spread feedback.
# ================================================================
def jumpingjack_logic(lm, rep_state: dict, ex_state: ExerciseState):
    L_SHOULDER, R_SHOULDER = 11, 12
    L_ELBOW,    R_ELBOW    = 13, 14
    L_WRIST,    R_WRIST    = 15, 16
    L_HIP,      R_HIP      = 23, 24
    L_ANKLE,    R_ANKLE    = 27, 28

    # Only require shoulders + wrists OR shoulders + ankles — not all 6
    shoulders_ok = visible(lm, L_SHOULDER, R_SHOULDER)
    wrists_ok    = visible(lm, L_WRIST, R_WRIST)
    ankles_ok    = visible(lm, L_ANKLE, R_ANKLE)

    if not shoulders_ok:
        return rep_state, ["Can't see shoulders — step back"], 0.0, {}

    angles_display = {}

    # Arms: angle at shoulder between elbow and hip
    if wrists_ok and visible(lm, L_ELBOW, R_ELBOW):
        l_arm = calculate_angle(_pt(lm, L_ELBOW), _pt(lm, L_SHOULDER), _pt(lm, L_HIP))
        r_arm = calculate_angle(_pt(lm, R_ELBOW), _pt(lm, R_SHOULDER), _pt(lm, R_HIP))
        angles_display["L.Arm"] = l_arm
        angles_display["R.Arm"] = r_arm

    feedback = []

    # --- Determine hand/foot positions ---
    if wrists_ok:
        # FIX: In MediaPipe y increases downward, so wrist.y < shoulder.y = hands UP
        hands_up   = (lm[L_WRIST].y < lm[L_SHOULDER].y - 0.05 and
                      lm[R_WRIST].y < lm[R_SHOULDER].y - 0.05)
        hands_down = (lm[L_WRIST].y > lm[L_SHOULDER].y + 0.05 and
                      lm[R_WRIST].y > lm[R_SHOULDER].y + 0.05)
    else:
        hands_up   = False
        hands_down = True   # assume resting if wrists not visible

    if ankles_ok:
        foot_spread = abs(lm[L_ANKLE].x - lm[R_ANKLE].x)
        # FIX: relaxed thresholds
        feet_apart = foot_spread > 0.18
        feet_close = foot_spread < 0.22
    else:
        feet_apart = False
        feet_close = True   # assume together if ankles not visible

    # --- Stage transitions ---
    # FIX: Use OR logic — either hands up OR feet apart counts as "up" position
    # This handles cases where camera clips feet or wrists momentarily
    if hands_up or feet_apart:
        rep_state["stage"] = "up"
    elif (hands_down or feet_close) and rep_state["stage"] == "up":
        if time.time() - rep_state.get("last_rep", 0) > 0.4:
            rep_state["counter"] += 1
            rep_state["stage"]    = "down"
            rep_state["last_rep"] = time.time()

    # --- Feedback ---
    if hands_up and feet_apart:
        feedback.append("Good form ✅")
    elif hands_up and not feet_apart and ankles_ok:
        feedback.append("Spread legs wider ↔")
    elif feet_apart and not hands_up and wrists_ok:
        feedback.append("Raise arms above head ↑")
    elif not hands_up and not feet_apart:
        feedback.append("Open arms and legs ↑↔")
    else:
        feedback.append("Keep going ✅")

    return rep_state, feedback, 0.0, angles_display


# ================================================================
# PULLUP
# FIX: Returns angles_display. Added shoulder angle for form check.
# ================================================================
def pullup_logic(lm, rep_state: dict, ex_state: ExerciseState):
    NOSE             = 0
    L_SHOULDER       = 11
    R_SHOULDER       = 12
    L_ELBOW          = 13
    R_ELBOW          = 14
    L_WRIST, R_WRIST = 15, 16

    wrists_ok = visible(lm, L_WRIST, R_WRIST)
    nose_ok   = visible(lm, NOSE)

    if not wrists_ok and not nose_ok:
        return rep_state, ["Can't see hands/head — adjust camera"], 0.0, {}

    angles_display = {}

    # Show elbow angles for form feedback
    if visible(lm, L_SHOULDER, L_ELBOW, L_WRIST):
        la = calculate_angle(_pt(lm, L_SHOULDER), _pt(lm, L_ELBOW), _pt(lm, L_WRIST))
        angles_display["L.Elbow"] = la
    if visible(lm, R_SHOULDER, R_ELBOW, R_WRIST):
        ra = calculate_angle(_pt(lm, R_SHOULDER), _pt(lm, R_ELBOW), _pt(lm, R_WRIST))
        angles_display["R.Elbow"] = ra

    if not wrists_ok:
        return rep_state, ["Can't see hands — adjust camera"], 0.0, angles_display

    bar_y = (lm[L_WRIST].y + lm[R_WRIST].y) / 2.0
    feedback = []

    if nose_ok:
        chin = lm[NOSE].y
        if chin < bar_y:
            if rep_state["stage"] != "up":
                rep_state["stage"] = "up"
            feedback.append("Chin above bar ✅")
        elif chin > bar_y and rep_state["stage"] == "up":
            if time.time() - rep_state.get("last_rep", 0) > 0.3:
                rep_state["counter"] += 1
                rep_state["stage"]    = "down"
                rep_state["last_rep"] = time.time()
            feedback.append("Lower to full hang")
        else:
            feedback.append("Pull until chin clears bar ↑")
    else:
        feedback.append("Can't see head — ensure face is visible")

    return rep_state, feedback, 0.0, angles_display


# ================================================================
# WALL PUSHUP
# New exercise — easier pushup variant done standing against a wall.
# Uses elbow angle same as regular pushup but with relaxed thresholds.
# ================================================================
def wallpushup_logic(lm, rep_state: dict, ex_state: ExerciseState):
    L_SHOULDER, L_ELBOW, L_WRIST = 11, 13, 15
    R_SHOULDER, R_ELBOW, R_WRIST = 12, 14, 16

    left_ok  = visible(lm, L_SHOULDER, L_ELBOW, L_WRIST)
    right_ok = visible(lm, R_SHOULDER, R_ELBOW, R_WRIST)

    if not left_ok and not right_ok:
        return rep_state, ["Can't see arms — face the camera"], 0.0, {}

    angles_display = {}
    elbow_raws = []

    if left_ok:
        la = calculate_angle(_pt(lm, L_SHOULDER), _pt(lm, L_ELBOW), _pt(lm, L_WRIST))
        elbow_raws.append(la)
        angles_display["L.Elbow"] = la
    if right_ok:
        ra = calculate_angle(_pt(lm, R_SHOULDER), _pt(lm, R_ELBOW), _pt(lm, R_WRIST))
        elbow_raws.append(ra)
        angles_display["R.Elbow"] = ra

    raw_elbow   = sum(elbow_raws) / len(elbow_raws)
    elbow_angle = ex_state.smooth("elbow", raw_elbow)

    if not ex_state.is_calibrated("elbow"):
        ex_state.calibrate("elbow", elbow_angle)
        n = ex_state.calib_progress("elbow")
        return rep_state, [f"Stand at wall — calibrating ({n}/5)"], elbow_angle, angles_display

    base    = ex_state.baseline("elbow")
    down_th = base - 40   # wall pushups have smaller range of motion
    up_th   = base - 10

    feedback     = []
    rep_complete = False

    if elbow_angle < down_th:
        if rep_state["stage"] != "down":
            rep_state["stage"]      = "down"
            rep_state["start_time"] = time.time()
    elif elbow_angle > up_th and rep_state["stage"] == "down":
        if time.time() - rep_state.get("last_rep", 0) > 0.3:
            rep_state["counter"] += 1
            rep_state["stage"]    = "up"
            rep_state["last_rep"] = time.time()
            rep_complete          = True

    if elbow_angle > up_th:
        feedback.append("Lean into the wall ↓")
    else:
        feedback.append("Good depth ✅")

    if ex_state.stability("elbow") > 40:
        feedback.append("Unstable ⚠")

    if rep_complete and rep_state.get("start_time"):
        duration = time.time() - rep_state["start_time"]
        if duration < 0.8:
            feedback.append("Too fast ⚠")

    return rep_state, feedback, elbow_angle, angles_display


# ================================================================
# BENCH PRESS
# Camera faces user from the side while lying down.
# Tracks elbow angle at chest level.
# ================================================================
def benchpress_logic(lm, rep_state: dict, ex_state: ExerciseState):
    L_SHOULDER, L_ELBOW, L_WRIST = 11, 13, 15
    R_SHOULDER, R_ELBOW, R_WRIST = 12, 14, 16

    left_ok  = visible(lm, L_SHOULDER, L_ELBOW, L_WRIST)
    right_ok = visible(lm, R_SHOULDER, R_ELBOW, R_WRIST)

    if not left_ok and not right_ok:
        return rep_state, ["Can't see arms — position camera to the side"], 0.0, {}

    angles_display = {}
    elbow_raws = []

    if left_ok:
        la = calculate_angle(_pt(lm, L_SHOULDER), _pt(lm, L_ELBOW), _pt(lm, L_WRIST))
        elbow_raws.append(la)
        angles_display["L.Elbow"] = la
    if right_ok:
        ra = calculate_angle(_pt(lm, R_SHOULDER), _pt(lm, R_ELBOW), _pt(lm, R_WRIST))
        elbow_raws.append(ra)
        angles_display["R.Elbow"] = ra

    raw_elbow   = sum(elbow_raws) / len(elbow_raws)
    elbow_angle = ex_state.smooth("elbow", raw_elbow)

    if not ex_state.is_calibrated("elbow"):
        ex_state.calibrate("elbow", elbow_angle)
        n = ex_state.calib_progress("elbow")
        return rep_state, [f"Hold bar up — calibrating ({n}/5)"], elbow_angle, angles_display

    base    = ex_state.baseline("elbow")
    down_th = base - 60
    up_th   = base - 15

    feedback     = []
    rep_complete = False

    if elbow_angle < down_th:
        if rep_state["stage"] != "down":
            rep_state["stage"]      = "down"
            rep_state["start_time"] = time.time()
    elif elbow_angle > up_th and rep_state["stage"] == "down":
        if time.time() - rep_state.get("last_rep", 0) > 0.3:
            rep_state["counter"] += 1
            rep_state["stage"]    = "up"
            rep_state["last_rep"] = time.time()
            rep_complete          = True

    if elbow_angle > up_th:
        feedback.append("Lower the bar ↓")
    else:
        feedback.append("Good range ✅")

    if ex_state.stability("elbow") > 40:
        feedback.append("Unstable ⚠")

    if rep_complete and rep_state.get("start_time"):
        duration = time.time() - rep_state["start_time"]
        if duration < 1.0:
            feedback.append("Too fast ⚠")
        elif duration > 5.0:
            feedback.append("Too slow ⚠")

    return rep_state, feedback, elbow_angle, angles_display