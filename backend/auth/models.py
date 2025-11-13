"""
Authentication Pydantic models
"""

from pydantic import BaseModel, EmailStr, Field
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
    accessToken: str = Field(alias="access_token", serialization_alias="accessToken")
    tokenType: str = Field(default="bearer", alias="token_type", serialization_alias="tokenType")
    expiresIn: int = Field(alias="expires_in", serialization_alias="expiresIn")
    
    class Config:
        from_attributes = True
        populate_by_name = True


class UserResponse(BaseModel):
    """User response model"""
    id: str
    email: str
    username: str
    isActive: bool = Field(alias="is_active", serialization_alias="isActive")
    isAdmin: bool = Field(default=False, alias="is_admin", serialization_alias="isAdmin")
    createdAt: datetime = Field(alias="created_at", serialization_alias="createdAt")
    
    class Config:
        from_attributes = True
        populate_by_name = True  # Allow both snake_case and camelCase
