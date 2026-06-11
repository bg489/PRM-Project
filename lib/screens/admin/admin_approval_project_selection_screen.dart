import 'package:flutter/material.dart';

import '../../data/mock_approval_requests.dart';
import '../../data/mock_workspaces.dart';
import '../../services/app_data_service.dart';
import '../approval/requirements_approval_screen.dart';
import 'admin_widgets.dart';

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
  List<MockApprovalRequest> approvalRequests = List.from(mockApprovalRequests);
  String selectedWorkspaceFilter = 'all';
  bool isLoading = true;
  String? errorMessage;

  List<MockProject> get filteredProjects {
    return projects.where((project) {
      return selectedWorkspaceFilter == 'all' ||
          project.workspaceId == selectedWorkspaceFilter;
    }).toList();
  }

  int get waitingTotal {
    return approvalRequests.where((request) => request.status == 'WAITING').length;
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
      final loadedRequests = await AppDataService.fetchApprovalRequests();
      if (!mounted) return;
      setState(() {
        workspaces = loadedWorkspaces;
        projects = loadedProjects;
        approvalRequests = loadedRequests;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        workspaces = List.from(mockWorkspaces);
        projects = List.from(mockProjects);
        approvalRequests = List.from(mockApprovalRequests);
        errorMessage = 'Chưa kết nối được backend, đang hiển thị yêu cầu dự phòng.';
        isLoading = false;
      });
    }
  }

  String getWorkspaceName(String workspaceId) {
    try {
      return workspaces.firstWhere((item) => item.id == workspaceId).name;
    } catch (_) {
      return 'Không rõ workspace';
    }
  }

  int getPendingApprovalCount(String projectId) {
    return approvalRequests
        .where((request) =>
            request.projectId == projectId && request.status == 'WAITING')
        .length;
  }

  void openApprovalScreen(MockProject project) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RequirementsApprovalScreen(project: project),
      ),
    ).then((_) => loadData());
  }

  @override
  Widget build(BuildContext context) {
    final workspaceById = <String, MockWorkspace>{};

    for (final workspace in workspaces) {
      workspaceById[workspace.id] = workspace;
    }

    final workspaceList = workspaceById.values.toList();

    final safeWorkspaceFilter =
    selectedWorkspaceFilter == 'all' ||
        workspaceById.containsKey(selectedWorkspaceFilter)
        ? selectedWorkspaceFilter
        : 'all';

    final visibleProjects = projects.where((project) {
      return safeWorkspaceFilter == 'all' ||
          project.workspaceId == safeWorkspaceFilter;
    }).toList();

    return AdminScreenScaffold(
      title: 'Chọn Project duyệt',
      icon: Icons.fact_check_rounded,
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
                          label: 'Project',
                          value: '${projects.length}',
                          icon: Icons.folder_open_rounded,
                          color: const Color(0xFF7C3AED),
                        ),
                        AdminStat(
                          label: 'Chờ duyệt',
                          value: '$waitingTotal',
                          icon: Icons.hourglass_top_rounded,
                          color: const Color(0xFFF59E0B),
                        ),
                        AdminStat(
                          label: 'Đã duyệt',
                          value:
                              "${approvalRequests.where((item) => item.status == 'APPROVED').length}",
                          icon: Icons.check_circle_rounded,
                          color: const Color(0xFF22C55E),
                        ),
                        AdminStat(
                          label: 'Từ chối',
                          value:
                              "${approvalRequests.where((item) => item.status == 'REJECTED').length}",
                          icon: Icons.cancel_rounded,
                          color: const Color(0xFFEF4444),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    AdminCard(
                      child: DropdownButtonFormField<String>(
                        value: safeWorkspaceFilter,
                        decoration: adminInputDecoration(
                          label: 'Lọc theo Workspace',
                          icon: Icons.workspaces_outline,
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: 'all',
                            child: Text('Tất cả Workspace'),
                          ),
                          ...workspaceList.map((workspace) {
                            return DropdownMenuItem<String>(
                              value: workspace.id,
                              child: Text(workspace.name),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            selectedWorkspaceFilter = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 18),
                    AdminSectionTitle(
                      title: 'Chọn Project cần duyệt',
                      countLabel: '${visibleProjects.length} project',
                    ),
                    const SizedBox(height: 14),
                    if (visibleProjects.isEmpty)
                      const AdminEmptyState(
                        icon: Icons.folder_off_outlined,
                        message: 'Không có project nào phù hợp bộ lọc.',
                      )
                    else
                      ...visibleProjects.map((project) {
                        final pendingCount = getPendingApprovalCount(project.id);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ApprovalProjectCard(
                            project: project,
                            workspaceName: getWorkspaceName(project.workspaceId),
                            pendingCount: pendingCount,
                            onTap: () => openApprovalScreen(project),
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

class _ApprovalProjectCard extends StatelessWidget {
  final MockProject project;
  final String workspaceName;
  final int pendingCount;
  final VoidCallback onTap;

  const _ApprovalProjectCard({
    required this.project,
    required this.workspaceName,
    required this.pendingCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (project.progress * 100).round();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: AdminCard(
        child: Column(
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Color(0xFF7C3AED),
                  child: Icon(Icons.folder_open_rounded, color: Colors.white),
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
                        '${project.code} - $workspaceName',
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
                AdminPill(
                  label: pendingCount > 0 ? '$pendingCount chờ' : 'Ổn',
                  color: pendingCount > 0
                      ? const Color(0xFFF97316)
                      : const Color(0xFF16A34A),
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
                value: project.progress.clamp(0.0, 1.0).toDouble(),
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
                AdminPill(
                  label: '${project.totalTasks} task',
                  color: const Color(0xFF2563EB),
                ),
                const SizedBox(width: 8),
                AdminPill(
                  label: project.deadline,
                  color: const Color(0xFFF59E0B),
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
                  textStyle: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
