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
  List<MockWorkspace> workspaces = List.from(mockWorkspaces);
  List<MockTask> tasks = List.from(mockTasks);
  List<MockProject> projects = List.from(mockProjects);
  final TextEditingController taskSearchController = TextEditingController();
  String selectedWorkspaceFilter = 'all';
  String selectedProjectFilter = 'all';
  String selectedStatusFilter = 'all';
  String selectedPriorityFilter = 'all';
  String selectedChecklistCountFilter = 'all';
  String selectedCommentCountFilter = 'all';
  String selectedTaskSort = 'az';
  bool isLoading = true;
  String? errorMessage;

  List<MockTask> get filteredTasks {
    final result = tasks.where((task) {
      final projectIndex = projects.indexWhere(
        (item) => item.id == task.projectId,
      );
      final project = projectIndex == -1 ? null : projects[projectIndex];
      final matchWorkspace =
          selectedWorkspaceFilter == 'all' ||
          project?.workspaceId == selectedWorkspaceFilter;
      final matchProject =
          selectedProjectFilter == 'all' ||
          task.projectId == selectedProjectFilter;
      final matchStatus =
          selectedStatusFilter == 'all' || task.status == selectedStatusFilter;
      final matchPriority =
          selectedPriorityFilter == 'all' ||
          task.priority == selectedPriorityFilter;
      final search = normalizeAdminSearch(taskSearchController.text);
      final projectName = normalizeAdminSearch(project?.name ?? '');
      final workspaceName = project == null
          ? ''
          : normalizeAdminSearch(getWorkspaceName(project.workspaceId));
      final matchSearch =
          search.isEmpty ||
          normalizeAdminSearch(task.title).contains(search) ||
          normalizeAdminSearch(task.description).contains(search) ||
          projectName.contains(search) ||
          workspaceName.contains(search);
      final matchChecklistCount = switch (selectedChecklistCountFilter) {
        'none' => task.checklistTotal == 0,
        '1-5' => task.checklistTotal >= 1 && task.checklistTotal <= 5,
        '6+' => task.checklistTotal >= 6,
        _ => true,
      };
      final matchCommentCount = switch (selectedCommentCountFilter) {
        'none' => task.commentCount == 0,
        '1-3' => task.commentCount >= 1 && task.commentCount <= 3,
        '4+' => task.commentCount >= 4,
        _ => true,
      };
      return matchWorkspace &&
          matchProject &&
          matchStatus &&
          matchPriority &&
          matchSearch &&
          matchChecklistCount &&
          matchCommentCount;
    }).toList();

    result.sort((first, second) {
      return switch (selectedTaskSort) {
        'za' => normalizeAdminSearch(
          second.title,
        ).compareTo(normalizeAdminSearch(first.title)),
        'checklistAsc' => first.checklistTotal.compareTo(second.checklistTotal),
        'checklistDesc' => second.checklistTotal.compareTo(
          first.checklistTotal,
        ),
        'commentsAsc' => first.commentCount.compareTo(second.commentCount),
        'commentsDesc' => second.commentCount.compareTo(first.commentCount),
        _ => normalizeAdminSearch(
          first.title,
        ).compareTo(normalizeAdminSearch(second.title)),
      };
    });
    return result;
  }

  List<MockProject> get workspaceFilteredProjects {
    if (selectedWorkspaceFilter == 'all') return projects;
    return projects
        .where((project) => project.workspaceId == selectedWorkspaceFilter)
        .toList();
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
      final loadedWorkspaces = await AppDataService.fetchWorkspaces();
      final loadedProjects = await AppDataService.fetchProjects();
      final loadedTasks = await AppDataService.fetchTasks();
      if (!mounted) return;
      setState(() {
        workspaces = loadedWorkspaces;
        projects = loadedProjects;
        tasks = loadedTasks;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        workspaces = List.from(mockWorkspaces);
        projects = List.from(mockProjects);
        tasks = List.from(mockTasks);
        errorMessage =
            'Chưa kết nối được backend, đang hiển thị task dự phòng.';
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    taskSearchController.dispose();
    super.dispose();
  }

  String getProjectName(String projectId) {
    try {
      return projects.firstWhere((project) => project.id == projectId).name;
    } catch (_) {
      return 'Không rõ project';
    }
  }

  String getWorkspaceName(String workspaceId) {
    try {
      return workspaces
          .firstWhere((workspace) => workspace.id == workspaceId)
          .name;
    } catch (_) {
      return 'Không rõ workspace';
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
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
                      workspaces: workspaces,
                      projects: workspaceFilteredProjects,
                      taskSearchController: taskSearchController,
                      selectedWorkspaceFilter: selectedWorkspaceFilter,
                      selectedProjectFilter: selectedProjectFilter,
                      selectedStatusFilter: selectedStatusFilter,
                      selectedPriorityFilter: selectedPriorityFilter,
                      selectedChecklistCountFilter:
                          selectedChecklistCountFilter,
                      selectedCommentCountFilter: selectedCommentCountFilter,
                      selectedSort: selectedTaskSort,
                      onWorkspaceChanged: (value) {
                        setState(() {
                          selectedWorkspaceFilter = value;
                          if (!workspaceFilteredProjects.any(
                            (project) => project.id == selectedProjectFilter,
                          )) {
                            selectedProjectFilter = 'all';
                          }
                        });
                      },
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
                      onChecklistCountChanged: (value) {
                        setState(() {
                          selectedChecklistCountFilter = value;
                        });
                      },
                      onCommentCountChanged: (value) {
                        setState(() {
                          selectedCommentCountFilter = value;
                        });
                      },
                      onSortChanged: (value) {
                        setState(() {
                          selectedTaskSort = value;
                        });
                      },
                      onSearchChanged: (_) => setState(() {}),
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
  final List<MockWorkspace> workspaces;
  final List<MockProject> projects;
  final TextEditingController taskSearchController;
  final String selectedWorkspaceFilter;
  final String selectedProjectFilter;
  final String selectedStatusFilter;
  final String selectedPriorityFilter;
  final String selectedChecklistCountFilter;
  final String selectedCommentCountFilter;
  final String selectedSort;
  final ValueChanged<String> onWorkspaceChanged;
  final ValueChanged<String> onProjectChanged;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onPriorityChanged;
  final ValueChanged<String> onChecklistCountChanged;
  final ValueChanged<String> onCommentCountChanged;
  final ValueChanged<String> onSortChanged;
  final ValueChanged<String> onSearchChanged;

  const _FilterPanel({
    required this.workspaces,
    required this.projects,
    required this.taskSearchController,
    required this.selectedWorkspaceFilter,
    required this.selectedProjectFilter,
    required this.selectedStatusFilter,
    required this.selectedPriorityFilter,
    required this.selectedChecklistCountFilter,
    required this.selectedCommentCountFilter,
    required this.selectedSort,
    required this.onWorkspaceChanged,
    required this.onProjectChanged,
    required this.onStatusChanged,
    required this.onPriorityChanged,
    required this.onChecklistCountChanged,
    required this.onCommentCountChanged,
    required this.onSortChanged,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: Column(
        children: [
          TextField(
            controller: taskSearchController,
            onChanged: onSearchChanged,
            decoration: adminInputDecoration(
              label: 'Tìm task theo tên',
              icon: Icons.search_rounded,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: selectedWorkspaceFilter,
            decoration: adminInputDecoration(
              label: 'Lọc theo workspace',
              icon: Icons.workspaces_outline,
            ),
            items: [
              const DropdownMenuItem(
                value: 'all',
                child: Text('Tất cả Workspace'),
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
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: selectedProjectFilter,
            decoration: adminInputDecoration(
              label: 'Lọc theo project',
              icon: Icons.folder_open_outlined,
            ),
            items: [
              const DropdownMenuItem(
                value: 'all',
                child: Text('Tất cả Project'),
              ),
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
              const DropdownMenuItem(
                value: 'all',
                child: Text('Tất cả trạng thái'),
              ),
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
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: selectedChecklistCountFilter,
            decoration: adminInputDecoration(
              label: 'Lọc theo số checklist',
              icon: Icons.checklist_rounded,
            ),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('Tất cả số lượng')),
              DropdownMenuItem(
                value: 'none',
                child: Text('Không có checklist'),
              ),
              DropdownMenuItem(
                value: '1-5',
                child: Text('Từ 1 đến 5 checklist'),
              ),
              DropdownMenuItem(
                value: '6+',
                child: Text('Từ 6 checklist trở lên'),
              ),
            ],
            onChanged: (value) {
              if (value != null) onChecklistCountChanged(value);
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: selectedCommentCountFilter,
            decoration: adminInputDecoration(
              label: 'Lọc theo số bình luận',
              icon: Icons.chat_bubble_outline_rounded,
            ),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('Tất cả số lượng')),
              DropdownMenuItem(value: 'none', child: Text('Chưa có bình luận')),
              DropdownMenuItem(
                value: '1-3',
                child: Text('Từ 1 đến 3 bình luận'),
              ),
              DropdownMenuItem(
                value: '4+',
                child: Text('Từ 4 bình luận trở lên'),
              ),
            ],
            onChanged: (value) {
              if (value != null) onCommentCountChanged(value);
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: selectedSort,
            decoration: adminInputDecoration(
              label: 'Sắp xếp task',
              icon: Icons.sort_by_alpha_rounded,
            ),
            items: const [
              DropdownMenuItem(value: 'az', child: Text('Tên A → Z')),
              DropdownMenuItem(value: 'za', child: Text('Tên Z → A')),
              DropdownMenuItem(
                value: 'checklistAsc',
                child: Text('Số checklist tăng dần'),
              ),
              DropdownMenuItem(
                value: 'checklistDesc',
                child: Text('Số checklist giảm dần'),
              ),
              DropdownMenuItem(
                value: 'commentsAsc',
                child: Text('Số bình luận tăng dần'),
              ),
              DropdownMenuItem(
                value: 'commentsDesc',
                child: Text('Số bình luận giảm dần'),
              ),
            ],
            onChanged: (value) {
              if (value != null) onSortChanged(value);
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
    final checklistProgress = task.checklistTotal == 0
        ? 0.0
        : task.checklistDone / task.checklistTotal;
    final statusValue = kanbanColumns.contains(task.status)
        ? task.status
        : kanbanColumns.first;

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
              AdminPill(label: task.dueDate, color: const Color(0xFFF59E0B)),
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
