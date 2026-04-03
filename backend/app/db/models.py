from sqlalchemy import Column, String, Float, DateTime, ForeignKey, Text, CheckConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
import uuid
from datetime import datetime
from .database import Base

class User(Base):
    __tablename__ = "users"
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String)
    email = Column(String, unique=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    sessions = relationship("Session", back_populates="user")
    training_summary = relationship("TrainingSummary", back_populates="user", uselist=False)
    rehab_summary = relationship("RehabSummary", back_populates="user", uselist=False)

class Session(Base):
    __tablename__ = "sessions"
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"))
    mode = Column(String) # 'training' or 'rehab'
    created_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("User", back_populates="sessions")
    training_record = relationship("TrainingSession", back_populates="session", uselist=False)
    rehab_record = relationship("RehabSession", back_populates="session", uselist=False)
    movement_metrics = relationship("MovementMetric", back_populates="session")

    __table_args__ = (
        CheckConstraint("mode IN ('training', 'rehab')", name="sessions_mode_check"),
    )

class TrainingSession(Base):
    __tablename__ = "training_sessions"
    session_id = Column(UUID(as_uuid=True), ForeignKey("sessions.id"), primary_key=True)
    score = Column(Float)
    symmetry = Column(Float)
    stability = Column(Float)
    speed = Column(Float)
    feedback = Column(Text)

    session = relationship("Session", back_populates="training_record")

class RehabSession(Base):
    __tablename__ = "rehab_sessions"
    session_id = Column(UUID(as_uuid=True), ForeignKey("sessions.id"), primary_key=True)
    injury_type = Column(String)
    stage = Column(String)
    score = Column(Float)
    safety = Column(Float) # Schema says double precision
    rom = Column(Float)
    stability = Column(Float)
    decision = Column(Text)
    feedback = Column(Text)

    session = relationship("Session", back_populates="rehab_record")

class MovementMetric(Base):
    __tablename__ = "movement_metrics"
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    session_id = Column(UUID(as_uuid=True), ForeignKey("sessions.id"))
    joint_name = Column(String)
    angle = Column(Float)
    velocity = Column(Float)
    acceleration = Column(Float)
    created_at = Column(DateTime, default=datetime.utcnow)

    session = relationship("Session", back_populates="movement_metrics")

class TrainingSummary(Base):
    __tablename__ = "training_summary"
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), primary_key=True)
    weekly_avg_score = Column(Float)
    monthly_avg_score = Column(Float)
    symmetry_trend = Column(Float)
    stability_trend = Column(Float)
    speed_trend = Column(Float)
    last_updated = Column(DateTime, default=datetime.utcnow)
    
    user = relationship("User", back_populates="training_summary")

class RehabSummary(Base):
    __tablename__ = "rehab_summary"
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), primary_key=True)
    safe_session_rate = Column(Float)
    avg_rom = Column(Float)
    stability_trend = Column(Float)
    recovery_trend = Column(Float)
    last_updated = Column(DateTime, default=datetime.utcnow)

    user = relationship("User", back_populates="rehab_summary")
