# Nexus Backend

Python 3.10 backend for the Nexus STGCN action recognition + rehabilitation pipeline.

## Structure
- `app/` - FastAPI app and business logic
- `nexus_stgcn_v2.pth` - model weights
- `sessions/` - runtime user session logs

## Install
```bash
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
```

## Run
```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

## Endpoints
- POST `/analyze` — fitness mode
- POST `/rehab` — rehab mode
- GET `/summary` — analytics
- WS `/stream` — real-time
- GET `/health`


## Python version

Required: Python 3.10.x (tested on 3.10.11).
Do not use Python 3.11+ (mediapipe + numpy version compatibility issues).

## Setup (PowerShell)

cd "d:\Final Nexus backend"
py -3.10 -m venv .venv
.venv\Scripts\Activate.ps1
python --version  # expect 3.10.11
pip install --upgrade pip
pip install -r requirements.txt