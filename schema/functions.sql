-- Task Management System - Functions and Stored Procedures
-- This script creates useful functions for the system

-- Function to update the updated_at timestamp
CREATE OR REPLACE FUNCTION app.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Function to hash passwords
CREATE OR REPLACE FUNCTION app.hash_password(password TEXT)
RETURNS TEXT AS $$
BEGIN
    RETURN crypt(password, gen_salt('bf'));
END;
$$ LANGUAGE plpgsql;

-- Function to verify passwords
CREATE OR REPLACE FUNCTION app.verify_password(password TEXT, hash TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN hash = crypt(password, hash);
END;
$$ LANGUAGE plpgsql;

-- Function to get user's full name
CREATE OR REPLACE FUNCTION app.get_user_full_name(user_id INTEGER)
RETURNS TEXT AS $$
DECLARE
    full_name TEXT;
BEGIN
    SELECT CONCAT(first_name, ' ', last_name) INTO full_name
    FROM app.users
    WHERE id = user_id;
    
    RETURN COALESCE(full_name, 'Unknown User');
END;
$$ LANGUAGE plpgsql;

-- Function to get task hierarchy (parent-child relationships)
CREATE OR REPLACE FUNCTION app.get_task_hierarchy(task_id INTEGER)
RETURNS TABLE(
    task_id INTEGER,
    title VARCHAR(300),
    level INTEGER,
    path TEXT
) AS $$
BEGIN
    RETURN QUERY
    WITH RECURSIVE task_tree AS (
        -- Base case: the root task
        SELECT 
            t.id,
            t.title,
            0 as level,
            t.title::TEXT as path
        FROM app.tasks t
        WHERE t.id = task_id
        
        UNION ALL
        
        -- Recursive case: child tasks
        SELECT 
            t.id,
            t.title,
            tt.level + 1,
            tt.path || ' > ' || t.title
        FROM app.tasks t
        JOIN task_tree tt ON t.parent_task_id = tt.task_id
    )
    SELECT 
        tt.task_id,
        tt.title,
        tt.level,
        tt.path
    FROM task_tree tt
    ORDER BY tt.level, tt.title;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate project progress
CREATE OR REPLACE FUNCTION app.calculate_project_progress(project_id INTEGER)
RETURNS DECIMAL(5,2) AS $$
DECLARE
    total_tasks INTEGER;
    completed_tasks INTEGER;
    progress DECIMAL(5,2);
BEGIN
    -- Count total tasks in project
    SELECT COUNT(*) INTO total_tasks
    FROM app.tasks
    WHERE project_id = project_id;
    
    -- Count completed tasks
    SELECT COUNT(*) INTO completed_tasks
    FROM app.tasks
    WHERE project_id = project_id AND status = 'completed';
    
    -- Calculate progress percentage
    IF total_tasks = 0 THEN
        progress := 0;
    ELSE
        progress := (completed_tasks::DECIMAL / total_tasks::DECIMAL) * 100;
    END IF;
    
    RETURN ROUND(progress, 2);
END;
$$ LANGUAGE plpgsql;

-- Function to get overdue tasks
CREATE OR REPLACE FUNCTION app.get_overdue_tasks(user_id INTEGER DEFAULT NULL)
RETURNS TABLE(
    task_id INTEGER,
    title VARCHAR(300),
    project_name VARCHAR(200),
    assigned_to_name TEXT,
    due_date TIMESTAMP WITH TIME ZONE,
    days_overdue INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        t.id,
        t.title,
        p.name,
        app.get_user_full_name(t.assigned_to),
        t.due_date,
        EXTRACT(DAY FROM (NOW() - t.due_date))::INTEGER as days_overdue
    FROM app.tasks t
    JOIN app.projects p ON t.project_id = p.id
    WHERE t.due_date < NOW()
    AND t.status NOT IN ('completed', 'cancelled')
    AND (user_id IS NULL OR t.assigned_to = user_id)
    ORDER BY t.due_date ASC;
END;
$$ LANGUAGE plpgsql;

-- Function to get task statistics
CREATE OR REPLACE FUNCTION app.get_task_statistics(project_id INTEGER DEFAULT NULL)
RETURNS TABLE(
    total_tasks BIGINT,
    pending_tasks BIGINT,
    in_progress_tasks BIGINT,
    completed_tasks BIGINT,
    overdue_tasks BIGINT,
    avg_completion_time DECIMAL(5,2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*) as total_tasks,
        COUNT(*) FILTER (WHERE status = 'pending') as pending_tasks,
        COUNT(*) FILTER (WHERE status = 'in_progress') as in_progress_tasks,
        COUNT(*) FILTER (WHERE status = 'completed') as completed_tasks,
        COUNT(*) FILTER (WHERE due_date < NOW() AND status NOT IN ('completed', 'cancelled')) as overdue_tasks,
        AVG(EXTRACT(EPOCH FROM (updated_at - created_at))/3600) FILTER (WHERE status = 'completed') as avg_completion_time
    FROM app.tasks
    WHERE (project_id IS NULL OR project_id = project_id);
END;
$$ LANGUAGE plpgsql;

-- Function to search tasks
CREATE OR REPLACE FUNCTION app.search_tasks(
    search_term TEXT,
    project_id INTEGER DEFAULT NULL,
    status_filter task_status DEFAULT NULL,
    priority_filter task_priority DEFAULT NULL
)
RETURNS TABLE(
    task_id INTEGER,
    title VARCHAR(300),
    description TEXT,
    status task_status,
    priority task_priority,
    project_name VARCHAR(200),
    assigned_to_name TEXT,
    due_date TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        t.id,
        t.title,
        t.description,
        t.status,
        t.priority,
        p.name,
        app.get_user_full_name(t.assigned_to),
        t.due_date
    FROM app.tasks t
    JOIN app.projects p ON t.project_id = p.id
    WHERE (
        t.title ILIKE '%' || search_term || '%' OR
        t.description ILIKE '%' || search_term || '%'
    )
    AND (project_id IS NULL OR t.project_id = project_id)
    AND (status_filter IS NULL OR t.status = status_filter)
    AND (priority_filter IS NULL OR t.priority = priority_filter)
    ORDER BY 
        CASE t.priority 
            WHEN 'urgent' THEN 1 
            WHEN 'high' THEN 2 
            WHEN 'medium' THEN 3 
            WHEN 'low' THEN 4 
        END,
        t.due_date ASC NULLS LAST;
END;
$$ LANGUAGE plpgsql;

-- Function to create a new user with hashed password
CREATE OR REPLACE FUNCTION app.create_user(
    p_username VARCHAR(50),
    p_email VARCHAR(255),
    p_password TEXT,
    p_first_name VARCHAR(100),
    p_last_name VARCHAR(100),
    p_role user_role DEFAULT 'developer'
)
RETURNS INTEGER AS $$
DECLARE
    user_id INTEGER;
BEGIN
    INSERT INTO app.users (username, email, password_hash, first_name, last_name, role)
    VALUES (p_username, p_email, app.hash_password(p_password), p_first_name, p_last_name, p_role)
    RETURNING id INTO user_id;
    
    RETURN user_id;
END;
$$ LANGUAGE plpgsql;

-- Function to validate task dependencies (prevent circular dependencies)
CREATE OR REPLACE FUNCTION app.validate_task_dependencies()
RETURNS TRIGGER AS $$
DECLARE
    circular_check INTEGER;
BEGIN
    -- Check for circular dependencies
    WITH RECURSIVE dependency_chain AS (
        SELECT NEW.task_id as task_id, NEW.depends_on_task_id as depends_on_task_id, 1 as depth
        UNION ALL
        SELECT dc.task_id, td.depends_on_task_id, dc.depth + 1
        FROM dependency_chain dc
        JOIN app.task_dependencies td ON dc.depends_on_task_id = td.task_id
        WHERE dc.depth < 10 -- Prevent infinite recursion
    )
    SELECT COUNT(*) INTO circular_check
    FROM dependency_chain
    WHERE task_id = depends_on_task_id;
    
    IF circular_check > 0 THEN
        RAISE EXCEPTION 'Circular dependency detected! Task % cannot depend on itself.', NEW.task_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to log audit changes
CREATE OR REPLACE FUNCTION app.log_audit_change()
RETURNS TRIGGER AS $$
DECLARE
    old_data JSONB;
    new_data JSONB;
BEGIN
    -- Convert OLD and NEW records to JSONB
    IF TG_OP = 'DELETE' THEN
        old_data := to_jsonb(OLD);
        new_data := NULL;
    ELSIF TG_OP = 'INSERT' THEN
        old_data := NULL;
        new_data := to_jsonb(NEW);
    ELSE -- UPDATE
        old_data := to_jsonb(OLD);
        new_data := to_jsonb(NEW);
    END IF;
    
    -- Insert audit record
    INSERT INTO audit.audit_log (table_name, operation, old_values, new_values, changed_by)
    VALUES (TG_TABLE_NAME, TG_OP, old_data, new_data, 
            COALESCE(NEW.id, OLD.id) -- Use the record ID as changed_by for simplicity
    );
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Success message
DO $$
BEGIN
    RAISE NOTICE 'All functions and stored procedures created successfully!';
    RAISE NOTICE 'Functions created:';
    RAISE NOTICE '- update_updated_at_column() - Auto-update timestamps';
    RAISE NOTICE '- hash_password() / verify_password() - Password security';
    RAISE NOTICE '- get_user_full_name() - User utilities';
    RAISE NOTICE '- get_task_hierarchy() - Task relationships';
    RAISE NOTICE '- calculate_project_progress() - Project metrics';
    RAISE NOTICE '- get_overdue_tasks() - Task monitoring';
    RAISE NOTICE '- get_task_statistics() - Analytics';
    RAISE NOTICE '- search_tasks() - Search functionality';
    RAISE NOTICE '- create_user() - User management';
    RAISE NOTICE '- validate_task_dependencies() - Data integrity';
    RAISE NOTICE '- log_audit_change() - Audit logging';
END $$;
