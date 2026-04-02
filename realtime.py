# import cv2
# import mediapipe as mp
# import numpy as np
# import torch
# import json
# import time
# from collections import deque

# from engine import FitnessEngine


# class STGCN_Lite(torch.nn.Module):
#     def __init__(self, num_class=9):
#         super().__init__()
#         self.bn    = torch.nn.BatchNorm1d(2 * 17)
#         self.conv1 = torch.nn.Sequential(
#             torch.nn.Conv2d(2, 64, kernel_size=(9, 1), padding=(4, 0)),
#             torch.nn.BatchNorm2d(64),
#             torch.nn.ReLU(),
#             torch.nn.MaxPool2d((2, 1)),
#         )
#         self.conv2 = torch.nn.Sequential(
#             torch.nn.Conv2d(64, 128, kernel_size=(1, 3), padding=(0, 1)),
#             torch.nn.BatchNorm2d(128),
#             torch.nn.ReLU(),
#             torch.nn.AdaptiveAvgPool2d(1),
#         )
#         self.fc = torch.nn.Linear(128, num_class)

#     def forward(self, x):
#         N, C, T, V = x.size()
#         x = x.permute(0, 1, 3, 2).contiguous().view(N, C * V, T)
#         x = self.bn(x)
#         x = x.view(N, C, V, T).permute(0, 1, 3, 2).contiguous()
#         x = self.conv1(x)
#         x = self.conv2(x)
#         x = x.view(N, -1)
#         return self.fc(x)


# # ================================================================
# # CONSTANTS
# # ================================================================

# SEQ_LEN         = 40
# DETECTION_DELAY = 15
# CONF_THRESHOLD  = 0.55
# FONT            = cv2.FONT_HERSHEY_SIMPLEX

# # FIX: Added wallpushup and benchpress keys, updated labels
# EXERCISE_KEYS: dict[str, str] = {
#     "1": "squat",
#     "2": "pushup",
#     "3": "lunges",
#     "4": "jumpingjack",
#     "5": "pullup",
#     "6": "wallpushup",
#     "7": "benchpress",
# }

# GOAL_KEYS: dict[str, int] = {
#     "q": 5,
#     "w": 10,
#     "e": 15,
#     "r": 20,
#     "t": 25,
#     "y": 30,
# }

# # FIX: Window size â€” set to 1280x720 so all UI fits comfortably
# WINDOW_W = 1280
# WINDOW_H = 720

# # MediaPipe landmark indices used for joint angle overlay
# # Maps joint name â†’ (point_a, vertex, point_c) for angle calculation display
# JOINT_OVERLAY_INDICES = {
#     "squat":       [(23, 25, 27), (24, 26, 28)],          # L/R knee
#     "pushup":      [(11, 13, 15), (12, 14, 16)],          # L/R elbow
#     "lunges":      [(23, 25, 27), (24, 26, 28)],          # L/R knee
#     "jumpingjack": [(13, 11, 23), (14, 12, 24)],          # L/R shoulder
#     "pullup":      [(11, 13, 15), (12, 14, 16)],          # L/R elbow
#     "wallpushup":  [(11, 13, 15), (12, 14, 16)],          # L/R elbow
#     "benchpress":  [(11, 13, 15), (12, 14, 16)],          # L/R elbow
# }


# # ================================================================
# # UI HELPERS
# # ================================================================

# def put_text(frame, text: str, pos: tuple, scale: float = 0.65,
#              color=(255, 255, 255), thickness: int = 2):
#     # Draw black shadow first for readability on any background
#     cv2.putText(frame, text, (pos[0]+1, pos[1]+1), FONT, scale, (0,0,0), thickness+1)
#     cv2.putText(frame, text, pos, FONT, scale, color, thickness)


# def draw_top_bar(frame, lines: list[tuple]):
#     """Semi-transparent top banner. lines = [(text, color), ...]"""
#     h, w     = frame.shape[:2]
#     banner_h = 36 + len(lines) * 28
#     overlay  = frame.copy()
#     cv2.rectangle(overlay, (0, 0), (w, banner_h), (10, 10, 10), -1)
#     cv2.addWeighted(overlay, 0.6, frame, 0.4, 0, frame)
#     for i, (text, color) in enumerate(lines):
#         put_text(frame, text, (12, 26 + i * 28), color=color)


# def draw_feedback_panel(frame, feedback: list[str]):
#     """
#     FIX: Draw feedback in a right-side panel so it doesn't overlap the pose.
#     """
#     h, w = frame.shape[:2]
#     panel_x = w - 320
#     panel_y = 100
#     panel_w = 310
#     panel_h = 30 + len(feedback) * 30

#     # Semi-transparent background
#     overlay = frame.copy()
#     cv2.rectangle(overlay, (panel_x - 8, panel_y - 8),
#                   (panel_x + panel_w, panel_y + panel_h), (10, 10, 10), -1)
#     cv2.addWeighted(overlay, 0.55, frame, 0.45, 0, frame)

#     put_text(frame, "FORM", (panel_x, panel_y + 2), scale=0.55,
#              color=(180, 180, 180), thickness=1)

#     for i, msg in enumerate(feedback):
#         color = (50, 220, 50) if "âœ…" in msg else \
#                 (0,  120, 255) if "âŒ" in msg else \
#                 (0,  200, 255) if "âš "  in msg else \
#                 (220, 220, 220)
#         put_text(frame, msg, (panel_x, panel_y + 28 + i * 28),
#                  scale=0.58, color=color, thickness=1)


