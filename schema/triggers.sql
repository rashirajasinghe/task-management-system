-- Task Management System - Triggers
-- This script creates triggers for data integrity and automation

-- Trigger to automatically update updated_at timestamp on users table
CREATE TRIGGER trigger_users_updated_at
    BEFORE UPDATE ON app.users
    FOR EACH ROW
    EXECUTE FUNCTION app.update_updated_at_column();

-- Trigger to automatically update updated_at timestamp on categories table
CREATE TRIGGER trigger_categories_updated_at
    BEFORE UPDATE ON app.categories
    FOR EACH ROW
    EXECUTE FUNCTION app.update_updated_at_column();

-- Trigger to automatically update updated_at timestamp on projects table
CREATE TRIGGER trigger_projects_updated_at
    BEFORE UPDATE ON app.projects
    FOR EACH ROW
    EXECUTE FUNCTION app.update_updated_at_column();

-- Trigger to automatically update updated_at timestamp on tasks table
CREATE TRIGGER trigger_tasks_updated_at
    BEFORE UPDATE ON app.tasks
    FOR EACH ROW
    EXECUTE FUNCTION app.update_updated_at_column();

-- Trigger to automatically update updated_at timestamp on comments table
CREATE TRIGGER trigger_comments_updated_at
    BEFORE UPDATE ON app.comments
    FOR EACH ROW
    EXECUTE FUNCTION app.update_updated_at_column();

-- Trigger to validate task dependencies and prevent circular references
CREATE TRIGGER trigger_validate_task_dependencies
    BEFORE INSERT OR UPDATE ON app.task_dependencies
    FOR EACH ROW
    EXECUTE FUNCTION app.validate_task_dependencies();

-- Trigger to log audit changes for users table
CREATE TRIGGER trigger_audit_users
    AFTER INSERT OR UPDATE OR DELETE ON app.users
    FOR EACH ROW
    EXECUTE FUNCTION app.log_audit_change();

-- Trigger to log audit changes for projects table
CREATE TRIGGER trigger_audit_projects
    AFTER INSERT OR UPDATE OR DELETE ON app.projects
    FOR EACH ROW
    EXECUTE FUNCTION app.log_audit_change();

-- Trigger to log audit changes for tasks table
CREATE TRIGGER trigger_audit_tasks
    AFTER INSERT OR UPDATE OR DELETE ON app.tasks
    FOR EACH ROW
    EXECUTE FUNCTION app.log_audit_change();

-- Trigger to log audit changes for comments table
CREATE TRIGGER trigger_audit_comments
    AFTER INSERT OR UPDATE OR DELETE ON app.comments
    FOR EACH ROW
    EXECUTE FUNCTION app.log_audit_change();

-- Trigger to automatically add project creator as a project member
CREATE OR REPLACE FUNCTION app.auto_add_project_creator()
RETURNS TRIGGER AS $$
BEGIN
    -- Add the creator as a project member with 'manager' role
    INSERT INTO app.project_members (project_id, user_id, role)
    VALUES (NEW.id, NEW.created_by, 'manager')
    ON CONFLICT (project_id, user_id) DO NOTHING;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_auto_add_project_creator
    AFTER INSERT ON app.projects
    FOR EACH ROW
    EXECUTE FUNCTION app.auto_add_project_creator();

-- Trigger to validate task assignment (ensure assigned user is a project member)
CREATE OR REPLACE FUNCTION app.validate_task_assignment()
RETURNS TRIGGER AS $$
DECLARE
    is_member BOOLEAN;
BEGIN
    -- If no assignment, allow it
    IF NEW.assigned_to IS NULL THEN
        RETURN NEW;
    END IF;
    
    -- Check if assigned user is a member of the project
    SELECT EXISTS(
        SELECT 1 FROM app.project_members pm
        WHERE pm.project_id = NEW.project_id 
        AND pm.user_id = NEW.assigned_to
    ) INTO is_member;
    
    IF NOT is_member THEN
        RAISE EXCEPTION 'User % is not a member of project %. Cannot assign task.', NEW.assigned_to, NEW.project_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_validate_task_assignment
    BEFORE INSERT OR UPDATE ON app.tasks
    FOR EACH ROW
    EXECUTE FUNCTION app.validate_task_assignment();

