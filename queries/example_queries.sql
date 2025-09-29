-- Task Management System - Example Queries
-- This script contains useful queries for exploring and managing the system

-- ============================================================================
-- BASIC QUERIES
-- ============================================================================

-- 1. Get all active users
SELECT 
    id,
    username,
    email,
    CONCAT(first_name, ' ', last_name) as full_name,
    role,
    last_login,
    created_at
FROM app.users
WHERE is_active = true
ORDER BY created_at DESC;

-- 2. Get all projects with their managers
SELECT 
    p.id,
    p.name,
    p.status,
    p.start_date,
    p.end_date,
    p.budget,
    CONCAT(u.first_name, ' ', u.last_name) as manager_name,
    u.email as manager_email
FROM app.projects p
LEFT JOIN app.users u ON p.manager_id = u.id
ORDER BY p.created_at DESC;

-- 3. Get task count by status
SELECT 
    status,
    COUNT(*) as task_count
FROM app.tasks
GROUP BY status
ORDER BY task_count DESC;

-- 4. Get tasks assigned to a specific user
SELECT 
    t.id,
    t.title,
    t.status,
    t.priority,
    t.due_date,
    p.name as project_name,
    c.name as category_name
FROM app.tasks t
JOIN app.projects p ON t.project_id = p.id
LEFT JOIN app.categories c ON t.category_id = c.id
WHERE t.assigned_to = 3 -- Replace with actual user ID
ORDER BY t.due_date ASC NULLS LAST;

-- ============================================================================
-- ADVANCED QUERIES
-- ============================================================================

-- 5. Get project progress for all active projects
SELECT 
    p.id,
    p.name,
    p.status,
    COUNT(t.id) as total_tasks,
    COUNT(t.id) FILTER (WHERE t.status = 'completed') as completed_tasks,
    ROUND(
        (COUNT(t.id) FILTER (WHERE t.status = 'completed')::DECIMAL / 
         NULLIF(COUNT(t.id), 0)::DECIMAL) * 100, 2
    ) as progress_percentage,
    app.calculate_project_progress(p.id) as calculated_progress
FROM app.projects p
LEFT JOIN app.tasks t ON p.id = t.project_id
WHERE p.status IN ('active', 'planning')
GROUP BY p.id, p.name, p.status
ORDER BY progress_percentage DESC;

-- 6. Get overdue tasks with details
SELECT 
    t.id,
    t.title,
    p.name as project_name,
    CONCAT(u.first_name, ' ', u.last_name) as assigned_to,
    t.due_date,
    EXTRACT(DAY FROM (NOW() - t.due_date))::INTEGER as days_overdue,
    c.name as category_name
FROM app.tasks t
JOIN app.projects p ON t.project_id = p.id
LEFT JOIN app.users u ON t.assigned_to = u.id
LEFT JOIN app.categories c ON t.category_id = c.id
WHERE t.due_date < NOW()
AND t.status NOT IN ('completed', 'cancelled')
ORDER BY t.due_date ASC;

-- 7. Get user workload (tasks assigned per user)
SELECT 
    u.id,
    CONCAT(u.first_name, ' ', u.last_name) as full_name,
    u.role,
    COUNT(t.id) as total_tasks,
    COUNT(t.id) FILTER (WHERE t.status = 'pending') as pending_tasks,
    COUNT(t.id) FILTER (WHERE t.status = 'in_progress') as in_progress_tasks,
    COUNT(t.id) FILTER (WHERE t.status = 'completed') as completed_tasks,
    SUM(t.estimated_hours) as total_estimated_hours,
    SUM(t.actual_hours) as total_actual_hours
FROM app.users u
LEFT JOIN app.tasks t ON u.id = t.assigned_to
WHERE u.is_active = true
GROUP BY u.id, u.first_name, u.last_name, u.role
ORDER BY total_tasks DESC;

-- 8. Get task dependencies (what tasks depend on what)
SELECT 
    t1.title as task_title,
    t1.status as task_status,
    p1.name as project_name,
    t2.title as depends_on_title,
    t2.status as depends_on_status,
    p2.name as depends_on_project
FROM app.task_dependencies td
JOIN app.tasks t1 ON td.task_id = t1.id
JOIN app.tasks t2 ON td.depends_on_task_id = t2.id
JOIN app.projects p1 ON t1.project_id = p1.id
JOIN app.projects p2 ON t2.project_id = p2.id
ORDER BY t1.title;