# def draw_angle_on_joint(frame, lm, triplet: tuple, frame_w: int, frame_h: int):
#     """
#     FIX: Draw the angle value next to the vertex joint on the skeleton.
#     triplet = (idx_a, idx_vertex, idx_c)
#     """
#     from exercise_logic import calculate_angle, visible
#     a_idx, v_idx, c_idx = triplet

#     if not visible(lm, a_idx, v_idx, c_idx):
#         return

#     a = [lm[a_idx].x, lm[a_idx].y]
#     v = [lm[v_idx].x, lm[v_idx].y]
#     c = [lm[c_idx].x, lm[c_idx].y]

#     angle = calculate_angle(a, v, c)

#     # Pixel coordinates of vertex
#     px = int(v[0] * frame_w)
#     py = int(v[1] * frame_h)

#     # Offset text slightly so it doesn't overlap the dot
#     offset_x = 12
#     offset_y = -12

#     color = (50, 220, 50)   if angle < 100 else \
#             (0,  200, 255)  if angle < 150 else \
#             (255, 180, 50)

#     # Small filled circle at joint
#     cv2.circle(frame, (px, py), 8, color, -1)
#     put_text(frame, f"{int(angle)}Â°", (px + offset_x, py + offset_y),
#              scale=0.55, color=color, thickness=1)


# def draw_angles_overlay(frame, lm, exercise: str):
#     """Draw angle values for all tracked joints of the current exercise."""
#     if lm is None or exercise not in JOINT_OVERLAY_INDICES:
#         return
#     h, w = frame.shape[:2]
#     for triplet in JOINT_OVERLAY_INDICES[exercise]:
#         draw_angle_on_joint(frame, lm, triplet, w, h)


# def draw_rep_counter(frame, reps: int, goal: int, exercise: str):
#     """Large rep counter in bottom-left."""
#     h, w = frame.shape[:2]

#     # Background box
#     overlay = frame.copy()
#     cv2.rectangle(overlay, (0, h - 120), (200, h), (10, 10, 10), -1)
#     cv2.addWeighted(overlay, 0.65, frame, 0.35, 0, frame)

#     put_text(frame, exercise.upper(), (10, h - 90), scale=0.6,
#              color=(180, 180, 180), thickness=1)
#     rep_color = (50, 220, 50) if (goal and reps >= goal) else (255, 255, 255)
#     put_text(frame, f"{reps} / {goal if goal else '--'}", (10, h - 48),
#              scale=1.4, color=rep_color, thickness=3)


# def draw_progress_bar(frame, reps: int, goal: int):
#     """Progress bar at the very bottom of the frame."""
#     if not goal:
#         return
#     h, w = frame.shape[:2]
#     progress = min(reps / goal, 1.0)
#     bar_w    = int(progress * (w - 20))

#     cv2.rectangle(frame, (10, h - 12), (w - 10, h - 4), (50, 50, 50), -1)
#     color = (50, 200, 50) if progress < 0.8 else (50, 220, 50)
#     cv2.rectangle(frame, (10, h - 12), (10 + bar_w, h - 4), color, -1)


# def draw_summary(frame, summary: dict):
#     h, w  = frame.shape[:2]
#     lines = [
#         (f"Exercise : {summary['exercise'].upper()}", (255, 255, 255)),
#         (f"Total    : {summary['total_reps']} reps",  (255, 255, 255)),
#         (f"Accuracy : {summary['accuracy']}%",         (50, 220, 50)),
#         (f"Good     : {summary['good_reps']}",          (50, 220, 50)),
#         (f"Bad      : {summary['bad_reps']}",           (0,  120, 255)),
#     ]
#     box_h = 50 + len(lines) * 40
#     box_w = 420
#     x0    = (w - box_w) // 2
#     y0    = (h - box_h) // 2

#     overlay = frame.copy()
#     cv2.rectangle(overlay, (x0 - 10, y0 - 10),
#                   (x0 + box_w + 10, y0 + box_h + 10), (15, 15, 15), -1)
#     cv2.addWeighted(overlay, 0.80, frame, 0.20, 0, frame)
#     cv2.rectangle(frame, (x0, y0), (x0 + box_w, y0 + box_h), (80, 80, 80), 1)

#     put_text(frame, "SESSION COMPLETE", (x0 + 80, y0 + 34),
#              scale=0.95, color=(50, 220, 50), thickness=2)
#     for i, (text, color) in enumerate(lines):
#         put_text(frame, text, (x0 + 20, y0 + 76 + i * 40), color=color)

#     put_text(frame, "Press Q to quit  |  1-7 new exercise",
#              (x0 + 30, y0 + box_h - 14), scale=0.52, color=(150, 150, 150))


# def draw_keybinds_hint(frame):
#     """Small hint in top-right corner during tracking."""
#     h, w = frame.shape[:2]
#     hints = ["Q=quit", "1-7=switch"]
#     for i, hint in enumerate(hints):
#         put_text(frame, hint, (w - 160, 30 + i * 22),
#                  scale=0.48, color=(130, 130, 130), thickness=1)


# # ================================================================
# # STATE FILE WRITER
# # ================================================================

# def _write_state(state_file, payload: dict):
#     """Write session snapshot to JSON so main.py FastAPI can read it."""
#     if not state_file:
#         return
#     try:
#         with open(state_file, "w") as f:
#             json.dump(payload, f)
#     except OSError:
#         pass


# # ================================================================
# # MAIN
# # ================================================================

# def main():
#     import argparse
#     parser = argparse.ArgumentParser()
#     parser.add_argument("--state-file", default=None,
#                         help="JSON file path for sharing state with main.py")
#     args        = parser.parse_args()
#     state_file  = args.state_file

