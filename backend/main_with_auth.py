"""
ARIA Backend API - FastAPI implementation with authentication and database
AI-powered requirements prioritization tool
"""

from fastapi import FastAPI, HTTPException, UploadFile, File, Depends, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, HTMLResponse
from fastapi.staticfiles import StaticFiles
import uvicorn
import uuid
from datetime import datetime, timedelta
from typing import List, Dict, Any, Optional
import os
import tempfile
import logging
import pandas as pd
from pathlib import Path
from sqlalchemy.orm import Session

from models import (
    Requirement, PrioritizedRequirement, UploadResponse,
    CreateRequirementsRequest, CreateRequirementsResponse,
    RequirementsList, PrioritizationRequest, PrioritizationResponse,
    Error, HealthResponse, Weights, SessionSummary, SessionsResponse,
    SessionDetails, ChatGPTAnalysisRequest, ChatGPTAnalysisResponse,
    LLMConfigRequest, LLMConfigResponse
)
from services.prioritization_service import PrioritizationService
from services.file_service import FileService
from services.export_service import ExportService
from services.database_service import DatabaseService
from services.analysis_service import AnalysisService
from services.llm_config_service import LLMConfigService
from database import get_db, engine, Base
from auth import AuthService, get_current_user, get_current_admin_user, UserCreate, UserLogin, Token, UserResponse
from database.models import User

