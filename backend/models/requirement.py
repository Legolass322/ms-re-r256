from pydantic import BaseModel, Field, validator
from typing import Optional
from enum import Enum


class RequirementCategory(str, Enum):
    FEATURE = "FEATURE"
    ENHANCEMENT = "ENHANCEMENT"
    BUG_FIX = "BUG_FIX"
    TECHNICAL = "TECHNICAL"
    COMPLIANCE = "COMPLIANCE"


class Requirement(BaseModel):
    id: str = Field(..., description="Unique identifier for the requirement")
    title: str = Field(..., max_length=200, description="Short title of the requirement")
    description: str = Field(..., max_length=2000, description="Detailed description of the requirement")
    
    businessValue: Optional[float] = Field(None, ge=1, le=10, description="Business value score (1-10)")
    cost: Optional[float] = Field(None, ge=1, le=10, description="Implementation cost estimate (1-10, where 10 is most expensive)")
    risk: Optional[float] = Field(None, ge=1, le=10, description="Implementation risk score (1-10, where 10 is highest risk)")
    urgency: Optional[float] = Field(None, ge=1, le=10, description="Urgency score (1-10)")
    stakeholderValue: Optional[float] = Field(None, ge=1, le=10, description="Stakeholder importance score (1-10)")
    
    category: Optional[RequirementCategory] = Field(None, description="Requirement category")

    class Config:
        use_enum_values = True


class PrioritizedRequirement(Requirement):
    priorityScore: float = Field(..., ge=0, le=100, description="Calculated priority score (0-100)")
    rank: int = Field(..., ge=1, description="Priority ranking (1 = highest priority)")
    confidence: Optional[float] = Field(None, ge=0, le=1, description="ML model confidence score (0-1)")
    reasoning: Optional[str] = Field(None, description="AI-generated explanation for the priority score")


class Weights(BaseModel):
    businessValue: float = Field(0.3, ge=0, le=1, description="Weight for business value")
    cost: float = Field(0.2, ge=0, le=1, description="Weight for cost")
    risk: float = Field(0.15, ge=0, le=1, description="Weight for risk")
    urgency: float = Field(0.2, ge=0, le=1, description="Weight for urgency")
    stakeholderValue: float = Field(0.15, ge=0, le=1, description="Weight for stakeholder value")

    @validator('*', pre=True)
    def validate_weights_sum(cls, v, values):
        if values:
            total = sum(values.values()) + v
            if abs(total - 1.0) > 0.01:
                raise ValueError("Weights must sum to 1.0")
        return v
