-- Task Management System Database Setup
-- This script creates the database and initial setup

-- Create database (run this as superuser)
-- CREATE DATABASE task_management;
-- \c task_management;

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Create custom types
CREATE TYPE user_role AS ENUM ('admin', 'manager', 'developer', 'tester', 'viewer');
CREATE TYPE task_status AS ENUM ('pending', 'in_progress', 'review', 'completed', 'cancelled');
CREATE TYPE task_priority AS ENUM ('low', 'medium', 'high', 'urgent');
CREATE TYPE project_status AS ENUM ('planning', 'active', 'on_hold', 'completed', 'cancelled');

-- Set timezone
SET timezone = 'UTC';

-- Create schemas for better organization
CREATE SCHEMA IF NOT EXISTS app;
CREATE SCHEMA IF NOT EXISTS audit;

-- Grant permissions
GRANT USAGE ON SCHEMA app TO PUBLIC;
GRANT USAGE ON SCHEMA audit TO PUBLIC;

-- Create audit table for tracking changes
CREATE TABLE audit.audit_log (
    id SERIAL PRIMARY KEY,
    table_name VARCHAR(50) NOT NULL,
    operation VARCHAR(10) NOT NULL,
    old_values JSONB,
    new_values JSONB,
    changed_by INTEGER,
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX idx_audit_log_table_name ON audit.audit_log(table_name);
CREATE INDEX idx_audit_log_changed_at ON audit.audit_log(changed_at);
CREATE INDEX idx_audit_log_changed_by ON audit.audit_log(changed_by);

-- Success message
DO $$
BEGIN
    RAISE NOTICE 'Database setup completed successfully!';
    RAISE NOTICE 'Next steps:';
    RAISE NOTICE '1. Run: \i schema/tables.sql';
    RAISE NOTICE '2. Run: \i schema/functions.sql';
    RAISE NOTICE '3. Run: \i schema/triggers.sql';
    RAISE NOTICE '4. Run: \i data/sample_data.sql';
END $$;