-- 9. Get recent activity (comments and task updates)
SELECT 
    'Comment' as activity_type,
    c.created_at,
    CONCAT(u.first_name, ' ', u.last_name) as user_name,
    t.title as task_title,
    p.name as project_name,
    LEFT(c.content, 100) as content_preview
FROM app.comments c
JOIN app.users u ON c.user_id = u.id
JOIN app.tasks t ON c.task_id = t.id
JOIN app.projects p ON t.project_id = p.id
WHERE c.created_at >= NOW() - INTERVAL '7 days'

UNION ALL

SELECT 
    'Task Update' as activity_type,
    t.updated_at,
    CONCAT(u.first_name, ' ', u.last_name) as user_name,
    t.title as task_title,
    p.name as project_name,
    'Status: ' || t.status as content_preview
FROM app.tasks t
JOIN app.users u ON t.assigned_to = u.id
JOIN app.projects p ON t.project_id = p.id
WHERE t.updated_at >= NOW() - INTERVAL '7 days'
AND t.updated_at != t.created_at

ORDER BY created_at DESC
LIMIT 20;

-- 10. Get project team members with their roles
SELECT 
    p.name as project_name,
    CONCAT(u.first_name, ' ', u.last_name) as member_name,
    u.email,
    u.role as user_role,
    pm.role as project_role,
    pm.joined_at
FROM app.projects p
JOIN app.project_members pm ON p.id = pm.project_id
JOIN app.users u ON pm.user_id = u.id
WHERE p.status != 'cancelled'
ORDER BY p.name, pm.role, u.last_name;

-- ============================================================================
-- ANALYTICS QUERIES
-- ============================================================================

-- 11. Get monthly task completion statistics
SELECT 
    DATE_TRUNC('month', updated_at) as month,
    COUNT(*) as completed_tasks,
    AVG(EXTRACT(EPOCH FROM (updated_at - created_at))/3600) as avg_completion_hours
FROM app.tasks
WHERE status = 'completed'
AND updated_at >= NOW() - INTERVAL '12 months'
GROUP BY DATE_TRUNC('month', updated_at)
ORDER BY month DESC;

-- 12. Get category performance (tasks completed per category)
SELECT 
    c.name as category_name,
    c.color,
    COUNT(t.id) as total_tasks,
    COUNT(t.id) FILTER (WHERE t.status = 'completed') as completed_tasks,
    ROUND(
        (COUNT(t.id) FILTER (WHERE t.status = 'completed')::DECIMAL / 
         NULLIF(COUNT(t.id), 0)::DECIMAL) * 100, 2
    ) as completion_rate,
    AVG(t.actual_hours) FILTER (WHERE t.status = 'completed') as avg_completion_hours
FROM app.categories c
LEFT JOIN app.tasks t ON c.id = t.category_id
GROUP BY c.id, c.name, c.color
ORDER BY completion_rate DESC;

-- 13. Get project budget vs actual hours (cost analysis)
SELECT 
    p.name as project_name,
    p.budget,
    SUM(t.actual_hours) as total_actual_hours,
    SUM(t.estimated_hours) as total_estimated_hours,
    CASE 
        WHEN p.budget > 0 THEN ROUND((SUM(t.actual_hours) * 50) / p.budget * 100, 2) -- Assuming $50/hour
        ELSE NULL
    END as budget_utilization_percentage
FROM app.projects p
LEFT JOIN app.tasks t ON p.id = t.project_id
WHERE p.budget IS NOT NULL
GROUP BY p.id, p.name, p.budget
ORDER BY budget_utilization_percentage DESC;

-- 14. Get task priority distribution
SELECT 
    priority,
    COUNT(*) as task_count,
    ROUND(COUNT(*)::DECIMAL / (SELECT COUNT(*) FROM app.tasks) * 100, 2) as percentage
FROM app.tasks
GROUP BY priority
ORDER BY 
    CASE priority 
        WHEN 'urgent' THEN 1 
        WHEN 'high' THEN 2 
        WHEN 'medium' THEN 3 
        WHEN 'low' THEN 4 
    END;

-- 15. Get user productivity metrics
SELECT 
    CONCAT(u.first_name, ' ', u.last_name) as full_name,
    u.role,
    COUNT(t.id) as total_tasks_assigned,
    COUNT(t.id) FILTER (WHERE t.status = 'completed') as completed_tasks,
    ROUND(
        (COUNT(t.id) FILTER (WHERE t.status = 'completed')::DECIMAL / 
         NULLIF(COUNT(t.id), 0)::DECIMAL) * 100, 2
    ) as completion_rate,
    SUM(t.actual_hours) as total_hours_worked,
    AVG(t.actual_hours) FILTER (WHERE t.status = 'completed') as avg_hours_per_task
