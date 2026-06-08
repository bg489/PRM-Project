class MockActivityLog {
  final String id;
  final String workspaceId;
  final String userId;
  final String userName;
  final String userAvatar;
  final String actionType;
  final String title;
  final String description;
  final String createdAt;

  const MockActivityLog({
    required this.id,
    required this.workspaceId,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.actionType,
    required this.title,
    required this.description,
    required this.createdAt,
  });
}

const List<String> activityActionTypes = [
  'TASK_CREATED',
  'TASK_UPDATED',
  'TASK_MOVED',
  'PROJECT_CREATED',
  'WORKSPACE_CREATED',
  'USER_ROLE_CHANGED',
  'LOGIN',
  'APPROVAL_SUBMITTED',
  'APPROVAL_APPROVED',
  'APPROVAL_REJECTED',
];

const List<MockActivityLog> mockActivityLogs = [
  MockActivityLog(
    id: 'log001',
    workspaceId: 'ws001',
    userId: 'u002',
    userName: 'Nguyễn Văn Quản Lý',
    userAvatar: 'QL',
    actionType: 'PROJECT_CREATED',
    title: 'Tạo dự án Mobile App v2.0',
    description: 'Manager đã tạo project mới trong workspace Phát triển Sản phẩm.',
    createdAt: 'Hôm nay, 08:30',
  ),
  MockActivityLog(
    id: 'log002',
    workspaceId: 'ws001',
    userId: 'u003',
    userName: 'Nguyễn Văn User',
    userAvatar: 'US',
    actionType: 'TASK_UPDATED',
    title: 'Cập nhật task thiết kế Login',
    description: 'User đã cập nhật mô tả và checklist của task.',
    createdAt: 'Hôm nay, 09:15',
  ),
  MockActivityLog(
    id: 'log003',
    workspaceId: 'ws001',
    userId: 'u004',
    userName: 'Trần Minh',
    userAvatar: 'TM',
    actionType: 'TASK_MOVED',
    title: 'Chuyển task sang Đang làm',
    description: 'Task “Tạo Kanban board” được chuyển từ Cần làm sang Đang làm.',
    createdAt: 'Hôm nay, 10:05',
  ),
  MockActivityLog(
    id: 'log004',
    workspaceId: 'ws001',
    userId: 'u005',
    userName: 'Lê Thị C',
    userAvatar: 'LC',
    actionType: 'APPROVAL_SUBMITTED',
    title: 'Gửi yêu cầu duyệt requirement',
    description: 'Nhân viên đã gửi yêu cầu duyệt kỹ thuật cho task UI.',
    createdAt: 'Hôm nay, 11:20',
  ),
  MockActivityLog(
    id: 'log005',
    workspaceId: 'ws001',
    userId: 'u002',
    userName: 'Nguyễn Văn Quản Lý',
    userAvatar: 'QL',
    actionType: 'APPROVAL_APPROVED',
    title: 'Phê duyệt yêu cầu kỹ thuật',
    description: 'Manager đã phê duyệt requirement cho task Kanban board.',
    createdAt: 'Hôm nay, 13:40',
  ),
  MockActivityLog(
    id: 'log006',
    workspaceId: 'ws002',
    userId: 'u002',
    userName: 'Nguyễn Văn Quản Lý',
    userAvatar: 'QL',
    actionType: 'WORKSPACE_CREATED',
    title: 'Tạo workspace Marketing',
    description: 'Workspace Marketing & Truyền thông được tạo trong hệ thống.',
    createdAt: 'Hôm qua, 16:10',
  ),
  MockActivityLog(
    id: 'log007',
    workspaceId: 'ws002',
    userId: 'u001',
    userName: 'Admin System',
    userAvatar: 'AD',
    actionType: 'USER_ROLE_CHANGED',
    title: 'Đổi role người dùng',
    description: 'Admin đã đổi role của một thành viên từ Member sang Manager.',
    createdAt: 'Hôm qua, 17:25',
  ),
  MockActivityLog(
    id: 'log008',
    workspaceId: 'ws003',
    userId: 'u003',
    userName: 'Nguyễn Văn User',
    userAvatar: 'US',
    actionType: 'LOGIN',
    title: 'Đăng nhập hệ thống',
    description: 'Người dùng đăng nhập vào Productivity Manager.',
    createdAt: '2 ngày trước, 08:00',
  ),
];