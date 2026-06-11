import 'package:flutter/material.dart';

import '../../data/mock_tasks.dart';
import '../../data/mock_workspaces.dart';
import '../../services/app_data_service.dart';
import 'admin_widgets.dart';

class AdminTaskManagementScreen extends StatefulWidget {
  const AdminTaskManagementScreen({super.key});

  @override
  State<AdminTaskManagementScreen> createState() =>
      _AdminTaskManagementScreenState();
}

class _AdminTaskManagementScreenState extends State<AdminTaskManagementScreen> {
  List<MockTask> tasks = List.from(mockTasks);
  List<MockProject> projects = List.from(mockProjects);
  String selectedProjectFilter = 'all';
  String selectedStatusFilter = 'all';
  String selectedPriorityFilter = 'all';
  bool isLoading = true;
  String? errorMessage;

  List<MockTask> get filteredTasks {
    return tasks.where((task) {
      final matchProject =
          selectedProjectFilter == 'all' || task.projectId == selectedProjectFilter;
      final matchStatus =
          selectedStatusFilter == 'all' || task.status == selectedStatusFilter;
      final matchPriority =
          selectedPriorityFilter == 'all' || task.priority == selectedPriorityFilter;
      return matchProject && matchStatus && matchPriority;
    }).toList();
  }

  int get doneTasks {
    return tasks.where((task) => task.status == kanbanColumns.last).length;
  }

  int get inProgressTasks {
    return tasks.where((task) {
      return task.status == kanbanColumns[1] || task.status == kanbanColumns[2];
    }).length;
  }

