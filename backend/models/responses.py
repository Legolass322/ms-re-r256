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


class SessionSummary(BaseModel):
    id: str = Field(..., description="Session identifier")
    name: Optional[str] = Field(None, description="Optional session name")
    createdAt: datetime = Field(..., description="Creation timestamp")
    updatedAt: Optional[datetime] = Field(None, description="Last update timestamp")
    requirementsCount: int = Field(..., description="Number of requirements in the session")
    prioritizedCount: int = Field(..., description="Number of prioritized requirements")


class SessionsResponse(BaseModel):
    sessions: List[SessionSummary] = Field(..., description="List of user sessions")


class SessionDetails(BaseModel):
    sessionId: str = Field(..., description="Session identifier")
    name: Optional[str] = Field(None, description="Optional session name")
    createdAt: datetime = Field(..., description="Creation timestamp")
    updatedAt: Optional[datetime] = Field(None, description="Last update timestamp")
    requirements: List[Requirement] = Field(..., description="Requirements saved in the session")
    prioritizedRequirements: List[PrioritizedRequirement] = Field(
        default_factory=list,
        description="Prioritized requirements saved in the session",
    )


class ChatGPTAnalysisRequest(BaseModel):
    sessionId: str = Field(..., description="Session ID to analyze")
    prompt: Optional[str] = Field(None, description="Optional additional context for ChatGPT")


class ChatGPTAnalysisResponse(BaseModel):
    sessionId: str = Field(..., description="Session analyzed")
    summary: str = Field(..., description="ChatGPT generated analysis summary")


class PrioritizationRequest(BaseModel):
    sessionId: str = Field(..., description="Session ID containing requirements to prioritize")
    weights: Optional[Weights] = Field(None, description="Custom weights for scoring criteria")


class PrioritizationResponse(BaseModel):
    sessionId: str = Field(..., description="Session ID")
    prioritizedRequirements: List[PrioritizedRequirement] = Field(..., description="Requirements sorted by priority (highest first)")
    processingTimeMs: int = Field(..., description="Processing time in milliseconds")
    metadata: Optional[Dict[str, Any]] = Field(None, description="Additional metadata about the analysis")


class LLMConfigRequest(BaseModel):
    apiKey: str = Field(..., description="LLM API key")
    baseUrl: str = Field(default="https://api.openai.com/v1", description="LLM API base URL")
    model: str = Field(default="gpt-4o-mini", description="LLM model name")


class LLMConfigResponse(BaseModel):
    baseUrl: str = Field(..., description="LLM API base URL")
    model: str = Field(..., description="LLM model name")
    hasApiKey: bool = Field(..., description="Whether API key is configured (key value is not returned for security)")


class ExportRequest(BaseModel):
    sessionId: Optional[str] = Field(None, description="Session ID of the report (optional)")
    requirements: List[PrioritizedRequirement] = Field(
        ..., min_items=1, description="Requirements to include in the export"
    )
