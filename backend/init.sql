-- ARIA Database Initialization Script
-- This script runs when PostgreSQL container starts for the first time

-- Create database if it doesn't exist (already created by POSTGRES_DB env var)
-- CREATE DATABASE IF NOT EXISTS aria_db;

-- Create extensions if needed
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Grant permissions
GRANT ALL PRIVILEGES ON DATABASE aria_db TO aria_user;
