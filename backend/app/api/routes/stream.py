import json
import logging
import cv2
import numpy as np
from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from app.utils.temporal_buffer import TemporalBuffer
from app.services.analysis_service import analysis_service
from app.services.rehab_service import rehab_service

router = APIRouter()

@router.websocket("/stream")
async def stream(websocket: WebSocket):
    await websocket.accept()
    buffer = None

    try:
        config = json.loads(await websocket.receive_text())
        mode = config.get("mode")
        user_id = config.get("user_id", "anonymous")
        selected_exercise = config.get("selected_exercise")
        if mode not in {"fitness", "rehab"}:
            await websocket.send_json({"status": "error", "message": "mode must be 'fitness' or 'rehab'"})
            return

        fps = int(config.get("fps", 30))
        window_seconds = float(config.get("window_seconds", 3.33))
        buffer = TemporalBuffer(fps=fps, window_seconds=window_seconds)

        while True:
            message = await websocket.receive_bytes()
            try:
                arr = np.frombuffer(message, np.uint8)
                frame = cv2.imdecode(arr, cv2.IMREAD_COLOR)
                if frame is None:
                    await websocket.send_json({"status": "error", "message": "invalid image bytes"})
                    continue

                if mode == "fitness":
                    result = analysis_service(frame, buffer, user_id, selected_exercise)
                else:
                    injury = config.get("injury", "ACL")
                    stage = config.get("stage", "early")
                    result = rehab_service(frame, buffer, user_id, injury, stage, selected_exercise)

                await websocket.send_json(result)
            except Exception as exc:
                logging.exception("stream frame error")
                await websocket.send_json({"status": "error", "message": str(exc)})
    except WebSocketDisconnect:
        logging.info("stream disconnected")
    except Exception:
        logging.exception("stream connect error")
    finally:
        try:
            await websocket.close()
        except Exception:
            pass
