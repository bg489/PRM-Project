import 'package:flutter/material.dart';
import '../../data/mock_users.dart';
import '../../data/mock_workspaces.dart';
import '../board/project_board_screen.dart';
import 'create_workspace_screen.dart';
import 'create_project_screen.dart';
import '../../data/mock_tasks.dart';
import '../calendar/calendar_view_screen.dart';
import '../analytics/productivity_analytics_screen.dart';
import '../profile/profile_settings_screen.dart';

class WorkspaceDashboardScreen extends StatefulWidget {
  final MockUser user;

  const WorkspaceDashboardScreen({
    super.key,
    required this.user,
  });

  @override
  State<WorkspaceDashboardScreen> createState() =>
      _WorkspaceDashboardScreenState();
}

class _WorkspaceDashboardScreenState extends State<WorkspaceDashboardScreen> {
  int selectedWorkspaceIndex = 0;
  List<MockWorkspace> workspaces = List.from(mockWorkspaces);
  List<MockProject> allProjects = List.from(mockProjects);
  @override
  void initState() {
    super.initState();
    workspaces = List.from(mockWorkspaces);
  }

  Future<void> openCreateWorkspaceScreen() async {
    final newWorkspace = await Navigator.push<MockWorkspace>(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateWorkspaceScreen(),
      ),
    );

    if (newWorkspace == null) return;

    setState(() {
      workspaces.add(newWorkspace);
      selectedWorkspaceIndex = workspaces.length - 1;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã tạo workspace "${newWorkspace.name}"'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> openCreateProjectScreen() async {
    final selectedWorkspace = workspaces[selectedWorkspaceIndex];

    final newProject = await Navigator.push<MockProject>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateProjectScreen(
          workspaceId: selectedWorkspace.id,
          workspaceName: selectedWorkspace.name,
        ),
      ),
    );

    if (newProject == null) return;

