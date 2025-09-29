-- Task Management System - Reports
-- This script contains comprehensive reports for business intelligence

-- ============================================================================
-- EXECUTIVE DASHBOARD REPORTS
-- ============================================================================

-- Report 1: Executive Summary Dashboard
CREATE OR REPLACE VIEW app.executive_dashboard AS
SELECT 
    'Total Projects' as metric,
    COUNT(*)::TEXT as value,
    'Projects' as unit
FROM app.projects
WHERE status != 'cancelled'

UNION ALL

SELECT 
    'Active Projects',
    COUNT(*)::TEXT,
    'Projects'
FROM app.projects
WHERE status = 'active'

UNION ALL

SELECT 
    'Total Tasks',
    COUNT(*)::TEXT,
    'Tasks'
FROM app.tasks

UNION ALL

SELECT 
    'Completed Tasks',
    COUNT(*)::TEXT,
    'Tasks'
FROM app.tasks
WHERE status = 'completed'

UNION ALL

SELECT 
    'Overdue Tasks',
    COUNT(*)::TEXT,
    'Tasks'
FROM app.tasks
WHERE due_date < NOW() AND status NOT IN ('completed', 'cancelled')

UNION ALL

SELECT 
    'Active Users',
    COUNT(*)::TEXT,
    'Users'
FROM app.users
WHERE is_active = true

UNION ALL

SELECT 
    'Total Budget',
    COALESCE(SUM(budget), 0)::TEXT,
    'USD'
FROM app.projects
WHERE status != 'cancelled';

-- Report 2: Project Performance Report
CREATE OR REPLACE VIEW app.project_performance AS
SELECT 
    p.id,
    p.name as project_name,
    p.status,
    p.start_date,
    p.end_date,
    p.budget,
    CONCAT(u.first_name, ' ', u.last_name) as manager_name,
    COUNT(t.id) as total_tasks,
    COUNT(t.id) FILTER (WHERE t.status = 'completed') as completed_tasks,
    COUNT(t.id) FILTER (WHERE t.status = 'in_progress') as in_progress_tasks,
    COUNT(t.id) FILTER (WHERE t.status = 'pending') as pending_tasks,
    ROUND(
        (COUNT(t.id) FILTER (WHERE t.status = 'completed')::DECIMAL / 
         NULLIF(COUNT(t.id), 0)::DECIMAL) * 100, 2
    ) as completion_percentage,
    SUM(t.estimated_hours) as total_estimated_hours,
    SUM(t.actual_hours) as total_actual_hours,
    ROUND(
        (SUM(t.actual_hours) / NULLIF(SUM(t.estimated_hours), 0)) * 100, 2
    ) as time_accuracy_percentage,
    COUNT(DISTINCT pm.user_id) as team_size
FROM app.projects p
LEFT JOIN app.users u ON p.manager_id = u.id
LEFT JOIN app.tasks t ON p.id = t.project_id
LEFT JOIN app.project_members pm ON p.id = pm.project_id
GROUP BY p.id, p.name, p.status, p.start_date, p.end_date, p.budget, u.first_name, u.last_name
ORDER BY completion_percentage DESC;

-- Report 3: Team Productivity Report
CREATE OR REPLACE VIEW app.team_productivity AS
SELECT 
    u.id,
    CONCAT(u.first_name, ' ', u.last_name) as full_name,
    u.role,
    u.email,
    COUNT(t.id) as total_tasks_assigned,
    COUNT(t.id) FILTER (WHERE t.status = 'completed') as completed_tasks,
    COUNT(t.id) FILTER (WHERE t.status = 'in_progress') as in_progress_tasks,
    COUNT(t.id) FILTER (WHERE t.status = 'pending') as pending_tasks,
    ROUND(
        (COUNT(t.id) FILTER (WHERE t.status = 'completed')::DECIMAL / 
         NULLIF(COUNT(t.id), 0)::DECIMAL) * 100, 2
    ) as completion_rate,
    SUM(t.estimated_hours) as total_estimated_hours,
    SUM(t.actual_hours) as total_actual_hours,
    ROUND(
        (SUM(t.actual_hours) / NULLIF(SUM(t.estimated_hours), 0)) * 100, 2
    ) as time_accuracy_percentage,
    AVG(t.actual_hours) FILTER (WHERE t.status = 'completed') as avg_hours_per_completed_task,
    COUNT(DISTINCT t.project_id) as projects_involved
