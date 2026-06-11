import 'package:flutter/material.dart';
import '../../data/mock_tasks.dart';
import '../../data/mock_workspaces.dart';
import '../task/task_detail_screen.dart';
import '../task/create_edit_task_screen.dart';
import '../calendar/calendar_view_screen.dart';
import '../analytics/productivity_analytics_screen.dart';
import '../../data/mock_users.dart';
import '../profile/profile_settings_screen.dart';
import 'board_configuration_screen.dart';
import '../approval/requirements_approval_screen.dart';
import '../../utils/app_navigation.dart';
import '../../utils/role_permissions.dart';
import '../../services/app_data_service.dart';

class ProjectBoardScreen extends StatefulWidget {
  final MockProject project;
  final MockUser user;

  const ProjectBoardScreen({
    super.key,
    required this.project,
    required this.user,
  });

  @override
  State<ProjectBoardScreen> createState() => _ProjectBoardScreenState();
}

class _ProjectBoardScreenState extends State<ProjectBoardScreen> {
  late List<MockTask> tasks;
  late List<String> boardColumns;
  bool isLoading = true;
  int waitingApprovalCount = 0;

  @override
  void initState() {
    super.initState();
    tasks = const [];
    boardColumns = List<String>.from(kanbanColumns);
    loadTasks();
  }

  Future<void> loadTasks() async {
    try {
      final fetchedLists = await AppDataService.fetchTaskLists(widget.project.id);
      final fetchedTasks = await AppDataService.fetchTasks(
        projectId: widget.project.id,
      );
      final approvalRequests = await AppDataService.fetchApprovalRequests(
        projectId: widget.project.id,
        status: 'WAITING',
      );

      if (!mounted) return;

      setState(() {
        tasks = fetchedTasks;
        boardColumns = fetchedLists.isEmpty
            ? List<String>.from(kanbanColumns)
            : fetchedLists.map((list) => list.name).toList();
        waitingApprovalCount = approvalRequests.length;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        tasks = getTasksByProject(widget.project.id);
        boardColumns = List<String>.from(kanbanColumns);
        waitingApprovalCount = 0;
        isLoading = false;
      });
    }
  }