# Initialize FastAPI app
app = FastAPI(
    title="ARIA - Advanced Requirements Intelligence & Analytics API",
    description="AI-powered requirements prioritization tool that automates multi-criteria analysis for objective requirement prioritization",
    version="1.0.0",
    contact={
        "name": "ARIA Team",
        "email": "support@aria-app.com"
    }
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify exact origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize services
prioritization_service = PrioritizationService()
file_service = FileService()
export_service = ExportService()
database_service = DatabaseService()
llm_config_service = LLMConfigService()
# AnalysisService will be initialized dynamically with config from DB
analysis_service = None

# Initialize logger first
logger = logging.getLogger("aria.backend")

# Create database tables
Base.metadata.create_all(bind=engine)

# Run migrations
try:
    from migrations.add_admin_and_llm_config import run_migration
    run_migration()
except Exception as e:
    logger.warning(f"Migration failed (may already be applied): {e}")

# ============================================================================
# AUTHENTICATION ENDPOINTS
# ============================================================================

@app.post("/auth/register", response_model=UserResponse, tags=["authentication"])
async def register(user_create: UserCreate, db: Session = Depends(get_db)):
    """Register a new user"""
    try:
        user = AuthService.create_user(db, user_create)
        return UserResponse(
            id=user.id,
            email=user.email,
            username=user.username,
            isActive=user.is_active,
            isAdmin=user.is_admin,
            createdAt=user.created_at
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.exception("Registration failed")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Registration failed: {str(e)}"
        )

@app.post("/auth/login", response_model=Token, tags=["authentication"])
async def login(user_login: UserLogin, db: Session = Depends(get_db)):
    """Login user and return JWT token"""
    user = AuthService.authenticate_user(db, user_login.username, user_login.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    access_token_expires = timedelta(minutes=30)
    access_token = AuthService.create_access_token(
        data={"sub": user.username}, expires_delta=access_token_expires
    )
    
    return Token(
        accessToken=access_token,
        tokenType="bearer",
        expiresIn=1800  # 30 minutes in seconds
    )

@app.get("/auth/me", response_model=UserResponse, tags=["authentication"])
async def get_current_user_info(current_user: User = Depends(get_current_user)):
    """Get current user information"""
    return UserResponse(
        id=current_user.id,
        email=current_user.email,
        username=current_user.username,
        isActive=current_user.is_active,
        isAdmin=current_user.is_admin,
        createdAt=current_user.created_at
    )

# ============================================================================
# HEALTH CHECK
# ============================================================================

@app.get("/health", response_model=HealthResponse, tags=["health"])
async def health_check():
    """Check API health status"""
    return HealthResponse(
        status="healthy",
        timestamp=datetime.now().isoformat(),
        version="1.0.0"
    )

# ============================================================================
# REQUIREMENTS ENDPOINTS
# ============================================================================

@app.post("/requirements/upload", response_model=UploadResponse, tags=["requirements"])
async def upload_requirements(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Upload requirements from CSV/Excel file"""
    try:
        # Validate file type
        if not file.filename.lower().endswith(('.csv', '.xlsx', '.xls')):
            raise HTTPException(
                status_code=400,
                detail=Error(
                    error="INVALID_FILE_TYPE",
                    message="File must be CSV or Excel format"
                ).dict()
            )
        
        # Read file content
        content = await file.read()
        
        # Parse requirements from file
        requirements = file_service.parse_requirements(content, file.filename)
        
        # Validate requirements count
        if len(requirements) > 100:
            raise HTTPException(
                status_code=413,
                detail=Error(
                    error="FILE_TOO_LARGE",
                    message="Maximum 100 requirements allowed"
                ).dict()
            )
        
        # Create session in database
        db_session = database_service.create_session(db, current_user.id)
        
        # Save requirements to database
        database_service.save_requirements(db, db_session.id, requirements)
        
        return UploadResponse(
            sessionId=db_session.id,
            requirementsCount=len(requirements),
            message=f"Successfully uploaded {len(requirements)} requirements",
            requirements=requirements
        )
        
    except Exception as e:
        logger.exception("Upload requirements failed")
        raise HTTPException(
            status_code=400,
            detail=Error(
                error="UPLOAD_FAILED",
                message=str(e)
            ).dict()
        )

@app.post("/requirements", response_model=CreateRequirementsResponse, tags=["requirements"])
async def create_requirements(
    request: CreateRequirementsRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Create requirements manually"""
    try:
        # Validate requirements count
        if len(request.requirements) > 100:
            raise HTTPException(
                status_code=400,
                detail=Error(
                    error="TOO_MANY_REQUIREMENTS",
                    message="Maximum 100 requirements allowed"
                ).dict()
            )
        
        # Create session in database
        db_session = database_service.create_session(db, current_user.id)
        
        # Save requirements to database
        database_service.save_requirements(db, db_session.id, request.requirements)
        
        return CreateRequirementsResponse(
            sessionId=db_session.id,
            requirementsCount=len(request.requirements),
            message=f"Successfully created {len(request.requirements)} requirements"
        )
        
    except Exception as e:
        logger.exception("Create requirements failed")
        raise HTTPException(
            status_code=400,
            detail=Error(
                error="CREATE_FAILED",
                message=str(e)
            ).dict()
        )

@app.get("/requirements", response_model=RequirementsList, tags=["requirements"])
async def get_requirements(
    sessionId: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get all requirements for a session"""
    # Verify session belongs to user
    session = database_service.get_session(db, sessionId, current_user.id)
    if not session:
        raise HTTPException(
            status_code=404,
            detail=Error(
                error="SESSION_NOT_FOUND",
                message="Session not found or access denied"
            ).dict()
        )
    
    requirements = database_service.get_requirements(db, sessionId)
    return RequirementsList(
        sessionId=sessionId,
        requirements=requirements
    )

# ============================================================================
# PRIORITIZATION ENDPOINTS
# ============================================================================

@app.post("/prioritization/analyze", response_model=PrioritizationResponse, tags=["prioritization"])
async def analyze_prioritization(
    request: PrioritizationRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Analyze and prioritize requirements using AI"""
    try:
        # Verify session belongs to user
        session = database_service.get_session(db, request.sessionId, current_user.id)
        if not session:
            raise HTTPException(
                status_code=404,
                detail=Error(
                    error="SESSION_NOT_FOUND",
                    message="Session not found or access denied"
                ).dict()
            )
        
        requirements = database_service.get_requirements(db, request.sessionId)
        if not requirements:
            raise HTTPException(
                status_code=400,
                detail=Error(
                    error="NO_REQUIREMENTS",
                    message="No requirements found in session"
                ).dict()
            )
        
        # Use custom weights if provided, otherwise use defaults
        weights = request.weights if request.weights else Weights()
        
        # Perform prioritization
        start_time = datetime.now()
        prioritized_requirements = prioritization_service.prioritize_requirements(
            requirements, weights
        )
        processing_time = int((datetime.now() - start_time).total_seconds() * 1000)
        
        # Save results to database
        database_service.save_prioritized_requirements(db, request.sessionId, prioritized_requirements)
        
        return PrioritizationResponse(
            sessionId=request.sessionId,
            prioritizedRequirements=prioritized_requirements,
            processingTimeMs=processing_time,
            metadata={
                "totalRequirements": len(requirements),
                "averageScore": sum(r.priorityScore for r in prioritized_requirements) / len(prioritized_requirements),
                "modelVersion": "1.0.0",
                "weightsUsed": weights.model_dump() if hasattr(weights, 'model_dump') else weights.dict()
            }
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=400,
            detail=Error(
                error="ANALYSIS_FAILED",
                message=str(e)
            ).dict()
        )

@app.get("/prioritization/{sessionId}", response_model=PrioritizationResponse, tags=["prioritization"])
async def get_prioritization(
    sessionId: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get prioritization results for a session"""
    # Verify session belongs to user
    session = database_service.get_session(db, sessionId, current_user.id)
    if not session:
        raise HTTPException(
            status_code=404,
            detail=Error(
                error="SESSION_NOT_FOUND",
                message="Session not found or access denied"
            ).dict()
        )
    
    prioritized_requirements = database_service.get_prioritized_requirements(db, sessionId)
    if not prioritized_requirements:
        raise HTTPException(
            status_code=404,
            detail=Error(
                error="NO_RESULTS",
                message="No prioritization results found for this session"
            ).dict()
        )
    
    return PrioritizationResponse(
        sessionId=sessionId,
        prioritizedRequirements=prioritized_requirements,
        processingTimeMs=0,  # Not available for cached results
        metadata={
            "totalRequirements": len(prioritized_requirements),
            "averageScore": sum(r.priorityScore for r in prioritized_requirements) / len(prioritized_requirements),
            "modelVersion": "1.0.0",
            "weightsUsed": {}
        }
    )


@app.post("/prioritization/chatgpt", response_model=ChatGPTAnalysisResponse, tags=["prioritization"])
async def analyze_with_chatgpt(
    request: ChatGPTAnalysisRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Generate prioritization insights using OpenAI ChatGPT."""
    session = database_service.get_session(db, request.sessionId, current_user.id)
    if not session:
        raise HTTPException(
            status_code=404,
            detail=Error(
                error="SESSION_NOT_FOUND",
                message="Session not found or access denied"
            ).dict()
        )

    requirements = database_service.get_requirements(db, request.sessionId)
    if not requirements:
        raise HTTPException(
            status_code=400,
            detail=Error(
                error="NO_REQUIREMENTS",
                message="No requirements found in session"
            ).dict()
        )

    try:
        # Get LLM config from database
        llm_config = llm_config_service.get_config(db)
        if not llm_config:
            raise HTTPException(
                status_code=400,
                detail=Error(
                    error="LLM_CONFIG_NOT_SET",
                    message="LLM configuration is not set. Please configure it in admin panel."
                ).dict()
            )
        
        # Create AnalysisService with config from DB
        service = AnalysisService(
            api_key=llm_config.api_key,
            base_url=llm_config.base_url,
            model=llm_config.model
        )
        
        summary = await service.analyze_requirements(
            requirements,
            request.prompt,
        )
        return ChatGPTAnalysisResponse(sessionId=request.sessionId, summary=summary)
    except HTTPException:
        raise
    except Exception as exc:
        logger.exception("ChatGPT analysis failed")
        raise HTTPException(
            status_code=500,
            detail=Error(
                error="ANALYSIS_FAILED",
                message=str(exc)
            ).dict()
        )

# ============================================================================
# EXPORT ENDPOINTS
# ============================================================================

@app.get("/export/csv/{sessionId}", tags=["export"])
async def export_csv(
    sessionId: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Export results as CSV"""
    # Verify session belongs to user
    session = database_service.get_session(db, sessionId, current_user.id)
    if not session:
        raise HTTPException(
            status_code=404,
            detail=Error(
                error="SESSION_NOT_FOUND",
                message="Session not found or access denied"
            ).dict()
        )
    
    prioritized_requirements = database_service.get_prioritized_requirements(db, sessionId)
    if not prioritized_requirements:
        raise HTTPException(
            status_code=404,
            detail=Error(
                error="NO_RESULTS",
                message="No prioritization results found for this session"
            ).dict()
        )
    
    # Generate CSV file
    csv_content = export_service.generate_csv(prioritized_requirements)
    
    # Create temporary file
    with tempfile.NamedTemporaryFile(mode='w', suffix='.csv', delete=False) as f:
        f.write(csv_content)
        temp_file = f.name
    
    return FileResponse(
        path=temp_file,
        filename=f"aria_prioritization_{sessionId}.csv",
        media_type="text/csv"
    )

@app.get("/export/html/{sessionId}", response_class=HTMLResponse, tags=["export"])
async def export_html(
    sessionId: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Export results as HTML report"""
    # Verify session belongs to user
    session = database_service.get_session(db, sessionId, current_user.id)
    if not session:
        raise HTTPException(
            status_code=404,
            detail=Error(
                error="SESSION_NOT_FOUND",
                message="Session not found or access denied"
            ).dict()
        )
    
    prioritized_requirements = database_service.get_prioritized_requirements(db, sessionId)
    if not prioritized_requirements:
        raise HTTPException(
            status_code=404,
            detail=Error(
                error="NO_RESULTS",
                message="No prioritization results found for this session"
            ).dict()
        )
    
    # Generate HTML report
    html_content = export_service.generate_html(prioritized_requirements, sessionId)
    return HTMLResponse(content=html_content)

# ============================================================================
# USER SESSIONS ENDPOINTS
# ============================================================================

@app.get("/sessions", response_model=SessionsResponse, tags=["sessions"])
async def get_user_sessions(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get all sessions for the current user"""
    sessions = database_service.get_user_sessions(db, current_user.id)
    summaries = []
    for session in sessions:
        requirements_count = database_service.count_requirements(db, session.id)
        prioritized_count = database_service.count_prioritized_requirements(db, session.id)
        summaries.append(
            SessionSummary(
                id=session.id,
                name=session.name,
                createdAt=session.created_at,
                updatedAt=session.updated_at,
                requirementsCount=requirements_count,
                prioritizedCount=prioritized_count,
            )
        )

    return SessionsResponse(sessions=summaries)


@app.get("/sessions/latest", response_model=SessionDetails, tags=["sessions"])
async def get_latest_session(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get the most recent session with requirements and prioritization results"""
    session = database_service.get_latest_session(db, current_user.id)
    if not session:
        raise HTTPException(
            status_code=404,
            detail=Error(
                error="NO_SESSIONS",
                message="No sessions found for this user"
            ).dict()
        )

    requirements = database_service.get_requirements(db, session.id)
    prioritized = database_service.get_prioritized_requirements(db, session.id)

    return SessionDetails(
        sessionId=session.id,
        name=session.name,
        createdAt=session.created_at,
        updatedAt=session.updated_at,
        requirements=requirements,
        prioritizedRequirements=prioritized,
    )


@app.get("/sessions/{sessionId}", response_model=SessionDetails, tags=["sessions"])
async def get_session_details(
    sessionId: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get requirements and prioritization results for a specific session"""
    session = database_service.get_session(db, sessionId, current_user.id)
    if not session:
        raise HTTPException(
            status_code=404,
            detail=Error(
                error="SESSION_NOT_FOUND",
                message="Session not found or access denied"
            ).dict()
        )

    requirements = database_service.get_requirements(db, sessionId)
    prioritized = database_service.get_prioritized_requirements(db, sessionId)

    return SessionDetails(
        sessionId=session.id,
        name=session.name,
        createdAt=session.created_at,
        updatedAt=session.updated_at,
        requirements=requirements,
        prioritizedRequirements=prioritized,
    )

# ============================================================================
# ADMIN ENDPOINTS
# ============================================================================

@app.get("/admin/llm-config", response_model=LLMConfigResponse, tags=["admin"])
async def get_llm_config(
    current_user: User = Depends(get_current_admin_user),
    db: Session = Depends(get_db)
):
    """Get current LLM configuration (admin only)"""
    config = llm_config_service.get_config(db)
    if not config:
        raise HTTPException(
            status_code=404,
            detail=Error(
                error="CONFIG_NOT_FOUND",
                message="LLM configuration not set"
            ).dict()
        )
    
    return LLMConfigResponse(
        baseUrl=config.base_url,
        model=config.model,
        hasApiKey=bool(config.api_key)
    )


@app.put("/admin/llm-config", response_model=LLMConfigResponse, tags=["admin"])
async def update_llm_config(
    request: LLMConfigRequest,
    current_user: User = Depends(get_current_admin_user),
    db: Session = Depends(get_db)
):
    """Update LLM configuration (admin only)"""
    try:
        config = llm_config_service.create_or_update_config(
            db=db,
            api_key=request.apiKey,
            base_url=request.baseUrl,
            model=request.model
        )
        
        return LLMConfigResponse(
            baseUrl=config.base_url,
            model=config.model,
            hasApiKey=bool(config.api_key)
        )
    except Exception as exc:
        logger.exception("Failed to update LLM config")
        raise HTTPException(
            status_code=500,
            detail=Error(
                error="UPDATE_FAILED",
                message=str(exc)
            ).dict()
        )


@app.delete("/admin/llm-config", tags=["admin"])
async def delete_llm_config(
    current_user: User = Depends(get_current_admin_user),
    db: Session = Depends(get_db)
):
    """Delete LLM configuration (admin only)"""
    deleted = llm_config_service.delete_config(db)
    if not deleted:
        raise HTTPException(
            status_code=404,
            detail=Error(
                error="CONFIG_NOT_FOUND",
                message="LLM configuration not found"
            ).dict()
        )
    
    return {"message": "LLM configuration deleted successfully"}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8080)
