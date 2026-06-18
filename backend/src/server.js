const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const express = require('express');
const mysql = require('mysql2/promise');

loadEnv();

const app = express();
const port = Number(process.env.PORT || 3000);
const jwtSecret = process.env.JWT_SECRET || 'development-secret-change-me';
const jwtTtlSeconds = Number(process.env.JWT_EXPIRES_IN_SECONDS || 604800);
const registrationOtpTtlMinutes = Number(
  process.env.REGISTRATION_OTP_TTL_MINUTES || 10,
);
const registrationMaxAttempts = Number(
  process.env.REGISTRATION_MAX_ATTEMPTS || 5,
);
const appPublicUrl = String(
  process.env.APP_PUBLIC_URL || `http://localhost:${port}`,
).replace(/\/$/, '');

const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  port: Number(process.env.DB_PORT || 3306),
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'productivity_management',
  waitForConnections: true,
  connectionLimit: Number(process.env.DB_CONNECTION_LIMIT || 10),
  namedPlaceholders: true,
  ssl: process.env.DB_SSL === 'true'
    ? { rejectUnauthorized: process.env.DB_SSL_REJECT_UNAUTHORIZED !== 'false' }
    : undefined,
});

app.use(express.json({ limit: '10mb' }));
app.use((req, res, next) => {
  const origin = process.env.CORS_ORIGIN || '*';
  res.setHeader('Access-Control-Allow-Origin', origin);
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS');

  if (req.method === 'OPTIONS') {
    res.sendStatus(204);
    return;
  }

  next();
});

app.get('/api/health', asyncHandler(async (_req, res) => {
  await pool.query('SELECT 1');
  res.json({ ok: true, service: 'productivity-management-backend' });
}));

app.post('/api/auth/register', asyncHandler(requestRegistrationVerification));
app.post('/api/auth/register/request', asyncHandler(requestRegistrationVerification));

app.post('/api/auth/register/verify', asyncHandler(async (req, res) => {
  const { verificationId, otp, token } = req.body;
  const verification = await findRegistrationVerification({
    verificationId,
    token,
  });

  await validateRegistrationVerification(verification, { otp, token });
  const result = await completeRegistration(verification, { otp, token });
  res.status(201).json(result);
}));

app.get('/api/auth/register/verify-link', asyncHandler(async (req, res) => {
  const verification = await findRegistrationVerification({
    token: req.query.token,
  });

  await validateRegistrationVerification(verification, {
    token: req.query.token,
  });
  await completeRegistration(verification, {
    token: req.query.token,
  });

  res
    .status(200)
    .type('html')
    .send(`<!doctype html>
<html lang="vi">
  <head><meta charset="utf-8"><title>Xác thực thành công</title></head>
  <body style="font-family:Arial,sans-serif;padding:40px;background:#f5f7fb;color:#111827">
    <h1>Email đã được xác thực</h1>
    <p>Tài khoản Productivity Manager đã được tạo. Bạn có thể quay lại ứng dụng và đăng nhập.</p>
  </body>
</html>`);
}));

app.post('/api/auth/login', asyncHandler(async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    throw httpError(400, 'Email and password are required.');
  }

  const rows = await query(
    'SELECT * FROM users WHERE email = ? LIMIT 1',
    [email.trim().toLowerCase()],
  );

  if (rows.length === 0 || !rows[0].is_active) {
    throw httpError(401, 'Invalid credentials.');
  }

  if (!verifyPassword(password, rows[0].password_hash)) {
    throw httpError(401, 'Invalid credentials.');
  }

  const user = mapUser(rows[0]);
  const token = signToken({ sub: user.id, role: user.role });

  await insertActivity({
    workspaceId: null,
    userId: user.id,
    actionType: 'LOGIN',
    title: 'Đăng nhập hệ thống',
    description: `${user.fullName} đăng nhập vào Productivity Manager.`,
  });

  res.json({ token, user });
}));

app.use('/api', requireAuth);

app.get('/api/auth/me', asyncHandler(async (req, res) => {
  res.json({ user: await getUserById(req.user.id) });
}));

app.post('/api/auth/logout', asyncHandler(async (_req, res) => {
  res.json({ ok: true });
}));

app.get('/api/users', asyncHandler(async (_req, res) => {
  const rows = await query('SELECT * FROM users ORDER BY created_at ASC');
  res.json(rows.map(mapUser));
}));

app.put('/api/users/:id', asyncHandler(async (req, res) => {
  const { fullName, role, avatarText, isActive, notificationEnabled } = req.body;
  const current = await getUserById(req.params.id);

  await execute(
    `UPDATE users
     SET full_name = ?, role = ?, avatar_text = ?, is_active = ?, notification_enabled = ?
     WHERE id = ?`,
    [
      fullName ?? current.fullName,
      role ?? current.role,
      (avatarText ?? current.avatarText).slice(0, 2).toUpperCase(),
      isActive ?? current.isActive,
      notificationEnabled ?? current.notificationEnabled,
      req.params.id,
    ],
  );

  await insertActivity({
    workspaceId: null,
    userId: req.user.id,
    actionType: 'USER_ROLE_CHANGED',
    title: 'Cập nhật người dùng',
    description: `Cập nhật tài khoản ${current.email}.`,
  });

  res.json(await getUserById(req.params.id));
}));

app.patch('/api/users/:id/security', asyncHandler(async (req, res) => {
  const { twoStepEnabled, biometricEnabled, notificationEnabled } = req.body;
  const current = await getUserById(req.params.id);

  await execute(
    `UPDATE users
     SET two_step_enabled = ?, biometric_enabled = ?, notification_enabled = ?
     WHERE id = ?`,
    [
      twoStepEnabled ?? current.twoStepEnabled,
      biometricEnabled ?? current.biometricEnabled,
      notificationEnabled ?? current.notificationEnabled,
      req.params.id,
    ],
  );

  res.json(await getUserById(req.params.id));
}));

app.post('/api/users/:id/change-password', asyncHandler(async (req, res) => {
  const { currentPassword, newPassword } = req.body;
  const rows = await query('SELECT * FROM users WHERE id = ? LIMIT 1', [req.params.id]);

  if (rows.length === 0) throw httpError(404, 'User not found.');
  if (!verifyPassword(currentPassword || '', rows[0].password_hash)) {
    throw httpError(400, 'Current password is not correct.');
  }
  assertStrongPassword(newPassword, 'New password');

  await execute('UPDATE users SET password_hash = ? WHERE id = ?', [
    hashPassword(newPassword),
    req.params.id,
  ]);

  res.json({ ok: true });
}));

app.get('/api/workspaces', asyncHandler(async (req, res) => {
  const rows = await query(workspaceSelectSql(req.user), workspaceSelectParams(req.user));
  res.json(rows.map(mapWorkspace));
}));

app.post('/api/workspaces', asyncHandler(async (req, res) => {
  const { name, description, iconText, memberIds = [] } = req.body;
  if (!name) throw httpError(400, 'Workspace name is required.');

  const workspaceId = makeId('ws');
  const safeIcon = (iconText || initials(name)).slice(0, 2).toUpperCase();

  await execute(
    `INSERT INTO workspaces (id, name, description, owner_id, icon_text)
     VALUES (?, ?, ?, ?, ?)`,
    [workspaceId, name.trim(), description || '', req.user.id, safeIcon],
  );
  await execute(
    `INSERT INTO workspace_members (workspace_id, user_id, member_role)
     VALUES (?, ?, 'Owner')`,
    [workspaceId, req.user.id],
  );

  const workspaceUsers = Array.isArray(memberIds) && memberIds.length > 0
    ? await getUsersByIds([req.user.id, ...memberIds])
    : await getAllActiveUsers();

  await ensureWorkspaceMembers(workspaceId, workspaceUsers, req.user.id);

  await insertActivity({
    workspaceId,
    userId: req.user.id,
    actionType: 'WORKSPACE_CREATED',
    title: `Tạo workspace ${name.trim()}`,
    description: `Workspace ${name.trim()} được tạo trong hệ thống.`,
  });

  res.status(201).json(await getWorkspaceById(workspaceId));
}));

app.put('/api/workspaces/:id', asyncHandler(async (req, res) => {
  const current = await getWorkspaceById(req.params.id);
  const { name, description, iconText } = req.body;

  await execute(
    `UPDATE workspaces SET name = ?, description = ?, icon_text = ? WHERE id = ?`,
    [
      name ?? current.name,
      description ?? current.description,
      (iconText ?? current.iconText).slice(0, 2).toUpperCase(),
      req.params.id,
    ],
  );

  res.json(await getWorkspaceById(req.params.id));
}));

