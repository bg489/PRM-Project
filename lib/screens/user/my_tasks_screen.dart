import 'package:flutter/material.dart';

import '../../data/mock_tasks.dart';
import '../../data/mock_users.dart';
import '../../data/mock_workspaces.dart';
import '../../services/app_data_service.dart';
import '../../utils/search_utils.dart';
import '../task/task_detail_screen.dart';
import 'user_approval_requests_screen.dart';

class MyTasksScreen extends StatefulWidget {
  final MockUser user;

  const MyTasksScreen({super.key, required this.user});

  @override
  State<MyTasksScreen> createState() => _MyTasksScreenState();
}

class _MyTasksScreenState extends State<MyTasksScreen> {
  List<MockTask> myTasks = const [];
  List<MockWorkspace> workspaces = const [];
  List<MockProject> projects = const [];
  final TextEditingController taskSearchController = TextEditingController();
  String selectedWorkspace = 'all';
  String selectedProject = 'all';
  String selectedStatus = 'all';
  String selectedPriority = 'all';
  String selectedChecklistCount = 'all';
  String selectedCommentCount = 'all';
  String selectedTaskSort = 'az';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadMyTasks();
  }

  Future<void> loadMyTasks() async {
    try {
      final fetchedWorkspaces = await AppDataService.fetchWorkspaces();
      final fetchedProjects = await AppDataService.fetchProjects();
      final fetchedTasks = await AppDataService.fetchTasks(
        assigneeId: widget.user.id,
      );
      if (!mounted) return;
      setState(() {
        workspaces = fetchedWorkspaces;
        projects = fetchedProjects;
        myTasks = fetchedTasks;
        isLoading = false;
      });
    } catch (_) {
      final assignedTasks = mockTasks.where((task) {
        return task.assigneeName == widget.user.fullName ||
            task.assigneeAvatar == widget.user.avatarText;
      }).toList();
      if (!mounted) return;
      setState(() {
        workspaces = List.from(mockWorkspaces);
        projects = List.from(mockProjects);
        myTasks = assignedTasks.isNotEmpty
            ? assignedTasks
            : mockTasks
                  .where((task) => task.status != 'Đã xong')
                  .take(5)
                  .toList();
        isLoading = false;
      });
    }
  }

  List<MockTask> get filteredTasks {
    final result = myTasks.where((task) {
      final projectIndex = projects.indexWhere(
        (project) => project.id == task.projectId,
      );
      final project = projectIndex == -1 ? null : projects[projectIndex];
      final workspaceOk =
          selectedWorkspace == 'all' ||
          project?.workspaceId == selectedWorkspace;
      final projectOk =
          selectedProject == 'all' || task.projectId == selectedProject;
      final statusOk = selectedStatus == 'all' || task.status == selectedStatus;
      final priorityOk =
          selectedPriority == 'all' || task.priority == selectedPriority;
      final search = normalizeSearchText(taskSearchController.text);
      final projectName = normalizeSearchText(project?.name ?? '');
      final workspaceName = project == null
          ? ''
          : normalizeSearchText(getWorkspaceName(project.workspaceId));
      final searchOk =
          search.isEmpty ||
          normalizeSearchText(task.title).contains(search) ||
          normalizeSearchText(task.description).contains(search) ||
          projectName.contains(search) ||
          workspaceName.contains(search);
      final checklistOk = switch (selectedChecklistCount) {
        'none' => task.checklistTotal == 0,
        '1-5' => task.checklistTotal >= 1 && task.checklistTotal <= 5,
        '6+' => task.checklistTotal >= 6,
        _ => true,
      };
      final commentOk = switch (selectedCommentCount) {
        'none' => task.commentCount == 0,
        '1-3' => task.commentCount >= 1 && task.commentCount <= 3,
        '4+' => task.commentCount >= 4,
        _ => true,
      };
      return workspaceOk &&
          projectOk &&
          statusOk &&
          priorityOk &&
          searchOk &&
          checklistOk &&
          commentOk;
    }).toList();

    result.sort((first, second) {
      return switch (selectedTaskSort) {
        'za' => normalizeSearchText(
          second.title,
        ).compareTo(normalizeSearchText(first.title)),
        'checklistAsc' => first.checklistTotal.compareTo(second.checklistTotal),
        'checklistDesc' => second.checklistTotal.compareTo(
          first.checklistTotal,
        ),
        'commentsAsc' => first.commentCount.compareTo(second.commentCount),
        'commentsDesc' => second.commentCount.compareTo(first.commentCount),
        _ => normalizeSearchText(
          first.title,
        ).compareTo(normalizeSearchText(second.title)),
      };
    });

    return result;
  }

  List<MockProject> get workspaceProjects {
    if (selectedWorkspace == 'all') return projects;
    return projects
        .where((project) => project.workspaceId == selectedWorkspace)
        .toList();
  }

  String getWorkspaceName(String workspaceId) {
    try {
      return workspaces
          .firstWhere((workspace) => workspace.id == workspaceId)
          .name;
    } catch (_) {
      return '';
    }
  }

  int get completedTasks {
    return myTasks.where((task) => task.status == 'Đã xong').length;
  }

  Future<void> updateTaskStatus(MockTask task, String newStatus) async {
    final previousTasks = List<MockTask>.from(myTasks);
    setState(() {
      myTasks = myTasks.map((item) {
        return item.id == task.id ? item.copyWith(status: newStatus) : item;
      }).toList();
    });

    try {
      final updatedTask = await AppDataService.updateTaskStatus(
        taskId: task.id,
        status: newStatus,
      );
      if (!mounted) return;
      setState(() {
        myTasks = myTasks.map((item) {
          return item.id == updatedTask.id ? updatedTask : item;
        }).toList();
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        myTasks = previousTasks;
      });
      showMessage('Không thể cập nhật trạng thái: $error');
    }
  }

  @override
  void dispose() {
    taskSearchController.dispose();
    super.dispose();
  }

  void openTaskDetail(MockTask task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskDetailScreen(task: task, currentUser: widget.user),
      ),
    );
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
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

    final visibleTasks = filteredTasks;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: Text('Task của ${widget.user.fullName}'),
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UserApprovalRequestsScreen(user: widget.user),
                ),
              );
            },
            icon: const Icon(Icons.fact_check_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadMyTasks,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _StatsCard(
              totalTasks: myTasks.length,
              completedTasks: completedTasks,
              highPriorityTasks: myTasks
                  .where((task) => task.priority == 'High')
                  .length,
            ),
            const SizedBox(height: 16),
            _FilterCard(
              workspaces: workspaces,
              projects: workspaceProjects,
              taskSearchController: taskSearchController,
              selectedWorkspace: selectedWorkspace,
              selectedProject: selectedProject,
              selectedStatus: selectedStatus,
              selectedPriority: selectedPriority,
              selectedChecklistCount: selectedChecklistCount,
              selectedCommentCount: selectedCommentCount,
              selectedTaskSort: selectedTaskSort,
              onWorkspaceChanged: (value) {
                setState(() {
                  selectedWorkspace = value;
                  if (!workspaceProjects.any(
                    (project) => project.id == selectedProject,
                  )) {
                    selectedProject = 'all';
                  }
                });
              },
              onProjectChanged: (value) {
                setState(() {
                  selectedProject = value;
                });
              },
              onStatusChanged: (value) {
                setState(() {
                  selectedStatus = value;
                });
              },
              onPriorityChanged: (value) {
                setState(() {
                  selectedPriority = value;
                });
              },
              onChecklistCountChanged: (value) {
                setState(() {
                  selectedChecklistCount = value;
                });
              },
              onCommentCountChanged: (value) {
                setState(() {
                  selectedCommentCount = value;
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
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Task của tôi',
                    style: TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  '${visibleTasks.length} task',
                  style: const TextStyle(
                    color: Color(0xFF6D28D9),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (visibleTasks.isEmpty)
              const _EmptyState()
            else
              ...visibleTasks.map((task) {
                return _TaskTile(
                  task: task,
                  onTap: () => openTaskDetail(task),
                  onStatusChanged: (status) => updateTaskStatus(task, status),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final int totalTasks;
  final int completedTasks;
  final int highPriorityTasks;

  const _StatsCard({
    required this.totalTasks,
    required this.completedTasks,
    required this.highPriorityTasks,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          _StatItem(label: 'Tổng', value: totalTasks),
          _StatItem(label: 'Đã xong', value: completedTasks),
          _StatItem(label: 'Ưu tiên cao', value: highPriorityTasks),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final int value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$value',
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterCard extends StatelessWidget {
  final List<MockWorkspace> workspaces;
  final List<MockProject> projects;
  final TextEditingController taskSearchController;
  final String selectedWorkspace;
  final String selectedProject;
  final String selectedStatus;
  final String selectedPriority;
  final String selectedChecklistCount;
  final String selectedCommentCount;
  final String selectedTaskSort;
  final ValueChanged<String> onWorkspaceChanged;
  final ValueChanged<String> onProjectChanged;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onPriorityChanged;
  final ValueChanged<String> onChecklistCountChanged;
  final ValueChanged<String> onCommentCountChanged;
  final ValueChanged<String> onSortChanged;
  final ValueChanged<String> onSearchChanged;

  const _FilterCard({
    required this.workspaces,
    required this.projects,
    required this.taskSearchController,
    required this.selectedWorkspace,
    required this.selectedProject,
    required this.selectedStatus,
    required this.selectedPriority,
    required this.selectedChecklistCount,
    required this.selectedCommentCount,
    required this.selectedTaskSort,
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
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            value: selectedWorkspace,
            isExpanded: true,
            decoration: _inputDecoration('Workspace'),
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
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: selectedProject,
            isExpanded: true,
            decoration: _inputDecoration('Project'),
            items: [
              const DropdownMenuItem(
                value: 'all',
                child: Text('Tất cả project'),
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
          TextField(
            controller: taskSearchController,
            onChanged: onSearchChanged,
            decoration: _inputDecoration(
              'Tìm task, project hoặc workspace',
            ).copyWith(prefixIcon: const Icon(Icons.search_rounded)),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: selectedStatus,
            isExpanded: true,
            decoration: _inputDecoration('Trạng thái'),
            items: [
              const DropdownMenuItem(value: 'all', child: Text('Tất cả')),
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
            value: selectedPriority,
            isExpanded: true,
            decoration: _inputDecoration('Priority'),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('Tất cả')),
              DropdownMenuItem(value: 'High', child: Text('Cao')),
              DropdownMenuItem(value: 'Medium', child: Text('Trung bình')),
              DropdownMenuItem(value: 'Low', child: Text('Thấp')),
            ],
            onChanged: (value) {
              if (value != null) onPriorityChanged(value);
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedChecklistCount,
                  isExpanded: true,
                  decoration: _inputDecoration('Checklist'),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                    DropdownMenuItem(value: 'none', child: Text('0 item')),
                    DropdownMenuItem(value: '1-5', child: Text('1 - 5 item')),
                    DropdownMenuItem(value: '6+', child: Text('Từ 6 item')),
                  ],
                  onChanged: (value) {
                    if (value != null) onChecklistCountChanged(value);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedCommentCount,
                  isExpanded: true,
                  decoration: _inputDecoration('Bình luận'),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                    DropdownMenuItem(value: 'none', child: Text('0 comment')),
                    DropdownMenuItem(value: '1-3', child: Text('1 - 3')),
                    DropdownMenuItem(value: '4+', child: Text('Từ 4')),
                  ],
                  onChanged: (value) {
                    if (value != null) onCommentCountChanged(value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: selectedTaskSort,
            isExpanded: true,
            decoration: _inputDecoration('Sắp xếp'),
            items: const [
              DropdownMenuItem(value: 'az', child: Text('Tên A - Z')),
              DropdownMenuItem(value: 'za', child: Text('Tên Z - A')),
              DropdownMenuItem(
                value: 'checklistAsc',
                child: Text('Ít checklist trước'),
              ),
              DropdownMenuItem(
                value: 'checklistDesc',
                child: Text('Nhiều checklist trước'),
              ),
              DropdownMenuItem(
                value: 'commentsAsc',
                child: Text('Ít bình luận trước'),
              ),
              DropdownMenuItem(
                value: 'commentsDesc',
                child: Text('Nhiều bình luận trước'),
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

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFF3F4F6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final MockTask task;
  final VoidCallback onTap;
  final ValueChanged<String> onStatusChanged;

  const _TaskTile({
    required this.task,
    required this.onTap,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final progress = task.checklistTotal == 0
        ? 0.0
        : task.checklistDone / task.checklistTotal;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  task.priority,
                  style: const TextStyle(
                    color: Color(0xFF7C3AED),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              task.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: task.status,
              decoration: const InputDecoration(labelText: 'Trạng thái'),
              items: kanbanColumns.map((status) {
                return DropdownMenuItem(value: status, child: Text(status));
              }).toList(),
              onChanged: (value) {
                if (value != null) onStatusChanged(value);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: const Center(
        child: Text(
          'Không có task nào phù hợp bộ lọc',
          style: TextStyle(
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.055),
        blurRadius: 16,
        offset: const Offset(0, 7),
      ),
    ],
  );
}