    setState(() {
      allProjects.add(newProject);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã tạo dự án "${newProject.name}"'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void openCreateMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Bạn muốn tạo gì?',
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),

              ListTile(
                leading: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE9FE),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.workspaces_rounded,
                    color: Color(0xFF7C3AED),
                  ),
                ),
                title: const Text(
                  'Tạo workspace',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: const Text('Tạo không gian làm việc mới'),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  openCreateWorkspaceScreen();
                },
              ),

              const SizedBox(height: 8),

              ListTile(
                leading: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDBEAFE),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.folder_open_rounded,
                    color: Color(0xFF2563EB),
                  ),
                ),
                title: const Text(
                  'Tạo dự án',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: const Text('Tạo dự án trong workspace đang chọn'),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  openCreateProjectScreen();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedWorkspace = workspaces[selectedWorkspaceIndex];
    final workspaceProjects = allProjects
        .where((project) => project.workspaceId == selectedWorkspace.id)
        .toList();
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      floatingActionButton: FloatingActionButton(
        onPressed: openCreateMenu,
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded, size: 30),
      ),
      bottomNavigationBar: _BottomNavBar(
        onBoardTap: () {
          if (workspaceProjects.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Workspace này chưa có dự án để mở bảng'),
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProjectBoardScreen(
                project: workspaceProjects.first,
                user: widget.user,
              ),
            ),
          );
        },
        onCalendarTap: () {
          if (workspaceProjects.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Workspace này chưa có dự án để xem lịch'),
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }

          final project = workspaceProjects.first;
          final tasks = getTasksByProject(project.id);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CalendarViewScreen(
                user: widget.user,
                project: project,
                tasks: tasks,
              ),
            ),
          );
        },
        onAnalyticsTap: () {
          if (workspaceProjects.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Workspace này chưa có dự án để xem phân tích'),
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }

          final project = workspaceProjects.first;
          final tasks = getTasksByProject(project.id);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductivityAnalyticsScreen(
                user: widget.user,
                project: project,
                tasks: tasks,
              ),
            ),
          );
        },
        onProfileTap: () {
          if (workspaceProjects.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Workspace này chưa có dự án để xem hồ sơ dự án'),
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }

          final project = workspaceProjects.first;
          final tasks = getTasksByProject(project.id);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProfileSettingsScreen(
                user: widget.user,
                project: project,
                tasks: tasks,
              ),
            ),
          );
        },
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 90),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(user: widget.user),
              const SizedBox(height: 18),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Không gian làm việc',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF111827),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: workspaces.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final workspace = workspaces[index];
                  final isSelected = selectedWorkspaceIndex == index;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedWorkspaceIndex = index;
                      });
                    },
                    child: _WorkspaceCard(
                      workspace: workspace,
                      isSelected: isSelected,
                      projectCount: allProjects
                          .where((project) => project.workspaceId == workspace.id)
                          .length,
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Text(
                      'Dự án đang thực hiện',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
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
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${workspaceProjects.length} dự án',
                        style: const TextStyle(
                          color: Color(0xFF6D28D9),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: workspaceProjects.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  return _ProjectCard(
                    project: workspaceProjects[index],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProjectBoardScreen(
                            project: workspaceProjects[index],
                            user: widget.user,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final MockUser user;

  const _Header({
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
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
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.white.withOpacity(0.22),
            child: Text(
              user.avatarText,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Xin chào,',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                Text(
                  user.fullName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          _HeaderIcon(
            icon: Icons.task_alt_rounded,
            badgeText: '3',
            onTap: () {},
          ),
          const SizedBox(width: 10),
          _HeaderIcon(
            icon: Icons.notifications_none_rounded,
            badgeText: '2',
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  final String badgeText;
  final VoidCallback onTap;

  const _HeaderIcon({
    required this.icon,
    required this.badgeText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
        Positioned(
          top: -5,
          right: -5,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF97316),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              badgeText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _WorkspaceCard extends StatelessWidget {
  final MockWorkspace workspace;
  final bool isSelected;
  final int projectCount;

  const _WorkspaceCard({
    required this.workspace,
    required this.isSelected,
    required this.projectCount,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isSelected ? const Color(0xFF7C3AED) : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isSelected
                    ? [
                  const Color(0xFF2563EB),
                  const Color(0xFF9333EA),
                ]
                    : [
                  const Color(0xFF60A5FA),
                  const Color(0xFFA78BFA),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Text(
                workspace.iconText,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  workspace.name,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    const Icon(
                      Icons.group_outlined,
                      size: 16,
                      color: Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${workspace.memberCount} thành viên',
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.folder_open_outlined,
                      size: 16,
                      color: Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$projectCount dự án',
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            isSelected
                ? Icons.check_circle_rounded
                : Icons.chevron_right_rounded,
            color: isSelected
                ? const Color(0xFF7C3AED)
                : const Color(0xFF9CA3AF),
          ),
        ],
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final MockProject project;
  final VoidCallback onTap;

  const _ProjectCard({
    required this.project,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (project.progress * 100).round();

    return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Container(
          padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  project.name,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Icon(
                Icons.trending_up_rounded,
                color: Color(0xFF22C55E),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            project.code,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),

          Row(
            children: [
              const Text(
                'Tiến độ',
                style: TextStyle(
                  color: Color(0xFF374151),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '$percent%',
                style: const TextStyle(
                  color: Color(0xFF2563EB),
                  fontWeight: FontWeight.w800,
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

          const SizedBox(height: 18),

          Row(
            children: [
              SizedBox(
                height: 30,
                width: 120,
                child: Stack(
                  children: List.generate(
                    project.members.length,
                        (index) {
                      return Positioned(
                        left: index * 22,
                        child: CircleAvatar(
                          radius: 15,
                          backgroundColor: _avatarColor(index),
                          child: Text(
                            project.members[index],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Hạn: ${project.deadline}',
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${project.completedTasks}/${project.totalTasks} tasks',
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
        ),
    );
  }

  Color _avatarColor(int index) {
    final colors = [
      const Color(0xFF818CF8),
      const Color(0xFF60A5FA),
      const Color(0xFFC084FC),
      const Color(0xFFF472B6),
      const Color(0xFF34D399),
    ];

    return colors[index % colors.length];
  }
}

class _BottomNavBar extends StatelessWidget {
  final VoidCallback onBoardTap;
  final VoidCallback onCalendarTap;
  final VoidCallback onAnalyticsTap;
  final VoidCallback onProfileTap;

  const _BottomNavBar({
    required this.onBoardTap,
    required this.onCalendarTap,
    required this.onAnalyticsTap,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: 0,
      height: 72,
      backgroundColor: Colors.white,
      indicatorColor: const Color(0xFFEDE9FE),
      onDestinationSelected: (index) {
        if (index == 0) {
          return;
        }

        if (index == 1) {
          onBoardTap();
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