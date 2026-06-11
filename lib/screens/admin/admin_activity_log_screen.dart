import 'package:flutter/material.dart';

import '../../data/mock_activity_logs.dart';
import '../../data/mock_users.dart';
import '../../data/mock_workspaces.dart';
import '../../services/app_data_service.dart';
import 'admin_widgets.dart';

class AdminActivityLogScreen extends StatefulWidget {
  const AdminActivityLogScreen({super.key});

  @override
  State<AdminActivityLogScreen> createState() => _AdminActivityLogScreenState();
}

class _AdminActivityLogScreenState extends State<AdminActivityLogScreen> {
  List<MockActivityLog> logs = List.from(mockActivityLogs);
  List<MockUser> users = List.from(mockUsers);
  List<MockWorkspace> workspaces = List.from(mockWorkspaces);
  String selectedActionType = 'all';
  String selectedUserId = 'all';
  String selectedWorkspaceId = 'all';
  bool isLoading = true;
  String? errorMessage;

  List<MockActivityLog> get filteredLogs {
    return logs.where((log) {
      final matchAction =
          selectedActionType == 'all' || log.actionType == selectedActionType;
      final matchUser = selectedUserId == 'all' || log.userId == selectedUserId;
      final matchWorkspace = selectedWorkspaceId == 'all' ||
          log.workspaceId == selectedWorkspaceId;
      return matchAction && matchUser && matchWorkspace;
    }).toList();
  }

  int get todayLogs {
    final now = DateTime.now();
    final todayPrefix =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    return logs.where((log) => log.createdAt.startsWith(todayPrefix)).length;
  }

