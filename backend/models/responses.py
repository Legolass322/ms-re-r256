from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
from datetime import datetime
from .requirement import Requirement, PrioritizedRequirement, Weights


class Error(BaseModel):
    error: str = Field(..., description="Error code")
    message: str = Field(..., description="Human-readable error message")
    details: Optional[Dict[str, Any]] = Field(None, description="Additional error details")


class HealthResponse(BaseModel):
    status: str = Field(..., description="Health status")
    timestamp: str = Field(..., description="Timestamp of health check")
    version: Optional[str] = Field(None, description="API version")


class UploadResponse(BaseModel):
    sessionId: str = Field(..., description="Session ID for this upload")
    requirementsCount: int = Field(..., description="Number of requirements parsed from file")
    message: str = Field(..., description="Success message")
    requirements: Optional[List[Requirement]] = Field(None, description="Parsed requirements")


class CreateRequirementsRequest(BaseModel):
    requirements: List[Requirement] = Field(..., min_items=1, max_items=100, description="List of requirements to create")


class CreateRequirementsResponse(BaseModel):
    sessionId: str = Field(..., description="Session ID for these requirements")
    requirementsCount: int = Field(..., description="Number of requirements created")
    message: Optional[str] = Field(None, description="Success message")


class RequirementsList(BaseModel):
    sessionId: str = Field(..., description="Session ID")
    requirements: List[Requirement] = Field(..., description="List of requirements")


class PrioritizationRequest(BaseModel):
    sessionId: str = Field(..., description="Session ID containing requirements to prioritize")
    weights: Optional[Weights] = Field(None, description="Custom weights for scoring criteria")


class PrioritizationResponse(BaseModel):
    sessionId: str = Field(..., description="Session ID")
    prioritizedRequirements: List[PrioritizedRequirement] = Field(..., description="Requirements sorted by priority (highest first)")
    processingTimeMs: int = Field(..., description="Processing time in milliseconds")
    metadata: Optional[Dict[str, Any]] = Field(None, description="Additional metadata about the analysis")
