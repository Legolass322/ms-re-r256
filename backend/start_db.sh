#!/bin/bash

# ARIA Database Startup Script

echo "🚀 Starting ARIA Database Services..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

# Start PostgreSQL and Redis
echo "📦 Starting PostgreSQL and Redis containers..."
docker-compose up -d

# Wait for PostgreSQL to be ready
echo "⏳ Waiting for PostgreSQL to be ready..."
until docker exec aria_postgres pg_isready -U aria_user -d aria_db > /dev/null 2>&1; do
    echo "   PostgreSQL is starting up..."
    sleep 2
done

echo "✅ PostgreSQL is ready!"

# Wait for Redis to be ready
echo "⏳ Waiting for Redis to be ready..."
until docker exec aria_redis redis-cli ping > /dev/null 2>&1; do
    echo "   Redis is starting up..."
    sleep 2
done

echo "✅ Redis is ready!"

echo ""
echo "🎉 Database services are running!"
echo "📊 PostgreSQL: localhost:6000 (aria_db/aria_user)"
echo "🔴 Redis: localhost:6400"
echo ""
echo "To stop services: docker-compose down"
echo "To view logs: docker-compose logs -f"
