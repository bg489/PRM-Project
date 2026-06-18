CREATE DATABASE IF NOT EXISTS productivity_management
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE productivity_management;

CREATE TABLE IF NOT EXISTS users (
  id VARCHAR(36) PRIMARY KEY,
  email VARCHAR(191) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  full_name VARCHAR(191) NOT NULL,
  role ENUM('Admin', 'Manager', 'Member') NOT NULL DEFAULT 'Member',
  avatar_text VARCHAR(8) NOT NULL,
  avatar_url VARCHAR(500) NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  notification_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  two_step_enabled BOOLEAN NOT NULL DEFAULT FALSE,
  biometric_enabled BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS registration_verifications (
  id VARCHAR(36) PRIMARY KEY,
  email VARCHAR(191) NOT NULL UNIQUE,
  full_name VARCHAR(191) NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  avatar_text VARCHAR(8) NOT NULL,
  verification_method ENUM('OTP', 'LINK', 'BOTH') NOT NULL DEFAULT 'OTP',
  otp_hash CHAR(64) NULL,
  verification_token_hash CHAR(64) NULL,
  attempts INT NOT NULL DEFAULT 0,
  expires_at TIMESTAMP NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uniq_registration_verification_token (verification_token_hash),
  INDEX idx_registration_verifications_expiry (expires_at)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS workspaces (
  id VARCHAR(36) PRIMARY KEY,
  name VARCHAR(191) NOT NULL,
  description TEXT NULL,
  owner_id VARCHAR(36) NOT NULL,
  icon_text VARCHAR(8) NOT NULL DEFAULT 'WS',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_workspaces_owner
    FOREIGN KEY (owner_id) REFERENCES users(id)
    ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS workspace_members (
  workspace_id VARCHAR(36) NOT NULL,
  user_id VARCHAR(36) NOT NULL,
  member_role ENUM('Owner', 'Manager', 'Member') NOT NULL DEFAULT 'Member',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (workspace_id, user_id),
  CONSTRAINT fk_workspace_members_workspace
    FOREIGN KEY (workspace_id) REFERENCES workspaces(id)
    ON DELETE CASCADE,
  CONSTRAINT fk_workspace_members_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS projects (
  id VARCHAR(36) PRIMARY KEY,
  workspace_id VARCHAR(36) NOT NULL,
  name VARCHAR(191) NOT NULL,
  description TEXT NULL,
  code VARCHAR(50) NOT NULL UNIQUE,
  deadline DATE NULL,
  status ENUM('Active', 'Archived') NOT NULL DEFAULT 'Active',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_projects_workspace
    FOREIGN KEY (workspace_id) REFERENCES workspaces(id)
    ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS project_members (
  project_id VARCHAR(36) NOT NULL,
  user_id VARCHAR(36) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (project_id, user_id),
  CONSTRAINT fk_project_members_project
    FOREIGN KEY (project_id) REFERENCES projects(id)
    ON DELETE CASCADE,
  CONSTRAINT fk_project_members_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS task_lists (
  id VARCHAR(36) PRIMARY KEY,
  project_id VARCHAR(36) NOT NULL,
  name VARCHAR(100) NOT NULL,
  position INT NOT NULL DEFAULT 0,
  wip_limit INT NULL,
  is_wip_enabled BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uniq_task_lists_project_name (project_id, name),
  CONSTRAINT fk_task_lists_project
    FOREIGN KEY (project_id) REFERENCES projects(id)
    ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS tasks (
  id VARCHAR(36) PRIMARY KEY,
  list_id VARCHAR(36) NOT NULL,
  project_id VARCHAR(36) NOT NULL,
  title VARCHAR(255) NOT NULL,
  description TEXT NULL,
  creator_id VARCHAR(36) NOT NULL,
  assignee_id VARCHAR(36) NULL,
  priority ENUM('Low', 'Medium', 'High') NOT NULL DEFAULT 'Medium',
  due_date DATE NULL,
  position INT NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_tasks_list
    FOREIGN KEY (list_id) REFERENCES task_lists(id)
    ON DELETE RESTRICT,
  CONSTRAINT fk_tasks_project
    FOREIGN KEY (project_id) REFERENCES projects(id)
    ON DELETE CASCADE,
  CONSTRAINT fk_tasks_creator
    FOREIGN KEY (creator_id) REFERENCES users(id)
    ON DELETE RESTRICT,
  CONSTRAINT fk_tasks_assignee
    FOREIGN KEY (assignee_id) REFERENCES users(id)
    ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS task_attachments (
  id VARCHAR(36) PRIMARY KEY,
  task_id VARCHAR(36) NOT NULL,
  file_name VARCHAR(255) NOT NULL,
  file_url VARCHAR(500) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_task_attachments_task
    FOREIGN KEY (task_id) REFERENCES tasks(id)
    ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS checklist_items (
  id VARCHAR(36) PRIMARY KEY,
  task_id VARCHAR(36) NOT NULL,
  title VARCHAR(255) NOT NULL,
  is_completed BOOLEAN NOT NULL DEFAULT FALSE,
  position INT NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_checklist_items_task
    FOREIGN KEY (task_id) REFERENCES tasks(id)
    ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS task_requirements (
  id VARCHAR(36) PRIMARY KEY,
  task_id VARCHAR(36) NOT NULL,
  title VARCHAR(255) NOT NULL,
  status ENUM('NOT_SUBMITTED', 'WAITING', 'APPROVED', 'REJECTED') NOT NULL DEFAULT 'NOT_SUBMITTED',
  submitted_by VARCHAR(36) NULL,
  reviewed_by VARCHAR(36) NULL,
  reject_reason TEXT NULL,
  submitted_at TIMESTAMP NULL,
  reviewed_at TIMESTAMP NULL,
  position INT NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_task_requirements_task
    FOREIGN KEY (task_id) REFERENCES tasks(id)
    ON DELETE CASCADE,
  CONSTRAINT fk_task_requirements_submitted_by
    FOREIGN KEY (submitted_by) REFERENCES users(id)
    ON DELETE SET NULL,
  CONSTRAINT fk_task_requirements_reviewed_by
    FOREIGN KEY (reviewed_by) REFERENCES users(id)
    ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS requirement_approval_requests (
  id VARCHAR(36) PRIMARY KEY,
  requirement_id VARCHAR(36) NOT NULL,
  task_id VARCHAR(36) NOT NULL,
  project_id VARCHAR(36) NOT NULL,
  user_id VARCHAR(36) NOT NULL,
  status ENUM('WAITING', 'APPROVED', 'REJECTED') NOT NULL DEFAULT 'WAITING',
  submitted_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  reviewed_at TIMESTAMP NULL,
  reviewer_id VARCHAR(36) NULL,
  reject_reason TEXT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_approval_requirement
    FOREIGN KEY (requirement_id) REFERENCES task_requirements(id)
    ON DELETE CASCADE,
  CONSTRAINT fk_approval_task
    FOREIGN KEY (task_id) REFERENCES tasks(id)
    ON DELETE CASCADE,
  CONSTRAINT fk_approval_project
    FOREIGN KEY (project_id) REFERENCES projects(id)
    ON DELETE CASCADE,
  CONSTRAINT fk_approval_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON DELETE CASCADE,
  CONSTRAINT fk_approval_reviewer
    FOREIGN KEY (reviewer_id) REFERENCES users(id)
    ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS comments (
  id VARCHAR(36) PRIMARY KEY,
  task_id VARCHAR(36) NOT NULL,
  user_id VARCHAR(36) NOT NULL,
  content TEXT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_comments_task
    FOREIGN KEY (task_id) REFERENCES tasks(id)
    ON DELETE CASCADE,
  CONSTRAINT fk_comments_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS notifications (
  id VARCHAR(36) PRIMARY KEY,
  target_user_id VARCHAR(36) NOT NULL,
  title VARCHAR(191) NOT NULL,
  message TEXT NOT NULL,
  type VARCHAR(50) NOT NULL,
  is_read BOOLEAN NOT NULL DEFAULT FALSE,
  task_id VARCHAR(36) NULL,
  project_id VARCHAR(36) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_notifications_user
    FOREIGN KEY (target_user_id) REFERENCES users(id)
    ON DELETE CASCADE,
  CONSTRAINT fk_notifications_task
    FOREIGN KEY (task_id) REFERENCES tasks(id)
    ON DELETE SET NULL,
  CONSTRAINT fk_notifications_project
    FOREIGN KEY (project_id) REFERENCES projects(id)
    ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS activity_logs (
  id VARCHAR(36) PRIMARY KEY,
  workspace_id VARCHAR(36) NULL,
  user_id VARCHAR(36) NULL,
  action_type VARCHAR(60) NOT NULL,
  title VARCHAR(191) NOT NULL,
  description TEXT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_activity_logs_workspace
    FOREIGN KEY (workspace_id) REFERENCES workspaces(id)
    ON DELETE SET NULL,
  CONSTRAINT fk_activity_logs_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE INDEX idx_projects_workspace ON projects(workspace_id);
CREATE INDEX idx_tasks_project ON tasks(project_id);
CREATE INDEX idx_tasks_assignee ON tasks(assignee_id);
CREATE INDEX idx_notifications_target ON notifications(target_user_id, is_read);
CREATE INDEX idx_activity_workspace ON activity_logs(workspace_id, created_at);
