import 'package:flutter/material.dart';

import '../../data/mock_activity_logs.dart';
import '../../data/mock_users.dart';
import '../../data/mock_workspaces.dart';

class AdminActivityLogScreen extends StatefulWidget {
  const AdminActivityLogScreen({super.key});

  @override
  State<AdminActivityLogScreen> createState() => _AdminActivityLogScreenState();
}

class _AdminActivityLogScreenState extends State<AdminActivityLogScreen> {
  List<MockActivityLog> logs = List.from(mockActivityLogs);

  String selectedActionType = 'all';
  String selectedUserId = 'all';
  String selectedWorkspaceId = 'all';

  List<MockActivityLog> get filteredLogs {
    return logs.where((log) {
      final matchAction =
          selectedActionType == 'all' || log.actionType == selectedActionType;

      final matchUser = selectedUserId == 'all' || log.userId == selectedUserId;

      final matchWorkspace =
          selectedWorkspaceId == 'all' || log.workspaceId == selectedWorkspaceId;

      return matchAction && matchUser && matchWorkspace;
    }).toList();
  }

  int get todayLogs {
    return logs.where((log) => log.createdAt.contains('Hôm nay')).length;
  }

  int get taskLogs {
    return logs.where((log) => log.actionType.startsWith('TASK')).length;
  }

  int get approvalLogs {
    return logs.where((log) => log.actionType.startsWith('APPROVAL')).length;
  }

  int get userLogs {
    return logs.where((log) => log.actionType.contains('USER')).length;
  }

