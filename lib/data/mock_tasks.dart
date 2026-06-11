class MockTask {
  final String id;
  final String? listId;
  final String projectId;
  final String title;
  final String description;
  final String? creatorId;
  final String? assigneeId;
  final String assigneeName;
  final String assigneeAvatar;
  final String priority;
  final String status;
  final String dueDate;
  final String dueDateFull;
  final int checklistDone;
  final int checklistTotal;
  final int commentCount;

  const MockTask({
    required this.id,
    this.listId,
    required this.projectId,
    required this.title,
    required this.description,
    this.creatorId,
    this.assigneeId,
    required this.assigneeName,
    required this.assigneeAvatar,
    required this.priority,
    required this.status,
    required this.dueDate,
    this.dueDateFull = '',
    required this.checklistDone,
    required this.checklistTotal,
    required this.commentCount,
  });

  factory MockTask.fromJson(Map<String, dynamic> json) {
    return MockTask(
      id: json['id']?.toString() ?? '',
      listId: json['listId']?.toString(),
      projectId: json['projectId']?.toString() ??
          json['project_id']?.toString() ??
          '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      creatorId: json['creatorId']?.toString(),
      assigneeId: json['assigneeId']?.toString(),
      assigneeName: json['assigneeName']?.toString() ?? 'Chưa phân công',
      assigneeAvatar: json['assigneeAvatar']?.toString() ?? 'NA',
      priority: json['priority']?.toString() ?? 'Medium',
      status: json['status']?.toString() ?? 'Cần làm',
      dueDate: json['dueDate']?.toString() ?? '',
      dueDateFull: json['dueDateFull']?.toString() ?? '',
      checklistDone: (json['checklistDone'] as num?)?.toInt() ?? 0,
      checklistTotal: (json['checklistTotal'] as num?)?.toInt() ?? 0,
      commentCount: (json['commentCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'listId': listId,
      'projectId': projectId,
      'title': title,
      'description': description,
      'creatorId': creatorId,
      'assigneeId': assigneeId,
      'assigneeName': assigneeName,
      'assigneeAvatar': assigneeAvatar,
      'priority': priority,
      'status': status,
      'dueDate': dueDateFull.isNotEmpty ? dueDateFull : dueDate,
      'checklistDone': checklistDone,
      'checklistTotal': checklistTotal,
      'commentCount': commentCount,
    };
  }

  MockTask copyWith({
    String? status,
    int? checklistDone,
    int? checklistTotal,
    int? commentCount,
  }) {
    return MockTask(
      id: id,
      listId: listId,
      projectId: projectId,
      title: title,
      description: description,
      creatorId: creatorId,
      assigneeId: assigneeId,
      assigneeName: assigneeName,
      assigneeAvatar: assigneeAvatar,
      priority: priority,
      status: status ?? this.status,
      dueDate: dueDate,
      dueDateFull: dueDateFull,
      checklistDone: checklistDone ?? this.checklistDone,
      checklistTotal: checklistTotal ?? this.checklistTotal,
      commentCount: commentCount ?? this.commentCount,
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
    description: 'Tạo UI login, validation và xử lý đăng nhập qua REST API.',
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
    title: 'Tạo API CRM',
    description: 'Chuẩn bị dữ liệu và endpoint cho CRM integration.',
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