  Future<void> moveTaskToColumn(MockTask task, String newStatus) async {
    final previousTasks = List<MockTask>.from(tasks);

    setState(() {
      tasks = tasks.map((item) {
        if (item.id == task.id) {
          return item.copyWith(status: newStatus);
        }
        return item;
      }).toList();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã chuyển "${task.title}" sang "$newStatus"'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 900),
      ),
    );

    try {
      final updatedTask = await AppDataService.updateTaskStatus(
        taskId: task.id,
        status: newStatus,
      );

      if (!mounted) return;

      setState(() {
        tasks = tasks.map((item) {
          return item.id == updatedTask.id ? updatedTask : item;
        }).toList();
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        tasks = previousTasks;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể cập nhật trạng thái: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void openTaskDetail(MockTask task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskDetailScreen(
          task: task,
          currentUser: widget.user,
        ),
      ),
    );
  }

  Future<void> openCreateTaskScreen() async {
    final newTask = await Navigator.push<MockTask>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateEditTaskScreen(
          projectId: widget.project.id,
        ),
      ),
    );

    if (newTask == null) return;

    setState(() {
      tasks = [newTask, ...tasks];
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã tạo task "${newTask.title}"'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void openCalendarScreen() {
    AppNavigation.goCalendar(
      context: context,
      user: widget.user,
      project: widget.project,
      tasks: tasks,
    );
  }

  void openAnalyticsScreen() {
    AppNavigation.goAnalytics(
      context: context,
      user: widget.user,
      project: widget.project,
      tasks: tasks,
    );
  }

  void openProfileScreen() {
    AppNavigation.goProfile(
      context: context,
      user: widget.user,
      project: widget.project,
      tasks: tasks,
    );
  }

  void openBoardConfigurationScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BoardConfigurationScreen(
          project: widget.project,
          tasks: tasks,
        ),
      ),
    ).then((_) => loadTasks());
  }

  void openRequirementsApprovalScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RequirementsApprovalScreen(
          project: widget.project,
          tasks: tasks,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F7FB),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final totalTasks = tasks.length;
    final doneColumn = boardColumns.isEmpty ? kanbanColumns.last : boardColumns.last;
    final doneTasks = tasks.where((task) => task.status == doneColumn).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      floatingActionButton: RolePermissions.canCreateTask(widget.user)
          ? FloatingActionButton(
        onPressed: openCreateTaskScreen,
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded, size: 30),
      )
          : null,
      bottomNavigationBar: _BoardBottomNavBar(
        onCalendarTap: openCalendarScreen,
        onAnalyticsTap: openAnalyticsScreen,
        onProfileTap: openProfileScreen,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _BoardHeader(
              projectName: widget.project.name,
              projectCode: widget.project.code,
              totalTasks: totalTasks,
              doneTasks: doneTasks,
              onBack: () => Navigator.pop(context),
              onSettingsTap: openBoardConfigurationScreen,
              onApprovalTap: openRequirementsApprovalScreen,
              canConfigureBoard: RolePermissions.canManageBoard(widget.user),
              canApproveRequirements: RolePermissions.canApproveRequirements(widget.user),
              approvalCount: waitingApprovalCount,
            ),
            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Text(
                    'Bảng công việc',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE9FE),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.swipe_rounded,
                          size: 16,
                          color: Color(0xFF6D28D9),
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Vuốt ngang',
                          style: TextStyle(
                            color: Color(0xFF6D28D9),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            Expanded(
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 90),
                itemCount: boardColumns.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final columnName = boardColumns[index];
                  final columnTasks =
                  tasks.where((task) => task.status == columnName).toList();

                  return DragTarget<MockTask>(
                    onWillAcceptWithDetails: (details) => true,
                    onAcceptWithDetails: (details) {
                      moveTaskToColumn(details.data, columnName);
                    },
                    builder: (context, candidateData, rejectedData) {
                      final isHovering = candidateData.isNotEmpty;

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 310,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isHovering
                              ? const Color(0xFFEDE9FE)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(
                            color: isHovering
                                ? const Color(0xFF7C3AED)
                                : const Color(0xFFE5E7EB),
                            width: 1.3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _ColumnHeader(
                              title: columnName,
                              count: columnTasks.length,
                              index: index,
                            ),
                            const SizedBox(height: 14),

                            Expanded(
                              child: columnTasks.isEmpty
                                  ? _EmptyColumn(columnName: columnName)
                                  : ListView.separated(
                                itemCount: columnTasks.length,
                                separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                                itemBuilder: (context, taskIndex) {
                                  final task = columnTasks[taskIndex];

                                  final taskWidget = GestureDetector(
                                    onTap: () => openTaskDetail(task),
                                    child: _TaskCard(task: task),
                                  );

                                  if (!RolePermissions.canManageBoard(widget.user)) {
                                    return taskWidget;
                                  }

                                  return LongPressDraggable<MockTask>(
                                    data: task,
                                    feedback: Material(
                                      color: Colors.transparent,
                                      child: SizedBox(
                                        width: 280,
                                        child: _TaskCard(
                                          task: task,
                                          isDragging: true,
                                        ),
                                      ),
                                    ),
                                    childWhenDragging: Opacity(
                                      opacity: 0.35,
                                      child: _TaskCard(task: task),
                                    ),
                                    child: taskWidget,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BoardHeader extends StatelessWidget {
  final String projectName;
  final String projectCode;
  final int totalTasks;
  final int doneTasks;
  final VoidCallback onBack;
  final VoidCallback onSettingsTap;
  final VoidCallback onApprovalTap;
  final bool canConfigureBoard;
  final bool canApproveRequirements;
  final int approvalCount;

  const _BoardHeader({
    required this.projectName,
    required this.projectCode,
    required this.totalTasks,
    required this.doneTasks,
    required this.onBack,
    required this.onSettingsTap,
    required this.onApprovalTap,
    required this.canConfigureBoard,
    required this.canApproveRequirements,
    required this.approvalCount,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalTasks == 0 ? 0.0 : doneTasks / totalTasks;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF2563EB),
            Color(0xFF9333EA),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          Row(
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      projectCode,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      projectName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              if (canApproveRequirements) ...[
                InkWell(
                  onTap: onApprovalTap,
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.fact_check_rounded,
                          color: Colors.white,
                        ),
                      ),
                      if (approvalCount > 0)
                        Positioned(
                          top: -6,
                          right: -6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF97316),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '$approvalCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
              ],

              if (canConfigureBoard)
                InkWell(
                  onTap: onSettingsTap,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$doneTasks/$totalTasks done',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ColumnHeader extends StatelessWidget {
  final String title;
  final int count;
  final int index;

  const _ColumnHeader({
    required this.title,
    required this.count,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getColumnColor(index);

    return Row(
      children: [
        Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  Color _getColumnColor(int index) {
    final colors = [
      const Color(0xFF64748B),
      const Color(0xFF2563EB),
      const Color(0xFFF59E0B),
      const Color(0xFF22C55E),
    ];

    return colors[index % colors.length];
  }
}

class _TaskCard extends StatelessWidget {
  final MockTask task;
  final bool isDragging;

  const _TaskCard({
    required this.task,
    this.isDragging = false,
  });

  @override
  Widget build(BuildContext context) {
    final progress =
    task.checklistTotal == 0 ? 0.0 : task.checklistDone / task.checklistTotal;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDragging ? const Color(0xFF7C3AED) : const Color(0xFFE5E7EB),
          width: isDragging ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDragging ? 0.14 : 0.05),
            blurRadius: isDragging ? 22 : 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PriorityBadge(priority: task.priority),
          const SizedBox(height: 10),
          Text(
            task.title,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 16,
              height: 1.25,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            task.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              const Icon(
                Icons.checklist_rounded,
                size: 18,
                color: Color(0xFF6B7280),
              ),
              const SizedBox(width: 6),
              Text(
                '${task.checklistDone}/${task.checklistTotal}',
                style: const TextStyle(
                  color: Color(0xFF374151),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
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

          Row(
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: const Color(0xFF6366F1),
                child: Text(
                  task.assigneeAvatar,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  task.assigneeName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF374151),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 16,
                color: Color(0xFF9CA3AF),
              ),
              const SizedBox(width: 4),
              Text(
                '${task.commentCount}',
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: Color(0xFF6B7280),
                ),
                const SizedBox(width: 6),
                Text(
                  'Hạn: ${task.dueDate}',
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
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

class _PriorityBadge extends StatelessWidget {
  final String priority;

  const _PriorityBadge({
    required this.priority,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getPriorityConfig(priority);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: config.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        config.label,
        style: TextStyle(
          color: config.color,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }

  _PriorityConfig _getPriorityConfig(String priority) {
    switch (priority) {
      case 'High':
        return _PriorityConfig(
          label: 'Cao',
          color: const Color(0xFFEF4444),
        );
      case 'Medium':
        return _PriorityConfig(
          label: 'Trung bình',
          color: const Color(0xFFF59E0B),
        );
      default:
        return _PriorityConfig(
          label: 'Thấp',
          color: const Color(0xFF22C55E),
        );
    }
  }
}

class _PriorityConfig {
  final String label;
  final Color color;

  _PriorityConfig({
    required this.label,
    required this.color,
  });
}

class _EmptyColumn extends StatelessWidget {
  final String columnName;

  const _EmptyColumn({
    required this.columnName,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.inbox_outlined,
              color: Color(0xFF9CA3AF),
              size: 38,
            ),
            const SizedBox(height: 10),
            Text(
              'Chưa có task trong "$columnName"',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BoardBottomNavBar extends StatelessWidget {
  final VoidCallback onCalendarTap;
  final VoidCallback onAnalyticsTap;
  final VoidCallback onProfileTap;

  const _BoardBottomNavBar({
    required this.onCalendarTap,
    required this.onAnalyticsTap,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: 1,
      height: 72,
      backgroundColor: Colors.white,
      indicatorColor: const Color(0xFFEDE9FE),
      onDestinationSelected: (index) {
        if (index == 0) {
          AppNavigation.goHome(context);
        }

        if (index == 1) {
          return;
        }

        if (index == 2) {
          onCalendarTap();
        }

        if (index == 3) {
          onAnalyticsTap();
        }

        if (index == 4) {
          onProfileTap();
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Trang chủ',
        ),
        NavigationDestination(
          icon: Icon(Icons.grid_view_outlined),
          selectedIcon: Icon(Icons.grid_view_rounded),
          label: 'Bảng',
        ),
        NavigationDestination(
          icon: Icon(Icons.calendar_month_outlined),
          selectedIcon: Icon(Icons.calendar_month_rounded),
          label: 'Lịch',
        ),
        NavigationDestination(
          icon: Icon(Icons.bar_chart_outlined),
          selectedIcon: Icon(Icons.bar_chart_rounded),
          label: 'Phân tích',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded),
          label: 'Cá nhân',
        ),
      ],
    );
  }
}