FROM app.users u
LEFT JOIN app.tasks t ON u.id = t.assigned_to
WHERE u.is_active = true
GROUP BY u.id, u.first_name, u.last_name, u.role, u.email
ORDER BY completion_rate DESC;

-- ============================================================================
-- OPERATIONAL REPORTS
-- ============================================================================

-- Report 4: Overdue Tasks Report
CREATE OR REPLACE VIEW app.overdue_tasks_report AS
SELECT 
    t.id,
    t.title,
    t.status,
    t.priority,
    p.name as project_name,
    CONCAT(u.first_name, ' ', u.last_name) as assigned_to,
    u.email as assigned_email,
    t.due_date,
    EXTRACT(DAY FROM (NOW() - t.due_date))::INTEGER as days_overdue,
    c.name as category_name,
    CONCAT(creator.first_name, ' ', creator.last_name) as created_by,
    t.created_at
FROM app.tasks t
JOIN app.projects p ON t.project_id = p.id
LEFT JOIN app.users u ON t.assigned_to = u.id
LEFT JOIN app.categories c ON t.category_id = c.id
LEFT JOIN app.users creator ON t.created_by = creator.id
WHERE t.due_date < NOW()
AND t.status NOT IN ('completed', 'cancelled')
ORDER BY days_overdue DESC, t.priority;

-- Report 5: Upcoming Deadlines Report
CREATE OR REPLACE VIEW app.upcoming_deadlines AS
SELECT 
    t.id,
    t.title,
    t.status,
    t.priority,
    p.name as project_name,
    CONCAT(u.first_name, ' ', u.last_name) as assigned_to,
    u.email as assigned_email,
    t.due_date,
    EXTRACT(DAY FROM (t.due_date - NOW()))::INTEGER as days_until_due,
    c.name as category_name,
    t.estimated_hours,
    t.actual_hours
FROM app.tasks t
JOIN app.projects p ON t.project_id = p.id
LEFT JOIN app.users u ON t.assigned_to = u.id
LEFT JOIN app.categories c ON t.category_id = c.id
WHERE t.due_date IS NOT NULL
AND t.due_date BETWEEN NOW() AND NOW() + INTERVAL '30 days'
AND t.status NOT IN ('completed', 'cancelled')
ORDER BY t.due_date ASC;

-- Report 6: Budget Utilization Report
CREATE OR REPLACE VIEW app.budget_utilization AS
SELECT 
    p.id,
    p.name as project_name,
    p.status,
    p.budget,
    SUM(t.actual_hours) as total_hours_worked,
    ROUND(SUM(t.actual_hours) * 50, 2) as estimated_cost, -- Assuming $50/hour
    ROUND(
        (SUM(t.actual_hours) * 50 / NULLIF(p.budget, 0)) * 100, 2
    ) as budget_utilization_percentage,
    ROUND(p.budget - (SUM(t.actual_hours) * 50), 2) as remaining_budget,
    COUNT(t.id) as total_tasks,
    COUNT(t.id) FILTER (WHERE t.status = 'completed') as completed_tasks
FROM app.projects p
LEFT JOIN app.tasks t ON p.id = t.project_id
WHERE p.budget IS NOT NULL AND p.budget > 0
GROUP BY p.id, p.name, p.status, p.budget
ORDER BY budget_utilization_percentage DESC;

-- ============================================================================
-- ANALYTICS REPORTS
-- ============================================================================

-- Report 7: Monthly Task Completion Trends
CREATE OR REPLACE VIEW app.monthly_completion_trends AS
SELECT 
    DATE_TRUNC('month', updated_at) as month,
    COUNT(*) as tasks_completed,
    COUNT(DISTINCT project_id) as projects_with_completions,
    AVG(EXTRACT(EPOCH FROM (updated_at - created_at))/3600) as avg_completion_hours,
    SUM(actual_hours) as total_hours_worked
FROM app.tasks
WHERE status = 'completed'
AND updated_at >= NOW() - INTERVAL '12 months'
GROUP BY DATE_TRUNC('month', updated_at)
ORDER BY month DESC;

