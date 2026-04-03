from collections import deque
import torch


class TemporalBuffer:
    def __init__(self, fps: int = 30, window_seconds: float = 3.33):
        self.fps = fps
        self.window_seconds = window_seconds
        self._maxlen = max(2, int(fps * window_seconds))
        self.buffer = deque(maxlen=self._maxlen)
        self.prediction_history = deque(maxlen=12)

    def set_window(self, seconds: float) -> None:
        new_maxlen = max(2, int(self.fps * seconds))
        self.window_seconds = seconds
        self.buffer = deque(list(self.buffer)[-new_maxlen:], maxlen=new_maxlen)
        self._maxlen = new_maxlen

    def add(self, landmarks: list) -> None:
        if not landmarks or len(landmarks) != 17:
            raise ValueError("landmarks must be list of 17 points")
        self.buffer.append(landmarks)

    def is_ready(self) -> bool:
        return len(self.buffer) == self._maxlen

    def to_tensor(self) -> torch.Tensor:
        if not self.is_ready():
            raise ValueError("buffer not ready")
        arr = torch.zeros((1, 2, self._maxlen, 17), dtype=torch.float32)
        for ti, frame in enumerate(self.buffer):
            for vi, joint in enumerate(frame):
                arr[0, 0, ti, vi] = float(joint["x"])
                arr[0, 1, ti, vi] = float(joint["y"])
        return arr

    def reset(self) -> None:
        self.buffer.clear()
        self.prediction_history.clear()

    def add_prediction(self, model_output: dict) -> None:
        if not model_output:
            return
        class_id = model_output.get("class_id")
        if class_id is None:
            return
        self.prediction_history.append(class_id)
