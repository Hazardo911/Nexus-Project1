import logging
import os
from datetime import datetime, timedelta
from fastapi import FastAPI, Query, Depends, HTTPException, status
from contextlib import asynccontextmanager
from app.core.ai.inference import get_model
from app.core.ai.model import CLASS_NAMES
from app.api.routes import analyze, demo, rehab, summary, stream
from app.services.session_service import get_active_session, stop_session
from app.core.auth import get_password_hash, verify_password, create_access_token, ACCESS_TOKEN_EXPIRE_MINUTES
from app.db import crud, dependencies
from pydantic import BaseModel
from sqlalchemy.orm import Session
from fastapi.middleware.cors import CORSMiddleware

class UserCreate(BaseModel):
    email: str
    password: str
    name: str

class UserLogin(BaseModel):
    email: str
    password: str

logging.basicConfig(level=logging.INFO)

@asynccontextmanager
async def lifespan(app: FastAPI):
    if os.getenv("CI") == "true":
        logging.info("⚡ CI mode: skipping model load")
    else:
        get_model()
        logging.info("Nexus model ready.")
    yield


app = FastAPI(title="Nexus AI Backend", version="2.0.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(analyze.router, prefix="/analyze")
app.include_router(rehab.router, prefix="/rehab")
app.include_router(summary.router, prefix="/summary")
app.include_router(stream.router)
app.include_router(demo.router)


@app.get("/health")
def health():
    return {
        "status": "running",
        "model": "nexus_stgcn_v2",
        "classes": list(CLASS_NAMES.values()),
    }

@app.get("/status")
def get_status(user_id: str = Query("anonymous")):
    active = get_active_session(user_id)
    return {
        "running": active is not None,
        "elapsed_seconds": 0 if not active else (datetime.utcnow() - datetime.fromisoformat(active["start_time"])).total_seconds()
    }

@app.get("/session")
def get_session(user_id: str = Query("anonymous")):
    active = get_active_session(user_id)
    if not active:
        return {"status": "error", "message": "No active session"}
    
    last_record = active.get("last_record", {})
    return {
        "exercise": last_record.get("exercise"),
        "reps": 0,
        "goal": 10,
        "feedback": last_record.get("feedback", []),
        "done": False
    }

@app.post("/stop")
def stop_user_session(user_id: str = Query("anonymous")):
    success = stop_session(user_id)
    return {"status": "success" if success else "not_found"}

@app.post("/start")
def start_session(user_id: str = Query("anonymous"), mode: str = Query("training")):
    # This might be redundant if /stream creates it, but good for REST flow
    from app.services.session_service import create_db_session
    session_id = create_db_session(user_id, mode)
    return {"status": "success", "session_id": session_id}

@app.post("/register")
def register_user(user_in: UserCreate, db: Session = Depends(dependencies.get_db)):
    db_user = crud.get_user_by_email(db, email=user_in.email)
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    
    hashed_pwd = get_password_hash(user_in.password)
    new_user = crud.create_user(db, name=user_in.name, email=user_in.email, password=hashed_pwd)
    
    access_token = create_access_token(data={"sub": new_user.email})
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user_id": str(new_user.id),
        "name": new_user.name
    }

@app.post("/login")
def login_user(user_in: UserLogin, db: Session = Depends(dependencies.get_db)):
    user = crud.get_user_by_email(db, email=user_in.email)
    if not user or not verify_password(user_in.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    access_token = create_access_token(data={"sub": user.email})
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user_id": str(user.id),
        "name": user.name
    }
