from sqlalchemy.orm import Session
from . import models
import uuid
from datetime import datetime

def get_user_by_email(db: Session, email: str):
    return db.query(models.User).filter(models.User.email == email).first()

def create_user(db: Session, name: str, email: str, password: str = None):
    # This will be called with hashed_password from the auth logic
    db_user = models.User(name=name, email=email, hashed_password=password)
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

def create_session(db: Session, user_id: str, mode: str):
    uid = uuid.UUID(user_id) if isinstance(user_id, str) else user_id
    db_session = models.Session(user_id=uid, mode=mode)
    db.add(db_session)
    db.commit()
    db.refresh(db_session)
    return db_session

def insert_training_session(db: Session, session_id: str, score: float, symmetry: float, stability: float, speed: float, feedback: str):
    sid = uuid.UUID(session_id) if isinstance(session_id, str) else session_id
    db_training = models.TrainingSession(
        session_id=sid,
        score=score,
        symmetry=symmetry,
        stability=stability,
        speed=speed,
        feedback=feedback
    )
    db.add(db_training)
    db.commit()
    db.refresh(db_training)
    return db_training

def insert_rehab_session(db: Session, session_id: str, injury_type: str, stage: str, score: float, safety: float, rom: float, stability: float, decision: str, feedback: str):
    sid = uuid.UUID(session_id) if isinstance(session_id, str) else session_id
    db_rehab = models.RehabSession(
        session_id=sid,
        injury_type=injury_type,
        stage=stage,
        score=score,
        safety=safety,
        rom=rom,
        stability=stability,
        decision=decision,
        feedback=feedback
    )
    db.add(db_rehab)
    db.commit()
    db.refresh(db_rehab)
    return db_rehab

def insert_movement_metric(db: Session, session_id: str, joint_name: str, angle: float, velocity: float, acceleration: float):
    sid = uuid.UUID(session_id) if isinstance(session_id, str) else session_id
    db_metric = models.MovementMetric(
        session_id=sid,
        joint_name=joint_name,
        angle=angle,
        velocity=velocity,
        acceleration=acceleration
    )
    db.add(db_metric)
    db.commit()
    db.refresh(db_metric)
    return db_metric

def upsert_training_summary(db: Session, user_id: str, weekly_avg: float, monthly_avg: float, symmetry_trend: float, stability_trend: float, speed_trend: float):
    uid = uuid.UUID(user_id) if isinstance(user_id, str) else user_id
    summary = db.query(models.TrainingSummary).filter(models.TrainingSummary.user_id == uid).first()
    if not summary:
        summary = models.TrainingSummary(user_id=uid)
        db.add(summary)
    
    summary.weekly_avg_score = weekly_avg
    summary.monthly_avg_score = monthly_avg
    summary.symmetry_trend = symmetry_trend
    summary.stability_trend = stability_trend
    summary.speed_trend = speed_trend
    summary.last_updated = datetime.utcnow()
    
    db.commit()
    db.refresh(summary)
    return summary

def upsert_rehab_summary(db: Session, user_id: str, safe_rate: float, avg_rom: float, stability_trend: float, recovery_trend: float):
    uid = uuid.UUID(user_id) if isinstance(user_id, str) else user_id
    summary = db.query(models.RehabSummary).filter(models.RehabSummary.user_id == uid).first()
    if not summary:
        summary = models.RehabSummary(user_id=uid)
        db.add(summary)
    
    summary.safe_session_rate = safe_rate
    summary.avg_rom = avg_rom
    summary.stability_trend = stability_trend
    summary.recovery_trend = recovery_trend
    summary.last_updated = datetime.utcnow()
    
    db.commit()
    db.refresh(summary)
    return summary