app.delete('/api/workspaces/:id', asyncHandler(async (req, res) => {
  await execute('DELETE FROM workspaces WHERE id = ?', [req.params.id]);
  res.json({ ok: true });
}));

app.get('/api/projects', asyncHandler(async (req, res) => {
  const rows = await query(projectSelectSql(req.user, req.query.workspaceId), projectSelectParams(req.user, req.query.workspaceId));
  res.json(rows.map(mapProject));
}));

app.get('/api/workspaces/:workspaceId/projects', asyncHandler(async (req, res) => {
  const rows = await query(projectSelectSql(req.user, req.params.workspaceId), projectSelectParams(req.user, req.params.workspaceId));
  res.json(rows.map(mapProject));
}));

app.get('/api/projects/:id', asyncHandler(async (req, res) => {
  res.json(await getProjectById(req.params.id));
}));

app.post('/api/projects', asyncHandler(async (req, res) => {
  const { workspaceId, name, description, code, deadline, memberIds = [] } = req.body;
  if (!workspaceId || !name || !code) {
    throw httpError(400, 'workspaceId, name and code are required.');
  }

  const projectId = makeId('p');
  await execute(
    `INSERT INTO projects (id, workspace_id, name, description, code, deadline, status)
     VALUES (?, ?, ?, ?, ?, ?, 'Active')`,
    [projectId, workspaceId, name.trim(), description || '', code.trim().toUpperCase(), toSqlDate(deadline)],
  );

  const projectUsers = Array.isArray(memberIds) && memberIds.length > 0
    ? await getUsersByIds([req.user.id, ...memberIds])
    : await getWorkspaceMemberUsers(workspaceId);

  const creatorExists = projectUsers.some((user) => user.id === req.user.id);
  if (!creatorExists) {
    projectUsers.push({
      id: req.user.id,
      role: req.user.role,
    });
  }

  await ensureWorkspaceMembers(workspaceId, projectUsers);
  await ensureProjectMembers(projectId, projectUsers);

  await createDefaultLists(projectId);
  await insertActivity({
    workspaceId,
    userId: req.user.id,
    actionType: 'PROJECT_CREATED',
    title: `Tạo dự án ${name.trim()}`,
    description: `Dự án ${name.trim()} được tạo trong workspace.`,
  });

  res.status(201).json(await getProjectById(projectId));
}));

app.put('/api/projects/:id', asyncHandler(async (req, res) => {
  const current = await getProjectById(req.params.id);
  const { workspaceId, name, description, code, deadline, status } = req.body;

  await execute(
    `UPDATE projects
     SET workspace_id = ?, name = ?, description = ?, code = ?, deadline = ?, status = ?
     WHERE id = ?`,
    [
      workspaceId ?? current.workspaceId,
      name ?? current.name,
      description ?? current.description,
      code ?? current.code,
      toSqlDate(deadline ?? current.deadline),
      status ?? current.status,
      req.params.id,
    ],
  );

  res.json(await getProjectById(req.params.id));
}));

app.delete('/api/projects/:id', asyncHandler(async (req, res) => {
  await execute('DELETE FROM projects WHERE id = ?', [req.params.id]);
  res.json({ ok: true });
}));

app.get('/api/projects/:projectId/lists', asyncHandler(async (req, res) => {
  const rows = await query(
    `SELECT id, project_id, name, position, wip_limit, is_wip_enabled
     FROM task_lists
     WHERE project_id = ?
     ORDER BY position ASC`,
    [req.params.projectId],
  );
  res.json(rows.map(mapTaskList));
}));

app.post('/api/projects/:projectId/lists', asyncHandler(async (req, res) => {
  const { name, position, wipLimit, isWipEnabled } = req.body;
  if (!name) throw httpError(400, 'List name is required.');

  const listId = makeId('lst');
  await execute(
    `INSERT INTO task_lists (id, project_id, name, position, wip_limit, is_wip_enabled)
     VALUES (?, ?, ?, ?, ?, ?)`,
    [listId, req.params.projectId, name.trim(), position ?? 0, wipLimit ?? null, isWipEnabled ?? false],
  );

  res.status(201).json(await getTaskListById(listId));
}));

app.put('/api/lists/:id', asyncHandler(async (req, res) => {
  const current = await getTaskListById(req.params.id);
  const { name, position, wipLimit, isWipEnabled } = req.body;

  await execute(
    `UPDATE task_lists SET name = ?, position = ?, wip_limit = ?, is_wip_enabled = ? WHERE id = ?`,
    [
      name ?? current.name,
      position ?? current.position,
      wipLimit ?? current.wipLimit,
      isWipEnabled ?? current.isWipEnabled,
      req.params.id,
    ],
  );

  res.json(await getTaskListById(req.params.id));
}));

app.delete('/api/lists/:id', asyncHandler(async (req, res) => {
  await execute('DELETE FROM task_lists WHERE id = ?', [req.params.id]);
  res.json({ ok: true });
}));

app.get('/api/tasks', asyncHandler(async (req, res) => {
  const filters = {
    workspaceId: req.query.workspaceId,
    projectId: req.query.projectId,
    assigneeId: req.query.assigneeId,
    status: req.query.status,
    priority: req.query.priority,
    search: req.query.search,
  };
  const { sql, params } = taskSelectSql(filters);
  const rows = await query(sql, params);
  res.json(rows.map(mapTask));
}));

app.get('/api/tasks/:id', asyncHandler(async (req, res) => {
  const task = await getTaskById(req.params.id);
  const checklistItems = await query(
    `SELECT id, task_id, title, is_completed, position
     FROM checklist_items
     WHERE task_id = ?
     ORDER BY position ASC`,
    [req.params.id],
  );
  const requirements = await query(
    `SELECT r.*, submitter.full_name AS submitted_by_name, reviewer.full_name AS reviewer_name
     FROM task_requirements r
     LEFT JOIN users submitter ON submitter.id = r.submitted_by
     LEFT JOIN users reviewer ON reviewer.id = r.reviewed_by
     WHERE r.task_id = ?
     ORDER BY r.position ASC`,
    [req.params.id],
  );
  const comments = await query(
    `SELECT c.*, u.full_name, u.avatar_text
     FROM comments c
     JOIN users u ON u.id = c.user_id
     WHERE c.task_id = ?
     ORDER BY c.created_at ASC`,
    [req.params.id],
  );

  res.json({
    task,
    checklistItems: checklistItems.map(mapChecklistItem),
    requirements: requirements.map(mapRequirement),
    comments: comments.map(mapComment),
  });
}));

