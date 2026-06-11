import '../data/mock_activity_logs.dart';
import '../data/mock_approval_requests.dart';
import '../data/mock_notifications.dart';
import '../data/mock_tasks.dart';
import '../data/mock_users.dart';
import '../data/mock_workspaces.dart';
import 'api_client.dart';

class AdminSummary {
  final int totalUsers;
  final int totalWorkspaces;
  final int totalProjects;
  final int totalTasks;
  final int completedTasks;
  final int pendingTasks;

  const AdminSummary({
    required this.totalUsers,
    required this.totalWorkspaces,
    required this.totalProjects,
    required this.totalTasks,
    required this.completedTasks,
    required this.pendingTasks,
  });

  factory AdminSummary.fromJson(Map<String, dynamic> json) {
    return AdminSummary(
      totalUsers: (json['totalUsers'] as num?)?.toInt() ?? 0,
      totalWorkspaces: (json['totalWorkspaces'] as num?)?.toInt() ?? 0,
      totalProjects: (json['totalProjects'] as num?)?.toInt() ?? 0,
      totalTasks: (json['totalTasks'] as num?)?.toInt() ?? 0,
      completedTasks: (json['completedTasks'] as num?)?.toInt() ?? 0,
      pendingTasks: (json['pendingTasks'] as num?)?.toInt() ?? 0,
    );
  }
}

class TaskListConfig {
  final String id;
  final String projectId;
  final String name;
  final int position;
  final int? wipLimit;
  final bool isWipEnabled;

  const TaskListConfig({
    required this.id,
    required this.projectId,
    required this.name,
    required this.position,
    required this.wipLimit,
    required this.isWipEnabled,
  });

  factory TaskListConfig.fromJson(Map<String, dynamic> json) {
    return TaskListConfig(
      id: json['id']?.toString() ?? '',
      projectId: json['projectId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      position: (json['position'] as num?)?.toInt() ?? 0,
      wipLimit: (json['wipLimit'] as num?)?.toInt(),
      isWipEnabled: json['isWipEnabled'] == true,
    );
  }
}

class ChecklistItemData {
  final String id;
  final String taskId;
  final String title;
  final bool isCompleted;
  final int position;

  const ChecklistItemData({
    required this.id,
    required this.taskId,
    required this.title,
    required this.isCompleted,
    required this.position,
  });

  factory ChecklistItemData.fromJson(Map<String, dynamic> json) {
    return ChecklistItemData(
      id: json['id']?.toString() ?? '',
      taskId: json['taskId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      isCompleted: json['isCompleted'] == true,
      position: (json['position'] as num?)?.toInt() ?? 0,
    );
  }
}

class RequirementData {
  final String id;
  final String taskId;
  final String title;
  final String status;
  final String statusLabel;
  final String? rejectReason;

  const RequirementData({
    required this.id,
    required this.taskId,
    required this.title,
    required this.status,
    required this.statusLabel,
    this.rejectReason,
  });

  factory RequirementData.fromJson(Map<String, dynamic> json) {
    return RequirementData(
      id: json['id']?.toString() ?? '',
      taskId: json['taskId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      status: json['status']?.toString() ?? 'NOT_SUBMITTED',
      statusLabel: json['statusLabel']?.toString() ?? 'Chưa gửi',
      rejectReason: json['rejectReason']?.toString(),
    );
  }
}

class CommentData {
  final String id;
  final String taskId;
  final String userId;
  final String name;
  final String avatar;
  final String content;
  final String time;

  const CommentData({
    required this.id,
    required this.taskId,
    required this.userId,
    required this.name,
    required this.avatar,
    required this.content,
    required this.time,
  });

  factory CommentData.fromJson(Map<String, dynamic> json) {
    return CommentData(
      id: json['id']?.toString() ?? '',
      taskId: json['taskId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Người dùng',
      avatar: json['avatar']?.toString() ?? 'NA',
      content: json['content']?.toString() ?? '',
      time: json['time']?.toString() ?? '',
    );
  }
}

class TaskDetailData {
  final MockTask task;
  final List<ChecklistItemData> checklistItems;
  final List<RequirementData> requirements;
  final List<CommentData> comments;

  const TaskDetailData({
    required this.task,
    required this.checklistItems,
    required this.requirements,
    required this.comments,
  });

  factory TaskDetailData.fromJson(Map<String, dynamic> json) {
    return TaskDetailData(
      task: MockTask.fromJson(json['task'] as Map<String, dynamic>),
      checklistItems: _list(json['checklistItems'])
          .map((item) => ChecklistItemData.fromJson(item))
          .toList(),
      requirements: _list(json['requirements'])
          .map((item) => RequirementData.fromJson(item))
          .toList(),
      comments: _list(json['comments'])
          .map((item) => CommentData.fromJson(item))
          .toList(),
    );
  }
}

class AppDataService {
  AppDataService._();

