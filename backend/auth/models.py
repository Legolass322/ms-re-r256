"""
Authentication Pydantic models
"""

from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import datetime


class UserCreate(BaseModel):
    """User registration model"""
    email: EmailStr
    username: str
    password: str


class UserLogin(BaseModel):
    """User login model"""
    username: str
    password: str


class Token(BaseModel):
    """JWT token response model"""
    access_token: str
    token_type: str = "bearer"
    expires_in: int


class UserResponse(BaseModel):
    """User response model"""
    id: str
    email: str
    username: str
    is_active: bool
    created_at: datetime
    
    class Config:
        from_attributes = True
