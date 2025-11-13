"""
Redis client configuration for ARIA backend.
"""

import os
from functools import lru_cache

import redis


def get_redis_url() -> str:
    """Resolve Redis connection URL from environment variables."""
    return os.getenv("REDIS_URL", "redis://localhost:6400/0")


@lru_cache()
def get_redis_client() -> redis.Redis:
    """Return a cached Redis client instance."""
    return redis.Redis.from_url(
        get_redis_url(),
        decode_responses=True,
        socket_timeout=5,
        socket_connect_timeout=5,
    )