-- Report 8: Category Performance Analysis
CREATE OR REPLACE VIEW app.category_performance AS
SELECT 
    c.id,
    c.name as category_name,
    c.color,
    COUNT(t.id) as total_tasks,
    COUNT(t.id) FILTER (WHERE t.status = 'completed') as completed_tasks,
    COUNT(t.id) FILTER (WHERE t.status = 'in_progress') as in_progress_tasks,
    COUNT(t.id) FILTER (WHERE t.status = 'pending') as pending_tasks,
    ROUND(
        (COUNT(t.id) FILTER (WHERE t.status = 'completed')::DECIMAL / 
         NULLIF(COUNT(t.id), 0)::DECIMAL) * 100, 2
    ) as completion_rate,
    AVG(t.estimated_hours) as avg_estimated_hours,
    AVG(t.actual_hours) FILTER (WHERE t.status = 'completed') as avg_actual_hours,
    ROUND(
        (AVG(t.actual_hours) FILTER (WHERE t.status = 'completed') / 
         NULLIF(AVG(t.estimated_hours), 0)) * 100, 2
    ) as time_accuracy_percentage
FROM app.categories c
LEFT JOIN app.tasks t ON c.id = t.category_id
GROUP BY c.id, c.name, c.color
ORDER BY completion_rate DESC;

-- Report 9: Priority Distribution Analysis
CREATE OR REPLACE VIEW app.priority_distribution AS
SELECT 
    priority,
    COUNT(*) as task_count,
    ROUND(COUNT(*)::DECIMAL / (SELECT COUNT(*) FROM app.tasks) * 100, 2) as percentage,
    COUNT(*) FILTER (WHERE status = 'completed') as completed_count,
    ROUND(
        (COUNT(*) FILTER (WHERE status = 'completed')::DECIMAL / 
         NULLIF(COUNT(*), 0)::DECIMAL) * 100, 2
    ) as completion_rate,
    AVG(EXTRACT(EPOCH FROM (updated_at - created_at))/3600) FILTER (WHERE status = 'completed') as avg_completion_hours
FROM app.tasks
GROUP BY priority
ORDER BY 
    CASE priority 
        WHEN 'urgent' THEN 1 
        WHEN 'high' THEN 2 
        WHEN 'medium' THEN 3 
        WHEN 'low' THEN 4 
    END;

-- ============================================================================
-- MAINTENANCE REPORTS
-- ============================================================================

-- Report 10: Data Quality Report
CREATE OR REPLACE VIEW app.data_quality_report AS
SELECT 
    'Tasks without assigned user' as issue_type,
    COUNT(*) as count,
    'Consider assigning tasks to improve accountability' as recommendation
FROM app.tasks
WHERE assigned_to IS NULL

UNION ALL

SELECT 
    'Tasks without due date',
    COUNT(*),
    'Set due dates to improve project planning'
FROM app.tasks
WHERE due_date IS NULL AND status NOT IN ('completed', 'cancelled')

UNION ALL

SELECT 
    'Tasks without category',
    COUNT(*),
    'Categorize tasks for better organization'
FROM app.tasks
WHERE category_id IS NULL

UNION ALL

SELECT 
    'Users without recent activity',
    COUNT(*),
    'Consider deactivating inactive users'
FROM app.users
WHERE is_active = true AND last_login < NOW() - INTERVAL '90 days'

UNION ALL

SELECT 
    'Projects without tasks',
    COUNT(*),
    'Add tasks or consider archiving empty projects'
FROM app.projects p
LEFT JOIN app.tasks t ON p.id = t.project_id
WHERE t.id IS NULL AND p.status != 'cancelled';

-- Report 11: System Health Report
CREATE OR REPLACE VIEW app.system_health AS
SELECT 
    'Database Size' as metric,
    pg_size_pretty(pg_database_size(current_database())) as value
FROM pg_database
WHERE datname = current_database()

UNION ALL

SELECT 
    'Total Tables',
    COUNT(*)::TEXT
FROM information_schema.tables
WHERE table_schema = 'app'

UNION ALL

SELECT 
    'Total Indexes',
    COUNT(*)::TEXT
FROM pg_indexes
WHERE schemaname = 'app'

UNION ALL

SELECT 
    'Last Backup',
    'Not configured' -- This would be updated by backup scripts

UNION ALL

SELECT 
    'Active Connections',
    (SELECT setting FROM pg_settings WHERE name = 'max_connections')::TEXT;

-- ============================================================================
-- CUSTOM REPORT FUNCTIONS
-- ============================================================================