  static Future<MockUser> login({
    required String email,
    required String password,
  }) async {
    final json = await apiClient.post(
      '/auth/login',
      body: {'email': email, 'password': password},
    ) as Map<String, dynamic>;
    await apiClient.setToken(json['token'].toString());
    return MockUser.fromJson(json['user'] as Map<String, dynamic>);
  }

  static Future<void> logout() async {
    await apiClient.clearToken();
  }

  static Future<String?> currentToken() {
    return apiClient.getToken();
  }

  static Future<List<MockUser>> fetchUsers() async {
    final json = await apiClient.get('/users');
    return _list(json).map((item) => MockUser.fromJson(item)).toList();
  }

  static Future<MockUser> updateUser(MockUser user) async {
    final json = await apiClient.put('/users/${user.id}', body: user.toJson());
    return MockUser.fromJson(json as Map<String, dynamic>);
  }

  static Future<MockUser> updateSecurity({
    required String userId,
    bool? twoStepEnabled,
    bool? biometricEnabled,
    bool? notificationEnabled,
  }) async {
    final json = await apiClient.patch(
      '/users/$userId/security',
      body: {
        if (twoStepEnabled != null) 'twoStepEnabled': twoStepEnabled,
        if (biometricEnabled != null) 'biometricEnabled': biometricEnabled,
        if (notificationEnabled != null) 'notificationEnabled': notificationEnabled,
      },
    );
    return MockUser.fromJson(json as Map<String, dynamic>);
  }

  static Future<void> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    await apiClient.post(
      '/users/$userId/change-password',
      body: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
  }

  static Future<List<MockWorkspace>> fetchWorkspaces() async {
    final json = await apiClient.get('/workspaces');
    return _list(json).map((item) => MockWorkspace.fromJson(item)).toList();
  }

  static Future<MockWorkspace> createWorkspace({
    required String name,
    required String description,
    required String iconText,
    List<String> memberIds = const [],
  }) async {
    final json = await apiClient.post(
      '/workspaces',
      body: {
        'name': name,
        'description': description,
        'iconText': iconText,
        'memberIds': memberIds,
      },
    );
    return MockWorkspace.fromJson(json as Map<String, dynamic>);
  }

  static Future<MockWorkspace> updateWorkspace(MockWorkspace workspace) async {
    final json = await apiClient.put(
      '/workspaces/${workspace.id}',
      body: workspace.toJson(),
    );
    return MockWorkspace.fromJson(json as Map<String, dynamic>);
  }

  static Future<void> deleteWorkspace(String id) async {
    await apiClient.delete('/workspaces/$id');
  }

  static Future<List<MockProject>> fetchProjects({String? workspaceId}) async {
    final json = await apiClient.get(
      '/projects',
      query: {'workspaceId': workspaceId},
    );
    return _list(json).map((item) => MockProject.fromJson(item)).toList();
  }

  static Future<MockProject> createProject({
    required String workspaceId,
    required String name,
    required String code,
    required String description,
    required String deadline,
    List<String> memberIds = const [],
  }) async {
    final json = await apiClient.post(
      '/projects',
      body: {
        'workspaceId': workspaceId,
        'name': name,
        'code': code,
        'description': description,
        'deadline': deadline,
        'memberIds': memberIds,
      },
    );
    return MockProject.fromJson(json as Map<String, dynamic>);
  }

  static Future<MockProject> updateProject(MockProject project) async {
    final json = await apiClient.put(
      '/projects/${project.id}',
      body: project.toJson(),
    );
    return MockProject.fromJson(json as Map<String, dynamic>);
  }

  static Future<void> deleteProject(String id) async {
    await apiClient.delete('/projects/$id');
  }

  static Future<List<TaskListConfig>> fetchTaskLists(String projectId) async {
    final json = await apiClient.get('/projects/$projectId/lists');
    return _list(json).map((item) => TaskListConfig.fromJson(item)).toList();
  }

  static Future<TaskListConfig> updateTaskList(TaskListConfig list) async {
    final json = await apiClient.put(
      '/lists/${list.id}',
      body: {
        'name': list.name,
        'position': list.position,
        'wipLimit': list.wipLimit,
        'isWipEnabled': list.isWipEnabled,
      },
    );
    return TaskListConfig.fromJson(json as Map<String, dynamic>);
  }

  static Future<TaskListConfig> createTaskList({
    required String projectId,
    required String name,
    required int position,
    int? wipLimit,
    bool isWipEnabled = false,
  }) async {
    final json = await apiClient.post(
      '/projects/$projectId/lists',
      body: {
        'name': name,
        'position': position,
        'wipLimit': wipLimit,
        'isWipEnabled': isWipEnabled,
      },
    );
    return TaskListConfig.fromJson(json as Map<String, dynamic>);
  }

  static Future<void> deleteTaskList(String id) async {
    await apiClient.delete('/lists/$id');
  }

