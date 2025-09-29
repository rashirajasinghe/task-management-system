-- Task Management System - Sample Data
-- This script populates the database with realistic sample data

-- Insert sample categories
INSERT INTO app.categories (name, description, color) VALUES
('Bug Fix', 'Issues and bug fixes', '#e74c3c'),
('Feature', 'New features and enhancements', '#2ecc71'),
('Documentation', 'Documentation and guides', '#3498db'),
('Testing', 'Testing and quality assurance', '#f39c12'),
('Refactoring', 'Code refactoring and optimization', '#9b59b6'),
('Research', 'Research and investigation tasks', '#1abc9c'),
('Maintenance', 'System maintenance and updates', '#34495e'),
('Design', 'UI/UX design tasks', '#e67e22');

-- Insert sample users
INSERT INTO app.users (username, email, password_hash, first_name, last_name, role) VALUES
('admin', 'admin@company.com', app.hash_password('admin123'), 'System', 'Administrator', 'admin'),
('john.doe', 'john.doe@company.com', app.hash_password('password123'), 'John', 'Doe', 'manager'),
('jane.smith', 'jane.smith@company.com', app.hash_password('password123'), 'Jane', 'Smith', 'developer'),
('mike.wilson', 'mike.wilson@company.com', app.hash_password('password123'), 'Mike', 'Wilson', 'developer'),
('sarah.jones', 'sarah.jones@company.com', app.hash_password('password123'), 'Sarah', 'Jones', 'tester'),
('alex.brown', 'alex.brown@company.com', app.hash_password('password123'), 'Alex', 'Brown', 'developer'),
('lisa.davis', 'lisa.davis@company.com', app.hash_password('password123'), 'Lisa', 'Davis', 'tester'),
('tom.garcia', 'tom.garcia@company.com', app.hash_password('password123'), 'Tom', 'Garcia', 'viewer');

-- Insert sample projects
INSERT INTO app.projects (name, description, status, start_date, end_date, budget, manager_id, created_by) VALUES
('E-Commerce Platform', 'Build a modern e-commerce platform with React and Node.js', 'active', '2024-01-15', '2024-06-30', 50000.00, 2, 1),
('Mobile App Development', 'iOS and Android mobile application for customer engagement', 'active', '2024-02-01', '2024-08-15', 75000.00, 2, 1),
('Data Analytics Dashboard', 'Business intelligence dashboard for sales analytics', 'planning', '2024-03-01', '2024-07-31', 30000.00, 2, 1),
('API Integration', 'Third-party API integrations and microservices', 'completed', '2023-10-01', '2023-12-31', 25000.00, 2, 1),
('Security Audit', 'Comprehensive security audit and improvements', 'on_hold', '2024-01-01', '2024-03-31', 15000.00, 2, 1);

-- Add project members (triggers will auto-add creators)
INSERT INTO app.project_members (project_id, user_id, role) VALUES
-- E-Commerce Platform team
(1, 3, 'lead_developer'),
(1, 4, 'developer'),
(1, 5, 'qa_lead'),
(1, 6, 'developer'),
-- Mobile App team
(2, 3, 'tech_lead'),
(2, 4, 'mobile_developer'),
(2, 7, 'qa_tester'),
(2, 8, 'ui_designer'),
-- Data Analytics team
(3, 6, 'data_engineer'),
(3, 4, 'backend_developer'),
(3, 5, 'qa_tester'),
-- API Integration team (completed project)
(4, 3, 'api_developer'),
(4, 4, 'integration_specialist'),
-- Security Audit team
(5, 6, 'security_analyst'),
(5, 3, 'penetration_tester');

