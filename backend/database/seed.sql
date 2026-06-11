USE productivity_management;

SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE activity_logs;
TRUNCATE TABLE notifications;
TRUNCATE TABLE comments;
TRUNCATE TABLE requirement_approval_requests;
TRUNCATE TABLE task_requirements;
TRUNCATE TABLE checklist_items;
TRUNCATE TABLE task_attachments;
TRUNCATE TABLE tasks;
TRUNCATE TABLE task_lists;
TRUNCATE TABLE project_members;
TRUNCATE TABLE projects;
TRUNCATE TABLE workspace_members;
TRUNCATE TABLE workspaces;
TRUNCATE TABLE users;
SET FOREIGN_KEY_CHECKS = 1;

INSERT INTO users
  (id, email, password_hash, full_name, role, avatar_text, is_active, notification_enabled, two_step_enabled, biometric_enabled, created_at)
VALUES
  ('u001', 'admin@company.com', 'scrypt$992ab96f91850cb7769eef7050126cb3$662cbb04a86652a34bac13f3d1c6c8b0aebeee685492cbe884b98ed47e7c8110a8b28d9a6be059835c18f043db3d20d45c622fda270e25067ea5b5e1e132aee2', 'Admin System', 'Admin', 'AD', TRUE, TRUE, FALSE, FALSE, '2026-06-01 08:00:00'),
  ('u002', 'manager@company.com', 'scrypt$34ad0d4467dd79c77ec6b3b5bfe0108b$67275265dc728ede076bb9a5f0bb0e8bbdb71bd947fa1bcb057beb4c55e6199a2fcd503c519e32506523416ec28b5abec9a1ba068662f2d0db4487b28ca678cc', 'Nguyễn Văn Quản Lý', 'Manager', 'QL', TRUE, TRUE, FALSE, FALSE, '2026-06-01 08:10:00'),
  ('u003', 'nguyenvana@company.com', 'scrypt$716f7b8df84e820751cac8ae3acd9117$c7143cae5096c8bff87798f1da1dab556f09083472fbd3ac763c95b9d13a1f8cdda46211d7a086790495532773a6e5100508a42169f1c68852745af02733a98d', 'Nguyễn Văn A', 'Member', 'NA', TRUE, TRUE, FALSE, FALSE, '2026-06-01 08:20:00'),
  ('u004', 'tranminh@company.com', 'scrypt$5d93860b7008578dee4737812be57197$85214f9c0e0591544e6da9629ca7b614dec90cb12f3e260fd3f35cfe6833866a7ad40d71446771dfe1dcc1316cac4cd8e9c1a0270ba3cef8cf49214b1e064272', 'Trần Minh', 'Member', 'TM', TRUE, TRUE, FALSE, FALSE, '2026-06-01 08:30:00'),
  ('u005', 'lethic@company.com', 'scrypt$dacc6c1930700359280dbec51cbdacfc$bbefba6cad0936c18811fd31673819af2cdf7dc77400710fe808f8d6918dfe5690f6bbf7750c9fa2ca6053d2c06a64360dfcfa46de273d6182b6b3bc982e527d', 'Lê Thị C', 'Member', 'LC', TRUE, TRUE, FALSE, FALSE, '2026-06-01 08:40:00'),
  ('u006', 'hani@company.com', 'scrypt$29a9b1c43c0636d233b4a081fec3275d$7b6279301042ee159b57d6ae5a345b4c1bc2344ba8d32fd2bd54b19534b11c261f15227bcb437dc2e0695f2245ae9367cdc5abf64661741142281c86774ce29d', 'Hà Nhi', 'Member', 'HN', TRUE, TRUE, FALSE, FALSE, '2026-06-01 08:50:00');

INSERT INTO workspaces
  (id, name, description, owner_id, icon_text, created_at)