#     # --- Load model ---
#     try:
#         with open("label_map.json") as f:
#             LABELS: dict[str, str] = json.load(f)
#         model = STGCN_Lite(num_class=len(LABELS))
#         model.load_state_dict(
#             torch.load("nexus_stgcn_final.pth", map_location="cpu")
#         )
#         model.eval()
#         model_available = True
#         print("[realtime] Model loaded.")
#     except FileNotFoundError:
#         print("[realtime] Model files not found â€” running in manual-select mode.")
#         LABELS          = {}
#         model           = None
#         model_available = False

#     engine    = FitnessEngine()
#     mp_pose   = mp.solutions.pose
#     mp_draw   = mp.solutions.drawing_utils
#     mp_style  = mp.solutions.drawing_styles
#     cap       = cv2.VideoCapture(0)

#     if not cap.isOpened():
#         print("[realtime] Cannot open camera.")
#         return

#     # FIX: Set camera resolution to match display window
#     cap.set(cv2.CAP_PROP_FRAME_WIDTH,  WINDOW_W)
#     cap.set(cv2.CAP_PROP_FRAME_HEIGHT, WINDOW_H)

#     # FIX: Create named window and resize it explicitly
#     cv2.namedWindow("AI Trainer", cv2.WINDOW_NORMAL)
#     cv2.resizeWindow("AI Trainer", WINDOW_W, WINDOW_H)

#     sequence: deque = deque(maxlen=SEQ_LEN)

#     state            = "SELECTING"
#     predicted_label  = None
#     confidence       = 0.0
#     detect_start     = time.time()
#     prediction_made  = False

#     # Custom drawing spec for skeleton â€” thicker lines, bigger joints
#     landmark_spec   = mp_draw.DrawingSpec(color=(0, 255, 120), thickness=2, circle_radius=4)
#     connection_spec = mp_draw.DrawingSpec(color=(255, 255, 255), thickness=2)

#     print("\n[realtime] Starting. Press 1-7 to pick exercise.\n")

#     with mp_pose.Pose(
#         min_detection_confidence=0.5,
#         min_tracking_confidence=0.5,
#         model_complexity=1,       # FIX: use complexity=1 (more accurate than 0)
#     ) as pose:

#         while cap.isOpened():
#             ret, frame = cap.read()
#             if not ret:
#                 break

#             frame = cv2.flip(frame, 1)

#             # FIX: Resize frame to consistent window size regardless of webcam output
#             frame = cv2.resize(frame, (WINDOW_W, WINDOW_H))

#             rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
#             rgb.flags.writeable = False
#             res = pose.process(rgb)
#             rgb.flags.writeable = True

#             lm = None
#             if res.pose_landmarks:
#                 # Draw skeleton with custom style
#                 mp_draw.draw_landmarks(
#                     frame,
#                     res.pose_landmarks,
#                     mp_pose.POSE_CONNECTIONS,
#                     landmark_spec,
#                     connection_spec,
#                 )
#                 lm = res.pose_landmarks.landmark

#                 kp = [[lm[i].x, lm[i].y] for i in range(17)]
#                 sequence.append(kp)

#             # ===========================================================
#             # STATE: SELECTING
#             # ===========================================================
#             if state == "SELECTING":
#                 if (model_available
#                         and len(sequence) == SEQ_LEN
#                         and not prediction_made
#                         and time.time() - detect_start > DETECTION_DELAY):

#                     data = np.array(sequence).transpose(2, 0, 1).astype(np.float32)
#                     data[0] -= data[0, :, 0:1]
#                     data[1] -= data[1, :, 0:1]
#                     data /= (np.abs(data).max() + 1e-6)

#                     tensor = torch.tensor(data).unsqueeze(0)
#                     with torch.no_grad():
#                         probs = torch.softmax(model(tensor), dim=1)
#                     pred_idx        = probs.argmax(dim=1).item()
#                     confidence      = probs[0][pred_idx].item()
#                     predicted_label = LABELS[str(pred_idx)]
#                     prediction_made = True
#                     print(f"[model] {predicted_label} ({confidence:.2f})")

#                 from engine import UNSUPPORTED
#                 lines = []
#                 if predicted_label and predicted_label in UNSUPPORTED:
#                     # Model detected cleanandjerk / handstandpushup â€” no logic available
#                     lines.append((
#                         f"Detected: {predicted_label.upper()} (no tracker yet) â€” pick manually below",
#                         (0, 165, 255)
#                     ))
#                 elif predicted_label and confidence >= CONF_THRESHOLD:
#                     lines.append((
#                         f"Detected: {predicted_label.upper()} ({confidence:.0%})  â€” press Y to confirm",
#                         (50, 220, 50)
#                     ))
#                 elif predicted_label:
#                     lines.append((
#                         f"Low confidence: {predicted_label} ({confidence:.0%}) â€” pick manually",
#                         (0, 165, 255)
#                     ))
#                 else:
#                     elapsed   = int(time.time() - detect_start)
#                     remaining = max(0, DETECTION_DELAY - elapsed)
#                     if remaining > 0:
#                         lines.append((f"Do a few reps to detect... ({remaining}s)", (180, 180, 180)))
#                     else:
#                         lines.append(("Pick an exercise:", (200, 200, 200)))

#                 # FIX: Split into two lines so all exercises fit on screen
#                 lines.append(("1-Squat  2-Pushup  3-Lunges  4-JumpingJack", (160, 160, 160)))
#                 lines.append(("5-Pullup  6-WallPushup  7-BenchPress", (160, 160, 160)))
#                 draw_top_bar(frame, lines)

#                 key = cv2.waitKey(10) & 0xFF

