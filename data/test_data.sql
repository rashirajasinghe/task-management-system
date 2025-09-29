-- Task Management System - Test Data
-- This script creates additional test data for comprehensive testing

-- Insert additional test users for different scenarios
INSERT INTO app.users (username, email, password_hash, first_name, last_name, role, is_active) VALUES
('test.inactive', 'inactive@company.com', app.hash_password('password123'), 'Inactive', 'User', 'developer', false),
('test.manager2', 'manager2@company.com', app.hash_password('password123'), 'Test', 'Manager', 'manager', true),
('test.developer', 'dev@company.com', app.hash_password('password123'), 'Test', 'Developer', 'developer', true),
('test.tester', 'tester@company.com', app.hash_password('password123'), 'Test', 'Tester', 'tester', true);

-- Insert test project for edge cases
INSERT INTO app.projects (name, description, status, start_date, end_date, budget, manager_id, created_by) VALUES
('Test Project - Edge Cases', 'Project for testing various edge cases and scenarios', 'active', '2024-01-01', '2024-12-31', 10000.00, 9, 1),
('Empty Project', 'Project with no tasks for testing empty states', 'planning', '2024-06-01', '2024-12-31', 5000.00, 9, 1);

-- Add members to test projects
INSERT INTO app.project_members (project_id, user_id, role) VALUES
(6, 9, 'manager'),
(6, 10, 'developer'),
(6, 11, 'tester'),
(7, 9, 'manager');

-- Insert test tasks with various edge cases
INSERT INTO app.tasks (title, description, status, priority, project_id, category_id, assigned_to, created_by, due_date, estimated_hours) VALUES
-- Tasks with no due date
('Task with No Due Date', 'This task has no due date set', 'pending', 'medium', 6, 1, 10, 9, NULL, 8.0),
-- Task with very high priority
('Critical Security Issue', 'Immediate security vulnerability that needs fixing', 'pending', 'urgent', 6, 1, 10, 9, NOW() + INTERVAL '1 day', 4.0),
-- Task with very long description
('Task with Long Description', 
 'This is a task with a very long description that tests how the system handles large amounts of text. ' ||
 'It includes multiple sentences and should demonstrate the database''s ability to store and retrieve ' ||
 'large text fields efficiently. This description continues to test various edge cases including ' ||
 'special characters like quotes, apostrophes, and other punctuation marks. The description also ' ||
 'includes numbers like 123, 456, and 789 to test numeric handling within text fields. ' ||
 'Finally, this description ends with a test of very long text to ensure the system can handle ' ||
 'realistic user input without any issues or truncation problems.',
 'pending', 'low', 6, 2, 10, 9, NOW() + INTERVAL '30 days', 16.0),
-- Task with very short title
('Bug', 'Short title task', 'pending', 'medium', 6, 1, 10, 9, NOW() + INTERVAL '7 days', 2.0),
-- Task with special characters in title
('Task with Special Chars: @#$%^&*()', 'Testing special characters in task title', 'pending', 'medium', 6, 2, 10, 9, NOW() + INTERVAL '14 days', 6.0),
-- Task assigned to inactive user
('Task for Inactive User', 'This task is assigned to an inactive user', 'pending', 'medium', 6, 1, 2, 9, NOW() + INTERVAL '21 days', 8.0),
-- Task with very high estimated hours
('Large Development Task', 'A very large task that requires many hours', 'pending', 'high', 6, 2, 10, 9, NOW() + INTERVAL '60 days', 200.0),
-- Task with zero estimated hours
('Quick Fix', 'A very quick task with no time estimate', 'pending', 'low', 6, 1, 10, 9, NOW() + INTERVAL '1 day', 0.0),
-- Overdue task
('Overdue Task', 'This task is already overdue', 'pending', 'high', 6, 1, 10, 9, NOW() - INTERVAL '5 days', 8.0),
-- Completed task with actual hours
('Completed Test Task', 'A task that has been completed', 'completed', 'medium', 6, 2, 10, 9, NOW() - INTERVAL '1 day', 8.0);

-- Update completed task with actual hours
UPDATE app.tasks SET actual_hours = 7.5 WHERE title = 'Completed Test Task';

-- Insert test comments with various content
INSERT INTO app.comments (task_id, user_id, content, is_internal) VALUES
(25, 10, 'This is a regular comment visible to all users.', false),
(25, 9, 'This is an internal comment only visible to team members.', true),
(25, 11, 'Testing comment with special characters: @#$%^&*() and numbers 123456', false),
(25, 10, 'Comment with very long content that tests the system''s ability to handle large text fields. ' ||
          'This comment includes multiple sentences and should demonstrate proper text handling. ' ||
          'It also includes various punctuation marks and special characters to test edge cases. ' ||
          'The comment continues with more text to ensure the database can handle realistic user input.',
          false),
(26, 9, 'URGENT: This needs immediate attention!', false),
(27, 10, 'Working on this complex task. Will need more time than estimated.', false),
(28, 10, 'Quick fix completed in 5 minutes.', false),
(29, 10, 'This task is overdue and needs to be prioritized.', false),
(30, 10, 'Task completed successfully within estimated time.', false);