VALUES
  ('ws001', 'Phát triển Sản phẩm', 'Không gian dành cho team sản phẩm và kỹ thuật', 'u002', 'SP', '2026-06-02 08:30:00'),
  ('ws002', 'Marketing & Truyền thông', 'Quản lý campaign, content và truyền thông', 'u002', 'MK', '2026-06-03 09:00:00'),
  ('ws003', 'Vận hành Nội bộ', 'Theo dõi các task vận hành công ty', 'u001', 'VH', '2026-06-04 09:30:00');

INSERT INTO workspace_members (workspace_id, user_id, member_role)
VALUES
  ('ws001', 'u001', 'Manager'), ('ws001', 'u002', 'Owner'), ('ws001', 'u003', 'Member'),
  ('ws001', 'u004', 'Member'), ('ws001', 'u005', 'Member'), ('ws001', 'u006', 'Member'),
  ('ws002', 'u001', 'Manager'), ('ws002', 'u002', 'Owner'), ('ws002', 'u003', 'Member'),
  ('ws002', 'u005', 'Member'),
  ('ws003', 'u001', 'Owner'), ('ws003', 'u002', 'Manager'), ('ws003', 'u003', 'Member'),
  ('ws003', 'u004', 'Member');

INSERT INTO projects
  (id, workspace_id, name, description, code, deadline, status, created_at)
VALUES
  ('p001', 'ws001', 'Mobile App v2.0', 'Ứng dụng Flutter quản lý năng suất bản mobile.', 'MOB-001', '2026-06-30', 'Active', '2026-06-05 08:30:00'),
  ('p002', 'ws001', 'CRM Integration', 'Tích hợp dữ liệu CRM với hệ thống productivity.', 'CRM-014', '2026-06-18', 'Active', '2026-06-05 09:00:00'),
  ('p003', 'ws001', 'Backend API Upgrade', 'Nâng cấp REST API và chuẩn hóa database.', 'API-022', '2026-06-25', 'Active', '2026-06-05 09:30:00'),
  ('p004', 'ws002', 'TikTok Launch Campaign', 'Chiến dịch ra mắt nội dung TikTok.', 'MKT-009', '2026-06-20', 'Active', '2026-06-06 08:00:00'),
  ('p005', 'ws002', 'Facebook Content Plan', 'Kế hoạch nội dung Facebook tháng 6.', 'FB-012', '2026-06-28', 'Active', '2026-06-06 08:30:00'),
  ('p006', 'ws003', 'Internal Workflow Setup', 'Chuẩn hóa quy trình vận hành nội bộ.', 'OPS-004', '2026-06-15', 'Active', '2026-06-07 08:30:00');

INSERT INTO project_members (project_id, user_id)
VALUES
  ('p001', 'u002'), ('p001', 'u003'), ('p001', 'u004'), ('p001', 'u005'), ('p001', 'u006'),
  ('p002', 'u002'), ('p002', 'u003'), ('p002', 'u004'), ('p002', 'u005'),
  ('p003', 'u001'), ('p003', 'u002'), ('p003', 'u003'), ('p003', 'u004'),
  ('p004', 'u002'), ('p004', 'u003'), ('p004', 'u005'),
  ('p005', 'u002'), ('p005', 'u003'), ('p005', 'u005'),
  ('p006', 'u001'), ('p006', 'u002'), ('p006', 'u004');

