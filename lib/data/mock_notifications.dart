class MockUserNotification {
  final String id;
  final String targetUserId;
  final String title;
  final String message;
  final String type;
  final String createdAt;
  final bool isRead;
  final String? taskId;
  final String? projectId;

  const MockUserNotification({
    required this.id,
    required this.targetUserId,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    required this.isRead,
    this.taskId,
    this.projectId,
  });

  MockUserNotification copyWith({
    bool? isRead,
  }) {
    return MockUserNotification(
      id: id,
      targetUserId: targetUserId,
      title: title,
      message: message,
      type: type,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      taskId: taskId,
      projectId: projectId,
    );
  }
}

const List<String> notificationTypes = [
  'TASK_ASSIGNED',
  'COMMENT_ADDED',
  'DEADLINE_REMINDER',
  'APPROVAL_APPROVED',
  'APPROVAL_REJECTED',
  'SYSTEM',
];

const List<MockUserNotification> mockUserNotifications = [
  MockUserNotification(
    id: 'noti001',
    targetUserId: 'u003',
    title: 'Bạn được giao task mới',
    message: 'Task “Thiết kế màn hình đăng nhập” đã được giao cho bạn.',
    type: 'TASK_ASSIGNED',
    createdAt: 'Hôm nay, 08:20',
    isRead: false,
    taskId: 't001',
    projectId: 'p001',
  ),
  MockUserNotification(
    id: 'noti002',
    targetUserId: 'u003',
    title: 'Có bình luận mới',
    message: 'Manager đã bình luận trong task “Xây dựng dashboard dự án”.',
    type: 'COMMENT_ADDED',
    createdAt: 'Hôm nay, 09:45',
    isRead: false,
    taskId: 't002',
    projectId: 'p001',
  ),
  MockUserNotification(
    id: 'noti003',
    targetUserId: 'u003',
    title: 'Deadline sắp đến',
    message: 'Task “Tạo Kanban board” sắp đến hạn vào ngày 13/06.',
    type: 'DEADLINE_REMINDER',
    createdAt: 'Hôm nay, 11:00',
    isRead: true,
    taskId: 't003',
    projectId: 'p001',
  ),
  MockUserNotification(
    id: 'noti004',
    targetUserId: 'u003',
    title: 'Yêu cầu đã được duyệt',
    message: 'Requirement của bạn trong task “Hoàn thiện theme app” đã được Manager phê duyệt.',
    type: 'APPROVAL_APPROVED',
    createdAt: 'Hôm qua, 15:30',
    isRead: true,
    taskId: 't005',
    projectId: 'p001',
  ),
  MockUserNotification(
    id: 'noti005',
    targetUserId: 'u003',
    title: 'Yêu cầu bị từ chối',
    message: 'Requirement trong task “Tối ưu task card component” bị từ chối. Vui lòng xem lý do và chỉnh sửa.',
    type: 'APPROVAL_REJECTED',
    createdAt: 'Hôm qua, 17:10',
    isRead: false,
    taskId: 't006',
    projectId: 'p001',
  ),
  MockUserNotification(
    id: 'noti006',
    targetUserId: 'u003',
    title: 'Thông báo hệ thống',
    message: 'Bạn đang dùng phiên bản mock UI của Productivity Manager.',
    type: 'SYSTEM',
    createdAt: '2 ngày trước, 08:00',
    isRead: true,
  ),
  MockUserNotification(
    id: 'noti007',
    targetUserId: 'u004',
    title: 'Bạn được giao task mới',
    message: 'Task “Tạo Kanban board” đã được giao cho bạn.',
    type: 'TASK_ASSIGNED',
    createdAt: 'Hôm nay, 10:05',
    isRead: false,
    taskId: 't003',
    projectId: 'p001',
  ),
];