app.post('/api/tasks', asyncHandler(async (req, res) => {
  const {
    projectId,
    title,
    description,
    assigneeId,
    assigneeName,
    priority = 'Medium',
    dueDate,
    status = 'Cần làm',
    checklistItems = [],
    requirements = [],
  } = req.body;

  if (!projectId || !title) {
    throw httpError(400, 'projectId and title are required.');
  }

  const assignee = assigneeId
    ? await getUserById(assigneeId)
    : await findUserByNameOrAvatar(assigneeName);
  const listId = await getListIdByName(projectId, status);
  const taskId = makeId('t');

  await execute(
    `INSERT INTO tasks (id, list_id, project_id, title, description, creator_id, assignee_id, priority, due_date)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [taskId, listId, projectId, title.trim(), description || '', req.user.id, assignee?.id || null, priority, toSqlDate(dueDate)],
  );

  const project = await getProjectById(projectId);

  if (assignee) {
    await execute(
      'INSERT IGNORE INTO project_members (project_id, user_id) VALUES (?, ?)',
      [projectId, assignee.id],
    );

    await ensureWorkspaceMembers(project.workspaceId, [assignee]);

    await createNotification({
      targetUserId: assignee.id,
      title: 'Bạn được giao task mới',
      message: `Task “${title.trim()}” đã được giao cho bạn.`,
      type: 'TASK_ASSIGNED',
      taskId,
      projectId,
    });
  }

  for (const [index, itemTitle] of checklistItems.entries()) {
    await execute(
      `INSERT INTO checklist_items (id, task_id, title, is_completed, position)
       VALUES (?, ?, ?, FALSE, ?)`,
      [makeId('ci'), taskId, String(itemTitle), index + 1],
    );
  }

  for (const [index, requirementTitle] of requirements.entries()) {
    await execute(
      `INSERT INTO task_requirements (id, task_id, title, status, position)
       VALUES (?, ?, ?, 'NOT_SUBMITTED', ?)`,
      [makeId('req'), taskId, String(requirementTitle), index + 1],
    );
  }


  await insertActivity({
    workspaceId: project.workspaceId,
    userId: req.user.id,
    actionType: 'TASK_CREATED',
    title: `Tạo task ${title.trim()}`,
    description: `Task “${title.trim()}” được tạo trong dự án ${project.name}.`,
  });

  res.status(201).json(await getTaskById(taskId));
}));

app.put('/api/tasks/:id', asyncHandler(async (req, res) => {
  const current = await getTaskById(req.params.id);
  const { title, description, assigneeId, priority, dueDate } = req.body;

  await execute(
    `UPDATE tasks
     SET title = ?, description = ?, assignee_id = ?, priority = ?, due_date = ?
     WHERE id = ?`,
    [
      title ?? current.title,
      description ?? current.description,
      assigneeId ?? current.assigneeId,
      priority ?? current.priority,
      toSqlDate(dueDate ?? current.dueDate),
      req.params.id,
    ],
  );

  await logTaskAction(req.params.id, req.user.id, 'TASK_UPDATED', 'Cập nhật task', `Task “${title ?? current.title}” đã được cập nhật.`);
  res.json(await getTaskById(req.params.id));
}));

app.patch('/api/tasks/:id/status', asyncHandler(async (req, res) => {
  const { status } = req.body;
  if (!status) throw httpError(400, 'status is required.');

  const current = await getTaskById(req.params.id);
  const listId = await getListIdByName(current.projectId, status);

  await execute('UPDATE tasks SET list_id = ? WHERE id = ?', [listId, req.params.id]);
  await logTaskAction(
    req.params.id,
    req.user.id,
    'TASK_MOVED',
    `Chuyển task sang ${status}`,
    `Task “${current.title}” được chuyển từ ${current.status} sang ${status}.`,
  );

  res.json(await getTaskById(req.params.id));
}));

app.delete('/api/tasks/:id', asyncHandler(async (req, res) => {
  await logTaskAction(req.params.id, req.user.id, 'TASK_UPDATED', 'Xóa task', 'Một task đã bị xóa khỏi hệ thống.');
  await execute('DELETE FROM tasks WHERE id = ?', [req.params.id]);
  res.json({ ok: true });
}));

app.patch('/api/checklist-items/:id', asyncHandler(async (req, res) => {
  const currentRows = await query('SELECT * FROM checklist_items WHERE id = ? LIMIT 1', [req.params.id]);
  if (currentRows.length === 0) throw httpError(404, 'Checklist item not found.');
  const current = currentRows[0];

  await execute(
    `UPDATE checklist_items SET title = ?, is_completed = ? WHERE id = ?`,
    [
      req.body.title ?? current.title,
      req.body.isCompleted ?? Boolean(current.is_completed),
      req.params.id,
    ],
  );

  const rows = await query('SELECT * FROM checklist_items WHERE id = ? LIMIT 1', [req.params.id]);
  res.json(mapChecklistItem(rows[0]));
}));

app.post('/api/tasks/:taskId/comments', asyncHandler(async (req, res) => {
  const { content } = req.body;
  if (!content || !content.trim()) throw httpError(400, 'Comment content is required.');

  const commentId = makeId('c');
  await execute(
    `INSERT INTO comments (id, task_id, user_id, content)
     VALUES (?, ?, ?, ?)`,
    [commentId, req.params.taskId, req.user.id, content.trim()],
  );

  const task = await getTaskById(req.params.taskId);
  if (task.assigneeId && task.assigneeId !== req.user.id) {
    await createNotification({
      targetUserId: task.assigneeId,
      title: 'Có bình luận mới',
      message: `${req.user.fullName} đã bình luận trong task “${task.title}”.`,
      type: 'COMMENT_ADDED',
      taskId: task.id,
      projectId: task.projectId,
    });
  }

  await logTaskAction(req.params.taskId, req.user.id, 'TASK_UPDATED', 'Thêm bình luận', `Có bình luận mới trong task “${task.title}”.`);

  const rows = await query(
    `SELECT c.*, u.full_name, u.avatar_text
     FROM comments c
     JOIN users u ON u.id = c.user_id
     WHERE c.id = ?
     LIMIT 1`,
    [commentId],
  );
  res.status(201).json(mapComment(rows[0]));
}));

app.post('/api/requirements/:id/submit', asyncHandler(async (req, res) => {
  const requirement = await getRequirementRow(req.params.id);
  await execute(
    `UPDATE task_requirements
     SET status = 'WAITING', submitted_by = ?, submitted_at = CURRENT_TIMESTAMP, reviewed_by = NULL, reviewed_at = NULL, reject_reason = NULL
     WHERE id = ?`,
    [req.user.id, req.params.id],
  );

  const requestId = makeId('ar');
  await execute(
    `INSERT INTO requirement_approval_requests
       (id, requirement_id, task_id, project_id, user_id, status, submitted_at)
     VALUES (?, ?, ?, ?, ?, 'WAITING', CURRENT_TIMESTAMP)`,
    [requestId, req.params.id, requirement.task_id, requirement.project_id, req.user.id],
  );

  await logTaskAction(requirement.task_id, req.user.id, 'APPROVAL_SUBMITTED', 'Gửi yêu cầu duyệt requirement', `Requirement “${requirement.title}” được gửi duyệt.`);

  res.status(201).json(await getApprovalRequestById(requestId));
}));

app.patch('/api/requirements/:id/review', asyncHandler(async (req, res) => {
  const request = await getLatestApprovalByRequirementId(req.params.id);
  if (!request) throw httpError(404, 'Approval request not found.');
  res.json(await reviewApprovalRequest(request.id, req.user.id, req.body.status, req.body.rejectReason));
}));

app.get('/api/approval-requests', asyncHandler(async (req, res) => {
  const conditions = [];
  const params = [];

  if (req.query.userId) {
    conditions.push('ar.user_id = ?');
    params.push(req.query.userId);
  }
  if (req.query.projectId) {
    conditions.push('ar.project_id = ?');
    params.push(req.query.projectId);
  }
  if (req.query.status && req.query.status !== 'all') {
    conditions.push('ar.status = ?');
    params.push(req.query.status);
  }

  const where = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';
  const rows = await query(`${approvalSelectSql()} ${where} ORDER BY ar.submitted_at DESC`, params);
  res.json(rows.map(mapApprovalRequest));
}));

app.patch('/api/approval-requests/:id/review', asyncHandler(async (req, res) => {
  res.json(await reviewApprovalRequest(req.params.id, req.user.id, req.body.status, req.body.rejectReason));
}));

app.get('/api/notifications', asyncHandler(async (req, res) => {
  const targetUserId = req.query.userId || req.user.id;
  const rows = await query(
    `SELECT *
     FROM notifications
     WHERE target_user_id = ?
     ORDER BY created_at DESC`,
    [targetUserId],
  );
  res.json(rows.map(mapNotification));
}));

app.patch('/api/notifications/:id/read', asyncHandler(async (req, res) => {
  await execute('UPDATE notifications SET is_read = TRUE WHERE id = ?', [req.params.id]);
  const rows = await query('SELECT * FROM notifications WHERE id = ? LIMIT 1', [req.params.id]);
  if (rows.length === 0) throw httpError(404, 'Notification not found.');
  res.json(mapNotification(rows[0]));
}));

app.delete('/api/notifications/:id', asyncHandler(async (req, res) => {
  await execute('DELETE FROM notifications WHERE id = ?', [req.params.id]);
  res.json({ ok: true });
}));

app.get('/api/activity-logs', asyncHandler(async (req, res) => {
  const conditions = [];
  const params = [];
  if (req.query.workspaceId && req.query.workspaceId !== 'all') {
    conditions.push('al.workspace_id = ?');
    params.push(req.query.workspaceId);
  }
  if (req.query.userId && req.query.userId !== 'all') {
    conditions.push('al.user_id = ?');
    params.push(req.query.userId);
  }
  if (req.query.actionType && req.query.actionType !== 'all') {
    conditions.push('al.action_type = ?');
    params.push(req.query.actionType);
  }

  const where = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';
  const rows = await query(
    `SELECT al.*, u.full_name, u.avatar_text
     FROM activity_logs al
     LEFT JOIN users u ON u.id = al.user_id
     ${where}
     ORDER BY al.created_at DESC
     LIMIT 200`,
    params,
  );
  res.json(rows.map(mapActivityLog));
}));

app.get('/api/admin/summary', asyncHandler(async (_req, res) => {
  const [users] = await query('SELECT COUNT(*) AS count FROM users');
  const [workspaces] = await query('SELECT COUNT(*) AS count FROM workspaces');
  const [projects] = await query('SELECT COUNT(*) AS count FROM projects');
  const [tasks] = await query('SELECT COUNT(*) AS count FROM tasks');
  const [completed] = await query(
    `SELECT COUNT(*) AS count
     FROM tasks t
     JOIN task_lists l ON l.id = t.list_id
     WHERE l.name = 'Đã xong'`,
  );

  res.json({
    totalUsers: Number(users.count),
    totalWorkspaces: Number(workspaces.count),
    totalProjects: Number(projects.count),
    totalTasks: Number(tasks.count),
    completedTasks: Number(completed.count),
    pendingTasks: Number(tasks.count) - Number(completed.count),
  });
}));

app.get('/api/analytics/project/:projectId', asyncHandler(async (req, res) => {
  const tasks = (await query(taskSelectSql({ projectId: req.params.projectId }).sql, [req.params.projectId])).map(mapTask);
  const total = tasks.length;
  const done = tasks.filter((task) => task.status === 'Đã xong').length;
  const overdue = tasks.filter((task) => task.status !== 'Đã xong' && isOverdue(task.dueDate)).length;

  res.json({
    totalTasks: total,
    completedTasks: done,
    inProgressTasks: tasks.filter((task) => task.status === 'Đang làm' || task.status === 'Kiểm tra').length,
    todoTasks: tasks.filter((task) => task.status === 'Cần làm').length,
    overdueTasks: overdue,
    completionRate: total === 0 ? 0 : done / total,
    tasks,
  });
}));

app.use((err, _req, res, _next) => {
  const status = err.statusCode || 500;
  if (status >= 500) {
    console.error(err);
  }
  res.status(status).json({
    message: err.message || 'Internal server error.',
  });
});

app.listen(port, () => {
  console.log(`Productivity backend listening on http://localhost:${port}/api`);
});

function loadEnv() {
  const envPath = path.resolve(__dirname, '..', '.env');
  if (!fs.existsSync(envPath)) return;

  const content = fs.readFileSync(envPath, 'utf8');
  for (const rawLine of content.split(/\r?\n/)) {
    const line = rawLine.trim();
    if (!line || line.startsWith('#') || !line.includes('=')) continue;
    const [key, ...valueParts] = line.split('=');
    if (!process.env[key]) {
      process.env[key] = valueParts.join('=').trim();
    }
  }
}

function asyncHandler(fn) {
  return (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);
}

function httpError(statusCode, message) {
  const error = new Error(message);
  error.statusCode = statusCode;
  return error;
}

async function requireAuth(req, _res, next) {
  try {
    const header = req.get('Authorization') || '';
    const token = header.startsWith('Bearer ') ? header.slice(7) : '';
    if (!token) throw httpError(401, 'Missing bearer token.');

    const payload = verifyToken(token);
    const user = await getUserById(payload.sub);
    if (!user.isActive) throw httpError(403, 'User is locked.');
    req.user = user;
    next();
  } catch (error) {
    next(error.statusCode ? error : httpError(401, 'Invalid token.'));
  }
}

async function query(sql, params = []) {
  const [rows] = await pool.query(sql, params);
  return rows;
}

async function execute(sql, params = []) {
  const [result] = await pool.execute(sql, params);
  return result;
}

async function requestRegistrationVerification(req, res) {
  const {
    email,
    password,
    fullName,
    avatarText,
    verificationMethod = 'OTP',
  } = req.body;

  if (!email || !password || !fullName) {
    throw httpError(400, 'Email, password and fullName are required.');
  }

  const normalizedEmail = String(email).trim().toLowerCase();
  const normalizedFullName = String(fullName).trim();
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(normalizedEmail)) {
    throw httpError(400, 'Email is invalid.');
  }
  if (!normalizedFullName) {
    throw httpError(400, 'fullName is required.');
  }

  assertStrongPassword(password);

  const method = String(verificationMethod).trim().toUpperCase();
  if (!['OTP', 'LINK', 'BOTH'].includes(method)) {
    throw httpError(400, 'verificationMethod must be OTP, LINK or BOTH.');
  }

  const existingUsers = await query(
    'SELECT id FROM users WHERE email = ? LIMIT 1',
    [normalizedEmail],
  );
  if (existingUsers.length > 0) {
    throw httpError(409, 'Email already exists.');
  }

  const verificationId = makeId('verify');
  const otp = String(crypto.randomInt(0, 1000000)).padStart(6, '0');
  const rawToken = crypto.randomBytes(32).toString('hex');
  const safeAvatar = String(avatarText || initials(normalizedFullName))
    .trim()
    .slice(0, 2)
    .toUpperCase() || initials(normalizedFullName);
  const expiresAt = new Date(
    Date.now() + registrationOtpTtlMinutes * 60 * 1000,
  );
  const verificationLink =
    `${appPublicUrl}/api/auth/register/verify-link?token=${encodeURIComponent(rawToken)}`;

  await execute(
    `DELETE FROM registration_verifications
     WHERE email = ? OR expires_at < CURRENT_TIMESTAMP`,
    [normalizedEmail],
  );
  await execute(
    `INSERT INTO registration_verifications
       (id, email, full_name, password_hash, avatar_text, verification_method,
        otp_hash, verification_token_hash, attempts, expires_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, 0, ?)`,
    [
      verificationId,
      normalizedEmail,
      normalizedFullName,
      hashPassword(password),
      safeAvatar,
      method,
      method === 'LINK' ? null : hashVerificationValue(otp),
      method === 'OTP' ? null : hashVerificationValue(rawToken),
      expiresAt,
    ],
  );

  const emailSent = await sendRegistrationVerificationEmail({
    email: normalizedEmail,
    fullName: normalizedFullName,
    method,
    otp,
    verificationLink,
  });

  if (!emailSent) {
    await execute('DELETE FROM registration_verifications WHERE id = ?', [
      verificationId,
    ]);
    throw httpError(503, 'Verification email could not be delivered.');
  }

  const response = {
    verificationId,
    email: normalizedEmail,
    verificationMethod: method,
    expiresInSeconds: registrationOtpTtlMinutes * 60,
    emailSent: true,
  };

  res.status(202).json(response);
}

async function findRegistrationVerification({ verificationId, token }) {
  let rows;
  if (verificationId) {
    rows = await query(
      'SELECT * FROM registration_verifications WHERE id = ? LIMIT 1',
      [verificationId],
    );
  } else if (token) {
    rows = await query(
      `SELECT *
       FROM registration_verifications
       WHERE verification_token_hash = ?
       LIMIT 1`,
      [hashVerificationValue(token)],
    );
  } else {
    throw httpError(400, 'verificationId or token is required.');
  }

  if (rows.length === 0) {
    throw httpError(404, 'Registration verification was not found.');
  }
  return rows[0];
}

async function validateRegistrationVerification(
  verification,
  { otp, token },
) {
  if (new Date(verification.expires_at).getTime() < Date.now()) {
    await execute('DELETE FROM registration_verifications WHERE id = ?', [
      verification.id,
    ]);
    throw httpError(410, 'Verification code or link has expired.');
  }

  if (Number(verification.attempts) >= registrationMaxAttempts) {
    throw httpError(429, 'Too many verification attempts. Request a new code.');
  }

  if (!hasValidRegistrationCredential(verification, { otp, token })) {
    await execute(
      `UPDATE registration_verifications
       SET attempts = attempts + 1
       WHERE id = ?`,
      [verification.id],
    );
    throw httpError(400, 'Verification code or link is not valid.');
  }
}

async function completeRegistration(verification, credentials) {
  const connection = await pool.getConnection();
  const userId = makeId('u');

  try {
    await connection.beginTransaction();

    const [verificationRows] = await connection.execute(
      `SELECT *
       FROM registration_verifications
       WHERE id = ?
       LIMIT 1
       FOR UPDATE`,
      [verification.id],
    );
    if (verificationRows.length === 0) {
      throw httpError(409, 'Registration verification was already used.');
    }

    const lockedVerification = verificationRows[0];
    if (new Date(lockedVerification.expires_at).getTime() < Date.now()) {
      throw httpError(410, 'Verification code or link has expired.');
    }
    if (!hasValidRegistrationCredential(lockedVerification, credentials)) {
      throw httpError(400, 'Verification code or link is not valid.');
    }

    const [existingUsers] = await connection.execute(
      'SELECT id FROM users WHERE email = ? LIMIT 1',
      [lockedVerification.email],
    );
    if (existingUsers.length > 0) {
      throw httpError(409, 'Email already exists.');
    }

    await connection.execute(
      `INSERT INTO users
         (id, email, password_hash, full_name, role, avatar_text)
       VALUES (?, ?, ?, ?, 'Member', ?)`,
      [
        userId,
        lockedVerification.email,
        lockedVerification.password_hash,
        lockedVerification.full_name,
        lockedVerification.avatar_text,
      ],
    );
    await connection.execute(
      `INSERT IGNORE INTO workspace_members
         (workspace_id, user_id, member_role)
       SELECT id, ?, 'Member'
       FROM workspaces`,
      [userId],
    );
    await connection.execute(
      `INSERT IGNORE INTO project_members (project_id, user_id)
       SELECT p.id, ?
       FROM projects p
       JOIN workspace_members wm ON wm.workspace_id = p.workspace_id
       WHERE wm.user_id = ?`,
      [userId, userId],
    );
    await connection.execute(
      'DELETE FROM registration_verifications WHERE id = ?',
      [lockedVerification.id],
    );
    await connection.execute(
      `INSERT INTO activity_logs
         (id, workspace_id, user_id, action_type, title, description)
       VALUES (?, NULL, ?, 'REGISTER', ?, ?)`,
      [
        makeId('log'),
        userId,
        'Đăng ký tài khoản',
        `${lockedVerification.full_name} đã xác thực email và đăng ký tài khoản mới.`,
      ],
    );

    await connection.commit();
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }

  const user = await getUserById(userId);
  const token = signToken({ sub: user.id, role: user.role });

  return { token, user };
}

async function sendRegistrationVerificationEmail({
  email,
  fullName,
  method,
  otp,
  verificationLink,
}) {
  if (!process.env.SMTP_HOST) {
    console.error('SMTP_HOST is not configured; verification email was not sent.');
    return false;
  }

  try {
    const nodemailer = require('nodemailer');
    const transporter = nodemailer.createTransport({
      host: process.env.SMTP_HOST,
      port: Number(process.env.SMTP_PORT || 587),
      secure: process.env.SMTP_SECURE === 'true',
      auth: process.env.SMTP_USER
        ? {
            user: process.env.SMTP_USER,
            pass: process.env.SMTP_PASSWORD || '',
          }
        : undefined,
    });

    const safeFullName = escapeHtml(fullName);
    const safeOtp = escapeHtml(otp);
    const safeVerificationLink = escapeHtml(verificationLink);
    const otpBlock = method === 'LINK'
      ? ''
      : `
        <tr>
          <td style="padding:0 32px 24px">
            <div style="background:#f5f3ff;border:1px solid #ddd6fe;border-radius:18px;padding:22px;text-align:center">
              <div style="color:#6d28d9;font-size:12px;font-weight:700;letter-spacing:1.5px;text-transform:uppercase">
                Mã xác thực của bạn
              </div>
              <div style="color:#111827;font-size:34px;font-weight:800;letter-spacing:9px;padding-top:12px">
                ${safeOtp}
              </div>
            </div>
          </td>
        </tr>`;
    const linkBlock = method === 'OTP'
      ? ''
      : `
        <tr>
          <td style="padding:0 32px 24px;text-align:center">
            <a href="${safeVerificationLink}"
               style="display:inline-block;background:#7c3aed;color:#ffffff;text-decoration:none;font-size:15px;font-weight:700;padding:15px 28px;border-radius:12px">
              Xác thực tài khoản
            </a>
          </td>
        </tr>`;
    const textContent = method === 'OTP'
      ? `Xin chào ${fullName}. OTP của bạn là ${otp}.`
      : method === 'LINK'
        ? `Xin chào ${fullName}. Link xác thực: ${verificationLink}`
        : `Xin chào ${fullName}. OTP: ${otp}. Link xác thực: ${verificationLink}`;

    await transporter.sendMail({
      from:
        process.env.EMAIL_FROM ||
        'Productivity Manager <no-reply@example.com>',
      to: email,
      subject: 'Xác thực đăng ký Productivity Manager',
      text: textContent,
      html: `<!doctype html>
<html lang="vi">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <title>Xác thực đăng ký</title>
  </head>
  <body style="margin:0;padding:0;background:#f3f4f6;font-family:Arial,sans-serif;color:#111827">
    <div style="display:none;max-height:0;overflow:hidden;color:transparent">
      Hoàn tất xác thực tài khoản Productivity Manager của bạn.
    </div>
    <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background:#f3f4f6">
      <tr>
        <td align="center" style="padding:32px 16px">
          <table role="presentation" width="100%" cellspacing="0" cellpadding="0"
                 style="max-width:600px;background:#ffffff;border-radius:24px;overflow:hidden;box-shadow:0 16px 40px rgba(17,24,39,.12)">
            <tr>
              <td style="background:#6d28d9;padding:30px 32px">
                <div style="color:#ddd6fe;font-size:13px;font-weight:700;letter-spacing:1.4px;text-transform:uppercase">
                  Productivity Manager
                </div>
                <div style="color:#ffffff;font-size:27px;font-weight:800;padding-top:8px">
                  Xác thực email đăng ký
                </div>
              </td>
            </tr>
            <tr>
              <td style="padding:30px 32px 18px">
                <div style="font-size:19px;font-weight:800">Xin chào ${safeFullName},</div>
                <p style="margin:12px 0 0;color:#4b5563;font-size:15px;line-height:1.65">
                  Cảm ơn bạn đã đăng ký. Hãy hoàn tất bước xác thực bên dưới để bắt đầu quản lý workspace, project và task.
                </p>
              </td>
            </tr>
            ${otpBlock}
            ${linkBlock}
            <tr>
              <td style="padding:0 32px 28px">
                <div style="background:#eff6ff;border-radius:14px;padding:16px;color:#1e3a8a;font-size:13px;line-height:1.55">
                  Mã hoặc liên kết sẽ hết hạn sau <strong>${registrationOtpTtlMinutes} phút</strong>.
                  Nếu bạn không thực hiện đăng ký này, hãy bỏ qua email.
                </div>
              </td>
            </tr>
            <tr>
              <td style="border-top:1px solid #e5e7eb;padding:20px 32px;color:#9ca3af;font-size:12px;line-height:1.5;text-align:center">
                Email tự động từ Productivity Manager. Vui lòng không trả lời email này.
              </td>
            </tr>
          </table>
        </td>
      </tr>
    </table>
  </body>
</html>`,
    });
    return true;
  } catch (error) {
    console.error('Could not send registration verification email.', error);
    return false;
  }
}

function hashVerificationValue(value) {
  return crypto
    .createHash('sha256')
    .update(String(value || ''))
    .digest('hex');
}

function safeHashEquals(value, expectedHash) {
  const candidate = Buffer.from(hashVerificationValue(value), 'hex');
  const expected = Buffer.from(String(expectedHash || ''), 'hex');
  return candidate.length === expected.length &&
    crypto.timingSafeEqual(candidate, expected);
}

function hasValidRegistrationCredential(verification, { otp, token } = {}) {
  const validOtp =
    Boolean(otp) &&
    Boolean(verification.otp_hash) &&
    safeHashEquals(otp, verification.otp_hash);
  const validToken =
    Boolean(token) &&
    Boolean(verification.verification_token_hash) &&
    safeHashEquals(token, verification.verification_token_hash);
  return validOtp || validToken;
}

function escapeHtml(value) {
  return String(value || '')
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#039;');
}

function makeId(prefix) {
  return `${prefix}${Date.now().toString(36)}${crypto.randomBytes(4).toString('hex')}`;
}

function assertStrongPassword(password, label = 'Password') {
  const value = String(password || '');
  if (value.length < 6) {
    throw httpError(400, `${label} must contain at least 6 characters.`);
  }
  if (!/[A-Z]/.test(value)) {
    throw httpError(400, `${label} must contain at least one uppercase letter.`);
  }
  if (!/[^A-Za-z0-9]/.test(value)) {
    throw httpError(400, `${label} must contain at least one special character.`);
  }
}

function hashPassword(password) {
  const salt = crypto.randomBytes(16).toString('hex');
  const hash = crypto.scryptSync(String(password), salt, 64).toString('hex');
  return `scrypt$${salt}$${hash}`;
}

function verifyPassword(password, encoded) {
  const [scheme, salt, storedHash] = String(encoded || '').split('$');
  if (scheme !== 'scrypt' || !salt || !storedHash) return false;

  const candidateHash = crypto.scryptSync(String(password), salt, 64);
  const storedBuffer = Buffer.from(storedHash, 'hex');
  return storedBuffer.length === candidateHash.length &&
    crypto.timingSafeEqual(storedBuffer, candidateHash);
}

function signToken(payload) {
  const header = base64Url(JSON.stringify({ alg: 'HS256', typ: 'JWT' }));
  const body = base64Url(JSON.stringify({
    ...payload,
    iat: Math.floor(Date.now() / 1000),
    exp: Math.floor(Date.now() / 1000) + jwtTtlSeconds,
  }));
  const signature = createSignature(`${header}.${body}`);
  return `${header}.${body}.${signature}`;
}

function verifyToken(token) {
  const [header, body, signature] = token.split('.');
  if (!header || !body || !signature) throw httpError(401, 'Invalid token.');

  const expected = createSignature(`${header}.${body}`);
  const expectedBuffer = Buffer.from(expected);
  const signatureBuffer = Buffer.from(signature);
  if (expectedBuffer.length !== signatureBuffer.length ||
    !crypto.timingSafeEqual(expectedBuffer, signatureBuffer)) {
    throw httpError(401, 'Invalid token signature.');
  }

  const payload = JSON.parse(Buffer.from(body, 'base64url').toString('utf8'));
  if (payload.exp && payload.exp < Math.floor(Date.now() / 1000)) {
    throw httpError(401, 'Token expired.');
  }
  return payload;
}

function createSignature(input) {
  return crypto
    .createHmac('sha256', jwtSecret)
    .update(input)
    .digest('base64url');
}

function base64Url(value) {
  return Buffer.from(value).toString('base64url');
}

async function getUserById(id) {
  const rows = await query('SELECT * FROM users WHERE id = ? LIMIT 1', [id]);
  if (rows.length === 0) throw httpError(404, 'User not found.');
  return mapUser(rows[0]);
}

async function findUserByNameOrAvatar(nameOrAvatar) {
  if (!nameOrAvatar) return null;
  const rows = await query(
    `SELECT *
     FROM users
     WHERE full_name = ? OR avatar_text = ?
     LIMIT 1`,
    [nameOrAvatar, String(nameOrAvatar).toUpperCase()],
  );
  return rows.length ? mapUser(rows[0]) : null;
}

async function getWorkspaceById(id) {
  const rows = await query(`${workspaceBaseSelect()} WHERE w.id = ?`, [id]);
  if (rows.length === 0) throw httpError(404, 'Workspace not found.');
  return mapWorkspace(rows[0]);
}

async function getProjectById(id) {
  const rows = await query(`${projectBaseSelect()} WHERE p.id = ?`, [id]);
  if (rows.length === 0) throw httpError(404, 'Project not found.');
  return mapProject(rows[0]);
}

async function getTaskListById(id) {
  const rows = await query(
    `SELECT id, project_id, name, position, wip_limit, is_wip_enabled
     FROM task_lists
     WHERE id = ?
     LIMIT 1`,
    [id],
  );
  if (rows.length === 0) throw httpError(404, 'Task list not found.');
  return mapTaskList(rows[0]);
}

async function getTaskById(id) {
  const { sql, params } = taskSelectSql({ taskId: id });
  const rows = await query(sql, params);
  if (rows.length === 0) throw httpError(404, 'Task not found.');
  return mapTask(rows[0]);
}

async function getRequirementRow(id) {
  const rows = await query(
    `SELECT r.*, t.project_id
     FROM task_requirements r
     JOIN tasks t ON t.id = r.task_id
     WHERE r.id = ?
     LIMIT 1`,
    [id],
  );
  if (rows.length === 0) throw httpError(404, 'Requirement not found.');
  return rows[0];
}

async function getApprovalRequestById(id) {
  const rows = await query(`${approvalSelectSql()} WHERE ar.id = ? LIMIT 1`, [id]);
  if (rows.length === 0) throw httpError(404, 'Approval request not found.');
  return mapApprovalRequest(rows[0]);
}

async function getLatestApprovalByRequirementId(requirementId) {
  const rows = await query(
    `${approvalSelectSql()} WHERE ar.requirement_id = ? ORDER BY ar.submitted_at DESC LIMIT 1`,
    [requirementId],
  );
  return rows.length ? mapApprovalRequest(rows[0]) : null;
}

async function getAllActiveUsers() {
  return query(
    `SELECT id, role
     FROM users
     WHERE is_active = TRUE`,
  );
}

async function getUsersByIds(ids) {
  const uniqueIds = [...new Set((ids || []).filter(Boolean).map(String))];

  if (uniqueIds.length === 0) return [];

  const placeholders = uniqueIds.map(() => '?').join(',');

  return query(
    `SELECT id, role
     FROM users
     WHERE is_active = TRUE AND id IN (${placeholders})`,
    uniqueIds,
  );
}

async function getWorkspaceMemberUsers(workspaceId) {
  return query(
    `SELECT u.id, u.role
     FROM workspace_members wm
     JOIN users u ON u.id = wm.user_id
     WHERE wm.workspace_id = ? AND u.is_active = TRUE`,
    [workspaceId],
  );
}

function workspaceMemberRole(user, isOwner = false) {
  if (isOwner) return 'Owner';
  if (user.role === 'Admin' || user.role === 'Manager') return 'Manager';
  return 'Member';
}

async function ensureWorkspaceMembers(workspaceId, users, ownerId = null) {
  for (const user of users) {
    await execute(
      `INSERT IGNORE INTO workspace_members (workspace_id, user_id, member_role)
       VALUES (?, ?, ?)`,
      [
        workspaceId,
        user.id,
        workspaceMemberRole(user, ownerId === user.id),
      ],
    );
  }
}

async function ensureProjectMembers(projectId, users) {
  for (const user of users) {
    await execute(
      `INSERT IGNORE INTO project_members (project_id, user_id)
       VALUES (?, ?)`,
      [projectId, user.id],
    );
  }
}

async function createDefaultLists(projectId) {
  const defaults = [
    ['Cần làm', 1, 5, true],
    ['Đang làm', 2, 4, true],
    ['Kiểm tra', 3, 3, true],
    ['Đã xong', 4, null, false],
  ];

  for (const [name, position, wipLimit, enabled] of defaults) {
    await execute(
      `INSERT INTO task_lists (id, project_id, name, position, wip_limit, is_wip_enabled)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [makeId('lst'), projectId, name, position, wipLimit, enabled],
    );
  }
}

async function getListIdByName(projectId, listName) {
  const rows = await query(
    `SELECT id FROM task_lists WHERE project_id = ? AND name = ? LIMIT 1`,
    [projectId, listName],
  );

  if (rows.length > 0) return rows[0].id;

  const listId = makeId('lst');
  const [countRow] = await query(
    'SELECT COALESCE(MAX(position), 0) + 1 AS next_position FROM task_lists WHERE project_id = ?',
    [projectId],
  );
  await execute(
    `INSERT INTO task_lists (id, project_id, name, position)
     VALUES (?, ?, ?, ?)`,
    [listId, projectId, listName, Number(countRow.next_position)],
  );
  return listId;
}

async function logTaskAction(taskId, userId, actionType, title, description) {
  const rows = await query(
    `SELECT t.id, t.project_id, p.workspace_id
     FROM tasks t
     JOIN projects p ON p.id = t.project_id
     WHERE t.id = ?
     LIMIT 1`,
    [taskId],
  );

  if (rows.length === 0) return;
  await insertActivity({
    workspaceId: rows[0].workspace_id,
    userId,
    actionType,
    title,
    description,
  });
}

async function insertActivity({ workspaceId, userId, actionType, title, description }) {
  await execute(
    `INSERT INTO activity_logs (id, workspace_id, user_id, action_type, title, description)
     VALUES (?, ?, ?, ?, ?, ?)`,
    [makeId('log'), workspaceId, userId, actionType, title, description],
  );
}

async function createNotification({ targetUserId, title, message, type, taskId = null, projectId = null }) {
  await execute(
    `INSERT INTO notifications (id, target_user_id, title, message, type, task_id, project_id)
     VALUES (?, ?, ?, ?, ?, ?, ?)`,
    [makeId('noti'), targetUserId, title, message, type, taskId, projectId],
  );
}

async function reviewApprovalRequest(id, reviewerId, status, rejectReason = null) {
  const normalizedStatus = String(status || '').toUpperCase();
  if (!['APPROVED', 'REJECTED'].includes(normalizedStatus)) {
    throw httpError(400, 'status must be APPROVED or REJECTED.');
  }

  const request = await getApprovalRequestById(id);
  const requirementStatus = normalizedStatus === 'APPROVED' ? 'APPROVED' : 'REJECTED';

  await execute(
    `UPDATE requirement_approval_requests
     SET status = ?, reviewed_at = CURRENT_TIMESTAMP, reviewer_id = ?, reject_reason = ?
     WHERE id = ?`,
    [normalizedStatus, reviewerId, rejectReason || null, id],
  );
  await execute(
    `UPDATE task_requirements
     SET status = ?, reviewed_by = ?, reviewed_at = CURRENT_TIMESTAMP, reject_reason = ?
     WHERE id = ?`,
    [requirementStatus, reviewerId, rejectReason || null, request.requirementId],
  );

  await createNotification({
    targetUserId: request.userId,
    title: normalizedStatus === 'APPROVED' ? 'Yêu cầu đã được duyệt' : 'Yêu cầu bị từ chối',
    message: normalizedStatus === 'APPROVED'
      ? `Requirement trong task “${request.taskTitle}” đã được phê duyệt.`
      : `Requirement trong task “${request.taskTitle}” bị từ chối. ${rejectReason || ''}`.trim(),
    type: normalizedStatus === 'APPROVED' ? 'APPROVAL_APPROVED' : 'APPROVAL_REJECTED',
    taskId: request.taskId,
    projectId: request.projectId,
  });

  await logTaskAction(
    request.taskId,
    reviewerId,
    normalizedStatus === 'APPROVED' ? 'APPROVAL_APPROVED' : 'APPROVAL_REJECTED',
    normalizedStatus === 'APPROVED' ? 'Phê duyệt yêu cầu kỹ thuật' : 'Từ chối yêu cầu kỹ thuật',
    normalizedStatus === 'APPROVED'
      ? `Requirement “${request.requirementTitle}” đã được phê duyệt.`
      : `Requirement “${request.requirementTitle}” bị từ chối.`,
  );

  if (normalizedStatus === 'APPROVED') {
    await moveTaskToDoneIfAllRequirementsApproved(request.taskId);
  }

  return getApprovalRequestById(id);
}

async function moveTaskToDoneIfAllRequirementsApproved(taskId) {
  const rows = await query(
    `SELECT
       SUM(status <> 'APPROVED') AS not_approved_count,
       COUNT(*) AS total_count
     FROM task_requirements
     WHERE task_id = ?`,
    [taskId],
  );

  const notApproved = Number(rows[0]?.not_approved_count || 0);
  const total = Number(rows[0]?.total_count || 0);
  if (total === 0 || notApproved > 0) return;

  const task = await getTaskById(taskId);
  const doneListId = await getListIdByName(task.projectId, 'Đã xong');
  await execute('UPDATE tasks SET list_id = ? WHERE id = ?', [doneListId, taskId]);
}

function workspaceBaseSelect() {
  return `
    SELECT
      w.*,
      COALESCE(member_stats.member_count, 0) AS member_count,
      COALESCE(project_stats.project_count, 0) AS project_count
    FROM workspaces w
    LEFT JOIN (
      SELECT workspace_id, COUNT(*) AS member_count
      FROM workspace_members
      GROUP BY workspace_id
    ) member_stats ON member_stats.workspace_id = w.id
    LEFT JOIN (
      SELECT workspace_id, COUNT(*) AS project_count
      FROM projects
      GROUP BY workspace_id
    ) project_stats ON project_stats.workspace_id = w.id
  `;
}

function workspaceSelectSql(user) {
  if (user.role === 'Admin') {
    return `${workspaceBaseSelect()} ORDER BY w.created_at ASC`;
  }

  return `
    ${workspaceBaseSelect()}
    WHERE w.owner_id = ? OR EXISTS (
      SELECT 1 FROM workspace_members wm
      WHERE wm.workspace_id = w.id AND wm.user_id = ?
    )
    ORDER BY w.created_at ASC
  `;
}

function workspaceSelectParams(user) {
  return user.role === 'Admin' ? [] : [user.id, user.id];
}

function projectBaseSelect() {
  return `
    SELECT
      p.*,
      COALESCE(task_stats.total_tasks, 0) AS total_tasks,
      COALESCE(task_stats.completed_tasks, 0) AS completed_tasks,
      CASE
        WHEN COALESCE(task_stats.total_tasks, 0) = 0 THEN 0
        ELSE COALESCE(task_stats.completed_tasks, 0) / task_stats.total_tasks
      END AS progress,
      COALESCE(member_stats.members, '') AS members
    FROM projects p
    LEFT JOIN (
      SELECT
        t.project_id,
        COUNT(*) AS total_tasks,
        SUM(CASE WHEN l.name = 'Đã xong' THEN 1 ELSE 0 END) AS completed_tasks
      FROM tasks t
      JOIN task_lists l ON l.id = t.list_id
      GROUP BY t.project_id
    ) task_stats ON task_stats.project_id = p.id
    LEFT JOIN (
      SELECT pm.project_id, GROUP_CONCAT(u.avatar_text ORDER BY u.id SEPARATOR ',') AS members
      FROM project_members pm
      JOIN users u ON u.id = pm.user_id
      GROUP BY pm.project_id
    ) member_stats ON member_stats.project_id = p.id
  `;
}

function projectSelectSql(user, workspaceId) {
  const clauses = [];
  if (workspaceId) clauses.push('p.workspace_id = ?');
  if (user.role !== 'Admin') {
    clauses.push(`EXISTS (
      SELECT 1 FROM project_members pm
      WHERE pm.project_id = p.id AND pm.user_id = ?
    )`);
  }

  const where = clauses.length ? `WHERE ${clauses.join(' AND ')}` : '';
  return `${projectBaseSelect()} ${where} ORDER BY p.created_at ASC`;
}

function projectSelectParams(user, workspaceId) {
  const params = [];
  if (workspaceId) params.push(workspaceId);
  if (user.role !== 'Admin') params.push(user.id);
  return params;
}

function taskSelectSql(filters = {}) {
  const conditions = [];
  const params = [];

  if (filters.taskId) {
    conditions.push('t.id = ?');
    params.push(filters.taskId);
  }
  if (filters.projectId) {
    conditions.push('t.project_id = ?');
    params.push(filters.projectId);
  }
  if (filters.workspaceId) {
    conditions.push('p.workspace_id = ?');
    params.push(filters.workspaceId);
  }
  if (filters.assigneeId) {
    conditions.push('t.assignee_id = ?');
    params.push(filters.assigneeId);
  }
  if (filters.status) {
    conditions.push('l.name = ?');
    params.push(filters.status);
  }
  if (filters.priority) {
    conditions.push('t.priority = ?');
    params.push(filters.priority);
  }
  if (filters.search) {
    conditions.push('(t.title LIKE ? OR t.description LIKE ?)');
    const pattern = `%${String(filters.search).trim()}%`;
    params.push(pattern, pattern);
  }

  const where = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';
  return {
    params,
    sql: `
      SELECT
        t.*,
        l.name AS list_name,
        u.full_name AS assignee_name,
        u.avatar_text AS assignee_avatar,
        COALESCE(ci.checklist_total, 0) AS checklist_total,
        COALESCE(ci.checklist_done, 0) AS checklist_done,
        COALESCE(cm.comment_count, 0) AS comment_count
      FROM tasks t
      JOIN task_lists l ON l.id = t.list_id
      JOIN projects p ON p.id = t.project_id
      LEFT JOIN users u ON u.id = t.assignee_id
      LEFT JOIN (
        SELECT task_id, COUNT(*) AS checklist_total, SUM(is_completed = TRUE) AS checklist_done
        FROM checklist_items
        GROUP BY task_id
      ) ci ON ci.task_id = t.id
      LEFT JOIN (
        SELECT task_id, COUNT(*) AS comment_count
        FROM comments
        GROUP BY task_id
      ) cm ON cm.task_id = t.id
      ${where}
      ORDER BY l.position ASC, t.position ASC, t.created_at ASC
    `,
  };
}

function approvalSelectSql() {
  return `
    SELECT
      ar.*,
      tr.title AS requirement_title,
      t.title AS task_title,
      submitter.full_name AS user_name,
      reviewer.full_name AS reviewer_name
    FROM requirement_approval_requests ar
    JOIN task_requirements tr ON tr.id = ar.requirement_id
    JOIN tasks t ON t.id = ar.task_id
    JOIN users submitter ON submitter.id = ar.user_id
    LEFT JOIN users reviewer ON reviewer.id = ar.reviewer_id
  `;
}

function mapUser(row) {
  return {
    id: row.id,
    email: row.email,
    fullName: row.full_name,
    role: row.role,
    avatarText: row.avatar_text,
    avatarUrl: row.avatar_url,
    isActive: Boolean(row.is_active),
    notificationEnabled: Boolean(row.notification_enabled),
    twoStepEnabled: Boolean(row.two_step_enabled),
    biometricEnabled: Boolean(row.biometric_enabled),
    createdAt: formatDateTime(row.created_at),
  };
}

function mapWorkspace(row) {
  return {
    id: row.id,
    name: row.name,
    description: row.description || '',
    ownerId: row.owner_id,
    memberCount: Number(row.member_count || 0),
    projectCount: Number(row.project_count || 0),
    iconText: row.icon_text || initials(row.name),
    createdAt: formatDateTime(row.created_at),
  };
}

function mapProject(row) {
  const totalTasks = Number(row.total_tasks || 0);
  const completedTasks = Number(row.completed_tasks || 0);
  return {
    id: row.id,
    workspaceId: row.workspace_id,
    name: row.name,
    description: row.description || '',
    code: row.code,
    deadline: formatDate(row.deadline, true),
    progress: totalTasks === 0 ? Number(row.progress || 0) : completedTasks / totalTasks,
    totalTasks,
    completedTasks,
    members: row.members ? String(row.members).split(',') : [],
    status: row.status,
    createdAt: formatDateTime(row.created_at),
  };
}

function mapTaskList(row) {
  return {
    id: row.id,
    projectId: row.project_id,
    name: row.name,
    position: Number(row.position || 0),
    wipLimit: row.wip_limit === null ? null : Number(row.wip_limit),
    isWipEnabled: Boolean(row.is_wip_enabled),
  };
}

function mapTask(row) {
  return {
    id: row.id,
    listId: row.list_id,
    projectId: row.project_id,
    title: row.title,
    description: row.description || '',
    creatorId: row.creator_id,
    assigneeId: row.assignee_id,
    assigneeName: row.assignee_name || 'Chưa phân công',
    assigneeAvatar: row.assignee_avatar || 'NA',
    priority: row.priority,
    status: row.list_name,
    dueDate: formatDate(row.due_date, false),
    dueDateFull: formatDate(row.due_date, true),
    checklistDone: Number(row.checklist_done || 0),
    checklistTotal: Number(row.checklist_total || 0),
    commentCount: Number(row.comment_count || 0),
    createdAt: formatDateTime(row.created_at),
  };
}

function mapChecklistItem(row) {
  return {
    id: row.id,
    taskId: row.task_id,
    title: row.title,
    isCompleted: Boolean(row.is_completed),
    position: Number(row.position || 0),
  };
}

function mapRequirement(row) {
  return {
    id: row.id,
    taskId: row.task_id,
    title: row.title,
    status: row.status,
    statusLabel: requirementStatusLabel(row.status),
    submittedBy: row.submitted_by,
    submittedByName: row.submitted_by_name,
    reviewerName: row.reviewer_name,
    rejectReason: row.reject_reason,
    submittedAt: formatDateTime(row.submitted_at),
    reviewedAt: formatDateTime(row.reviewed_at),
    position: Number(row.position || 0),
  };
}

function mapComment(row) {
  return {
    id: row.id,
    taskId: row.task_id,
    userId: row.user_id,
    name: row.full_name,
    avatar: row.avatar_text,
    content: row.content,
    time: formatTime(row.created_at),
    createdAt: formatDateTime(row.created_at),
  };
}

function mapApprovalRequest(row) {
  return {
    id: row.id,
    requirementId: row.requirement_id,
    userId: row.user_id,
    userName: row.user_name,
    taskId: row.task_id,
    projectId: row.project_id,
    taskTitle: row.task_title,
    requirementTitle: row.requirement_title,
    status: row.status,
    submittedAt: formatDateTime(row.submitted_at),
    reviewedAt: formatDateTime(row.reviewed_at),
    reviewerId: row.reviewer_id,
    reviewerName: row.reviewer_name,
    rejectReason: row.reject_reason,
  };
}

function mapNotification(row) {
  return {
    id: row.id,
    targetUserId: row.target_user_id,
    title: row.title,
    message: row.message,
    type: row.type,
    createdAt: formatDateTime(row.created_at),
    isRead: Boolean(row.is_read),
    taskId: row.task_id,
    projectId: row.project_id,
  };
}

function mapActivityLog(row) {
  return {
    id: row.id,
    workspaceId: row.workspace_id,
    userId: row.user_id,
    userName: row.full_name || 'Hệ thống',
    userAvatar: row.avatar_text || 'SY',
    actionType: row.action_type,
    title: row.title,
    description: row.description,
    createdAt: formatDateTime(row.created_at),
  };
}

function toSqlDate(value) {
  if (!value) return null;
  if (value instanceof Date) return value.toISOString().slice(0, 10);

  const raw = String(value).trim();
  if (/^\d{4}-\d{2}-\d{2}/.test(raw)) return raw.slice(0, 10);

  const parts = raw.split('/');
  if (parts.length >= 2) {
    const day = parts[0].padStart(2, '0');
    const month = parts[1].padStart(2, '0');
    const year = parts[2] || String(new Date().getFullYear());
    return `${year}-${month}-${day}`;
  }

  const parsed = new Date(raw);
  return Number.isNaN(parsed.getTime()) ? null : parsed.toISOString().slice(0, 10);
}

function formatDate(value, includeYear) {
  if (!value) return '';
  const date = value instanceof Date ? value : new Date(value);
  if (Number.isNaN(date.getTime())) return '';
  const day = String(date.getDate()).padStart(2, '0');
  const month = String(date.getMonth() + 1).padStart(2, '0');
  return includeYear ? `${day}/${month}/${date.getFullYear()}` : `${day}/${month}`;
}

function formatTime(value) {
  if (!value) return '';
  const date = value instanceof Date ? value : new Date(value);
  if (Number.isNaN(date.getTime())) return '';
  return `${String(date.getHours()).padStart(2, '0')}:${String(date.getMinutes()).padStart(2, '0')}`;
}

function formatDateTime(value) {
  if (!value) return null;
  const date = value instanceof Date ? value : new Date(value);
  if (Number.isNaN(date.getTime())) return null;
  const day = String(date.getDate()).padStart(2, '0');
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const year = date.getFullYear();
  return `${day}/${month}/${year} ${formatTime(date)}`;
}

function requirementStatusLabel(status) {
  switch (status) {
    case 'WAITING':
      return 'Đang chờ duyệt';
    case 'APPROVED':
      return 'Đã duyệt';
    case 'REJECTED':
      return 'Bị từ chối';
    default:
      return 'Chưa gửi';
  }
}

function initials(value) {
  return String(value || 'NA')
    .trim()
    .split(/\s+/)
    .map((part) => part[0])
    .join('')
    .slice(0, 2)
    .toUpperCase() || 'NA';
}

function isOverdue(shortDate) {
  if (!shortDate || !shortDate.includes('/')) return false;
  const [day, month] = shortDate.split('/').map(Number);
  const date = new Date(new Date().getFullYear(), month - 1, day, 23, 59, 59);
  return date.getTime() < Date.now();
}