  int get taskLogs => logs.where((log) => log.actionType.startsWith('TASK')).length;
  int get approvalLogs =>
      logs.where((log) => log.actionType.startsWith('APPROVAL')).length;
  int get userLogs =>
      logs.where((log) => log.actionType.contains('USER')).length;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final loadedLogs = await AppDataService.fetchActivityLogs();
      final loadedUsers = await AppDataService.fetchUsers();
      final loadedWorkspaces = await AppDataService.fetchWorkspaces();
      if (!mounted) return;
      setState(() {
        logs = loadedLogs;
        users = loadedUsers;
        workspaces = loadedWorkspaces;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        logs = List.from(mockActivityLogs);
        users = List.from(mockUsers);
        workspaces = List.from(mockWorkspaces);
        errorMessage = 'Chưa kết nối được backend, đang hiển thị log dự phòng.';
        isLoading = false;
      });
    }
  }

  String getWorkspaceName(String workspaceId) {
    if (workspaceId.isEmpty) return 'Toàn hệ thống';
    try {
      return workspaces.firstWhere((item) => item.id == workspaceId).name;
    } catch (_) {
      return 'Không rõ workspace';
    }
  }

  void clearFilters() {
    setState(() {
      selectedActionType = 'all';
      selectedUserId = 'all';
      selectedWorkspaceId = 'all';
    });
  }

  void showLogDetail(MockActivityLog log) {
    final actionConfig = _getActionConfig(log.actionType);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.68,
          minChildSize: 0.42,
          maxChildSize: 0.88,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: ListView(
                controller: scrollController,
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: actionConfig.color.withOpacity(0.16),
                    child: Icon(
                      actionConfig.icon,
                      color: actionConfig.color,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    log.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: AdminPill(
                      label: actionConfig.label,
                      color: actionConfig.color,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _DetailBlock(
                    icon: Icons.description_outlined,
                    title: 'Mô tả hoạt động',
                    content: log.description,
                  ),
                  _DetailBlock(
                    icon: Icons.person_outline_rounded,
                    title: 'Người thực hiện',
                    content: '${log.userName} (${log.userAvatar})',
                  ),
                  _DetailBlock(
                    icon: Icons.workspaces_outline,
                    title: 'Workspace',
                    content: getWorkspaceName(log.workspaceId),
                  ),
                  _DetailBlock(
                    icon: Icons.access_time_rounded,
                    title: 'Thời gian',
                    content: log.createdAt,
                  ),
                  _DetailBlock(
                    icon: Icons.code_rounded,
                    title: 'Action Type',
                    content: log.actionType,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  _ActionConfig _getActionConfig(String actionType) {
    switch (actionType) {
      case 'TASK_CREATED':
        return _ActionConfig(
          label: 'Tạo task',
          color: const Color(0xFF2563EB),
          icon: Icons.add_task_rounded,
        );
      case 'TASK_UPDATED':
        return _ActionConfig(
          label: 'Cập nhật task',
          color: const Color(0xFF7C3AED),
          icon: Icons.edit_rounded,
        );
      case 'TASK_MOVED':
        return _ActionConfig(
          label: 'Di chuyển task',
          color: const Color(0xFFF59E0B),
          icon: Icons.swap_horiz_rounded,
        );
      case 'PROJECT_CREATED':
        return _ActionConfig(
          label: 'Tạo project',
          color: const Color(0xFF2563EB),
          icon: Icons.folder_open_rounded,
        );
      case 'WORKSPACE_CREATED':
        return _ActionConfig(
          label: 'Tạo workspace',
          color: const Color(0xFF7C3AED),
          icon: Icons.workspaces_rounded,
        );
      case 'USER_ROLE_CHANGED':
        return _ActionConfig(
          label: 'Đổi role',
          color: const Color(0xFFEF4444),
          icon: Icons.admin_panel_settings_rounded,
        );
      case 'LOGIN':
        return _ActionConfig(
          label: 'Đăng nhập',
          color: const Color(0xFF22C55E),
          icon: Icons.login_rounded,
        );
      case 'APPROVAL_SUBMITTED':
        return _ActionConfig(
          label: 'Gửi duyệt',
          color: const Color(0xFFF59E0B),
          icon: Icons.upload_file_rounded,
        );
      case 'APPROVAL_APPROVED':
        return _ActionConfig(
          label: 'Đã duyệt',
          color: const Color(0xFF22C55E),
          icon: Icons.check_circle_rounded,
        );
      case 'APPROVAL_REJECTED':
        return _ActionConfig(
          label: 'Từ chối',
          color: const Color(0xFFEF4444),
          icon: Icons.cancel_rounded,
        );
      default:
        return _ActionConfig(
          label: 'Hoạt động',
          color: const Color(0xFF6B7280),
          icon: Icons.history_rounded,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleLogs = filteredLogs;

    return AdminScreenScaffold(
      title: 'Activity Log',
      icon: Icons.history_rounded,
      child: RefreshIndicator(
        onRefresh: loadData,
        child: isLoading
            ? const AdminLoading()
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (errorMessage != null) ...[
                      AdminErrorBanner(
                        message: errorMessage!,
                        onRetry: loadData,
                      ),
                      const SizedBox(height: 16),
                    ],
                    AdminStatGrid(
                      stats: [
                        AdminStat(
                          label: 'Tổng log',
                          value: '${logs.length}',
                          icon: Icons.monitor_heart_rounded,
                          color: const Color(0xFF7C3AED),
                        ),
                        AdminStat(
                          label: 'Hôm nay',
                          value: '$todayLogs',
                          icon: Icons.today_rounded,
                          color: const Color(0xFF22C55E),
                        ),
                        AdminStat(
                          label: 'Task',
                          value: '$taskLogs',
                          icon: Icons.task_alt_rounded,
                          color: const Color(0xFF2563EB),
                        ),
                        AdminStat(
                          label: 'Duyệt',
                          value: '$approvalLogs',
                          icon: Icons.fact_check_rounded,
                          color: const Color(0xFFF59E0B),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _FilterPanel(
                      users: users,
                      workspaces: workspaces,
                      selectedActionType: selectedActionType,
                      selectedUserId: selectedUserId,
                      selectedWorkspaceId: selectedWorkspaceId,
                      onActionChanged: (value) {
                        setState(() {
                          selectedActionType = value;
                        });
                      },
                      onUserChanged: (value) {
                        setState(() {
                          selectedUserId = value;
                        });
                      },
                      onWorkspaceChanged: (value) {
                        setState(() {
                          selectedWorkspaceId = value;
                        });
                      },
                      onClear: clearFilters,
                    ),
                    const SizedBox(height: 18),
                    AdminSectionTitle(
                      title: 'Activity Log',
                      countLabel: '${visibleLogs.length} log',
                    ),
                    const SizedBox(height: 14),
                    if (visibleLogs.isEmpty)
                      const AdminEmptyState(
                        icon: Icons.history_toggle_off_rounded,
                        message: 'Không có log nào phù hợp bộ lọc.',
                      )
                    else
                      ...visibleLogs.map((log) {
                        final config = _getActionConfig(log.actionType);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ActivityLogCard(
                            log: log,
                            actionConfig: config,
                            workspaceName: getWorkspaceName(log.workspaceId),
                            onTap: () => showLogDetail(log),
                          ),
                        );
                      }),
                  ],
                ),
              ),
      ),
    );
  }
}

class _FilterPanel extends StatelessWidget {
  final List<MockUser> users;
  final List<MockWorkspace> workspaces;
  final String selectedActionType;
  final String selectedUserId;
  final String selectedWorkspaceId;
  final ValueChanged<String> onActionChanged;
  final ValueChanged<String> onUserChanged;
  final ValueChanged<String> onWorkspaceChanged;
  final VoidCallback onClear;

  const _FilterPanel({
    required this.users,
    required this.workspaces,
    required this.selectedActionType,
    required this.selectedUserId,
    required this.selectedWorkspaceId,
    required this.onActionChanged,
    required this.onUserChanged,
    required this.onWorkspaceChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Bộ lọc Activity',
                  style: TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton(onPressed: onClear, child: const Text('Xóa lọc')),
            ],
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: selectedActionType,
            decoration: adminInputDecoration(
              label: 'Lọc theo hành động',
              icon: Icons.category_outlined,
            ),
            items: [
              const DropdownMenuItem(value: 'all', child: Text('Tất cả hành động')),
              ...activityActionTypes.map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }),
            ],
            onChanged: (value) {
              if (value != null) onActionChanged(value);
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: selectedUserId,
            decoration: adminInputDecoration(
              label: 'Lọc theo user',
              icon: Icons.person_outline_rounded,
            ),
            items: [
              const DropdownMenuItem(value: 'all', child: Text('Tất cả user')),
              ...users.map((user) {
                return DropdownMenuItem(value: user.id, child: Text(user.fullName));
              }),
            ],
            onChanged: (value) {
              if (value != null) onUserChanged(value);
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: selectedWorkspaceId,
            decoration: adminInputDecoration(
              label: 'Lọc theo workspace',
              icon: Icons.workspaces_outline,
            ),
            items: [
              const DropdownMenuItem(
                value: 'all',
                child: Text('Tất cả workspace'),
              ),
              ...workspaces.map((workspace) {
                return DropdownMenuItem(
                  value: workspace.id,
                  child: Text(workspace.name),
                );
              }),
            ],
            onChanged: (value) {
              if (value != null) onWorkspaceChanged(value);
            },
          ),
        ],
      ),
    );
  }
}

class _ActivityLogCard extends StatelessWidget {
  final MockActivityLog log;
  final _ActionConfig actionConfig;
  final String workspaceName;
  final VoidCallback onTap;

  const _ActivityLogCard({
    required this.log,
    required this.actionConfig,
    required this.workspaceName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: AdminCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: actionConfig.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(17),
              ),
              child: Icon(actionConfig.icon, color: actionConfig.color),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AdminPill(label: actionConfig.label, color: actionConfig.color),
                      const Spacer(),
                      Text(
                        log.createdAt,
                        style: const TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    log.title,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    log.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: const Color(0xFF6366F1),
                        child: Text(
                          log.userAvatar,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          log.userName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF374151),
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Flexible(
                        child: Text(
                          workspaceName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailBlock extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;

  const _DetailBlock({
    required this.icon,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AdminCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF7C3AED)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    content,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionConfig {
  final String label;
  final Color color;
  final IconData icon;

  const _ActionConfig({
    required this.label,
    required this.color,
    required this.icon,
  });
}