INSERT INTO task_lists (id, project_id, name, position, wip_limit, is_wip_enabled)
VALUES
  ('l_p001_todo', 'p001', 'Cần làm', 1, 5, TRUE),
  ('l_p001_doing', 'p001', 'Đang làm', 2, 4, TRUE),
  ('l_p001_testing', 'p001', 'Kiểm tra', 3, 3, TRUE),
  ('l_p001_done', 'p001', 'Đã xong', 4, NULL, FALSE),
  ('l_p002_todo', 'p002', 'Cần làm', 1, 5, TRUE),
  ('l_p002_doing', 'p002', 'Đang làm', 2, 4, TRUE),
  ('l_p002_testing', 'p002', 'Kiểm tra', 3, 3, TRUE),
  ('l_p002_done', 'p002', 'Đã xong', 4, NULL, FALSE),
  ('l_p003_todo', 'p003', 'Cần làm', 1, 5, TRUE),
  ('l_p003_doing', 'p003', 'Đang làm', 2, 4, TRUE),
  ('l_p003_testing', 'p003', 'Kiểm tra', 3, 3, TRUE),
  ('l_p003_done', 'p003', 'Đã xong', 4, NULL, FALSE),
  ('l_p004_todo', 'p004', 'Cần làm', 1, 5, TRUE),
  ('l_p004_doing', 'p004', 'Đang làm', 2, 4, TRUE),
  ('l_p004_testing', 'p004', 'Kiểm tra', 3, 3, TRUE),
  ('l_p004_done', 'p004', 'Đã xong', 4, NULL, FALSE),
  ('l_p005_todo', 'p005', 'Cần làm', 1, 5, TRUE),
  ('l_p005_doing', 'p005', 'Đang làm', 2, 4, TRUE),
  ('l_p005_testing', 'p005', 'Kiểm tra', 3, 3, TRUE),
  ('l_p005_done', 'p005', 'Đã xong', 4, NULL, FALSE),
  ('l_p006_todo', 'p006', 'Cần làm', 1, 5, TRUE),
  ('l_p006_doing', 'p006', 'Đang làm', 2, 4, TRUE),
  ('l_p006_testing', 'p006', 'Kiểm tra', 3, 3, TRUE),
  ('l_p006_done', 'p006', 'Đã xong', 4, NULL, FALSE);

INSERT INTO tasks
  (id, list_id, project_id, title, description, creator_id, assignee_id, priority, due_date, position, created_at)
VALUES
  ('t001', 'l_p001_todo', 'p001', 'Thiết kế màn hình đăng nhập', 'Tạo UI login, validation và xử lý đăng nhập qua REST API.', 'u002', 'u005', 'High', '2026-06-10', 1, '2026-06-08 08:00:00'),
  ('t002', 'l_p001_doing', 'p001', 'Xây dựng dashboard dự án', 'Hiển thị workspace, project và tiến độ hoàn thành.', 'u002', 'u003', 'Medium', '2026-06-12', 1, '2026-06-08 08:30:00'),
  ('t003', 'l_p001_doing', 'p001', 'Tạo Kanban board', 'Hiển thị task theo cột và hỗ trợ kéo thả.', 'u002', 'u004', 'High', '2026-06-13', 2, '2026-06-08 09:00:00'),
  ('t004', 'l_p001_testing', 'p001', 'Kiểm thử giao diện mobile', 'Test responsive trên nhiều kích thước màn hình.', 'u002', 'u006', 'Low', '2026-06-15', 1, '2026-06-08 09:30:00'),
  ('t005', 'l_p001_done', 'p001', 'Hoàn thiện theme app', 'Chuẩn hóa màu sắc, typography, spacing.', 'u002', 'u005', 'Medium', '2026-06-09', 1, '2026-06-08 10:00:00'),
  ('t006', 'l_p001_todo', 'p001', 'Tối ưu task card component', 'Tách widget card để tái sử dụng nhiều màn hình.', 'u002', 'u004', 'Medium', '2026-06-16', 2, '2026-06-08 10:30:00'),
  ('t007', 'l_p002_todo', 'p002', 'Tạo API CRM', 'Chuẩn bị dữ liệu và endpoint cho CRM integration.', 'u002', 'u003', 'High', '2026-06-17', 1, '2026-06-08 11:00:00');

