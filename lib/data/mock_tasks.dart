class MockTask {
  final String id;
  final String projectId;
  final String title;
  final String description;
  final String assigneeName;
  final String assigneeAvatar;
  final String priority;
  final String status;
  final String dueDate;
  final int checklistDone;
  final int checklistTotal;
  final int commentCount;

  const MockTask({
    required this.id,
    required this.projectId,
    required this.title,
    required this.description,
    required this.assigneeName,
    required this.assigneeAvatar,
    required this.priority,
    required this.status,
    required this.dueDate,
    required this.checklistDone,
    required this.checklistTotal,
    required this.commentCount,
  });

  MockTask copyWith({
    String? status,
  }) {
    return MockTask(
      id: id,
      projectId: projectId,
      title: title,
      description: description,
      assigneeName: assigneeName,
      assigneeAvatar: assigneeAvatar,
      priority: priority,
      status: status ?? this.status,
      dueDate: dueDate,
      checklistDone: checklistDone,
      checklistTotal: checklistTotal,
      commentCount: commentCount,
    );
  }
}

const List<String> kanbanColumns = [
  'Cần làm',
  'Đang làm',
  'Kiểm tra',
  'Đã xong',
];

const List<MockTask> mockTasks = [
  MockTask(
    id: 't001',
    projectId: 'p001',
    title: 'Thiết kế màn hình đăng nhập',
    description: 'Tạo UI login, validation và xử lý mock login.',
    assigneeName: 'Lê Thị C',
    assigneeAvatar: 'LC',
    priority: 'High',
    status: 'Cần làm',
    dueDate: '10/06',
    checklistDone: 2,
    checklistTotal: 5,
    commentCount: 3,
  ),
  MockTask(
    id: 't002',
    projectId: 'p001',
    title: 'Xây dựng dashboard dự án',
    description: 'Hiển thị workspace, project và tiến độ hoàn thành.',
    assigneeName: 'Nguyễn Văn A',
    assigneeAvatar: 'NA',
    priority: 'Medium',
    status: 'Đang làm',
    dueDate: '12/06',
    checklistDone: 4,
    checklistTotal: 6,
    commentCount: 5,
  ),
  MockTask(
    id: 't003',
    projectId: 'p001',
    title: 'Tạo Kanban board',
    description: 'Hiển thị task theo cột và hỗ trợ kéo thả.',
    assigneeName: 'Trần Minh',
    assigneeAvatar: 'TM',
    priority: 'High',
    status: 'Đang làm',
    dueDate: '13/06',
    checklistDone: 3,
    checklistTotal: 7,
    commentCount: 2,
  ),
  MockTask(
    id: 't004',
    projectId: 'p001',
    title: 'Kiểm thử giao diện mobile',
    description: 'Test responsive trên nhiều kích thước màn hình.',
    assigneeName: 'Hà Nhi',
    assigneeAvatar: 'HN',
    priority: 'Low',
    status: 'Kiểm tra',
    dueDate: '15/06',
    checklistDone: 5,
    checklistTotal: 5,
    commentCount: 1,
  ),
  MockTask(
    id: 't005',
    projectId: 'p001',
    title: 'Hoàn thiện theme app',
    description: 'Chuẩn hóa màu sắc, typography, spacing.',
    assigneeName: 'Lê Thị C',
    assigneeAvatar: 'LC',
    priority: 'Medium',
    status: 'Đã xong',
    dueDate: '09/06',
    checklistDone: 6,
    checklistTotal: 6,
    commentCount: 4,
  ),
  MockTask(
    id: 't006',
    projectId: 'p001',
    title: 'Tối ưu task card component',
    description: 'Tách widget card để tái sử dụng nhiều màn hình.',
    assigneeName: 'Trần Minh',
    assigneeAvatar: 'TM',
    priority: 'Medium',
    status: 'Cần làm',
    dueDate: '16/06',
    checklistDone: 1,
    checklistTotal: 4,
    commentCount: 0,
  ),
  MockTask(
    id: 't007',
    projectId: 'p002',
    title: 'Tạo API mock CRM',
    description: 'Chuẩn bị dữ liệu giả cho CRM integration.',
    assigneeName: 'Nguyễn Văn A',
    assigneeAvatar: 'NA',
    priority: 'High',
    status: 'Cần làm',
    dueDate: '17/06',
    checklistDone: 0,
    checklistTotal: 5,
    commentCount: 2,
  ),
];

List<MockTask> getTasksByProject(String projectId) {
  return mockTasks.where((task) => task.projectId == projectId).toList();
}