"""
SQLAlchemy database models
"""

from sqlalchemy import Column, Integer, String, Float, DateTime, Text, ForeignKey, Boolean
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from .database import Base
import uuid
from datetime import datetime


class User(Base):
    """User model for authentication"""
    __tablename__ = "users"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    email = Column(String, unique=True, index=True, nullable=False)
    username = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    is_active = Column(Boolean, default=True)
    is_admin = Column(Boolean, default=False, nullable=False)  # Admin flag
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relationships
    sessions = relationship("Session", back_populates="user", cascade="all, delete-orphan")


class Session(Base):
    """Session model for storing requirement analysis sessions"""
    __tablename__ = "sessions"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String, ForeignKey("users.id"), nullable=False)
    name = Column(String, nullable=True)  # Optional session name
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relationships
    user = relationship("User", back_populates="sessions")
    requirements = relationship("Requirement", back_populates="session", cascade="all, delete-orphan")
    prioritized_requirements = relationship("PrioritizedRequirement", back_populates="session", cascade="all, delete-orphan")


class Requirement(Base):
    """Requirement model for storing individual requirements"""
    __tablename__ = "requirements"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    session_id = Column(String, ForeignKey("sessions.id"), nullable=False)
    external_id = Column(String, nullable=False)  # ID from uploaded file or user input
    title = Column(String, nullable=False)
    description = Column(Text, nullable=False)
    business_value = Column(Float, nullable=True)
    cost = Column(Float, nullable=True)
    risk = Column(Float, nullable=True)
    urgency = Column(Float, nullable=True)
    stakeholder_value = Column(Float, nullable=True)
    category = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationships
    session = relationship("Session", back_populates="requirements")
    prioritized_requirements = relationship("PrioritizedRequirement", back_populates="requirement", cascade="all, delete-orphan")


class PrioritizedRequirement(Base):
    """Prioritized requirement model for storing analysis results"""
    __tablename__ = "prioritized_requirements"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    session_id = Column(String, ForeignKey("sessions.id"), nullable=False)
    requirement_id = Column(String, ForeignKey("requirements.id"), nullable=False)
    priority_score = Column(Float, nullable=False)
    rank = Column(Integer, nullable=False)
    confidence = Column(Float, nullable=True)
    reasoning = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationships
    session = relationship("Session", back_populates="prioritized_requirements")
    requirement = relationship("Requirement", back_populates="prioritized_requirements")


class LLMConfig(Base):
    """LLM configuration model for storing API settings"""
    __tablename__ = "llm_config"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    api_key = Column(String, nullable=False)  # Encrypted API key
    base_url = Column(String, nullable=False, default="https://api.openai.com/v1")
    model = Column(String, nullable=False, default="gpt-4o-mini")
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