  int get highPriorityTasks {
    return tasks.where((task) => task.priority == 'High').length;
  }

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
      final loadedProjects = await AppDataService.fetchProjects();
      final loadedTasks = await AppDataService.fetchTasks();
      if (!mounted) return;
      setState(() {
        projects = loadedProjects;
        tasks = loadedTasks;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        projects = List.from(mockProjects);
        tasks = List.from(mockTasks);
        errorMessage = 'Chưa kết nối được backend, đang hiển thị task dự phòng.';
        isLoading = false;
      });
    }
  }

  String getProjectName(String projectId) {
    try {
      return projects.firstWhere((project) => project.id == projectId).name;
    } catch (_) {
      return 'Không rõ project';
    }
  }

  Future<void> updateTaskStatus(MockTask task, String newStatus) async {
    final index = tasks.indexWhere((item) => item.id == task.id);
    if (index == -1) return;

    setState(() {
      tasks[index] = tasks[index].copyWith(status: newStatus);
    });

    try {
      final savedTask = await AppDataService.updateTaskStatus(
        taskId: task.id,
        status: newStatus,
      );
      if (!mounted) return;
      setState(() {
        tasks[index] = savedTask;
      });
      showAdminMessage(context, 'Đã đổi trạng thái task sang "$newStatus"');
    } catch (error) {
      if (!mounted) return;
      setState(() {
        tasks[index] = task;
      });
      showAdminMessage(context, 'Không thể cập nhật task: $error');
    }
  }

  Future<void> deleteTask(MockTask task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: const Text('Xóa Task'),
          content: Text('Bạn có chắc muốn xóa task "${task.title}" không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
              ),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await AppDataService.deleteTask(task.id);
      if (!mounted) return;
      setState(() {
        tasks.removeWhere((item) => item.id == task.id);
      });
      showAdminMessage(context, 'Đã xóa task');
    } catch (error) {
      if (!mounted) return;
      showAdminMessage(context, 'Không thể xóa task: $error');
    }
  }

  void showTaskDetail(MockTask task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.72,
          minChildSize: 0.45,
          maxChildSize: 0.9,
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
                    backgroundColor: const Color(0xFF7C3AED),
                    child: Text(
                      task.assigneeAvatar,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    task.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    getProjectName(task.projectId),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 18),
                  AdminStatGrid(
                    stats: [
                      AdminStat(
                        label: 'Trạng thái',
                        value: task.status,
                        icon: Icons.view_kanban_outlined,
                        color: const Color(0xFF7C3AED),
                      ),
                      AdminStat(
                        label: 'Priority',
                        value: _priorityLabel(task.priority),
                        icon: Icons.flag_outlined,
                        color: _priorityColor(task.priority),
                      ),
                      AdminStat(
                        label: 'Checklist',
                        value: '${task.checklistDone}/${task.checklistTotal}',
                        icon: Icons.checklist_rounded,
                        color: const Color(0xFF2563EB),
                      ),
                      AdminStat(
                        label: 'Bình luận',
                        value: '${task.commentCount}',
                        icon: Icons.chat_bubble_outline_rounded,
                        color: const Color(0xFFF59E0B),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  AdminCard(
                    child: Text(
                      task.description,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Đổi trạng thái nhanh',
                    style: TextStyle(
                      color: Color(0xFF111827),
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: kanbanColumns.map((status) {
                      return ChoiceChip(
                        selected: task.status == status,
                        label: Text(status),
                        onSelected: (_) {
                          Navigator.pop(bottomSheetContext);
                          updateTaskStatus(task, status);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _priorityLabel(String priority) {
    switch (priority) {
      case 'High':
        return 'Cao';
      case 'Medium':
        return 'Trung bình';
      default:
        return 'Thấp';
    }
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'High':
        return const Color(0xFFEF4444);
      case 'Medium':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF22C55E);
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleTasks = filteredTasks;

    return AdminScreenScaffold(
      title: 'Quản lý Task',
      icon: Icons.task_alt_rounded,
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
                          label: 'Tổng',
                          value: '${tasks.length}',
                          icon: Icons.fact_check_rounded,
                          color: const Color(0xFF7C3AED),
                        ),
                        AdminStat(
                          label: 'Đã xong',
                          value: '$doneTasks',
                          icon: Icons.check_circle_rounded,
                          color: const Color(0xFF22C55E),
                        ),
                        AdminStat(
                          label: 'Đang làm',
                          value: '$inProgressTasks',
                          icon: Icons.pending_actions_rounded,
                          color: const Color(0xFFF59E0B),
                        ),
                        AdminStat(
                          label: 'Ưu tiên cao',
                          value: '$highPriorityTasks',
                          icon: Icons.flag_rounded,
                          color: const Color(0xFFEF4444),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _FilterPanel(
                      projects: projects,
                      selectedProjectFilter: selectedProjectFilter,
                      selectedStatusFilter: selectedStatusFilter,
                      selectedPriorityFilter: selectedPriorityFilter,
                      onProjectChanged: (value) {
                        setState(() {
                          selectedProjectFilter = value;
                        });
                      },
                      onStatusChanged: (value) {
                        setState(() {
                          selectedStatusFilter = value;
                        });
                      },
                      onPriorityChanged: (value) {
                        setState(() {
                          selectedPriorityFilter = value;
                        });
                      },
                    ),
                    const SizedBox(height: 18),
                    AdminSectionTitle(
                      title: 'Tất cả Task',
                      countLabel: '${visibleTasks.length} task',
                    ),
                    const SizedBox(height: 14),
                    if (visibleTasks.isEmpty)
                      const AdminEmptyState(
                        icon: Icons.task_alt_outlined,
                        message: 'Không có task nào phù hợp bộ lọc.',
                      )
                    else
                      ...visibleTasks.map((task) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _TaskAdminCard(
                            task: task,
                            projectName: getProjectName(task.projectId),
                            priorityLabel: _priorityLabel(task.priority),
                            priorityColor: _priorityColor(task.priority),
                            onView: () => showTaskDetail(task),
                            onStatusChanged: (status) {
                              updateTaskStatus(task, status);
                            },
                            onDelete: () => deleteTask(task),
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
  final List<MockProject> projects;
  final String selectedProjectFilter;
  final String selectedStatusFilter;
  final String selectedPriorityFilter;
  final ValueChanged<String> onProjectChanged;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onPriorityChanged;

  const _FilterPanel({
    required this.projects,
    required this.selectedProjectFilter,
    required this.selectedStatusFilter,
    required this.selectedPriorityFilter,
    required this.onProjectChanged,
    required this.onStatusChanged,
    required this.onPriorityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            value: selectedProjectFilter,
            decoration: adminInputDecoration(
              label: 'Lọc theo project',
              icon: Icons.folder_open_outlined,
            ),
            items: [
              const DropdownMenuItem(value: 'all', child: Text('Tất cả Project')),
              ...projects.map((project) {
                return DropdownMenuItem(
                  value: project.id,
                  child: Text(project.name),
                );
              }),
            ],
            onChanged: (value) {
              if (value != null) onProjectChanged(value);
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: selectedStatusFilter,
            decoration: adminInputDecoration(
              label: 'Lọc theo trạng thái',
              icon: Icons.view_kanban_outlined,
            ),
            items: [
              const DropdownMenuItem(value: 'all', child: Text('Tất cả trạng thái')),
              ...kanbanColumns.map((status) {
                return DropdownMenuItem(value: status, child: Text(status));
              }),
            ],
            onChanged: (value) {
              if (value != null) onStatusChanged(value);
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: selectedPriorityFilter,
            decoration: adminInputDecoration(
              label: 'Lọc theo priority',
              icon: Icons.flag_outlined,
            ),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('Tất cả priority')),
              DropdownMenuItem(value: 'High', child: Text('Cao')),
              DropdownMenuItem(value: 'Medium', child: Text('Trung bình')),
              DropdownMenuItem(value: 'Low', child: Text('Thấp')),
            ],
            onChanged: (value) {
              if (value != null) onPriorityChanged(value);
            },
          ),
        ],
      ),
    );
  }
}

class _TaskAdminCard extends StatelessWidget {
  final MockTask task;
  final String projectName;
  final String priorityLabel;
  final Color priorityColor;
  final VoidCallback onView;
  final ValueChanged<String> onStatusChanged;
  final VoidCallback onDelete;

  const _TaskAdminCard({
    required this.task,
    required this.projectName,
    required this.priorityLabel,
    required this.priorityColor,
    required this.onView,
    required this.onStatusChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final checklistProgress =
        task.checklistTotal == 0 ? 0.0 : task.checklistDone / task.checklistTotal;
    final statusValue =
        kanbanColumns.contains(task.status) ? task.status : kanbanColumns.first;

    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF6366F1),
                child: Text(
                  task.assigneeAvatar,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      projectName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              AdminPill(label: priorityLabel, color: priorityColor),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              AdminPill(
                label: task.assigneeName,
                color: const Color(0xFF2563EB),
              ),
              const SizedBox(width: 8),
              AdminPill(
                label: task.dueDate,
                color: const Color(0xFFF59E0B),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '${task.checklistDone}/${task.checklistTotal}',
                style: const TextStyle(
                  color: Color(0xFF374151),
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: checklistProgress.clamp(0.0, 1.0).toDouble(),
                    minHeight: 7,
                    backgroundColor: const Color(0xFFE5E7EB),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF7C3AED),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: statusValue,
            decoration: adminInputDecoration(label: 'Trạng thái'),
            items: kanbanColumns.map((status) {
              return DropdownMenuItem(value: status, child: Text(status));
            }).toList(),
            onChanged: (value) {
              if (value != null && value != task.status) onStatusChanged(value);
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onView,
                  icon: const Icon(Icons.remove_red_eye_outlined, size: 18),
                  label: const Text('Xem'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('Xóa'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
