"""
Script to make a user an admin
"""
from sqlalchemy import text
from database.database import engine
import logging
import sys

logger = logging.getLogger("aria.migration")

def make_user_admin(username: str):
    """Make a user an admin by username"""
    try:
        with engine.begin() as conn:
            # Update user to be admin
            result = conn.execute(
                text("""
                    UPDATE users 
                    SET is_admin = TRUE 
                    WHERE username = :username
                """),
                {"username": username}
            )
            
            if result.rowcount == 0:
                logger.warning(f"User '{username}' not found")
                return False
            
            logger.info(f"User '{username}' is now an admin")
            return True
    except Exception as e:
        logger.error(f"Failed to make user admin: {e}")
        raise

if __name__ == "__main__":
    username = sys.argv[1] if len(sys.argv) > 1 else "admin"
    make_user_admin(username)

