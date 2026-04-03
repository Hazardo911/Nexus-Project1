import json
import os
import subprocess
import sys
import tempfile
import time
from typing import Optional

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

app = FastAPI(title='AI Fitness Coach API')

app.add_middleware(
    CORSMiddleware,
    allow_origins=['*'],
    allow_methods=['*'],
    allow_headers=['*'],
)

STATE_FILE = os.path.join(tempfile.gettempdir(), 'nexus_session_state.json')

_DEFAULT_STATE = {
    'exercise': None,
    'reps': 0,
    'goal': None,
    'stage': None,
    'feedback': [],
    'accuracy': 0.0,
    'angles': {},
    'done': False,
    'started_at': None,
}

_process: subprocess.Popen | None = None
_started_at: float | None = None


class StartSessionRequest(BaseModel):
    exercise: Optional[str] = None
    goal: Optional[int] = None


def _read_state() -> dict:
    try:
        with open(STATE_FILE, 'r') as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return dict(_DEFAULT_STATE)


def _clear_state(exercise: str | None = None, goal: int | None = None):
    state = dict(_DEFAULT_STATE)
    state['started_at'] = time.time()
    state['exercise'] = exercise
    state['goal'] = goal
    try:
        with open(STATE_FILE, 'w') as f:
            json.dump(state, f)
    except OSError:
        pass


@app.get('/')
def home():
    return {
        'message': 'AI Fitness Coach API is running',
        'endpoints': [
            'GET  /exercises',
            'POST /start',
            'POST /stop',
            'GET  /status',
            'GET  /session',
            'GET  /summary',
            'POST /session/reset',
        ]
    }


@app.get('/exercises')
def list_exercises():
    return {
        'exercises': [
            'squat',
            'pushup',
            'lunges',
            'jumpingjack',
            'pullup',
            'wallpushup',
            'benchpress',
        ]
    }


@app.post('/start')
def start_session(payload: StartSessionRequest | None = None):
    global _process, _started_at

    if _process is not None and _process.poll() is None:
        raise HTTPException(status_code=409, detail='Session already running')

    requested_exercise = payload.exercise.lower() if payload and payload.exercise else None
    requested_goal = payload.goal if payload else None

    _clear_state(requested_exercise, requested_goal)
    _started_at = time.time()

    command = [sys.executable, 'realtime.py', '--state-file', STATE_FILE]
    if requested_exercise:
        command.extend(['--exercise', requested_exercise])
    if requested_goal:
        command.extend(['--goal', str(requested_goal)])

    _process = subprocess.Popen(command, stdout=None, stderr=None)
    return {
        'status': 'started',
        'pid': _process.pid,
        'exercise': requested_exercise,
        'goal': requested_goal,
    }


@app.post('/stop')
def stop_session():
    global _process

    if _process is None or _process.poll() is not None:
        raise HTTPException(status_code=404, detail='No session is running')

    _process.terminate()
    try:
        _process.wait(timeout=5)
    except subprocess.TimeoutExpired:
        _process.kill()

    _process = None
    return {'status': 'stopped'}


@app.get('/status')
def get_status():
    running = _process is not None and _process.poll() is None
    elapsed = None
    if running and _started_at:
        elapsed = round(time.time() - _started_at, 1)
    return {
        'running': running,
        'elapsed_seconds': elapsed,
        'pid': _process.pid if running else None,
    }


@app.get('/session')
def get_session():
    state = _read_state()
    if state.get('started_at') is None:
        raise HTTPException(status_code=404, detail='No session data yet - call POST /start first')
    return state


@app.get('/summary')
def get_summary():
    state = _read_state()
    if not state.get('done'):
        raise HTTPException(status_code=404, detail='Session not complete yet - keep going!')
    return {
        'exercise': state.get('exercise'),
        'total_reps': state.get('reps', 0),
        'goal': state.get('goal'),
        'accuracy': state.get('accuracy', 0.0),
        'done': True,
    }


@app.post('/session/reset')
def reset_session():
    existing = _read_state()
    _clear_state(existing.get('exercise'), existing.get('goal'))
    return {'status': 'reset'}