INSERT INTO checklist_items (id, task_id, title, is_completed, position)
VALUES
  ('ci001', 't001', 'Kiểm tra layout trên màn hình mobile', TRUE, 1),
  ('ci002', 't001', 'Hoàn thiện component chính', TRUE, 2),
  ('ci003', 't001', 'Test thao tác người dùng', FALSE, 3),
  ('ci004', 't001', 'Đồng bộ UI với Kanban board', FALSE, 4),
  ('ci005', 't001', 'Chuẩn bị demo cho quản lý', FALSE, 5),
  ('ci006', 't002', 'Thiết kế thẻ workspace', TRUE, 1),
  ('ci007', 't002', 'Thiết kế thẻ project', TRUE, 2),
  ('ci008', 't002', 'Tính progress dự án', TRUE, 3),
  ('ci009', 't002', 'Nối API workspaces', TRUE, 4),
  ('ci010', 't002', 'Nối API projects', FALSE, 5),
  ('ci011', 't002', 'Kiểm tra loading state', FALSE, 6),
  ('ci012', 't003', 'Tạo cột Cần làm', TRUE, 1),
  ('ci013', 't003', 'Tạo cột Đang làm', TRUE, 2),
  ('ci014', 't003', 'Tạo cột Kiểm tra', TRUE, 3),
  ('ci015', 't003', 'Tạo cột Đã xong', FALSE, 4),
  ('ci016', 't003', 'Kéo thả task', FALSE, 5),
  ('ci017', 't003', 'Optimistic update', FALSE, 6),
  ('ci018', 't003', 'Rollback khi API lỗi', FALSE, 7),
  ('ci019', 't004', 'Test màn hình nhỏ', TRUE, 1),
  ('ci020', 't004', 'Test màn hình lớn', TRUE, 2),
  ('ci021', 't004', 'Test dark mode', TRUE, 3),
  ('ci022', 't004', 'Test điều hướng', TRUE, 4),
  ('ci023', 't004', 'Ghi nhận lỗi UI', TRUE, 5),
  ('ci024', 't005', 'Chuẩn hóa màu chính', TRUE, 1),
  ('ci025', 't005', 'Chuẩn hóa màu phụ', TRUE, 2),
  ('ci026', 't005', 'Chuẩn hóa text style', TRUE, 3),
  ('ci027', 't005', 'Chuẩn hóa spacing', TRUE, 4),
  ('ci028', 't005', 'Kiểm tra light mode', TRUE, 5),
  ('ci029', 't005', 'Kiểm tra dark mode', TRUE, 6),
  ('ci030', 't006', 'Tách widget card', TRUE, 1),
  ('ci031', 't006', 'Thêm trạng thái drag', FALSE, 2),
  ('ci032', 't006', 'Kiểm tra reuse admin', FALSE, 3),
  ('ci033', 't006', 'Cập nhật test UI', FALSE, 4),
  ('ci034', 't007', 'Thiết kế payload CRM', FALSE, 1),
  ('ci035', 't007', 'Tạo endpoint sync', FALSE, 2),
  ('ci036', 't007', 'Map dữ liệu account', FALSE, 3),
  ('ci037', 't007', 'Map dữ liệu contact', FALSE, 4),
  ('ci038', 't007', 'Test retry', FALSE, 5);

INSERT INTO task_requirements
  (id, task_id, title, status, submitted_by, reviewed_by, reject_reason, submitted_at, reviewed_at, position)
VALUES
  ('req001', 't001', 'Giao diện phải đúng layout mobile đã thống nhất', 'WAITING', 'u003', NULL, NULL, '2026-06-11 09:10:00', NULL, 1),
  ('req002', 't001', 'Task card phải hiển thị priority, deadline và assignee', 'APPROVED', 'u003', 'u002', NULL, '2026-06-10 14:20:00', '2026-06-10 16:00:00', 2),
  ('req003', 't001', 'Checklist phải cập nhật tiến độ ngay khi tick chọn', 'NOT_SUBMITTED', NULL, NULL, NULL, NULL, NULL, 3),
  ('req004', 't002', 'Dashboard phải hiển thị progress theo task', 'APPROVED', 'u003', 'u002', NULL, '2026-06-10 14:20:00', '2026-06-10 16:00:00', 1),
  ('req005', 't003', 'Kéo thả task giữa các cột phải cập nhật UI ngay', 'REJECTED', 'u003', 'u002', 'Cần chỉnh lại spacing giữa các task card và kiểm tra lại trạng thái sau khi kéo thả.', '2026-06-10 10:45:00', '2026-06-10 13:30:00', 1),
  ('req006', 't005', 'Màu sắc phải đồng bộ với thiết kế xanh tím', 'APPROVED', 'u003', 'u002', NULL, '2026-06-09 11:00:00', '2026-06-09 15:15:00', 1),
  ('req007', 't006', 'Task card phải hiển thị priority, deadline và assignee', 'WAITING', 'u004', NULL, NULL, '2026-06-11 10:05:00', NULL, 1);

