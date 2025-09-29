-- Task Management System - Table Definitions
-- This script creates all the main tables for the system

-- Users table
CREATE TABLE app.users (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    role user_role DEFAULT 'developer',
    is_active BOOLEAN DEFAULT true,
    last_login TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT chk_username_length CHECK (LENGTH(username) >= 3),
    CONSTRAINT chk_email_format CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

-- Categories table
CREATE TABLE app.categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    color VARCHAR(7) DEFAULT '#3498db', -- Hex color code
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Projects table
CREATE TABLE app.projects (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    status project_status DEFAULT 'planning',
    start_date DATE,
    end_date DATE,
    budget DECIMAL(12,2),
    manager_id INTEGER REFERENCES app.users(id) ON DELETE SET NULL,
    created_by INTEGER REFERENCES app.users(id) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT chk_end_date_after_start CHECK (end_date IS NULL OR end_date >= start_date),
    CONSTRAINT chk_budget_positive CHECK (budget IS NULL OR budget >= 0)
);

-- Tasks table
CREATE TABLE app.tasks (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
    title VARCHAR(300) NOT NULL,
    description TEXT,
    status task_status DEFAULT 'pending',
    priority task_priority DEFAULT 'medium',
    project_id INTEGER REFERENCES app.projects(id) ON DELETE CASCADE,
    category_id INTEGER REFERENCES app.categories(id) ON DELETE SET NULL,
    assigned_to INTEGER REFERENCES app.users(id) ON DELETE SET NULL,
    created_by INTEGER REFERENCES app.users(id) NOT NULL,
    due_date TIMESTAMP WITH TIME ZONE,
    estimated_hours DECIMAL(5,2),
    actual_hours DECIMAL(5,2) DEFAULT 0,
    parent_task_id INTEGER REFERENCES app.tasks(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT chk_estimated_hours_positive CHECK (estimated_hours IS NULL OR estimated_hours >= 0),
    CONSTRAINT chk_actual_hours_positive CHECK (actual_hours >= 0),
    CONSTRAINT chk_no_self_reference CHECK (parent_task_id IS NULL OR parent_task_id != id)
);

-- Comments table
CREATE TABLE app.comments (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
    task_id INTEGER REFERENCES app.tasks(id) ON DELETE CASCADE NOT NULL,
    user_id INTEGER REFERENCES app.users(id) ON DELETE CASCADE NOT NULL,
    content TEXT NOT NULL,
    is_internal BOOLEAN DEFAULT false, -- Internal comments not visible to clients
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT chk_content_not_empty CHECK (LENGTH(TRIM(content)) > 0)
);

-- Attachments table
CREATE TABLE app.attachments (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
    task_id INTEGER REFERENCES app.tasks(id) ON DELETE CASCADE NOT NULL,
    uploaded_by INTEGER REFERENCES app.users(id) ON DELETE CASCADE NOT NULL,
    filename VARCHAR(255) NOT NULL,
    original_filename VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_size BIGINT NOT NULL,
    mime_type VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT chk_file_size_positive CHECK (file_size > 0)
);

-- Task dependencies table (for task relationships)
CREATE TABLE app.task_dependencies (
    id SERIAL PRIMARY KEY,
    task_id INTEGER REFERENCES app.tasks(id) ON DELETE CASCADE NOT NULL,
    depends_on_task_id INTEGER REFERENCES app.tasks(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT chk_no_self_dependency CHECK (task_id != depends_on_task_id),
    CONSTRAINT uk_task_dependency UNIQUE (task_id, depends_on_task_id)
);

-- Project members table (many-to-many relationship)
CREATE TABLE app.project_members (
    id SERIAL PRIMARY KEY,
    project_id INTEGER REFERENCES app.projects(id) ON DELETE CASCADE NOT NULL,
    user_id INTEGER REFERENCES app.users(id) ON DELETE CASCADE NOT NULL,
    role VARCHAR(50) DEFAULT 'member',
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT uk_project_member UNIQUE (project_id, user_id)
);

-- Create indexes for better performance
CREATE INDEX idx_users_email ON app.users(email);
CREATE INDEX idx_users_username ON app.users(username);
CREATE INDEX idx_users_role ON app.users(role);
CREATE INDEX idx_users_active ON app.users(is_active);

CREATE INDEX idx_projects_status ON app.projects(status);
CREATE INDEX idx_projects_manager ON app.projects(manager_id);
CREATE INDEX idx_projects_created_by ON app.projects(created_by);
CREATE INDEX idx_projects_dates ON app.projects(start_date, end_date);

CREATE INDEX idx_tasks_project ON app.tasks(project_id);
CREATE INDEX idx_tasks_status ON app.tasks(status);
CREATE INDEX idx_tasks_priority ON app.tasks(priority);
CREATE INDEX idx_tasks_assigned_to ON app.tasks(assigned_to);
CREATE INDEX idx_tasks_due_date ON app.tasks(due_date);
CREATE INDEX idx_tasks_parent ON app.tasks(parent_task_id);
CREATE INDEX idx_tasks_created_by ON app.tasks(created_by);

CREATE INDEX idx_comments_task ON app.comments(task_id);
CREATE INDEX idx_comments_user ON app.comments(user_id);
CREATE INDEX idx_comments_created_at ON app.comments(created_at);

CREATE INDEX idx_attachments_task ON app.attachments(task_id);
CREATE INDEX idx_attachments_uploaded_by ON app.attachments(uploaded_by);

CREATE INDEX idx_task_dependencies_task ON app.task_dependencies(task_id);
CREATE INDEX idx_task_dependencies_depends_on ON app.task_dependencies(depends_on_task_id);

CREATE INDEX idx_project_members_project ON app.project_members(project_id);
CREATE INDEX idx_project_members_user ON app.project_members(user_id);

-- Create composite indexes for common queries
CREATE INDEX idx_tasks_project_status ON app.tasks(project_id, status);
CREATE INDEX idx_tasks_assigned_status ON app.tasks(assigned_to, status);
CREATE INDEX idx_tasks_due_date_status ON app.tasks(due_date, status) WHERE due_date IS NOT NULL;

-- Success message
DO $$
BEGIN
    RAISE NOTICE 'All tables created successfully!';
    RAISE NOTICE 'Tables created:';
    RAISE NOTICE '- users (user management)';
    RAISE NOTICE '- categories (task categorization)';
    RAISE NOTICE '- projects (project management)';
    RAISE NOTICE '- tasks (task management)';
    RAISE NOTICE '- comments (task discussions)';
    RAISE NOTICE '- attachments (file management)';
    RAISE NOTICE '- task_dependencies (task relationships)';
    RAISE NOTICE '- project_members (project team management)';
    RAISE NOTICE '- audit_log (change tracking)';
END $$;