#                 if key == ord("y") and predicted_label and confidence >= CONF_THRESHOLD:
#                     ok = engine.set_exercise(predicted_label)
#                     if ok:
#                         state = "SETTING_GOAL"

#                 elif key != 255 and chr(key) in EXERCISE_KEYS:
#                     chosen = EXERCISE_KEYS[chr(key)]
#                     ok = engine.set_exercise(chosen)
#                     if ok:
#                         state = "SETTING_GOAL"

#                 elif key == ord("q"):
#                     break

#                 cv2.imshow("AI Trainer", frame)
#                 continue

#             # ===========================================================
#             # STATE: SETTING_GOAL
#             # ===========================================================
#             if state == "SETTING_GOAL":
#                 lines = [
#                     (f"Exercise: {engine.current_exercise.upper()}", (255, 255, 255)),
#                     ("Set target reps:", (200, 200, 200)),
#                     ("Q=5  W=10  E=15  R=20  T=25  Y=30", (160, 160, 160)),
#                 ]
#                 draw_top_bar(frame, lines)

#                 key      = cv2.waitKey(10) & 0xFF
#                 key_char = chr(key) if key != 255 else ""

#                 if key_char in GOAL_KEYS:
#                     engine.set_goal(GOAL_KEYS[key_char])
#                     print(f"[session] {engine.current_exercise} | goal: {GOAL_KEYS[key_char]} reps")
#                     state = "TRACKING"
#                 elif key == ord("q"):
#                     break

#                 cv2.imshow("AI Trainer", frame)
#                 continue

#             # ===========================================================
#             # STATE: TRACKING
#             # ===========================================================
#             if state == "TRACKING":
#                 result = None

#                 if lm is not None:
#                     result = engine.process(lm)

#                 if result:
#                     reps     = result["reps"]
#                     goal     = result["goal"]
#                     exercise = result["exercise"]
#                     feedback = result["feedback"]

#                     # Write live state so main.py /session stays fresh
#                     summary_now = engine.get_summary()
#                     _write_state(state_file, {
#                         "exercise":   exercise,
#                         "reps":       reps,
#                         "goal":       goal,
#                         "stage":      result.get("stage"),
#                         "feedback":   feedback,
#                         "accuracy":   summary_now["accuracy"],
#                         "angles":     result.get("angles", {}),
#                         "done":       result["done"],
#                         "started_at": time.time(),
#                     })

#                     # Draw angle values directly on skeleton joints
#                     draw_angles_overlay(frame, lm, exercise)

#                     # Rep counter (bottom-left)
#                     draw_rep_counter(frame, reps, goal, exercise)

#                     # Feedback panel (right side)
#                     draw_feedback_panel(frame, feedback)

#                     # Progress bar (bottom strip)
#                     draw_progress_bar(frame, reps, goal)

#                     # Keybind hint (top-right)
#                     draw_keybinds_hint(frame)

#                     if result["done"]:
#                         state = "DONE"
#                 else:
#                     # FIX: Only show "no pose" message â€” never hard-block
#                     put_text(frame, "Adjusting pose detection...", (10, 50),
#                              scale=0.65, color=(0, 180, 255))

#                 key = cv2.waitKey(10) & 0xFF
#                 if key == ord("q"):
#                     break
#                 elif key != 255 and chr(key) in EXERCISE_KEYS:
#                     chosen = EXERCISE_KEYS[chr(key)]
#                     if engine.set_exercise(chosen):
#                         state = "SETTING_GOAL"

#                 cv2.imshow("AI Trainer", frame)
#                 continue

#             # ===========================================================
#             # STATE: DONE
#             # ===========================================================
#             if state == "DONE":
#                 summary = engine.get_summary()
#                 print("\n[session] Summary:", summary)
#                 _write_state(state_file, {
#                     "exercise":   summary["exercise"],
#                     "reps":       summary["total_reps"],
#                     "goal":       engine.goal,
#                     "stage":      "done",
#                     "feedback":   ["Session complete âœ…"],
#                     "accuracy":   summary["accuracy"],
#                     "angles":     {},
#                     "done":       True,
#                     "started_at": time.time(),
#                 })
#                 draw_summary(frame, summary)
#                 cv2.imshow("AI Trainer", frame)

#                 key = cv2.waitKey(10) & 0xFF
#                 if key == ord("q"):
#                     break
#                 elif key != 255 and chr(key) in EXERCISE_KEYS:
#                     chosen = EXERCISE_KEYS[chr(key)]
#                     if engine.set_exercise(chosen):
#                         prediction_made = False
#                         predicted_label = None
#                         sequence.clear()
#                         detect_start    = time.time()
#                         state           = "SETTING_GOAL"

#     cap.release()
#     cv2.destroyAllWindows()


# if __name__ == "__main__":
#     main()

import cv2
import mediapipe as mp
import numpy as np
import torch
import json
import time
from collections import deque

from engine import FitnessEngine


class STGCN_Lite(torch.nn.Module):
    def __init__(self, num_class=9):
        super().__init__()
        self.bn    = torch.nn.BatchNorm1d(2 * 17)
        self.conv1 = torch.nn.Sequential(
            torch.nn.Conv2d(2, 64, kernel_size=(9, 1), padding=(4, 0)),
            torch.nn.BatchNorm2d(64),
            torch.nn.ReLU(),
            torch.nn.MaxPool2d((2, 1)),
        )
        self.conv2 = torch.nn.Sequential(
            torch.nn.Conv2d(64, 128, kernel_size=(1, 3), padding=(0, 1)),
            torch.nn.BatchNorm2d(128),
            torch.nn.ReLU(),
            torch.nn.AdaptiveAvgPool2d(1),
        )
        self.fc = torch.nn.Linear(128, num_class)

    def forward(self, x):
        N, C, T, V = x.size()
        x = x.permute(0, 1, 3, 2).contiguous().view(N, C * V, T)
        x = self.bn(x)
        x = x.view(N, C, V, T).permute(0, 1, 3, 2).contiguous()
        x = self.conv1(x)
        x = self.conv2(x)
        x = x.view(N, -1)
        return self.fc(x)


