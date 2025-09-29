# Task Management System - Quick Setup Guide

## Overview
A simple PostgreSQL-based Task Management System with projects, tasks, users, and reporting.

## Prerequisites
- PostgreSQL 12+ with `psql`
- Text editor (VS Code, Notepad++, etc.)
- OS: Windows, macOS, or Linux

## Setup

### 1. Create Database and User
```sql
\c postgres
CREATE DATABASE task_management;
CREATE USER task_user WITH PASSWORD 'secure_password';
GRANT ALL PRIVILEGES ON DATABASE task_management TO task_user;
```

### 2. Initialize Schema and Tables
```sql
\c task_management
\i 'E:/My Projects/task-management-system/schema/setup.sql'
\i 'E:/My Projects/task-management-system/schema/tables.sql'
\i 'E:/My Projects/task-management-system/schema/functions.sql'
\i 'E:/My Projects/task-management-system/schema/triggers.sql'
```

### 3. Load Sample Data
```sql
\c task_management
\i 'E:/My Projects/task-management-system/data/sample_data.sql'
\i 'E:/My Projects/task-management-system/data/test_data.sql'
```

### 4. Verify Installation
```sql
\c task_management
\i 'E:/My Projects/task-management-system/queries/example_queries.sql'
```

## Quick Commands
```sql
-- Connect to DB
\c task_management -U task_user
-- List tables
\dt app.*
-- View table structure
\d app.users
-- Sample query
SELECT * FROM app.users;
```

## Notes
- Use forward slashes `/` in Windows paths.
- Ensure file paths are correct for `\i` commands.
- Use `psql` to run all commands; Bash/terminal commands are not needed.
- Backup: `\! pg_dump -U postgres -h localhost task_management > backup.sql`