import argparse
import asyncio
import json
from pathlib import Path

import cv2
import websockets


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Stream a recorded exercise video to the Nexus backend WebSocket."
    )
    parser.add_argument(
        "video",
        help="Path to the recorded video file you want to test.",
    )
    parser.add_argument(
        "--ws-url",
        default="ws://127.0.0.1:8000/stream",
        help="Backend WebSocket URL.",
    )
    parser.add_argument(
        "--mode",
        choices=["fitness", "rehab"],
        default="fitness",
        help="Pipeline mode to test.",
    )
    parser.add_argument("--user-id", default="test_user", help="User id for the session.")
    parser.add_argument("--injury", default="ACL", help="Rehab injury type.")
    parser.add_argument("--stage", default="early", help="Rehab stage.")
    parser.add_argument(
        "--fps",
        type=int,
        default=30,
        help="FPS value sent to the backend buffer config.",
    )
    parser.add_argument(
        "--window-seconds",
        type=float,
        default=3.33,
        help="Temporal window size sent to the backend.",
    )
    parser.add_argument(
        "--max-frames",
        type=int,
        default=0,
        help="Optional frame limit. Use 0 to send the full video.",
    )
    return parser.parse_args()


async def stream_video(args: argparse.Namespace) -> None:
    video_path = Path(args.video)
    if not video_path.exists():
        raise FileNotFoundError(f"Video not found: {video_path}")

    config = {
        "mode": args.mode,
        "user_id": args.user_id,
        "injury": args.injury,
        "stage": args.stage,
        "fps": args.fps,
        "window_seconds": args.window_seconds,
    }

    cap = cv2.VideoCapture(str(video_path))
    if not cap.isOpened():
        raise RuntimeError(f"Unable to open video: {video_path}")

    print(f"Streaming {video_path} to {args.ws_url}")
    print(f"Config: {json.dumps(config)}")

    try:
        async with websockets.connect(args.ws_url, max_size=10_000_000) as ws:
            await ws.send(json.dumps(config))

            frame_count = 0
            while True:
                ok, frame = cap.read()
                if not ok:
                    print("Video complete.")
                    break

                ok, encoded = cv2.imencode(".jpg", frame)
                if not ok:
                    print(f"frame={frame_count + 1} skipped: jpeg encode failed")
                    continue

                await ws.send(encoded.tobytes())
                response = await ws.recv()

                frame_count += 1
                print(f"frame={frame_count} response={response}")

                if args.max_frames and frame_count >= args.max_frames:
                    print(f"Stopped after {frame_count} frames due to --max-frames.")
                    break
    finally:
        cap.release()


def main() -> None:
    args = parse_args()
    asyncio.run(stream_video(args))


if __name__ == "__main__":
    main()