# ================================================================
# CONSTANTS
# ================================================================

SEQ_LEN         = 40
DETECTION_DELAY = 15
CONF_THRESHOLD  = 0.70   # raised â€” model is unreliable at low confidence
FONT            = cv2.FONT_HERSHEY_SIMPLEX

# FIX: Added wallpushup and benchpress keys, updated labels
EXERCISE_KEYS: dict[str, str] = {
    "1": "squat",
    "2": "pushup",
    "3": "lunges",
    "4": "jumpingjack",
    "5": "pullup",
    "6": "wallpushup",
    "7": "benchpress",
}

GOAL_KEYS: dict[str, int] = {
    "q": 5,
    "w": 10,
    "e": 15,
    "r": 20,
    "t": 25,
    "y": 30,
}

# FIX: Window size â€” set to 1280x720 so all UI fits comfortably
WINDOW_W = 1280
WINDOW_H = 720

# MediaPipe landmark indices used for joint angle overlay
# Maps joint name â†’ (point_a, vertex, point_c) for angle calculation display
JOINT_OVERLAY_INDICES = {
    "squat":       [(23, 25, 27), (24, 26, 28)],          # L/R knee
    "pushup":      [(11, 13, 15), (12, 14, 16)],          # L/R elbow
    "lunges":      [(23, 25, 27), (24, 26, 28)],          # L/R knee
    "jumpingjack": [(13, 11, 23), (14, 12, 24)],          # L/R shoulder
    "pullup":      [(11, 13, 15), (12, 14, 16)],          # L/R elbow
    "wallpushup":  [(11, 13, 15), (12, 14, 16)],          # L/R elbow
    "benchpress":  [(11, 13, 15), (12, 14, 16)],          # L/R elbow
}


# ================================================================
# UI HELPERS
# ================================================================

def put_text(frame, text: str, pos: tuple, scale: float = 0.65,
             color=(255, 255, 255), thickness: int = 2):
    # Draw black shadow first for readability on any background
    cv2.putText(frame, text, (pos[0]+1, pos[1]+1), FONT, scale, (0,0,0), thickness+1)
    cv2.putText(frame, text, pos, FONT, scale, color, thickness)


def draw_top_bar(frame, lines: list[tuple]):
    """Semi-transparent top banner. lines = [(text, color), ...]"""
    h, w     = frame.shape[:2]
    banner_h = 36 + len(lines) * 28
    overlay  = frame.copy()
    cv2.rectangle(overlay, (0, 0), (w, banner_h), (10, 10, 10), -1)
    cv2.addWeighted(overlay, 0.6, frame, 0.4, 0, frame)
    for i, (text, color) in enumerate(lines):
        put_text(frame, text, (12, 26 + i * 28), color=color)


def draw_feedback_panel(frame, feedback: list[str]):
    """
    FIX: Draw feedback in a right-side panel so it doesn't overlap the pose.
    """
    h, w = frame.shape[:2]
    panel_x = w - 320
    panel_y = 100
    panel_w = 310
    panel_h = 30 + len(feedback) * 30

    # Semi-transparent background
    overlay = frame.copy()
    cv2.rectangle(overlay, (panel_x - 8, panel_y - 8),
                  (panel_x + panel_w, panel_y + panel_h), (10, 10, 10), -1)
    cv2.addWeighted(overlay, 0.55, frame, 0.45, 0, frame)

    put_text(frame, "FORM", (panel_x, panel_y + 2), scale=0.55,
             color=(180, 180, 180), thickness=1)

    for i, msg in enumerate(feedback):
        color = (50, 220, 50) if "âœ…" in msg else \
                (0,  120, 255) if "âŒ" in msg else \
                (0,  200, 255) if "âš "  in msg else \
                (220, 220, 220)
        put_text(frame, msg, (panel_x, panel_y + 28 + i * 28),
                 scale=0.58, color=color, thickness=1)


def draw_angle_on_joint(frame, lm, triplet: tuple, frame_w: int, frame_h: int):
    """
    FIX: Draw the angle value next to the vertex joint on the skeleton.
    triplet = (idx_a, idx_vertex, idx_c)
    """
    from exercise_logic import calculate_angle, visible
    a_idx, v_idx, c_idx = triplet

    if not visible(lm, a_idx, v_idx, c_idx):
        return

    a = [lm[a_idx].x, lm[a_idx].y]
    v = [lm[v_idx].x, lm[v_idx].y]
    c = [lm[c_idx].x, lm[c_idx].y]

    angle = calculate_angle(a, v, c)

    # Pixel coordinates of vertex
    px = int(v[0] * frame_w)
    py = int(v[1] * frame_h)

    # Offset text slightly so it doesn't overlap the dot
    offset_x = 12
    offset_y = -12

    color = (50, 220, 50)   if angle < 100 else \
            (0,  200, 255)  if angle < 150 else \
            (255, 180, 50)

    # Small filled circle at joint
    cv2.circle(frame, (px, py), 8, color, -1)
    put_text(frame, f"{int(angle)}Â°", (px + offset_x, py + offset_y),
             scale=0.55, color=color, thickness=1)


