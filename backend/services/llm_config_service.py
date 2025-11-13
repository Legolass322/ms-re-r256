"""
Service for managing LLM configuration
"""

from sqlalchemy.orm import Session
from database.models import LLMConfig
import uuid


class LLMConfigService:
    """Service for managing LLM configuration"""

    @staticmethod
    def get_config(db: Session) -> LLMConfig | None:
        """Get the current LLM configuration (there should be only one)"""
        return db.query(LLMConfig).first()

    @staticmethod
    def create_or_update_config(
        db: Session,
        api_key: str,
        base_url: str = "https://api.openai.com/v1",
        model: str = "gpt-4o-mini",
    ) -> LLMConfig:
        """Create or update LLM configuration"""
        config = LLMConfigService.get_config(db)
        
        if config:
            # Update existing config
            config.api_key = api_key
            config.base_url = base_url
            config.model = model
        else:
            # Create new config
            config = LLMConfig(
                id=str(uuid.uuid4()),
                api_key=api_key,
                base_url=base_url,
                model=model,
            )
            db.add(config)
        
        db.commit()
        db.refresh(config)
        return config

    @staticmethod
    def delete_config(db: Session) -> bool:
        """Delete LLM configuration"""
        config = LLMConfigService.get_config(db)
        if config:
            db.delete(config)
            db.commit()
            return True
        return False

