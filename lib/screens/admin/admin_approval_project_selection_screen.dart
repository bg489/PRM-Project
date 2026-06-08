import 'package:flutter/material.dart';

import '../../data/mock_tasks.dart';
import '../../data/mock_workspaces.dart';
import '../approval/requirements_approval_screen.dart';

class AdminApprovalProjectSelectionScreen extends StatefulWidget {
  const AdminApprovalProjectSelectionScreen({super.key});

  @override
  State<AdminApprovalProjectSelectionScreen> createState() =>
      _AdminApprovalProjectSelectionScreenState();
}

class _AdminApprovalProjectSelectionScreenState
    extends State<AdminApprovalProjectSelectionScreen> {
  List<MockProject> projects = List.from(mockProjects);
  List<MockWorkspace> workspaces = List.from(mockWorkspaces);

  String selectedWorkspaceFilter = 'all';

  List<MockProject> get filteredProjects {
    return projects.where((project) {
      return selectedWorkspaceFilter == 'all' ||
          project.workspaceId == selectedWorkspaceFilter;
    }).toList();
  }

  String getWorkspaceName(String workspaceId) {
    try {
      return workspaces.firstWhere((item) => item.id == workspaceId).name;
    } catch (_) {
      return 'Không rõ workspace';
    }
  }

  List<MockTask> getProjectTasks(String projectId) {
    return getTasksByProject(projectId);
  }

  int getPendingApprovalCount(String projectId) {
    final tasks = getProjectTasks(projectId);

    return tasks.where((task) => task.status != 'Đã xong').length;
  }

  void openApprovalScreen(MockProject project) {
    final tasks = getProjectTasks(project.id);

    if (tasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Project này chưa có task để duyệt yêu cầu'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RequirementsApprovalScreen(
          project: project,
          tasks: tasks,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleProjects = filteredProjects;

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
                      totalProjects: projects.length,
                      totalPending: projects.fold(
                        0,
                            (sum, project) =>
                        sum + getPendingApprovalCount(project.id),
                      ),
                    ),

                    const SizedBox(height: 20),

                    _FilterPanel(
                      workspaces: workspaces,
                      selectedWorkspaceFilter: selectedWorkspaceFilter,
                      onWorkspaceChanged: (value) {
                        setState(() {
                          selectedWorkspaceFilter = value;
                        });
                      },
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Chọn Project cần duyệt',
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
                            '${visibleProjects.length} project',
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
                      'Admin chọn một project để xem danh sách yêu cầu kỹ thuật đang chờ duyệt.',
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 16),

                    if (visibleProjects.isEmpty)
                      const _EmptyProjectList()
                    else
                      ...visibleProjects.map((project) {
                        final tasks = getProjectTasks(project.id);
                        final pendingCount =
                        getPendingApprovalCount(project.id);

                        return _ApprovalProjectCard(
                          project: project,
                          workspaceName: getWorkspaceName(project.workspaceId),
                          taskCount: tasks.length,
                          pendingCount: pendingCount,
                          onTap: () => openApprovalScreen(project),
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
              'Chọn Project duyệt',
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
              Icons.fact_check_rounded,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewPanel extends StatelessWidget {
  final int totalProjects;
  final int totalPending;

  const _OverviewPanel({
    required this.totalProjects,
    required this.totalPending,
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
                Icons.approval_rounded,
                color: Colors.white,
                size: 30,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tổng quan duyệt yêu cầu',
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
                  label: 'Project',
                  value: '$totalProjects',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _OverviewMiniStat(
                  label: 'Chờ duyệt',
                  value: '$totalPending',
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
        horizontal: 10,
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
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterPanel extends StatelessWidget {
  final List<MockWorkspace> workspaces;
  final String selectedWorkspaceFilter;
  final ValueChanged<String> onWorkspaceChanged;

  const _FilterPanel({
    required this.workspaces,
    required this.selectedWorkspaceFilter,
    required this.onWorkspaceChanged,
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
                'Lọc theo Workspace',
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
            value: selectedWorkspaceFilter,
            decoration: InputDecoration(
              hintText: 'Chọn workspace',
              prefixIcon: const Icon(Icons.workspaces_outline),
              filled: true,
              fillColor: const Color(0xFFF3F4F6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
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
              if (value == null) return;
              onWorkspaceChanged(value);
            },
          ),
        ],
      ),
    );
  }
}

class _ApprovalProjectCard extends StatelessWidget {
  final MockProject project;
  final String workspaceName;
  final int taskCount;
  final int pendingCount;
  final VoidCallback onTap;

  const _ApprovalProjectCard({
    required this.project,
    required this.workspaceName,
    required this.taskCount,
    required this.pendingCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (project.progress * 100).round();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF2563EB),
                        Color(0xFF9333EA),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.folder_open_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.name,
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${project.code} • $workspaceName',
                        maxLines: 1,
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: pendingCount > 0
                        ? const Color(0xFFFFEDD5)
                        : const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    pendingCount > 0 ? '$pendingCount chờ' : 'Đã ổn',
                    style: TextStyle(
                      color: pendingCount > 0
                          ? const Color(0xFFF97316)
                          : const Color(0xFF16A34A),
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                const Text(
                  'Tiến độ',
                  style: TextStyle(
                    color: Color(0xFF374151),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Text(
                  '$percent%',
                  style: const TextStyle(
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: project.progress,
                minHeight: 8,
                backgroundColor: const Color(0xFFE5E7EB),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF2563EB),
                ),
              ),
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                _SmallInfoChip(
                  icon: Icons.task_alt_rounded,
                  label: '$taskCount task',
                ),
                const SizedBox(width: 8),
                _SmallInfoChip(
                  icon: Icons.calendar_today_outlined,
                  label: project.deadline,
                ),
              ],
            ),

            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.fact_check_rounded),
                label: const Text('Mở danh sách duyệt'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
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

class _EmptyProjectList extends StatelessWidget {
  const _EmptyProjectList();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: const Column(
        children: [
          Icon(
            Icons.folder_off_outlined,
            size: 46,
            color: Color(0xFF9CA3AF),
          ),
          SizedBox(height: 10),
          Text(
            'Không có project nào phù hợp bộ lọc',
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