  static Future<List<MockTask>> fetchTasks({
    String? projectId,
    String? assigneeId,
  }) async {
    final json = await apiClient.get(
      '/tasks',
      query: {
        'projectId': projectId,
        'assigneeId': assigneeId,
      },
    );
    return _list(json).map((item) => MockTask.fromJson(item)).toList();
  }

  static Future<TaskDetailData> fetchTaskDetail(String taskId) async {
    final json = await apiClient.get('/tasks/$taskId');
    return TaskDetailData.fromJson(json as Map<String, dynamic>);
  }

  static Future<MockTask> createTask({
    required String projectId,
    required String title,
    required String description,
    required String assigneeId,
    required String assigneeName,
    required String priority,
    required String dueDate,
    required List<String> checklistItems,
    required List<String> requirements,
  }) async {
    final json = await apiClient.post(
      '/tasks',
      body: {
        'projectId': projectId,
        'title': title,
        'description': description,
        'assigneeId': assigneeId,
        'assigneeName': assigneeName,
        'priority': priority,
        'dueDate': dueDate,
        'checklistItems': checklistItems,
        'requirements': requirements,
      },
    );
    return MockTask.fromJson(json as Map<String, dynamic>);
  }

  static Future<MockTask> updateTaskStatus({
    required String taskId,
    required String status,
  }) async {
    final json = await apiClient.patch(
      '/tasks/$taskId/status',
      body: {'status': status},
    );
    return MockTask.fromJson(json as Map<String, dynamic>);
  }

  static Future<MockTask> updateTask(MockTask task) async {
    final json = await apiClient.put(
      '/tasks/${task.id}',
      body: task.toJson(),
    );
    return MockTask.fromJson(json as Map<String, dynamic>);
  }

  static Future<void> deleteTask(String id) async {
    await apiClient.delete('/tasks/$id');
  }

  static Future<ChecklistItemData> updateChecklistItem({
    required String id,
    required bool isCompleted,
  }) async {
    final json = await apiClient.patch(
      '/checklist-items/$id',
      body: {'isCompleted': isCompleted},
    );
    return ChecklistItemData.fromJson(json as Map<String, dynamic>);
  }

  static Future<CommentData> addComment({
    required String taskId,
    required String content,
  }) async {
    final json = await apiClient.post(
      '/tasks/$taskId/comments',
      body: {'content': content},
    );
    return CommentData.fromJson(json as Map<String, dynamic>);
  }

  static Future<void> submitRequirement(String requirementId) async {
    await apiClient.post('/requirements/$requirementId/submit');
  }

  static Future<void> reviewRequirement({
    required String requirementId,
    required String status,
    String? rejectReason,
  }) async {
    await apiClient.patch(
      '/requirements/$requirementId/review',
      body: {
        'status': status,
        if (rejectReason != null) 'rejectReason': rejectReason,
      },
    );
  }

  static Future<List<MockApprovalRequest>> fetchApprovalRequests({
    String? userId,
    String? projectId,
    String? status,
  }) async {
    final json = await apiClient.get(
      '/approval-requests',
      query: {
        'userId': userId,
        'projectId': projectId,
        'status': status,
      },
    );
    return _list(json).map((item) => MockApprovalRequest.fromJson(item)).toList();
  }

  static Future<MockApprovalRequest> reviewApprovalRequest({
    required String id,
    required String status,
    String? rejectReason,
  }) async {
    final json = await apiClient.patch(
      '/approval-requests/$id/review',
      body: {
        'status': status,
        if (rejectReason != null) 'rejectReason': rejectReason,
      },
    );
    return MockApprovalRequest.fromJson(json as Map<String, dynamic>);
  }

  static Future<List<MockUserNotification>> fetchNotifications({
    required String userId,
  }) async {
    final json = await apiClient.get('/notifications', query: {'userId': userId});
    return _list(json)
        .map((item) => MockUserNotification.fromJson(item))
        .toList();
  }

  static Future<MockUserNotification> markNotificationRead(String id) async {
    final json = await apiClient.patch('/notifications/$id/read');
    return MockUserNotification.fromJson(json as Map<String, dynamic>);
  }

  static Future<void> deleteNotification(String id) async {
    await apiClient.delete('/notifications/$id');
  }

  static Future<List<MockActivityLog>> fetchActivityLogs({
    String? workspaceId,
    String? userId,
    String? actionType,
  }) async {
    final json = await apiClient.get(
      '/activity-logs',
      query: {
        'workspaceId': workspaceId,
        'userId': userId,
        'actionType': actionType,
      },
    );
    return _list(json).map((item) => MockActivityLog.fromJson(item)).toList();
  }

  static Future<AdminSummary> fetchAdminSummary() async {
    final json = await apiClient.get('/admin/summary');
    return AdminSummary.fromJson(json as Map<String, dynamic>);
  }
}

List<Map<String, dynamic>> _list(dynamic json) {
  return (json as List<dynamic>? ?? const [])
      .whereType<Map<String, dynamic>>()
      .toList();
}
