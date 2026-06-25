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
import '../user/my_tasks_screen.dart';
import '../../utils/role_permissions.dart';
import '../../utils/search_utils.dart';
import '../user/user_notifications_screen.dart';
import '../../services/app_data_service.dart';

class WorkspaceDashboardScreen extends StatefulWidget {
  final MockUser user;

  const WorkspaceDashboardScreen({super.key, required this.user});

  @override
  State<WorkspaceDashboardScreen> createState() =>
      _WorkspaceDashboardScreenState();
}

class _WorkspaceDashboardScreenState extends State<WorkspaceDashboardScreen> {
  int selectedWorkspaceIndex = 0;
  List<MockWorkspace> workspaces = List.from(mockWorkspaces);
  List<MockProject> allProjects = List.from(mockProjects);
  final TextEditingController workspaceSearchController =
      TextEditingController();
  final TextEditingController projectSearchController = TextEditingController();
  String selectedWorkspaceProjectCountFilter = 'all';
  String selectedWorkspaceSort = 'az';
  String selectedProjectTaskCountFilter = 'all';
  String selectedProjectSort = 'az';
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    try {
      final fetchedWorkspaces = await AppDataService.fetchWorkspaces();
      final fetchedProjects = await AppDataService.fetchProjects();

      if (!mounted) return;

      setState(() {
        workspaces = fetchedWorkspaces;
        allProjects = fetchedProjects;
        selectedWorkspaceIndex = selectedWorkspaceIndex
            .clamp(0, workspaces.isEmpty ? 0 : workspaces.length - 1)
            .toInt();
        isLoading = false;
        errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = error.toString();
      });
    }
  }

  List<MockWorkspace> get filteredWorkspaces {
    final search = normalizeSearchText(workspaceSearchController.text);
    final result = workspaces.where((workspace) {
      final projectCount = getWorkspaceProjectCount(workspace.id);
      final matchesSearch =
          search.isEmpty ||
          normalizeSearchText(workspace.name).contains(search) ||
          normalizeSearchText(workspace.description).contains(search);
      final matchesProjectCount = switch (selectedWorkspaceProjectCountFilter) {
        'none' => projectCount == 0,
        '1-3' => projectCount >= 1 && projectCount <= 3,
        '4+' => projectCount >= 4,
        _ => true,
      };

      return matchesSearch && matchesProjectCount;
    }).toList();

    result.sort((first, second) {
      return switch (selectedWorkspaceSort) {
        'za' => normalizeSearchText(
          second.name,
        ).compareTo(normalizeSearchText(first.name)),
        'projectsAsc' => getWorkspaceProjectCount(
          first.id,
        ).compareTo(getWorkspaceProjectCount(second.id)),
        'projectsDesc' => getWorkspaceProjectCount(
          second.id,
        ).compareTo(getWorkspaceProjectCount(first.id)),
        _ => normalizeSearchText(
          first.name,
        ).compareTo(normalizeSearchText(second.name)),
      };
    });

    return result;
  }

  int getWorkspaceProjectCount(String workspaceId) {
    return allProjects
        .where((project) => project.workspaceId == workspaceId)
        .length;
  }

  MockWorkspace? selectedWorkspaceFrom(List<MockWorkspace> visibleWorkspaces) {
    if (visibleWorkspaces.isEmpty || workspaces.isEmpty) return null;

    final safeIndex = selectedWorkspaceIndex
        .clamp(0, workspaces.length - 1)
        .toInt();
    final currentWorkspace = workspaces[safeIndex];
    for (final workspace in visibleWorkspaces) {
      if (workspace.id == currentWorkspace.id) {
        return workspace;
      }
    }

    return visibleWorkspaces.first;
  }

  List<MockProject> filteredProjectsForWorkspace(MockWorkspace? workspace) {
    if (workspace == null) return const [];

    final search = normalizeSearchText(projectSearchController.text);
    final result = allProjects.where((project) {
      final matchesWorkspace = project.workspaceId == workspace.id;
      final matchesSearch =
          search.isEmpty ||
          normalizeSearchText(project.name).contains(search) ||
          normalizeSearchText(project.code).contains(search) ||
          normalizeSearchText(project.description).contains(search);
      final matchesTaskCount = switch (selectedProjectTaskCountFilter) {
        'none' => project.totalTasks == 0,
        '1-5' => project.totalTasks >= 1 && project.totalTasks <= 5,
        '6-20' => project.totalTasks >= 6 && project.totalTasks <= 20,
        '21+' => project.totalTasks >= 21,
        _ => true,
      };

      return matchesWorkspace && matchesSearch && matchesTaskCount;
    }).toList();

    result.sort((first, second) {
      return switch (selectedProjectSort) {
        'za' => normalizeSearchText(
          second.name,
        ).compareTo(normalizeSearchText(first.name)),
        'tasksAsc' => first.totalTasks.compareTo(second.totalTasks),
        'tasksDesc' => second.totalTasks.compareTo(first.totalTasks),
        _ => normalizeSearchText(
          first.name,
        ).compareTo(normalizeSearchText(second.name)),
      };
    });

    return result;
  }

  Future<void> openCreateWorkspaceScreen() async {
    final newWorkspace = await Navigator.push<MockWorkspace>(
      context,
      MaterialPageRoute(builder: (_) => const CreateWorkspaceScreen()),
    );

    if (newWorkspace == null) return;

    try {
      final savedWorkspace = await AppDataService.createWorkspace(
        name: newWorkspace.name,
        description: newWorkspace.description,
        iconText: newWorkspace.iconText,
      );

      setState(() {
        workspaces.add(savedWorkspace);
        selectedWorkspaceIndex = workspaces.length - 1;
      });
    } catch (error) {
      showMessage('Không thể tạo workspace: $error');
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã tạo workspace "${newWorkspace.name}"'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> openCreateProjectScreen() async {
    final selectedWorkspace = selectedWorkspaceFrom(filteredWorkspaces);
    if (selectedWorkspace == null) {
      showMessage('Không có workspace phù hợp để tạo dự án.');
      return;
    }

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

    try {
      final savedProject = await AppDataService.createProject(
        workspaceId: selectedWorkspace.id,
        name: newProject.name,
        code: newProject.code,
        description: newProject.description,
        deadline: newProject.deadline,
      );

      setState(() {
        allProjects.add(savedProject);
      });
    } catch (error) {
      showMessage('Không thể tạo dự án: $error');
      return;
    }

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

              if (RolePermissions.canCreateWorkspace(widget.user))
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
                  subtitle: const Text('Chỉ Admin được tạo workspace'),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    openCreateWorkspaceScreen();
                  },
                ),

              if (RolePermissions.canCreateProject(widget.user))
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
                  subtitle: const Text('Manager/Admin được tạo dự án'),
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

  Future<List<MockTask>> loadProjectTasks(String projectId) async {
    try {
      return await AppDataService.fetchTasks(projectId: projectId);
    } catch (_) {
      return getTasksByProject(projectId);
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  void dispose() {
    workspaceSearchController.dispose();
    projectSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F7FB),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (workspaces.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        floatingActionButton: RolePermissions.canCreateWorkspace(widget.user)
            ? FloatingActionButton(
                onPressed: openCreateMenu,
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                child: const Icon(Icons.add_rounded, size: 30),
              )
            : null,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              errorMessage ?? 'Chưa có workspace nào trong hệ thống.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );
    }

    final visibleWorkspaces = filteredWorkspaces;
    final selectedWorkspace = selectedWorkspaceFrom(visibleWorkspaces);
    final workspaceProjects = filteredProjectsForWorkspace(selectedWorkspace);
    final selectedWorkspaceProjectTotal = selectedWorkspace == null
        ? 0
        : getWorkspaceProjectCount(selectedWorkspace.id);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      floatingActionButton:
          RolePermissions.canCreateProject(widget.user) ||
              RolePermissions.canCreateWorkspace(widget.user)
          ? FloatingActionButton(
              onPressed: openCreateMenu,
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              child: const Icon(Icons.add_rounded, size: 30),
            )
          : null,
      bottomNavigationBar: _BottomNavBar(
        onBoardTap: () {
          if (workspaceProjects.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Không có dự án phù hợp bộ lọc để mở bảng'),
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
        onCalendarTap: () async {
          if (workspaceProjects.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Không có dự án phù hợp bộ lọc để xem lịch'),
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }

          final project = workspaceProjects.first;
          final tasks = await loadProjectTasks(project.id);
          if (!context.mounted) return;

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
        onAnalyticsTap: () async {
          if (workspaceProjects.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Không có dự án phù hợp bộ lọc để xem phân tích'),
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }

          final project = workspaceProjects.first;
          final tasks = await loadProjectTasks(project.id);
          if (!context.mounted) return;

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
        onProfileTap: () async {
          if (workspaceProjects.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Không có dự án phù hợp bộ lọc để xem hồ sơ dự án',
                ),
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }

          final project = workspaceProjects.first;
          final tasks = await loadProjectTasks(project.id);
          if (!context.mounted) return;

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
              _Header(
                user: widget.user,
                onMyTasksTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MyTasksScreen(user: widget.user),
                    ),
                  );
                },
                onNotificationsTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          UserNotificationsScreen(user: widget.user),
                    ),
                  );
                },
              ),
              const SizedBox(height: 18),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Không gian làm việc',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF111827),
                        ),
                      ),
                    ),
                    _SoftCountPill(
                      label: '${visibleWorkspaces.length}/${workspaces.length}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _DashboardFilterCard(
                  searchController: workspaceSearchController,
                  searchLabel: 'Tìm workspace theo tên',
                  countLabel: 'Số project',
                  selectedCountFilter: selectedWorkspaceProjectCountFilter,
                  selectedSort: selectedWorkspaceSort,
                  countItems: const [
                    DropdownMenuItem(
                      value: 'all',
                      child: Text('Mọi số project'),
                    ),
                    DropdownMenuItem(value: 'none', child: Text('0 project')),
                    DropdownMenuItem(
                      value: '1-3',
                      child: Text('1 - 3 project'),
                    ),
                    DropdownMenuItem(value: '4+', child: Text('Từ 4 project')),
                  ],
                  sortItems: const [
                    DropdownMenuItem(value: 'az', child: Text('Tên A - Z')),
                    DropdownMenuItem(value: 'za', child: Text('Tên Z - A')),
                    DropdownMenuItem(
                      value: 'projectsAsc',
                      child: Text('Ít project trước'),
                    ),
                    DropdownMenuItem(
                      value: 'projectsDesc',
                      child: Text('Nhiều project trước'),
                    ),
                  ],
                  onSearchChanged: (_) => setState(() {}),
                  onCountChanged: (value) {
                    setState(() {
                      selectedWorkspaceProjectCountFilter = value;
                    });
                  },
                  onSortChanged: (value) {
                    setState(() {
                      selectedWorkspaceSort = value;
                    });
                  },
                ),
              ),
              const SizedBox(height: 12),

              if (visibleWorkspaces.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: _DashboardEmptyState(
                    icon: Icons.workspaces_outline,
                    message: 'Không có workspace phù hợp bộ lọc.',
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: visibleWorkspaces.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final workspace = visibleWorkspaces[index];
                    final isSelected = workspace.id == selectedWorkspace?.id;

                    return GestureDetector(
                      onTap: () {
                        final workspaceIndex = workspaces.indexWhere(
                          (item) => item.id == workspace.id,
                        );
                        if (workspaceIndex == -1) return;

                        setState(() {
                          selectedWorkspaceIndex = workspaceIndex;
                        });
                      },
                      child: _WorkspaceCard(
                        workspace: workspace,
                        isSelected: isSelected,
                        projectCount: getWorkspaceProjectCount(workspace.id),
                      ),
                    );
                  },
                ),

              const SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Dự án đang thực hiện',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                    _SoftCountPill(
                      label:
                          '${workspaceProjects.length}/$selectedWorkspaceProjectTotal dự án',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _DashboardFilterCard(
                  searchController: projectSearchController,
                  searchLabel: 'Tìm project theo tên',
                  countLabel: 'Số task',
                  selectedCountFilter: selectedProjectTaskCountFilter,
                  selectedSort: selectedProjectSort,
                  countItems: const [
                    DropdownMenuItem(value: 'all', child: Text('Mọi số task')),
                    DropdownMenuItem(value: 'none', child: Text('0 task')),
                    DropdownMenuItem(value: '1-5', child: Text('1 - 5 task')),
                    DropdownMenuItem(value: '6-20', child: Text('6 - 20 task')),
                    DropdownMenuItem(value: '21+', child: Text('Từ 21 task')),
                  ],
                  sortItems: const [
                    DropdownMenuItem(value: 'az', child: Text('Tên A - Z')),
                    DropdownMenuItem(value: 'za', child: Text('Tên Z - A')),
                    DropdownMenuItem(
                      value: 'tasksAsc',
                      child: Text('Ít task trước'),
                    ),
                    DropdownMenuItem(
                      value: 'tasksDesc',
                      child: Text('Nhiều task trước'),
                    ),
                  ],
                  onSearchChanged: (_) => setState(() {}),
                  onCountChanged: (value) {
                    setState(() {
                      selectedProjectTaskCountFilter = value;
                    });
                  },
                  onSortChanged: (value) {
                    setState(() {
                      selectedProjectSort = value;
                    });
                  },
                ),
              ),
              const SizedBox(height: 12),

              if (workspaceProjects.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: _DashboardEmptyState(
                    icon: Icons.folder_off_outlined,
                    message: 'Không có project phù hợp bộ lọc.',
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: workspaceProjects.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final project = workspaceProjects[index];
                    return _ProjectCard(
                      project: project,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProjectBoardScreen(
                              project: project,
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
  final VoidCallback onMyTasksTap;
  final VoidCallback onNotificationsTap;

  const _Header({
    required this.user,
    required this.onMyTasksTap,
    required this.onNotificationsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF9333EA)],
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
                  style: TextStyle(color: Colors.white70, fontSize: 14),
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
            onTap: onMyTasksTap,
          ),
          const SizedBox(width: 10),
          _HeaderIcon(
            icon: Icons.notifications_none_rounded,
            badgeText: '3',
            onTap: onNotificationsTap,
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
            child: Icon(icon, color: Colors.white, size: 24),
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

class _DashboardFilterCard extends StatelessWidget {
  final TextEditingController searchController;
  final String searchLabel;
  final String countLabel;
  final String selectedCountFilter;
  final String selectedSort;
  final List<DropdownMenuItem<String>> countItems;
  final List<DropdownMenuItem<String>> sortItems;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onCountChanged;
  final ValueChanged<String> onSortChanged;

  const _DashboardFilterCard({
    required this.searchController,
    required this.searchLabel,
    required this.countLabel,
    required this.selectedCountFilter,
    required this.selectedSort,
    required this.countItems,
    required this.sortItems,
    required this.onSearchChanged,
    required this.onCountChanged,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.055),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: _dashboardInputDecoration(
              searchLabel,
              icon: Icons.search_rounded,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedCountFilter,
                  isExpanded: true,
                  decoration: _dashboardInputDecoration(countLabel),
                  items: countItems,
                  onChanged: (value) {
                    if (value != null) onCountChanged(value);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedSort,
                  isExpanded: true,
                  decoration: _dashboardInputDecoration('Sắp xếp'),
                  items: sortItems,
                  onChanged: (value) {
                    if (value != null) onSortChanged(value);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SoftCountPill extends StatelessWidget {
  final String label;

  const _SoftCountPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE9FE),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF6D28D9),
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _DashboardEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _DashboardEmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF9CA3AF), size: 34),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration _dashboardInputDecoration(String label, {IconData? icon}) {
  return InputDecoration(
    labelText: label,
    prefixIcon: icon == null ? null : Icon(icon),
    filled: true,
    fillColor: const Color(0xFFF3F4F6),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
  );
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
                    ? [const Color(0xFF2563EB), const Color(0xFF9333EA)]
                    : [const Color(0xFF60A5FA), const Color(0xFFA78BFA)],
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

  const _ProjectCard({required this.project, required this.onTap});

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
                const Icon(Icons.trending_up_rounded, color: Color(0xFF22C55E)),
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
                    children: List.generate(project.members.length, (index) {
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
                    }),
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