-- Insert sample tasks for E-Commerce Platform
INSERT INTO app.tasks (title, description, status, priority, project_id, category_id, assigned_to, created_by, due_date, estimated_hours) VALUES
('Setup Project Structure', 'Initialize React project with TypeScript and essential dependencies', 'completed', 'high', 1, 2, 3, 2, '2024-01-20', 8.0),
('Design Database Schema', 'Create PostgreSQL database schema for products, users, and orders', 'completed', 'high', 1, 2, 3, 2, '2024-01-25', 12.0),
('Implement User Authentication', 'JWT-based authentication system with login/register functionality', 'in_progress', 'high', 1, 2, 4, 2, '2024-02-15', 16.0),
('Product Catalog API', 'REST API endpoints for product management and search', 'pending', 'high', 1, 2, 6, 2, '2024-02-20', 20.0),
('Shopping Cart Implementation', 'Frontend shopping cart with add/remove/update functionality', 'pending', 'medium', 1, 2, 3, 2, '2024-02-25', 12.0),
('Payment Integration', 'Stripe payment gateway integration', 'pending', 'high', 1, 2, 4, 2, '2024-03-01', 24.0),
('Order Management System', 'Backend system for order processing and tracking', 'pending', 'medium', 1, 2, 6, 2, '2024-03-05', 18.0),
('Admin Dashboard', 'Admin interface for managing products and orders', 'pending', 'medium', 1, 2, 3, 2, '2024-03-10', 20.0),
('Fix Login Bug', 'Users unable to login with special characters in password', 'pending', 'urgent', 1, 1, 4, 2, '2024-02-10', 4.0),
('Write API Documentation', 'Comprehensive API documentation with examples', 'pending', 'low', 1, 3, 3, 2, '2024-03-15', 8.0);

-- Insert sample tasks for Mobile App Development
INSERT INTO app.tasks (title, description, status, priority, project_id, category_id, assigned_to, created_by, due_date, estimated_hours) VALUES
('Mobile App Architecture', 'Design React Native app architecture and navigation structure', 'completed', 'high', 2, 2, 3, 2, '2024-02-10', 16.0),
('User Interface Design', 'Create wireframes and UI mockups for all screens', 'in_progress', 'high', 2, 8, 8, 2, '2024-02-20', 24.0),
('Backend API Development', 'RESTful API for mobile app data synchronization', 'pending', 'high', 2, 2, 4, 2, '2024-02-25', 32.0),
('Push Notifications', 'Implement push notification system for user engagement', 'pending', 'medium', 2, 2, 3, 2, '2024-03-05', 12.0),
('Offline Data Sync', 'Implement offline data storage and synchronization', 'pending', 'high', 2, 2, 4, 2, '2024-03-10', 20.0),
('App Store Submission', 'Prepare and submit app to iOS and Google Play stores', 'pending', 'medium', 2, 2, 3, 2, '2024-07-01', 8.0),
('Performance Testing', 'Load testing and performance optimization', 'pending', 'medium', 2, 4, 7, 2, '2024-06-15', 16.0),
('Security Review', 'Security audit and vulnerability assessment', 'pending', 'high', 2, 7, 6, 2, '2024-06-20', 12.0);

-- Insert sample tasks for Data Analytics Dashboard
INSERT INTO app.tasks (title, description, status, priority, project_id, category_id, assigned_to, created_by, due_date, estimated_hours) VALUES
('Data Warehouse Design', 'Design data warehouse schema for analytics', 'pending', 'high', 3, 2, 6, 2, '2024-03-15', 24.0),
('ETL Pipeline Development', 'Extract, Transform, Load pipeline for data processing', 'pending', 'high', 3, 2, 4, 2, '2024-03-20', 32.0),
('Dashboard UI Components', 'React components for charts and data visualization', 'pending', 'medium', 3, 2, 6, 2, '2024-04-01', 20.0),
('Real-time Data Streaming', 'Kafka-based real-time data streaming setup', 'pending', 'high', 3, 2, 4, 2, '2024-04-05', 28.0),
('Machine Learning Models', 'Predictive analytics models for sales forecasting', 'pending', 'medium', 3, 6, 6, 2, '2024-04-15', 40.0),
('Performance Optimization', 'Query optimization and caching strategies', 'pending', 'low', 3, 5, 4, 2, '2024-05-01', 16.0);

-- Insert sample comments
INSERT INTO app.comments (task_id, user_id, content, is_internal) VALUES
(1, 3, 'Project structure setup completed successfully. All dependencies installed and configured.', false),
(1, 2, 'Great work! The structure looks clean and well-organized.', false),
(2, 3, 'Database schema designed with proper relationships and indexes. Ready for implementation.', false),
(3, 4, 'Started working on authentication. Using bcrypt for password hashing and JWT for tokens.', false),
(3, 2, 'Make sure to implement proper input validation and rate limiting.', false),
(3, 5, 'I can help test the authentication flow once it is ready.', false),
(9, 4, 'Found the issue - special characters in password are not being escaped properly in the SQL query.', false),
(9, 2, 'This is critical for user security. Please fix immediately.', false),
(9, 4, 'Fixed! Updated the parameterized query to handle special characters correctly.', false),
(12, 8, 'Working on the main dashboard wireframe. Will share mockups by end of week.', false),
(12, 2, 'Looking forward to seeing the designs. Focus on user experience and accessibility.', false);

