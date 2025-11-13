"""
Authentication service with JWT tokens
"""

from datetime import datetime, timedelta
from typing import Optional
from jose import JWTError, jwt
from passlib.context import CryptContext
from fastapi import HTTPException, status, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from redis.exceptions import RedisError

from redis_client import get_redis_client

from database import get_db, User
from .models import UserCreate, UserLogin, Token, UserResponse

# Configuration
SECRET_KEY = "your-secret-key-change-in-production"  # In production, use environment variable
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

# Password hashing
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# JWT token scheme
security = HTTPBearer()


class AuthService:
    """Authentication service"""
    
    _REDIS_USER_KEY_PREFIX = "aria:auth:user:"

    @staticmethod
    def _redis_key(username: str) -> str:
        """Build Redis key for user credentials."""
        return f"{AuthService._REDIS_USER_KEY_PREFIX}{username.lower()}"

    @staticmethod
    def _cache_user_credentials(
        username: str,
        hashed_password: str,
        email: str,
        user_id: str,
    ) -> None:
        """Persist hashed password and basic metadata in Redis."""
        try:
            client = get_redis_client()
            client.hset(
                AuthService._redis_key(username),
                mapping={
                    "hashed_password": hashed_password,
                    "email": email,
                    "user_id": user_id,
                },
            )
        except RedisError:
            # Do not block registration/login if Redis is unavailable
            pass

    @staticmethod
    def _get_cached_password(username: str) -> Optional[str]:
        """Retrieve hashed password from Redis cache."""
        try:
            client = get_redis_client()
            return client.hget(
                AuthService._redis_key(username),
                "hashed_password",
            )
        except RedisError:
            return None

    @staticmethod
    def verify_password(plain_password: str, hashed_password: str) -> bool:
        """Verify a password against its hash"""
        return pwd_context.verify(plain_password, hashed_password)
    
    @staticmethod
    def get_password_hash(password: str) -> str:
        """Hash a password"""
        # Truncate password to 72 bytes for bcrypt compatibility
        if len(password.encode('utf-8')) > 72:
            password = password[:72]
        return pwd_context.hash(password)
    
    @staticmethod
    def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
        """Create JWT access token"""
        to_encode = data.copy()
        if expires_delta:
            expire = datetime.utcnow() + expires_delta
        else:
            expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
        
        to_encode.update({"exp": expire})
        encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
        return encoded_jwt
    
    @staticmethod
    def verify_token(token: str) -> Optional[str]:
        """Verify JWT token and return username"""
        try:
            payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
            username: str = payload.get("sub")
            if username is None:
                return None
            return username
        except JWTError:
            return None
    
    @staticmethod
    def authenticate_user(db: Session, username: str, password: str) -> Optional[User]:
        """Authenticate user with username and password"""
        cached_hash = AuthService._get_cached_password(username)
        user = db.query(User).filter(User.username == username).first()
        if not user:
            return None

        hashed_password = cached_hash or user.hashed_password
        if not hashed_password:
            return None

        if not AuthService.verify_password(password, hashed_password):
            return None

        if not cached_hash:
            AuthService._cache_user_credentials(
                username=username,
                hashed_password=hashed_password,
                email=user.email,
                user_id=user.id,
            )

        return user
    
    @staticmethod
    def create_user(db: Session, user_create: UserCreate) -> User:
        """Create a new user"""
        # Check if user already exists
        existing_user = db.query(User).filter(
            (User.username == user_create.username) | 
            (User.email == user_create.email)
        ).first()
        
        if existing_user:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Username or email already registered"
            )
        
        # Create new user
        hashed_password = AuthService.get_password_hash(user_create.password)
        db_user = User(
            email=user_create.email,
            username=user_create.username,
            hashed_password=hashed_password
        )
        
        db.add(db_user)
        db.commit()
        db.refresh(db_user)

        AuthService._cache_user_credentials(
            username=db_user.username,
            hashed_password=hashed_password,
            email=db_user.email,
            user_id=db_user.id,
        )

        return db_user


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: Session = Depends(get_db)
) -> User:
    """Get current authenticated user from JWT token"""
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    
    try:
        token = credentials.credentials
        username = AuthService.verify_token(token)
        if username is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception
    
    user = db.query(User).filter(User.username == username).first()
    if user is None:
        raise credentials_exception
    
    return user


async def get_current_admin_user(
    current_user: User = Depends(get_current_user)
) -> User:
    """Get current authenticated admin user"""
    if not current_user.is_admin:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin access required"
        )
    return current_user
