import 'package:flutter/material.dart';

import '../../data/mock_tasks.dart';
import '../../data/mock_workspaces.dart';

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
    return tasks.where((task) => task.status == 'Đã xong').length;
  }

  int get inProgressTasks {
    return tasks.where((task) {
      return task.status == 'Đang làm' || task.status == 'Kiểm tra';
    }).length;
  }

  int get highPriorityTasks {
    return tasks.where((task) => task.priority == 'High').length;
  }

  String getProjectName(String projectId) {
    try {
      return projects.firstWhere((project) => project.id == projectId).name;
    } catch (_) {
      return 'Không rõ project';
    }
  }

  void updateTaskStatus(MockTask task, String newStatus) {
    final realIndex = tasks.indexWhere((item) => item.id == task.id);

    if (realIndex == -1) return;

    setState(() {
      tasks[realIndex] = tasks[realIndex].copyWith(status: newStatus);
    });

    showMessage('Đã đổi trạng thái task sang "$newStatus"');
  }

  void deleteTask(MockTask task) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text('Xóa Task'),
          content: Text(
            'Bạn có chắc muốn xóa task "${task.title}" không?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  tasks.removeWhere((item) => item.id == task.id);
                });

                Navigator.pop(dialogContext);
                showMessage('Đã xóa task mock');
              },
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
  }

  void showTaskDetail(MockTask task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.78,
          minChildSize: 0.45,
          maxChildSize: 0.92,
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
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF2563EB),
                              Color(0xFF9333EA),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(
                          Icons.task_alt_rounded,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Center(
                      child: Text(
                        task.title,
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
                      child: Text(
                        getProjectName(task.projectId),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    Row(
                      children: [
                        Expanded(
                          child: _DetailStatBox(
                            label: 'Trạng thái',
                            value: task.status,
                            icon: Icons.view_kanban_outlined,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DetailStatBox(
                            label: 'Priority',
                            value: _priorityLabel(task.priority),
                            icon: Icons.flag_outlined,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _DetailStatBox(
                            label: 'Checklist',
                            value: '${task.checklistDone}/${task.checklistTotal}',
                            icon: Icons.checklist_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DetailStatBox(
                            label: 'Bình luận',
                            value: '${task.commentCount}',
                            icon: Icons.chat_bubble_outline_rounded,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    _InfoBlock(
                      icon: Icons.description_outlined,
                      title: 'Mô tả',
                      content: task.description,
                    ),

                    const SizedBox(height: 12),

                    _InfoBlock(
                      icon: Icons.person_outline_rounded,
                      title: 'Người phụ trách',
                      content: '${task.assigneeName} (${task.assigneeAvatar})',
                    ),

                    const SizedBox(height: 12),

                    _InfoBlock(
                      icon: Icons.calendar_today_outlined,
                      title: 'Deadline',
                      content: task.dueDate,
                    ),

                    const SizedBox(height: 18),

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
                        final isSelected = task.status == status;

                        return ChoiceChip(
                          selected: isSelected,
                          label: Text(status),
                          selectedColor: const Color(0xFFEDE9FE),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? const Color(0xFF6D28D9)
                                : const Color(0xFF374151),
                            fontWeight: FontWeight.w800,
                          ),
                          onSelected: (_) {
                            Navigator.pop(bottomSheetContext);
                            updateTaskStatus(task, status);
                          },
                        );
                      }).toList(),
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

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleTasks = filteredTasks;

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
                      totalTasks: tasks.length,
                      doneTasks: doneTasks,
                      inProgressTasks: inProgressTasks,
                      highPriorityTasks: highPriorityTasks,
                    ),

                    const SizedBox(height: 20),

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

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Tất cả Task',
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
                            '${visibleTasks.length} task',
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
                      'Admin có thể xem, lọc, đổi trạng thái hoặc xóa task mock.',
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 16),

                    if (visibleTasks.isEmpty)
                      const _EmptyTaskList()
                    else
                      ...visibleTasks.map((task) {
                        return _TaskAdminCard(
                          task: task,
                          projectName: getProjectName(task.projectId),
                          onView: () => showTaskDetail(task),
                          onStatusChanged: (status) {
                            updateTaskStatus(task, status);
                          },
                          onDelete: () => deleteTask(task),
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
              'Quản lý Task',
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
              Icons.task_alt_rounded,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewPanel extends StatelessWidget {
  final int totalTasks;
  final int doneTasks;
  final int inProgressTasks;
  final int highPriorityTasks;

  const _OverviewPanel({
    required this.totalTasks,
    required this.doneTasks,
    required this.inProgressTasks,
    required this.highPriorityTasks,
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
                Icons.fact_check_rounded,
                color: Colors.white,
                size: 30,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tổng quan Task',
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
                  label: 'Tổng',
                  value: '$totalTasks',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _OverviewMiniStat(
                  label: 'Đã xong',
                  value: '$doneTasks',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _OverviewMiniStat(
                  label: 'Đang làm',
                  value: '$inProgressTasks',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _OverviewMiniStat(
                  label: 'Ưu tiên cao',
                  value: '$highPriorityTasks',
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
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.filter_alt_outlined,
                color: Color(0xFF7C3AED),
              ),
              SizedBox(width: 8),
              Text(
                'Bộ lọc Task',
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          DropdownButtonFormField<String>(
            value: selectedProjectFilter,
            decoration: _inputDecoration(
              hintText: 'Lọc theo project',
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
              if (value == null) return;
              onProjectChanged(value);
            },
          ),

          const SizedBox(height: 12),

          DropdownButtonFormField<String>(
            value: selectedStatusFilter,
            decoration: _inputDecoration(
              hintText: 'Lọc theo trạng thái',
              icon: Icons.view_kanban_outlined,
            ),
            items: [
              const DropdownMenuItem(
                value: 'all',
                child: Text('Tất cả trạng thái'),
              ),
              ...kanbanColumns.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(status),
                );
              }),
            ],
            onChanged: (value) {
              if (value == null) return;
              onStatusChanged(value);
            },
          ),

          const SizedBox(height: 12),

          DropdownButtonFormField<String>(
            value: selectedPriorityFilter,
            decoration: _inputDecoration(
              hintText: 'Lọc theo priority',
              icon: Icons.flag_outlined,
            ),
            items: const [
              DropdownMenuItem(
                value: 'all',
                child: Text('Tất cả priority'),
              ),
              DropdownMenuItem(
                value: 'High',
                child: Text('Cao'),
              ),
              DropdownMenuItem(
                value: 'Medium',
                child: Text('Trung bình'),
              ),
              DropdownMenuItem(
                value: 'Low',
                child: Text('Thấp'),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;
              onPriorityChanged(value);
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

class _TaskAdminCard extends StatelessWidget {
  final MockTask task;
  final String projectName;
  final VoidCallback onView;
  final ValueChanged<String> onStatusChanged;
  final VoidCallback onDelete;

  const _TaskAdminCard({
    required this.task,
    required this.projectName,
    required this.onView,
    required this.onStatusChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final priorityConfig = _priorityConfig(task.priority);
    final checklistProgress =
    task.checklistTotal == 0 ? 0.0 : task.checklistDone / task.checklistTotal;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
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
              _PriorityBadge(
                label: priorityConfig.label,
                color: priorityConfig.color,
              ),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              _SmallInfoChip(
                icon: Icons.person_outline_rounded,
                label: task.assigneeName,
              ),
              const SizedBox(width: 8),
              _SmallInfoChip(
                icon: Icons.calendar_today_outlined,
                label: task.dueDate,
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
                    value: checklistProgress,
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
            value: task.status,
            decoration: InputDecoration(
              labelText: 'Trạng thái',
              filled: true,
              fillColor: const Color(0xFFF3F4F6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
            items: kanbanColumns.map((status) {
              return DropdownMenuItem(
                value: status,
                child: Text(status),
              );
            }).toList(),
            onChanged: (value) {
              if (value == null) return;
              onStatusChanged(value);
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
                  style: _buttonStyle(const Color(0xFF2563EB)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('Xóa'),
                  style: _buttonStyle(const Color(0xFFEF4444)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  _PriorityConfig _priorityConfig(String priority) {
    switch (priority) {
      case 'High':
        return _PriorityConfig('Cao', const Color(0xFFEF4444));
      case 'Medium':
        return _PriorityConfig('Trung bình', const Color(0xFFF59E0B));
      default:
        return _PriorityConfig('Thấp', const Color(0xFF22C55E));
    }
  }

  ButtonStyle _buttonStyle(Color color) {
    return OutlinedButton.styleFrom(
      foregroundColor: color,
      side: BorderSide(color: color.withOpacity(0.35)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _PriorityBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
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

class _SmallInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SmallInfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: const Color(0xFF6B7280),
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
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
      ),
    );
  }
}

class _DetailStatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _DetailStatBox({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: const Color(0xFF7C3AED),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;

  const _InfoBlock({
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

class _EmptyTaskList extends StatelessWidget {
  const _EmptyTaskList();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: const Column(
        children: [
          Icon(
            Icons.task_alt_outlined,
            size: 46,
            color: Color(0xFF9CA3AF),
          ),
          SizedBox(height: 10),
          Text(
            'Không có task nào phù hợp bộ lọc',
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

class _PriorityConfig {
  final String label;
  final Color color;

  _PriorityConfig(this.label, this.color);
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