"""
Database migration script to add is_admin column and llm_config table
"""
from sqlalchemy import text
from database.database import engine
import logging

logger = logging.getLogger("aria.migration")

def run_migration():
    """Run database migration"""
    try:
        with engine.begin() as conn:  # Use begin() for automatic transaction management
            # Add is_admin column to users table if it doesn't exist
            conn.execute(text("""
                DO $$ 
                BEGIN
                    IF NOT EXISTS (
                        SELECT 1 FROM information_schema.columns 
                        WHERE table_name = 'users' AND column_name = 'is_admin'
                    ) THEN
                        ALTER TABLE users ADD COLUMN is_admin BOOLEAN NOT NULL DEFAULT FALSE;
                    END IF;
                END $$;
            """))
            
            # Create llm_config table if it doesn't exist
            conn.execute(text("""
                CREATE TABLE IF NOT EXISTS llm_config (
                    id VARCHAR NOT NULL PRIMARY KEY,
                    api_key VARCHAR NOT NULL,
                    base_url VARCHAR NOT NULL DEFAULT 'https://api.openai.com/v1',
                    model VARCHAR NOT NULL DEFAULT 'gpt-4o-mini',
                    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                    updated_at TIMESTAMP WITH TIME ZONE
                );
            """))
            
        logger.info("Migration completed successfully")
    except Exception as e:
        logger.error(f"Migration failed: {e}")
        raise

if __name__ == "__main__":
    run_migration()