def draw_angles_overlay(frame, lm, exercise: str):
    """Draw angle values for all tracked joints of the current exercise."""
    if lm is None or exercise not in JOINT_OVERLAY_INDICES:
        return
    h, w = frame.shape[:2]
    for triplet in JOINT_OVERLAY_INDICES[exercise]:
        draw_angle_on_joint(frame, lm, triplet, w, h)


def draw_rep_counter(frame, reps: int, goal: int, exercise: str):
    """Large rep counter in bottom-left."""
    h, w = frame.shape[:2]

    # Background box
    overlay = frame.copy()
    cv2.rectangle(overlay, (0, h - 120), (200, h), (10, 10, 10), -1)
    cv2.addWeighted(overlay, 0.65, frame, 0.35, 0, frame)

    put_text(frame, exercise.upper(), (10, h - 90), scale=0.6,
             color=(180, 180, 180), thickness=1)
    rep_color = (50, 220, 50) if (goal and reps >= goal) else (255, 255, 255)
    put_text(frame, f"{reps} / {goal if goal else '--'}", (10, h - 48),
             scale=1.4, color=rep_color, thickness=3)


def draw_progress_bar(frame, reps: int, goal: int):
    """Progress bar at the very bottom of the frame."""
    if not goal:
        return
    h, w = frame.shape[:2]
    progress = min(reps / goal, 1.0)
    bar_w    = int(progress * (w - 20))

    cv2.rectangle(frame, (10, h - 12), (w - 10, h - 4), (50, 50, 50), -1)
    color = (50, 200, 50) if progress < 0.8 else (50, 220, 50)
    cv2.rectangle(frame, (10, h - 12), (10 + bar_w, h - 4), color, -1)


def draw_summary(frame, summary: dict):
    h, w  = frame.shape[:2]
    lines = [
        (f"Exercise : {summary['exercise'].upper()}", (255, 255, 255)),
        (f"Total    : {summary['total_reps']} reps",  (255, 255, 255)),
        (f"Accuracy : {summary['accuracy']}%",         (50, 220, 50)),
        (f"Good     : {summary['good_reps']}",          (50, 220, 50)),
        (f"Bad      : {summary['bad_reps']}",           (0,  120, 255)),
    ]
    box_h = 50 + len(lines) * 40
    box_w = 420
    x0    = (w - box_w) // 2
    y0    = (h - box_h) // 2

    overlay = frame.copy()
    cv2.rectangle(overlay, (x0 - 10, y0 - 10),
                  (x0 + box_w + 10, y0 + box_h + 10), (15, 15, 15), -1)
    cv2.addWeighted(overlay, 0.80, frame, 0.20, 0, frame)
    cv2.rectangle(frame, (x0, y0), (x0 + box_w, y0 + box_h), (80, 80, 80), 1)

    put_text(frame, "SESSION COMPLETE", (x0 + 80, y0 + 34),
             scale=0.95, color=(50, 220, 50), thickness=2)
    for i, (text, color) in enumerate(lines):
        put_text(frame, text, (x0 + 20, y0 + 76 + i * 40), color=color)

    put_text(frame, "Press Q to quit  |  1-7 new exercise",
             (x0 + 30, y0 + box_h - 14), scale=0.52, color=(150, 150, 150))


def draw_keybinds_hint(frame):
    """Small hint in top-right corner during tracking."""
    h, w = frame.shape[:2]
    hints = ["Q=quit", "1-7=switch"]
    for i, hint in enumerate(hints):
        put_text(frame, hint, (w - 160, 30 + i * 22),
                 scale=0.48, color=(130, 130, 130), thickness=1)


# ================================================================
# STATE FILE WRITER
# ================================================================

def _write_state(state_file, payload: dict):
    """Write session snapshot to JSON so main.py FastAPI can read it."""
    if not state_file:
        return
    try:
        with open(state_file, "w") as f:
            json.dump(payload, f)
    except OSError:
        pass


# ================================================================
# MAIN
# ================================================================