-- Trigger to update project status based on task completion
CREATE OR REPLACE FUNCTION app.update_project_status()
RETURNS TRIGGER AS $$
DECLARE
    project_id INTEGER;
    total_tasks INTEGER;
    completed_tasks INTEGER;
    in_progress_tasks INTEGER;
    pending_tasks INTEGER;
BEGIN
    -- Get project ID from the task
    project_id := COALESCE(NEW.project_id, OLD.project_id);
    
    -- Count tasks by status
    SELECT 
        COUNT(*),
        COUNT(*) FILTER (WHERE status = 'completed'),
        COUNT(*) FILTER (WHERE status = 'in_progress'),
        COUNT(*) FILTER (WHERE status = 'pending')
    INTO total_tasks, completed_tasks, in_progress_tasks, pending_tasks
    FROM app.tasks
    WHERE project_id = project_id;
    
    -- Update project status based on task completion
    IF total_tasks = 0 THEN
        -- No tasks, keep current status
        NULL;
    ELSIF completed_tasks = total_tasks THEN
        -- All tasks completed
        UPDATE app.projects 
        SET status = 'completed', updated_at = NOW()
        WHERE id = project_id AND status != 'completed';
    ELSIF completed_tasks > 0 OR in_progress_tasks > 0 THEN
        -- Some progress made
        UPDATE app.projects 
        SET status = 'active', updated_at = NOW()
        WHERE id = project_id AND status = 'planning';
    END IF;
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_project_status
    AFTER INSERT OR UPDATE OR DELETE ON app.tasks
    FOR EACH ROW
    EXECUTE FUNCTION app.update_project_status();

-- Trigger to prevent deletion of users who are project managers
CREATE OR REPLACE FUNCTION app.prevent_manager_deletion()
RETURNS TRIGGER AS $$
DECLARE
    managed_projects INTEGER;
BEGIN
    -- Count projects managed by this user
    SELECT COUNT(*) INTO managed_projects
    FROM app.projects
    WHERE manager_id = OLD.id;
    
    IF managed_projects > 0 THEN
        RAISE EXCEPTION 'Cannot delete user %. User is managing % project(s). Please reassign projects first.', 
            OLD.username, managed_projects;
    END IF;
    
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_prevent_manager_deletion
    BEFORE DELETE ON app.users
    FOR EACH ROW
    EXECUTE FUNCTION app.prevent_manager_deletion();

-- Trigger to clean up orphaned attachments when tasks are deleted
CREATE OR REPLACE FUNCTION app.cleanup_attachments()
RETURNS TRIGGER AS $$
BEGIN
    -- Delete associated attachments
    DELETE FROM app.attachments WHERE task_id = OLD.id;
    
    -- Note: In a real application, you might want to move files to a trash folder
    -- instead of deleting them immediately
    
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_cleanup_attachments
    BEFORE DELETE ON app.tasks
    FOR EACH ROW
    EXECUTE FUNCTION app.cleanup_attachments();

-- Trigger to validate file size limits for attachments
CREATE OR REPLACE FUNCTION app.validate_attachment_size()
RETURNS TRIGGER AS $$
DECLARE
    max_size BIGINT := 10485760; -- 10MB in bytes
BEGIN
    IF NEW.file_size > max_size THEN
        RAISE EXCEPTION 'File size (%, bytes) exceeds maximum allowed size (%, bytes)', 
            NEW.file_size, max_size;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_validate_attachment_size
    BEFORE INSERT ON app.attachments
    FOR EACH ROW
    EXECUTE FUNCTION app.validate_attachment_size();

-- Success message
DO $$
BEGIN
    RAISE NOTICE 'All triggers created successfully!';
    RAISE NOTICE 'Triggers created:';
    RAISE NOTICE '- Auto-update timestamps on all main tables';
    RAISE NOTICE '- Validate task dependencies (prevent circular references)';
    RAISE NOTICE '- Audit logging for all main tables';
    RAISE NOTICE '- Auto-add project creator as member';
    RAISE NOTICE '- Validate task assignment (user must be project member)';
    RAISE NOTICE '- Update project status based on task completion';
    RAISE NOTICE '- Prevent deletion of project managers';
    RAISE NOTICE '- Clean up orphaned attachments';
    RAISE NOTICE '- Validate attachment file size limits';
END $$;