FROM app.users u
LEFT JOIN app.tasks t ON u.id = t.assigned_to
WHERE u.is_active = true
GROUP BY u.id, u.first_name, u.last_name, u.role
HAVING COUNT(t.id) > 0
ORDER BY completion_rate DESC;

-- ============================================================================
-- SEARCH AND FILTER QUERIES
-- ============================================================================

-- 16. Search tasks by keyword
SELECT 
    t.id,
    t.title,
    t.description,
    t.status,
    t.priority,
    p.name as project_name,
    CONCAT(u.first_name, ' ', u.last_name) as assigned_to,
    t.due_date
FROM app.tasks t
JOIN app.projects p ON t.project_id = p.id
LEFT JOIN app.users u ON t.assigned_to = u.id
WHERE (
    t.title ILIKE '%authentication%' OR
    t.description ILIKE '%authentication%'
)
ORDER BY 
    CASE t.priority 
        WHEN 'urgent' THEN 1 
        WHEN 'high' THEN 2 
        WHEN 'medium' THEN 3 
        WHEN 'low' THEN 4 
    END,
    t.due_date ASC NULLS LAST;

-- 17. Get tasks by date range
SELECT 
    t.id,
    t.title,
    t.status,
    t.priority,
    p.name as project_name,
    t.created_at,
    t.due_date
FROM app.tasks t
JOIN app.projects p ON t.project_id = p.id
WHERE t.created_at BETWEEN '2024-01-01' AND '2024-12-31'
ORDER BY t.created_at DESC;

-- 18. Get tasks by multiple criteria
SELECT 
    t.id,
    t.title,
    t.status,
    t.priority,
    p.name as project_name,
    c.name as category_name,
    CONCAT(u.first_name, ' ', u.last_name) as assigned_to,
    t.due_date
FROM app.tasks t
JOIN app.projects p ON t.project_id = p.id
LEFT JOIN app.categories c ON t.category_id = c.id
LEFT JOIN app.users u ON t.assigned_to = u.id
WHERE t.status = 'in_progress'
AND t.priority IN ('high', 'urgent')
AND t.due_date IS NOT NULL
AND t.due_date <= NOW() + INTERVAL '7 days'
ORDER BY t.priority, t.due_date;

-- ============================================================================
-- MAINTENANCE QUERIES
-- ============================================================================

-- 19. Find orphaned records
SELECT 'Tasks without valid project' as issue_type, COUNT(*) as count
FROM app.tasks t
LEFT JOIN app.projects p ON t.project_id = p.id
WHERE p.id IS NULL

UNION ALL

SELECT 'Comments without valid task', COUNT(*)
FROM app.comments c
LEFT JOIN app.tasks t ON c.task_id = t.id
WHERE t.id IS NULL

UNION ALL

SELECT 'Attachments without valid task', COUNT(*)
FROM app.attachments a
LEFT JOIN app.tasks t ON a.task_id = t.id
WHERE t.id IS NULL;

-- 20. Get database statistics
SELECT 
    'Total Users' as metric, COUNT(*)::TEXT as value
FROM app.users
WHERE is_active = true

UNION ALL

SELECT 'Total Projects', COUNT(*)::TEXT
FROM app.projects

UNION ALL

SELECT 'Total Tasks', COUNT(*)::TEXT
FROM app.tasks

UNION ALL

SELECT 'Completed Tasks', COUNT(*)::TEXT
FROM app.tasks
WHERE status = 'completed'

UNION ALL

SELECT 'Overdue Tasks', COUNT(*)::TEXT
FROM app.tasks
WHERE due_date < NOW() AND status NOT IN ('completed', 'cancelled')

UNION ALL

SELECT 'Total Comments', COUNT(*)::TEXT
FROM app.comments

UNION ALL

SELECT 'Total Attachments', COUNT(*)::TEXT
FROM app.attachments;

-- Success message
DO $$
BEGIN
    RAISE NOTICE 'Example queries loaded successfully!';
    RAISE NOTICE 'Query categories:';
    RAISE NOTICE '- Basic queries (1-4): Simple data retrieval';
    RAISE NOTICE '- Advanced queries (5-10): Complex joins and aggregations';
    RAISE NOTICE '- Analytics queries (11-15): Business intelligence and metrics';
    RAISE NOTICE '- Search queries (16-18): Filtering and searching';
    RAISE NOTICE '- Maintenance queries (19-20): System health and statistics';
    RAISE NOTICE '';
    RAISE NOTICE 'You can run individual queries or modify them for your needs!';
END $$;