  String getWorkspaceName(String workspaceId) {
    try {
      return mockWorkspaces.firstWhere((item) => item.id == workspaceId).name;
    } catch (_) {
      return 'Không rõ workspace';
    }
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
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    Center(
                      child: Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          color: actionConfig.color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Icon(
                          actionConfig.icon,
                          color: actionConfig.color,
                          size: 34,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Center(
                      child: Text(
                        log.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          height: 1.25,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Center(
                      child: _ActionBadge(
                        label: actionConfig.label,
                        color: actionConfig.color,
                      ),
                    ),

                    const SizedBox(height: 22),

                    _DetailBlock(
                      icon: Icons.description_outlined,
                      title: 'Mô tả hoạt động',
                      content: log.description,
                    ),

                    const SizedBox(height: 12),

                    _DetailBlock(
                      icon: Icons.person_outline_rounded,
                      title: 'Người thực hiện',
                      content: '${log.userName} (${log.userAvatar})',
                    ),

                    const SizedBox(height: 12),

                    _DetailBlock(
                      icon: Icons.workspaces_outline,
                      title: 'Workspace',
                      content: getWorkspaceName(log.workspaceId),
                    ),

                    const SizedBox(height: 12),

                    _DetailBlock(
                      icon: Icons.access_time_rounded,
                      title: 'Thời gian',
                      content: log.createdAt,
                    ),

                    const SizedBox(height: 12),

                    _DetailBlock(
                      icon: Icons.code_rounded,
                      title: 'Action Type',
                      content: log.actionType,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void clearFilters() {
    setState(() {
      selectedActionType = 'all';
      selectedUserId = 'all';
      selectedWorkspaceId = 'all';
    });
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

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _OverviewPanel(
                      totalLogs: logs.length,
                      todayLogs: todayLogs,
                      taskLogs: taskLogs,
                      approvalLogs: approvalLogs,
                    ),

                    const SizedBox(height: 20),

                    _FilterPanel(
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

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Activity Log',
                            style: TextStyle(
                              color: Color(0xFF111827),
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDE9FE),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${visibleLogs.length} log',
                            style: const TextStyle(
                              color: Color(0xFF6D28D9),
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Admin có thể theo dõi lịch sử hoạt động trong hệ thống.',
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 16),

                    if (visibleLogs.isEmpty)
                      const _EmptyLogList()
                    else
                      ...visibleLogs.map((log) {
                        final config = _getActionConfig(log.actionType);

                        return _ActivityLogCard(
                          log: log,
                          actionConfig: config,
                          workspaceName: getWorkspaceName(log.workspaceId),
                          onTap: () => showLogDetail(log),
                        );
                      }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onBack;

  const _Header({
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF111827),
            Color(0xFF7C3AED),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.16),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 19,
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Activity Log',
              style: TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.history_rounded,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewPanel extends StatelessWidget {
  final int totalLogs;
  final int todayLogs;
  final int taskLogs;
  final int approvalLogs;

  const _OverviewPanel({
    required this.totalLogs,
    required this.todayLogs,
    required this.taskLogs,
    required this.approvalLogs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF111827),
            Color(0xFF7C3AED),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withOpacity(0.22),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(
                Icons.monitor_heart_rounded,
                color: Colors.white,
                size: 30,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tổng quan hoạt động',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _OverviewMiniStat(
                  label: 'Tổng log',
                  value: '$totalLogs',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _OverviewMiniStat(
                  label: 'Hôm nay',
                  value: '$todayLogs',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _OverviewMiniStat(
                  label: 'Task',
                  value: '$taskLogs',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _OverviewMiniStat(
                  label: 'Duyệt',
                  value: '$approvalLogs',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewMiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _OverviewMiniStat({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterPanel extends StatelessWidget {
  final String selectedActionType;
  final String selectedUserId;
  final String selectedWorkspaceId;
  final ValueChanged<String> onActionChanged;
  final ValueChanged<String> onUserChanged;
  final ValueChanged<String> onWorkspaceChanged;
  final VoidCallback onClear;

  const _FilterPanel({
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
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.filter_alt_outlined,
                color: Color(0xFF7C3AED),
              ),
              const SizedBox(width: 8),
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
              TextButton(
                onPressed: onClear,
                child: const Text('Xóa lọc'),
              ),
            ],
          ),

          const SizedBox(height: 14),

          DropdownButtonFormField<String>(
            value: selectedActionType,
            decoration: _inputDecoration(
              hintText: 'Lọc theo hành động',
              icon: Icons.category_outlined,
            ),
            items: [
              const DropdownMenuItem(
                value: 'all',
                child: Text('Tất cả hành động'),
              ),
              ...activityActionTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type),
                );
              }),
            ],
            onChanged: (value) {
              if (value == null) return;
              onActionChanged(value);
            },
          ),

          const SizedBox(height: 12),

          DropdownButtonFormField<String>(
            value: selectedUserId,
            decoration: _inputDecoration(
              hintText: 'Lọc theo user',
              icon: Icons.person_outline_rounded,
            ),
            items: [
              const DropdownMenuItem(
                value: 'all',
                child: Text('Tất cả user'),
              ),
              ...mockUsers.map((user) {
                return DropdownMenuItem(
                  value: user.id,
                  child: Text(user.fullName),
                );
              }),
            ],
            onChanged: (value) {
              if (value == null) return;
              onUserChanged(value);
            },
          ),

          const SizedBox(height: 12),

          DropdownButtonFormField<String>(
            value: selectedWorkspaceId,
            decoration: _inputDecoration(
              hintText: 'Lọc theo workspace',
              icon: Icons.workspaces_outline,
            ),
            items: [
              const DropdownMenuItem(
                value: 'all',
                child: Text('Tất cả workspace'),
              ),
              ...mockWorkspaces.map((workspace) {
                return DropdownMenuItem(
                  value: workspace.id,
                  child: Text(workspace.name),
                );
              }),
            ],
            onChanged: (value) {
              if (value == null) return;
              onWorkspaceChanged(value);
            },
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: const Color(0xFFF3F4F6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
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
      borderRadius: BorderRadius.circular(26),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
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
              child: Icon(
                actionConfig.icon,
                color: actionConfig.color,
              ),
            ),

            const SizedBox(width: 13),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _ActionBadge(
                        label: actionConfig.label,
                        color: actionConfig.color,
                      ),
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
                      const Icon(
                        Icons.workspaces_outline,
                        size: 15,
                        color: Color(0xFF9CA3AF),
                      ),
                      const SizedBox(width: 4),
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

class _ActionBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _ActionBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 11,
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: const Color(0xFF7C3AED),
          ),
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
    );
  }
}

class _EmptyLogList extends StatelessWidget {
  const _EmptyLogList();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: const Column(
        children: [
          Icon(
            Icons.history_toggle_off_rounded,
            size: 46,
            color: Color(0xFF9CA3AF),
          ),
          SizedBox(height: 10),
          Text(
            'Không có log nào phù hợp bộ lọc',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionConfig {
  final String label;
  final Color color;
  final IconData icon;

  _ActionConfig({
    required this.label,
    required this.color,
    required this.icon,
  });
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(26),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.055),
        blurRadius: 16,
        offset: const Offset(0, 7),
      ),
    ],
  );
}