-- Insert sample task dependencies
INSERT INTO app.task_dependencies (task_id, depends_on_task_id) VALUES
(3, 1), -- User Authentication depends on Project Structure
(3, 2), -- User Authentication depends on Database Schema
(4, 2), -- Product Catalog API depends on Database Schema
(5, 3), -- Shopping Cart depends on User Authentication
(6, 4), -- Payment Integration depends on Product Catalog API
(6, 5), -- Payment Integration depends on Shopping Cart
(7, 4), -- Order Management depends on Product Catalog API
(8, 3), -- Admin Dashboard depends on User Authentication
(8, 4), -- Admin Dashboard depends on Product Catalog API
(10, 4), -- API Documentation depends on Product Catalog API
(13, 12), -- Backend API depends on UI Design
(14, 13), -- Push Notifications depend on Backend API
(15, 13), -- Offline Data Sync depends on Backend API
(16, 14), -- App Store Submission depends on Push Notifications
(16, 15), -- App Store Submission depends on Offline Data Sync
(17, 13), -- Performance Testing depends on Backend API
(18, 13), -- Security Review depends on Backend API
(19, 20), -- ETL Pipeline depends on Data Warehouse Design
(20, 19), -- Dashboard UI depends on ETL Pipeline
(21, 20), -- Real-time Streaming depends on ETL Pipeline
(22, 20), -- ML Models depend on ETL Pipeline
(23, 20); -- Performance Optimization depends on ETL Pipeline

-- Insert sample attachments (mock file paths)
INSERT INTO app.attachments (task_id, uploaded_by, filename, original_filename, file_path, file_size, mime_type) VALUES
(1, 3, 'project_structure_20240120.pdf', 'Project Structure Documentation.pdf', '/uploads/task_1/project_structure_20240120.pdf', 2048576, 'application/pdf'),
(2, 3, 'database_schema_v1.sql', 'Database Schema v1.sql', '/uploads/task_2/database_schema_v1.sql', 15360, 'application/sql'),
(2, 3, 'erd_diagram.png', 'ERD Diagram.png', '/uploads/task_2/erd_diagram.png', 1024000, 'image/png'),
(3, 4, 'auth_flow_diagram.drawio', 'Authentication Flow.drawio', '/uploads/task_3/auth_flow_diagram.drawio', 51200, 'application/xml'),
(9, 4, 'bug_report_20240208.txt', 'Bug Report - Login Issue.txt', '/uploads/task_9/bug_report_20240208.txt', 2048, 'text/plain'),
(12, 8, 'mobile_wireframes_v1.fig', 'Mobile App Wireframes v1.fig', '/uploads/task_12/mobile_wireframes_v1.fig', 2048000, 'application/octet-stream'),
(12, 8, 'ui_mockups.png', 'UI Mockups.png', '/uploads/task_12/ui_mockups.png', 3072000, 'image/png');

-- Update some tasks with actual hours (for completed tasks)
UPDATE app.tasks SET actual_hours = 7.5 WHERE id = 1; -- Project Structure
UPDATE app.tasks SET actual_hours = 11.0 WHERE id = 2; -- Database Schema
UPDATE app.tasks SET actual_hours = 15.5 WHERE id = 11; -- Mobile App Architecture

-- Update some tasks to completed status
UPDATE app.tasks SET status = 'completed', actual_hours = 7.5 WHERE id = 1;
UPDATE app.tasks SET status = 'completed', actual_hours = 11.0 WHERE id = 2;
UPDATE app.tasks SET status = 'completed', actual_hours = 15.5 WHERE id = 11;

-- Success message
DO $$
BEGIN
    RAISE NOTICE 'Sample data loaded successfully!';
    RAISE NOTICE 'Data loaded:';
    RAISE NOTICE '- 8 categories';
    RAISE NOTICE '- 8 users (1 admin, 1 manager, 4 developers, 2 testers, 1 viewer)';
    RAISE NOTICE '- 5 projects (3 active, 1 completed, 1 on hold)';
    RAISE NOTICE '- 24 tasks across all projects';
    RAISE NOTICE '- 11 comments';
    RAISE NOTICE '- 15 task dependencies';
    RAISE NOTICE '- 7 file attachments';
    RAISE NOTICE '';
    RAISE NOTICE 'You can now run example queries to explore the data!';
END $$;