INSERT INTO requirement_approval_requests
  (id, requirement_id, task_id, project_id, user_id, status, submitted_at, reviewed_at, reviewer_id, reject_reason)
VALUES
  ('ar001', 'req001', 't001', 'p001', 'u003', 'WAITING', '2026-06-11 09:10:00', NULL, NULL, NULL),
  ('ar002', 'req004', 't002', 'p001', 'u003', 'APPROVED', '2026-06-10 14:20:00', '2026-06-10 16:00:00', 'u002', NULL),
  ('ar003', 'req005', 't003', 'p001', 'u003', 'REJECTED', '2026-06-10 10:45:00', '2026-06-10 13:30:00', 'u002', 'Cần chỉnh lại spacing giữa các task card và kiểm tra lại trạng thái sau khi kéo thả.'),
  ('ar004', 'req006', 't005', 'p001', 'u003', 'APPROVED', '2026-06-09 11:00:00', '2026-06-09 15:15:00', 'u002', NULL),
  ('ar005', 'req007', 't006', 'p001', 'u004', 'WAITING', '2026-06-11 10:05:00', NULL, NULL, NULL);

INSERT INTO comments (id, task_id, user_id, content, created_at)
VALUES
  ('c001', 't001', 'u002', 'Phần UI đang ổn, kiểm tra thêm spacing giữa các card.', '2026-06-11 09:20:00'),
  ('c002', 't001', 'u005', 'Em đã cập nhật checklist và gửi yêu cầu duyệt.', '2026-06-11 10:05:00'),
  ('c003', 't001', 'u003', 'Đã rà lại validation email.', '2026-06-11 10:20:00'),
  ('c004', 't002', 'u002', 'Dashboard cần hiển thị progress rõ hơn.', '2026-06-10 09:10:00'),
  ('c005', 't002', 'u003', 'Em đã thêm progress bar.', '2026-06-10 10:15:00'),
  ('c006', 't002', 'u004', 'Card project đã dễ nhìn hơn.', '2026-06-10 11:00:00'),
  ('c007', 't002', 'u002', 'Cần bổ sung loading state.', '2026-06-10 14:00:00'),
  ('c008', 't002', 'u003', 'Đã nhận task loading.', '2026-06-10 15:30:00'),
  ('c009', 't003', 'u004', 'Drag đang chạy được trên mobile.', '2026-06-11 10:05:00'),
  ('c010', 't003', 'u002', 'Cần kiểm tra rollback khi API lỗi.', '2026-06-11 10:25:00'),
  ('c011', 't004', 'u006', 'Đã test xong màn hình mobile.', '2026-06-10 16:30:00'),
  ('c012', 't005', 'u005', 'Theme đã đồng bộ light/dark.', '2026-06-09 14:00:00'),
  ('c013', 't005', 'u002', 'Màu chính đã đạt yêu cầu.', '2026-06-09 15:15:00'),
  ('c014', 't005', 'u003', 'Typography nhìn ổn hơn.', '2026-06-09 15:45:00'),
  ('c015', 't005', 'u004', 'Spacing card đã đồng đều.', '2026-06-09 16:10:00'),
  ('c016', 't007', 'u002', 'Chuẩn bị schema CRM trước.', '2026-06-11 09:30:00'),
  ('c017', 't007', 'u003', 'Em sẽ tạo endpoint sync trước.', '2026-06-11 10:00:00');