-- Function to generate custom project report
CREATE OR REPLACE FUNCTION app.generate_project_report(project_id INTEGER)
RETURNS TABLE(
    project_name VARCHAR(200),
    total_tasks BIGINT,
    completed_tasks BIGINT,
    in_progress_tasks BIGINT,
    pending_tasks BIGINT,
    overdue_tasks BIGINT,
    completion_percentage DECIMAL(5,2),
    total_estimated_hours DECIMAL(8,2),
    total_actual_hours DECIMAL(8,2),
    time_accuracy_percentage DECIMAL(5,2),
    team_size BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.name,
        COUNT(t.id),
        COUNT(t.id) FILTER (WHERE t.status = 'completed'),
        COUNT(t.id) FILTER (WHERE t.status = 'in_progress'),
        COUNT(t.id) FILTER (WHERE t.status = 'pending'),
        COUNT(t.id) FILTER (WHERE t.due_date < NOW() AND t.status NOT IN ('completed', 'cancelled')),
        ROUND(
            (COUNT(t.id) FILTER (WHERE t.status = 'completed')::DECIMAL / 
             NULLIF(COUNT(t.id), 0)::DECIMAL) * 100, 2
        ),
        SUM(t.estimated_hours),
        SUM(t.actual_hours),
        ROUND(
            (SUM(t.actual_hours) / NULLIF(SUM(t.estimated_hours), 0)) * 100, 2
        ),
        COUNT(DISTINCT pm.user_id)
    FROM app.projects p
    LEFT JOIN app.tasks t ON p.id = t.project_id
    LEFT JOIN app.project_members pm ON p.id = pm.project_id
    WHERE p.id = project_id
    GROUP BY p.id, p.name;
END;
$$ LANGUAGE plpgsql;

-- Function to generate user performance report
CREATE OR REPLACE FUNCTION app.generate_user_report(user_id INTEGER)
RETURNS TABLE(
    user_name TEXT,
    role user_role,
    total_tasks BIGINT,
    completed_tasks BIGINT,
    completion_rate DECIMAL(5,2),
    total_hours_worked DECIMAL(8,2),
    avg_hours_per_task DECIMAL(5,2),
    projects_involved BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        CONCAT(u.first_name, ' ', u.last_name),
        u.role,
        COUNT(t.id),
        COUNT(t.id) FILTER (WHERE t.status = 'completed'),
        ROUND(
            (COUNT(t.id) FILTER (WHERE t.status = 'completed')::DECIMAL / 
             NULLIF(COUNT(t.id), 0)::DECIMAL) * 100, 2
        ),
        SUM(t.actual_hours),
        AVG(t.actual_hours) FILTER (WHERE t.status = 'completed'),
        COUNT(DISTINCT t.project_id)
    FROM app.users u
    LEFT JOIN app.tasks t ON u.id = t.assigned_to
    WHERE u.id = user_id
    GROUP BY u.id, u.first_name, u.last_name, u.role;
END;
$$ LANGUAGE plpgsql;

-- Success message
DO $$
BEGIN
    RAISE NOTICE 'Reports created successfully!';
    RAISE NOTICE 'Available reports:';
    RAISE NOTICE '- Executive Dashboard (executive_dashboard view)';
    RAISE NOTICE '- Project Performance (project_performance view)';
    RAISE NOTICE '- Team Productivity (team_productivity view)';
    RAISE NOTICE '- Overdue Tasks (overdue_tasks_report view)';
    RAISE NOTICE '- Upcoming Deadlines (upcoming_deadlines view)';
    RAISE NOTICE '- Budget Utilization (budget_utilization view)';
    RAISE NOTICE '- Monthly Trends (monthly_completion_trends view)';
    RAISE NOTICE '- Category Performance (category_performance view)';
    RAISE NOTICE '- Priority Distribution (priority_distribution view)';
    RAISE NOTICE '- Data Quality (data_quality_report view)';
    RAISE NOTICE '- System Health (system_health view)';
    RAISE NOTICE '';
    RAISE NOTICE 'Custom report functions:';
    RAISE NOTICE '- app.generate_project_report(project_id)';
    RAISE NOTICE '- app.generate_user_report(user_id)';
    RAISE NOTICE '';
    RAISE NOTICE 'Example usage:';
    RAISE NOTICE 'SELECT * FROM app.executive_dashboard;';
    RAISE NOTICE 'SELECT * FROM app.generate_project_report(1);';
END $$;