-- Insert test attachments with various file types
INSERT INTO app.attachments (task_id, uploaded_by, filename, original_filename, file_path, file_size, mime_type) VALUES
(25, 10, 'test_document.pdf', 'Test Document.pdf', '/uploads/task_25/test_document.pdf', 1024000, 'application/pdf'),
(25, 10, 'test_image.png', 'Test Image.png', '/uploads/task_25/test_image.png', 512000, 'image/png'),
(25, 10, 'test_code.js', 'test_code.js', '/uploads/task_25/test_code.js', 2048, 'application/javascript'),
(25, 10, 'test_data.csv', 'test_data.csv', '/uploads/task_25/test_data.csv', 10240, 'text/csv'),
(26, 9, 'security_report.pdf', 'Security Vulnerability Report.pdf', '/uploads/task_26/security_report.pdf', 2048000, 'application/pdf'),
(27, 10, 'large_document.pdf', 'Very Large Document.pdf', '/uploads/task_27/large_document.pdf', 10485760, 'application/pdf'), -- 10MB file
(28, 10, 'quick_fix.patch', 'quick_fix.patch', '/uploads/task_28/quick_fix.patch', 512, 'text/plain'),
(29, 10, 'overdue_analysis.xlsx', 'Overdue Task Analysis.xlsx', '/uploads/task_29/overdue_analysis.xlsx', 256000, 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'),
(30, 10, 'completion_report.docx', 'Task Completion Report.docx', '/uploads/task_30/completion_report.docx', 128000, 'application/vnd.openxmlformats-officedocument.wordprocessingml.document');

-- Insert test task dependencies (including some complex chains)
INSERT INTO app.task_dependencies (task_id, depends_on_task_id) VALUES
(25, 26), -- Task with no due date depends on critical security issue
(27, 25), -- Long description task depends on no due date task
(28, 27), -- Short title task depends on long description task
(29, 28), -- Special chars task depends on short title task
(31, 30), -- Large development task depends on completed task
(32, 31), -- Quick fix depends on large development task
(33, 32), -- Overdue task depends on quick fix

-- Insert test data for performance testing (bulk insert)
INSERT INTO app.tasks (title, description, status, priority, project_id, category_id, assigned_to, created_by, due_date, estimated_hours)
SELECT 
    'Bulk Test Task ' || i,
    'This is test task number ' || i || ' created for performance testing.',
    CASE (i % 4)
        WHEN 0 THEN 'pending'
        WHEN 1 THEN 'in_progress'
        WHEN 2 THEN 'review'
        ELSE 'completed'
    END,
    CASE (i % 4)
        WHEN 0 THEN 'low'
        WHEN 1 THEN 'medium'
        WHEN 2 THEN 'high'
        ELSE 'urgent'
    END,
    6, -- Test project
    (i % 8) + 1, -- Cycle through categories
    10, -- Test developer
    9, -- Test manager
    NOW() + (i * INTERVAL '1 day'),
    (i % 20) + 1
FROM generate_series(1, 100) AS i;

-- Insert bulk comments for performance testing
INSERT INTO app.comments (task_id, user_id, content, is_internal)
SELECT 
    34 + (i % 10), -- Reference to first 10 test tasks
    9 + (i % 4), -- Cycle through test users
    'Bulk test comment number ' || i || ' for performance testing.',
    (i % 2) = 0 -- Alternate between internal and external
FROM generate_series(1, 200) AS i;

-- Success message
DO $$
DECLARE
    task_count INTEGER;
    comment_count INTEGER;
    attachment_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO task_count FROM app.tasks;
    SELECT COUNT(*) INTO comment_count FROM app.comments;
    SELECT COUNT(*) INTO attachment_count FROM app.attachments;
    
    RAISE NOTICE 'Test data loaded successfully!';
    RAISE NOTICE 'Additional data loaded:';
    RAISE NOTICE '- 4 additional test users';
    RAISE NOTICE '- 2 additional test projects';
    RAISE NOTICE '- 9 additional test tasks with edge cases';
    RAISE NOTICE '- 100 bulk test tasks for performance testing';
    RAISE NOTICE '- 9 additional test comments';
    RAISE NOTICE '- 200 bulk test comments';
    RAISE NOTICE '- 9 additional test attachments';
    RAISE NOTICE '- 7 additional task dependencies';
    RAISE NOTICE '';
    RAISE NOTICE 'Total counts:';
    RAISE NOTICE '- % total tasks', task_count;
    RAISE NOTICE '- % total comments', comment_count;
    RAISE NOTICE '- % total attachments', attachment_count;
    RAISE NOTICE '';
    RAISE NOTICE 'Test data includes various edge cases:';
    RAISE NOTICE '- Tasks with no due dates';
    RAISE NOTICE '- Overdue tasks';
    RAISE NOTICE '- Tasks with special characters';
    RAISE NOTICE '- Very long descriptions';
    RAISE NOTICE '- Different file types and sizes';
    RAISE NOTICE '- Complex dependency chains';
    RAISE NOTICE '- Bulk data for performance testing';
END $$;
