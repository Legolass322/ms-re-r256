from fastapi import FastAPI, HTTPException, UploadFile, File, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, HTMLResponse
from fastapi.staticfiles import StaticFiles
import uvicorn
import uuid
from datetime import datetime
from typing import List, Dict, Any
import os
import tempfile
import pandas as pd
from pathlib import Path

from models import (
    Requirement, PrioritizedRequirement, UploadResponse, 
    CreateRequirementsRequest, CreateRequirementsResponse,
    RequirementsList, PrioritizationRequest, PrioritizationResponse,
    Error, HealthResponse, Weights
)
from services.prioritization_service import PrioritizationService
from services.file_service import FileService
from services.export_service import ExportService

app = FastAPI(
    title="ARIA - Advanced Requirements Intelligence & Analytics API",
    description="AI-powered requirements prioritization tool that automates multi-criteria analysis for objective requirement prioritization",
    version="1.0.0",
    contact={
        "name": "ARIA Team",
        "email": "support@aria-app.com"
    }
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

prioritization_service = PrioritizationService()
file_service = FileService()
export_service = ExportService()

sessions: Dict[str, Dict[str, Any]] = {}

@app.get("/health", response_model=HealthResponse, tags=["health"])
async def health_check():
    return HealthResponse(
        status="healthy",
        timestamp=datetime.now().isoformat(),
        version="1.0.0"
    )

@app.post("/requirements/upload", response_model=UploadResponse, tags=["requirements"])
async def upload_requirements(file: UploadFile = File(...)):
    try:
        if not file.filename.lower().endswith(('.csv', '.xlsx', '.xls')):
            raise HTTPException(
                status_code=400,
                detail=Error(
                    error="INVALID_FILE_TYPE",
                    message="File must be CSV or Excel format"
                ).dict()
            )
        
        content = await file.read()
        
        requirements = file_service.parse_requirements(content, file.filename)
        
        if len(requirements) > 100:
            raise HTTPException(
                status_code=413,
                detail=Error(
                    error="FILE_TOO_LARGE",
                    message="Maximum 100 requirements allowed"
                ).dict()
            )
        
        session_id = str(uuid.uuid4())
        sessions[session_id] = {
            "requirements": requirements,
            "created_at": datetime.now(),
            "prioritized_requirements": None
        }
        
        return UploadResponse(
            sessionId=session_id,
            requirementsCount=len(requirements),
            message=f"Successfully uploaded {len(requirements)} requirements",
            requirements=requirements
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=400,
            detail=Error(
                error="UPLOAD_FAILED",
                message=str(e)
            ).dict()
        )

@app.post("/requirements", response_model=CreateRequirementsResponse, tags=["requirements"])
async def create_requirements(request: CreateRequirementsRequest):
    try:
        if len(request.requirements) > 100:
            raise HTTPException(
                status_code=400,
                detail=Error(
                    error="TOO_MANY_REQUIREMENTS",
                    message="Maximum 100 requirements allowed"
                ).dict()
            )
        
        session_id = str(uuid.uuid4())
        sessions[session_id] = {
            "requirements": request.requirements,
            "created_at": datetime.now(),
            "prioritized_requirements": None
        }
        
        return CreateRequirementsResponse(
            sessionId=session_id,
            requirementsCount=len(request.requirements),
            message=f"Successfully created {len(request.requirements)} requirements"
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=400,
            detail=Error(
                error="CREATE_FAILED",
                message=str(e)
            ).dict()
        )

@app.get("/requirements", response_model=RequirementsList, tags=["requirements"])
async def get_requirements(sessionId: str):
    if sessionId not in sessions:
        raise HTTPException(
            status_code=404,
            detail=Error(
                error="SESSION_NOT_FOUND",
                message="Session not found"
            ).dict()
        )
    
    return RequirementsList(
        sessionId=sessionId,
        requirements=sessions[sessionId]["requirements"]
    )

@app.post("/prioritization/analyze", response_model=PrioritizationResponse, tags=["prioritization"])
async def analyze_prioritization(request: PrioritizationRequest):
    try:
        if request.sessionId not in sessions:
            raise HTTPException(
                status_code=404,
                detail=Error(
                    error="SESSION_NOT_FOUND",
                    message="Session not found"
                ).dict()
            )
        
        requirements = sessions[request.sessionId]["requirements"]
        if not requirements:
            raise HTTPException(
                status_code=400,
                detail=Error(
                    error="NO_REQUIREMENTS",
                    message="No requirements found in session"
                ).dict()
            )
        
        weights = request.weights if request.weights else Weights()
        
        start_time = datetime.now()
        prioritized_requirements = prioritization_service.prioritize_requirements(
            requirements, weights
        )
        processing_time = int((datetime.now() - start_time).total_seconds() * 1000)
        
        sessions[request.sessionId]["prioritized_requirements"] = prioritized_requirements
        
        return PrioritizationResponse(
            sessionId=request.sessionId,
            prioritizedRequirements=prioritized_requirements,
            processingTimeMs=processing_time,
            metadata={
                "totalRequirements": len(requirements),
                "averageScore": sum(r.priorityScore for r in prioritized_requirements) / len(prioritized_requirements),
                "modelVersion": "1.0.0",
                "weightsUsed": weights.dict()
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
async def get_prioritization(sessionId: str):
    if sessionId not in sessions:
        raise HTTPException(
            status_code=404,
            detail=Error(
                error="SESSION_NOT_FOUND",
                message="Session not found"
            ).dict()
        )
    
    session = sessions[sessionId]
    if not session["prioritized_requirements"]:
        raise HTTPException(
            status_code=404,
            detail=Error(
                error="NO_RESULTS",
                message="No prioritization results found for this session"
            ).dict()
        )
    
    return PrioritizationResponse(
        sessionId=sessionId,
        prioritizedRequirements=session["prioritized_requirements"],
        processingTimeMs=0,
        metadata={
            "totalRequirements": len(session["requirements"]),
            "averageScore": sum(r.priorityScore for r in session["prioritized_requirements"]) / len(session["prioritized_requirements"]),
            "modelVersion": "1.0.0",
            "weightsUsed": {}
        }
    )

@app.get("/export/csv/{sessionId}", tags=["export"])
async def export_csv(sessionId: str):
    if sessionId not in sessions:
        raise HTTPException(
            status_code=404,
            detail=Error(
                error="SESSION_NOT_FOUND",
                message="Session not found"
            ).dict()
        )
    
    session = sessions[sessionId]
    if not session["prioritized_requirements"]:
        raise HTTPException(
            status_code=404,
            detail=Error(
                error="NO_RESULTS",
                message="No prioritization results found for this session"
            ).dict()
        )
    
    csv_content = export_service.generate_csv(session["prioritized_requirements"])
    
    with tempfile.NamedTemporaryFile(mode='w', suffix='.csv', delete=False) as f:
        f.write(csv_content)
        temp_file = f.name
    
    return FileResponse(
        path=temp_file,
        filename=f"aria_prioritization_{sessionId}.csv",
        media_type="text/csv"
    )

@app.get("/export/html/{sessionId}", response_class=HTMLResponse, tags=["export"])
async def export_html(sessionId: str):
    if sessionId not in sessions:
        raise HTTPException(
            status_code=404,
            detail=Error(
                error="SESSION_NOT_FOUND",
                message="Session not found"
            ).dict()
        )
    
    session = sessions[sessionId]
    if not session["prioritized_requirements"]:
        raise HTTPException(
            status_code=404,
            detail=Error(
                error="NO_RESULTS",
                message="No prioritization results found for this session"
            ).dict()
        )
    
    html_content = export_service.generate_html(session["prioritized_requirements"], sessionId)
    return HTMLResponse(content=html_content)

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8080)
