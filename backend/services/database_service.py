"""
Database service for requirements and sessions
"""

from typing import List, Optional
from sqlalchemy.orm import Session
from datetime import datetime

from database.models import User, Session as DBSession, Requirement as DBRequirement, PrioritizedRequirement as DBPrioritizedRequirement
from models.requirement import Requirement, PrioritizedRequirement, RequirementCategory


class DatabaseService:
    """Service for database operations"""
    
    @staticmethod
    def create_session(db: Session, user_id: str, name: Optional[str] = None) -> DBSession:
        """Create a new analysis session"""
        db_session = DBSession(
            user_id=user_id,
            name=name or f"Session {datetime.now().strftime('%Y-%m-%d %H:%M')}"
        )
        db.add(db_session)
        db.commit()
        db.refresh(db_session)
        return db_session
    
    @staticmethod
    def save_requirements(db: Session, session_id: str, requirements: List[Requirement]) -> List[DBRequirement]:
        """Save requirements to database"""
        db_requirements = []
        for req in requirements:
            db_req = DBRequirement(
                session_id=session_id,
                external_id=req.id,
                title=req.title,
                description=req.description,
                business_value=req.businessValue,
                cost=req.cost,
                risk=req.risk,
                urgency=req.urgency,
                stakeholder_value=req.stakeholderValue,
                category=req.category.value if req.category else None
            )
            db.add(db_req)
            db_requirements.append(db_req)
        
        db.commit()
        for db_req in db_requirements:
            db.refresh(db_req)
        
        return db_requirements
    
    @staticmethod
    def save_prioritized_requirements(
        db: Session, 
        session_id: str, 
        prioritized_requirements: List[PrioritizedRequirement]
    ) -> List[DBPrioritizedRequirement]:
        """Save prioritized requirements to database"""
        # First, get the requirements from the session
        db_requirements = db.query(DBRequirement).filter(DBRequirement.session_id == session_id).all()
        req_map = {req.external_id: req.id for req in db_requirements}
        
        # Clear existing prioritized requirements for this session
        db.query(DBPrioritizedRequirement).filter(DBPrioritizedRequirement.session_id == session_id).delete()
        
        db_prioritized = []
        for prioritized_req in prioritized_requirements:
            requirement_id = req_map.get(prioritized_req.id)
            if requirement_id:
                db_prioritized_req = DBPrioritizedRequirement(
                    session_id=session_id,
                    requirement_id=requirement_id,
                    priority_score=prioritized_req.priorityScore,
                    rank=prioritized_req.rank,
                    confidence=prioritized_req.confidence,
                    reasoning=prioritized_req.reasoning
                )
                db.add(db_prioritized_req)
                db_prioritized.append(db_prioritized_req)
        
        db.commit()
        for db_prioritized_req in db_prioritized:
            db.refresh(db_prioritized_req)
        
        return db_prioritized
    
    @staticmethod
    def get_requirements(db: Session, session_id: str) -> List[Requirement]:
        """Get requirements from database"""
        db_requirements = db.query(DBRequirement).filter(DBRequirement.session_id == session_id).all()
        
        requirements = []
        for db_req in db_requirements:
            category = None
            if db_req.category:
                try:
                    category = RequirementCategory(db_req.category)
                except ValueError:
                    pass
            
            req = Requirement(
                id=db_req.external_id,
                title=db_req.title,
                description=db_req.description,
                businessValue=db_req.business_value,
                cost=db_req.cost,
                risk=db_req.risk,
                urgency=db_req.urgency,
                stakeholderValue=db_req.stakeholder_value,
                category=category
            )
            requirements.append(req)
        
        return requirements
    
    @staticmethod
    def get_prioritized_requirements(db: Session, session_id: str) -> List[PrioritizedRequirement]:
        """Get prioritized requirements from database"""
        db_prioritized = db.query(DBPrioritizedRequirement).filter(
            DBPrioritizedRequirement.session_id == session_id
        ).join(DBRequirement).order_by(DBPrioritizedRequirement.rank).all()
        
        prioritized_requirements = []
        for db_prioritized_req in db_prioritized:
            # Get the original requirement
            db_req = db_prioritized_req.requirement
            
            category = None
            if db_req.category:
                try:
                    category = RequirementCategory(db_req.category)
                except ValueError:
                    pass
            
            req = PrioritizedRequirement(
                id=db_req.external_id,
                title=db_req.title,
                description=db_req.description,
                businessValue=db_req.business_value,
                cost=db_req.cost,
                risk=db_req.risk,
                urgency=db_req.urgency,
                stakeholderValue=db_req.stakeholder_value,
                category=category,
                priorityScore=db_prioritized_req.priority_score,
                rank=db_prioritized_req.rank,
                confidence=db_prioritized_req.confidence,
                reasoning=db_prioritized_req.reasoning
            )
            prioritized_requirements.append(req)
        
        return prioritized_requirements
    
    @staticmethod
    def get_user_sessions(db: Session, user_id: str) -> List[DBSession]:
        """Get all sessions for a user"""
        return db.query(DBSession).filter(DBSession.user_id == user_id).order_by(DBSession.created_at.desc()).all()
    
    @staticmethod
    def get_session(db: Session, session_id: str, user_id: str) -> Optional[DBSession]:
        """Get a specific session for a user"""
        return db.query(DBSession).filter(
            DBSession.id == session_id,
            DBSession.user_id == user_id
        ).first()