INSERT INTO notifications
  (id, target_user_id, title, message, type, is_read, task_id, project_id, created_at)
VALUES
  ('noti001', 'u003', 'Bạn được giao task mới', 'Task “Thiết kế màn hình đăng nhập” đã được giao cho bạn.', 'TASK_ASSIGNED', FALSE, 't001', 'p001', '2026-06-11 08:20:00'),
  ('noti002', 'u003', 'Có bình luận mới', 'Manager đã bình luận trong task “Xây dựng dashboard dự án”.', 'COMMENT_ADDED', FALSE, 't002', 'p001', '2026-06-11 09:45:00'),
  ('noti003', 'u003', 'Deadline sắp đến', 'Task “Tạo Kanban board” sắp đến hạn vào ngày 13/06.', 'DEADLINE_REMINDER', TRUE, 't003', 'p001', '2026-06-11 11:00:00'),
  ('noti004', 'u003', 'Yêu cầu đã được duyệt', 'Requirement của bạn trong task “Hoàn thiện theme app” đã được Manager phê duyệt.', 'APPROVAL_APPROVED', TRUE, 't005', 'p001', '2026-06-10 15:30:00'),
  ('noti005', 'u003', 'Yêu cầu bị từ chối', 'Requirement trong task “Tối ưu task card component” bị từ chối. Vui lòng xem lý do và chỉnh sửa.', 'APPROVAL_REJECTED', FALSE, 't006', 'p001', '2026-06-10 17:10:00'),
  ('noti006', 'u003', 'Thông báo hệ thống', 'Bạn đang dùng dữ liệu thật từ REST API Node.js và MySQL.', 'SYSTEM', TRUE, NULL, NULL, '2026-06-09 08:00:00'),
  ('noti007', 'u004', 'Bạn được giao task mới', 'Task “Tạo Kanban board” đã được giao cho bạn.', 'TASK_ASSIGNED', FALSE, 't003', 'p001', '2026-06-11 10:05:00');

INSERT INTO activity_logs
  (id, workspace_id, user_id, action_type, title, description, created_at)
VALUES
  ('log001', 'ws001', 'u002', 'PROJECT_CREATED', 'Tạo dự án Mobile App v2.0', 'Manager đã tạo project mới trong workspace Phát triển Sản phẩm.', '2026-06-11 08:30:00'),
  ('log002', 'ws001', 'u003', 'TASK_UPDATED', 'Cập nhật task thiết kế Login', 'User đã cập nhật mô tả và checklist của task.', '2026-06-11 09:15:00'),
  ('log003', 'ws001', 'u004', 'TASK_MOVED', 'Chuyển task sang Đang làm', 'Task “Tạo Kanban board” được chuyển từ Cần làm sang Đang làm.', '2026-06-11 10:05:00'),
  ('log004', 'ws001', 'u005', 'APPROVAL_SUBMITTED', 'Gửi yêu cầu duyệt requirement', 'Nhân viên đã gửi yêu cầu duyệt kỹ thuật cho task UI.', '2026-06-11 11:20:00'),
  ('log005', 'ws001', 'u002', 'APPROVAL_APPROVED', 'Phê duyệt yêu cầu kỹ thuật', 'Manager đã phê duyệt requirement cho task Kanban board.', '2026-06-11 13:40:00'),
  ('log006', 'ws002', 'u002', 'WORKSPACE_CREATED', 'Tạo workspace Marketing', 'Workspace Marketing & Truyền thông được tạo trong hệ thống.', '2026-06-10 16:10:00'),
  ('log007', 'ws002', 'u001', 'USER_ROLE_CHANGED', 'Đổi role người dùng', 'Admin đã đổi role của một thành viên từ Member sang Manager.', '2026-06-10 17:25:00'),
  ('log008', 'ws003', 'u003', 'LOGIN', 'Đăng nhập hệ thống', 'Người dùng đăng nhập vào Productivity Manager.', '2026-06-09 08:00:00');