def main():
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--state-file", default=None,
                        help="JSON file path for sharing state with main.py")
    parser.add_argument("--exercise", default=None,
                        help="Optional exercise to preselect before opening the camera loop")
    parser.add_argument("--goal", type=int, default=None,
                        help="Optional rep goal to prefill before tracking")
    args        = parser.parse_args()
    state_file  = args.state_file

    # --- Load model ---
    try:
        with open("label_map.json") as f:
            LABELS: dict[str, str] = json.load(f)
        model = STGCN_Lite(num_class=len(LABELS))
        model.load_state_dict(
            torch.load("nexus_stgcn_final.pth", map_location="cpu")
        )
        model.eval()
        model_available = True
        print("[realtime] Model loaded.")
    except FileNotFoundError:
        print("[realtime] Model files not found â€” running in manual-select mode.")
        LABELS          = {}
        model           = None
        model_available = False

    engine    = FitnessEngine()
    requested_exercise = args.exercise.lower() if args.exercise else None
    requested_goal = args.goal if args.goal and args.goal > 0 else None
    mp_pose   = mp.solutions.pose
    mp_draw   = mp.solutions.drawing_utils
    mp_style  = mp.solutions.drawing_styles
    cap       = cv2.VideoCapture(0)

    if not cap.isOpened():
        print("[realtime] Cannot open camera.")
        return

    # FIX: Set camera resolution to match display window
    cap.set(cv2.CAP_PROP_FRAME_WIDTH,  WINDOW_W)
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, WINDOW_H)

    # FIX: Create named window and resize it explicitly
    cv2.namedWindow("AI Trainer", cv2.WINDOW_NORMAL)
    cv2.resizeWindow("AI Trainer", WINDOW_W, WINDOW_H)

    sequence: deque = deque(maxlen=SEQ_LEN)

    state            = "SELECTING"
    if requested_exercise:
        ok = engine.set_exercise(requested_exercise)
        if ok:
            state = "TRACKING" if requested_goal else "SETTING_GOAL"
            if requested_goal:
                engine.set_goal(requested_goal)
                print(f"[session] preselected {requested_exercise} | goal: {requested_goal} reps")
            else:
                print(f"[session] preselected {requested_exercise} | waiting for goal")
        else:
            print(f"[session] unable to preselect exercise: {requested_exercise}")
    predicted_label  = None
    confidence       = 0.0
    detect_start     = time.time()
    prediction_made  = False

    # Custom drawing spec for skeleton â€” thicker lines, bigger joints
    landmark_spec   = mp_draw.DrawingSpec(color=(0, 255, 120), thickness=2, circle_radius=4)
    connection_spec = mp_draw.DrawingSpec(color=(255, 255, 255), thickness=2)

    print("\n[realtime] Starting. Press 1-7 to pick exercise.\n")

    with mp_pose.Pose(
        min_detection_confidence=0.5,
        min_tracking_confidence=0.5,
        model_complexity=1,       # FIX: use complexity=1 (more accurate than 0)
    ) as pose:

        while cap.isOpened():
            ret, frame = cap.read()
            if not ret:
                break

            frame = cv2.flip(frame, 1)

            # FIX: Resize frame to consistent window size regardless of webcam output
            frame = cv2.resize(frame, (WINDOW_W, WINDOW_H))

            rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            rgb.flags.writeable = False
            res = pose.process(rgb)
            rgb.flags.writeable = True

            lm = None
            if res.pose_landmarks:
                # Draw skeleton with custom style
                mp_draw.draw_landmarks(
                    frame,
                    res.pose_landmarks,
                    mp_pose.POSE_CONNECTIONS,
                    landmark_spec,
                    connection_spec,
                )
                lm = res.pose_landmarks.landmark

                kp = [[lm[i].x, lm[i].y] for i in range(17)]
                sequence.append(kp)

            # ===========================================================
            # STATE: SELECTING
            # ===========================================================
            if state == "SELECTING":
                if (model_available
                        and len(sequence) == SEQ_LEN
                        and not prediction_made
                        and time.time() - detect_start > DETECTION_DELAY):

                    data = np.array(sequence).transpose(2, 0, 1).astype(np.float32)
                    data[0] -= data[0, :, 0:1]
                    data[1] -= data[1, :, 0:1]
                    data /= (np.abs(data).max() + 1e-6)

                    tensor = torch.tensor(data).unsqueeze(0)
                    with torch.no_grad():
                        probs = torch.softmax(model(tensor), dim=1)

                    # -------------------------------------------------------
                    # FIX: Suppress unreliable classes that the model
                    # over-predicts (handstandpushup, cleanandjerk).
                    # Zero out their probability before picking the winner â€”
                    # they remain in the model output but can never be chosen.
                    # -------------------------------------------------------
                    SUPPRESSED_LABELS = {"handstandpushup", "cleanandjerk"}
                    for idx_str, lbl in LABELS.items():
                        if lbl in SUPPRESSED_LABELS:
                            probs[0][int(idx_str)] = 0.0

                    # Re-normalise so probabilities still sum to 1
                    prob_sum = probs[0].sum()
                    if prob_sum > 0:
                        probs[0] /= prob_sum

                    # FIX: Vote across 3 shifted windows â€” only accept a label
                    # if it wins in at least 2 out of 3 windows.
                    # This kills one-frame flukes that used to dominate.
                    votes = []
                    seq_list = list(sequence)
                    for shift in [0, SEQ_LEN // 4, SEQ_LEN // 2]:
                        window = seq_list[shift:shift + SEQ_LEN]
                        if len(window) < SEQ_LEN:
                            window = seq_list  # fallback to full window
                        d = np.array(window).transpose(2, 0, 1).astype(np.float32)
                        d[0] -= d[0, :, 0:1]
                        d[1] -= d[1, :, 0:1]
                        d /= (np.abs(d).max() + 1e-6)
                        t = torch.tensor(d).unsqueeze(0)
                        with torch.no_grad():
                            p = torch.softmax(model(t), dim=1)
                        for idx_str, lbl in LABELS.items():
                            if lbl in SUPPRESSED_LABELS:
                                p[0][int(idx_str)] = 0.0
                        p[0] /= (p[0].sum() + 1e-9)
                        votes.append(LABELS[str(p.argmax(dim=1).item())])

                    # Majority vote
                    from collections import Counter
                    vote_counts    = Counter(votes)
                    top_label, top_count = vote_counts.most_common(1)[0]

                    pred_idx        = probs.argmax(dim=1).item()
                    confidence      = probs[0][pred_idx].item()

                    # Only accept prediction if majority vote agrees
                    if top_count >= 2 and top_label == LABELS[str(pred_idx)]:
                        predicted_label = top_label
                    elif top_count >= 2:
                        # Votes converged on something different from single-pass
                        predicted_label = top_label
                        confidence      = 0.45   # treat as low-confidence suggestion
                    else:
                        # No majority â€” ask user to pick manually
                        predicted_label = None
                        confidence      = 0.0

                    prediction_made = True
                    print(f"[model] votes={votes} â†’ {predicted_label} ({confidence:.2f})")

                from engine import UNSUPPORTED
                lines = []
                if predicted_label and predicted_label in UNSUPPORTED:
                    # Model detected cleanandjerk / handstandpushup â€” no logic available
                    lines.append((
                        f"Detected: {predicted_label.upper()} (no tracker yet) â€” pick manually below",
                        (0, 165, 255)
                    ))
                elif predicted_label and confidence >= CONF_THRESHOLD:
                    lines.append((
                        f"Detected: {predicted_label.upper()} ({confidence:.0%})  â€” press Y to confirm",
                        (50, 220, 50)
                    ))
                elif predicted_label:
                    lines.append((
                        f"Low confidence: {predicted_label} ({confidence:.0%}) â€” pick manually",
                        (0, 165, 255)
                    ))
                else:
                    elapsed   = int(time.time() - detect_start)
                    remaining = max(0, DETECTION_DELAY - elapsed)
                    if remaining > 0:
                        lines.append((f"Do a few reps to detect... ({remaining}s)", (180, 180, 180)))
                    else:
                        lines.append(("Pick an exercise:", (200, 200, 200)))

                # FIX: Split into two lines so all exercises fit on screen
                lines.append(("1-Squat  2-Pushup  3-Lunges  4-JumpingJack", (160, 160, 160)))
                lines.append(("5-Pullup  6-WallPushup  7-BenchPress", (160, 160, 160)))
                draw_top_bar(frame, lines)

                key = cv2.waitKey(10) & 0xFF

                if key == ord("y") and predicted_label and confidence >= CONF_THRESHOLD:
                    ok = engine.set_exercise(predicted_label)
                    if ok:
                        state = "SETTING_GOAL"

                elif key != 255 and chr(key) in EXERCISE_KEYS:
                    chosen = EXERCISE_KEYS[chr(key)]
                    ok = engine.set_exercise(chosen)
                    if ok:
                        state = "SETTING_GOAL"

                elif key == ord("q"):
                    break

                cv2.imshow("AI Trainer", frame)
                continue

            # ===========================================================
            # STATE: SETTING_GOAL
            # ===========================================================
            if state == "SETTING_GOAL":
                lines = [
                    (f"Exercise: {engine.current_exercise.upper()}", (255, 255, 255)),
                    ("Set target reps:", (200, 200, 200)),
                    ("Q=5  W=10  E=15  R=20  T=25  Y=30", (160, 160, 160)),
                ]
                draw_top_bar(frame, lines)

                key      = cv2.waitKey(10) & 0xFF
                key_char = chr(key) if key != 255 else ""

                if key_char in GOAL_KEYS:
                    engine.set_goal(GOAL_KEYS[key_char])
                    print(f"[session] {engine.current_exercise} | goal: {GOAL_KEYS[key_char]} reps")
                    state = "TRACKING"
                elif key == ord("q"):
                    break

                cv2.imshow("AI Trainer", frame)
                continue

            # ===========================================================
            # STATE: TRACKING
            # ===========================================================
            if state == "TRACKING":
                result = None

                if lm is not None:
                    result = engine.process(lm)

                if result:
                    reps     = result["reps"]
                    goal     = result["goal"]
                    exercise = result["exercise"]
                    feedback = result["feedback"]

                    # Write live state so main.py /session stays fresh
                    summary_now = engine.get_summary()
                    _write_state(state_file, {
                        "exercise":   exercise,
                        "reps":       reps,
                        "goal":       goal,
                        "stage":      result.get("stage"),
                        "feedback":   feedback,
                        "accuracy":   summary_now["accuracy"],
                        "angles":     result.get("angles", {}),
                        "done":       result["done"],
                        "started_at": time.time(),
                    })

                    # Draw angle values directly on skeleton joints
                    draw_angles_overlay(frame, lm, exercise)

                    # Rep counter (bottom-left)
                    draw_rep_counter(frame, reps, goal, exercise)

                    # Feedback panel (right side)
                    draw_feedback_panel(frame, feedback)

                    # Progress bar (bottom strip)
                    draw_progress_bar(frame, reps, goal)

                    # Keybind hint (top-right)
                    draw_keybinds_hint(frame)

                    if result["done"]:
                        state = "DONE"
                else:
                    # FIX: Only show "no pose" message â€” never hard-block
                    put_text(frame, "Adjusting pose detection...", (10, 50),
                             scale=0.65, color=(0, 180, 255))

                key = cv2.waitKey(10) & 0xFF
                if key == ord("q"):
                    break
                elif key != 255 and chr(key) in EXERCISE_KEYS:
                    chosen = EXERCISE_KEYS[chr(key)]
                    if engine.set_exercise(chosen):
                        state = "SETTING_GOAL"

                cv2.imshow("AI Trainer", frame)
                continue

            # ===========================================================
            # STATE: DONE
            # ===========================================================
            if state == "DONE":
                summary = engine.get_summary()
                print("\n[session] Summary:", summary)
                _write_state(state_file, {
                    "exercise":   summary["exercise"],
                    "reps":       summary["total_reps"],
                    "goal":       engine.goal,
                    "stage":      "done",
                    "feedback":   ["Session complete âœ…"],
                    "accuracy":   summary["accuracy"],
                    "angles":     {},
                    "done":       True,
                    "started_at": time.time(),
                })
                draw_summary(frame, summary)
                cv2.imshow("AI Trainer", frame)

                key = cv2.waitKey(10) & 0xFF
                if key == ord("q"):
                    break
                elif key != 255 and chr(key) in EXERCISE_KEYS:
                    chosen = EXERCISE_KEYS[chr(key)]
                    if engine.set_exercise(chosen):
                        prediction_made = False
                        predicted_label = None
                        sequence.clear()
                        detect_start    = time.time()
                        state           = "SETTING_GOAL"

    cap.release()
    cv2.destroyAllWindows()


if __name__ == "__main__":
    main()








