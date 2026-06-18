import 'package:flutter/material.dart';

import '../../data/mock_workspaces.dart';
import '../../services/app_data_service.dart';
import 'admin_widgets.dart';

class AdminProjectManagementScreen extends StatefulWidget {
  const AdminProjectManagementScreen({super.key});

  @override
  State<AdminProjectManagementScreen> createState() =>
      _AdminProjectManagementScreenState();
}

class _AdminProjectManagementScreenState
    extends State<AdminProjectManagementScreen> {
  List<MockWorkspace> workspaces = List.from(mockWorkspaces);
  List<MockProject> projects = List.from(mockProjects);
  final TextEditingController projectSearchController = TextEditingController();
  String selectedWorkspaceFilter = 'all';
  String selectedStatusFilter = 'all';
  String selectedTaskCountFilter = 'all';
  String selectedProjectSort = 'az';
  bool isLoading = true;
  String? errorMessage;

  List<MockProject> get filteredProjects {
    final search = normalizeAdminSearch(projectSearchController.text);
    final result = projects.where((project) {
      final matchWorkspace =
          selectedWorkspaceFilter == 'all' ||
          project.workspaceId == selectedWorkspaceFilter;
      final matchStatus =
          selectedStatusFilter == 'all' ||
          project.status == selectedStatusFilter;
      final matchSearch =
          search.isEmpty ||
          normalizeAdminSearch(project.name).contains(search) ||
          normalizeAdminSearch(project.code).contains(search) ||
          normalizeAdminSearch(
            getWorkspaceName(project.workspaceId),
          ).contains(search);
      final matchTaskCount = switch (selectedTaskCountFilter) {
        'none' => project.totalTasks == 0,
        '1-5' => project.totalTasks >= 1 && project.totalTasks <= 5,
        '6-20' => project.totalTasks >= 6 && project.totalTasks <= 20,
        '21+' => project.totalTasks >= 21,
        _ => true,
      };
      return matchWorkspace && matchStatus && matchSearch && matchTaskCount;
    }).toList();

    result.sort((first, second) {
      return switch (selectedProjectSort) {
        'za' => normalizeAdminSearch(
          second.name,
        ).compareTo(normalizeAdminSearch(first.name)),
        'tasksAsc' => first.totalTasks.compareTo(second.totalTasks),
        'tasksDesc' => second.totalTasks.compareTo(first.totalTasks),
        'progressAsc' => first.progress.compareTo(second.progress),
        'progressDesc' => second.progress.compareTo(first.progress),
        _ => normalizeAdminSearch(
          first.name,
        ).compareTo(normalizeAdminSearch(second.name)),
      };
    });
    return result;
  }

  int get activeProjects {
    return projects.where((project) => project.status == 'Active').length;
  }

  int get archivedProjects {
    return projects.where((project) => project.status == 'Archived').length;
  }

  int get totalTasks {
    return projects.fold(0, (sum, project) => sum + project.totalTasks);
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  void dispose() {
    projectSearchController.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final loadedWorkspaces = await AppDataService.fetchWorkspaces();
      final loadedProjects = await AppDataService.fetchProjects();
      if (!mounted) return;
      setState(() {
        workspaces = loadedWorkspaces;
        projects = loadedProjects;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        workspaces = List.from(mockWorkspaces);
        projects = List.from(mockProjects);
        errorMessage =
            'Chưa kết nối được backend, đang hiển thị project dự phòng.';
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

  Future<void> openProjectForm({MockProject? project}) async {
    if (workspaces.isEmpty) {
      showAdminMessage(context, 'Cần có workspace trước khi tạo project');
      return;
    }

    final isEditMode = project != null;
    final nameController = TextEditingController(text: project?.name ?? '');
    final codeController = TextEditingController(text: project?.code ?? '');
    final descriptionController = TextEditingController(
      text: project?.description ?? '',
    );
    var selectedWorkspaceId = project?.workspaceId ?? workspaces.first.id;
    var selectedDeadline = project == null
        ? DateTime.now().add(const Duration(days: 14))
        : _parseDeadline(project.deadline);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        var isSaving = false;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEditMode ? 'Chỉnh sửa Project' : 'Tạo Project mới',
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: nameController,
                        decoration: adminInputDecoration(
                          label: 'Tên dự án',
                          icon: Icons.title_rounded,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: codeController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: adminInputDecoration(
                          label: 'Mã dự án',
                          icon: Icons.qr_code_2_rounded,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descriptionController,
                        maxLines: 3,
                        decoration: adminInputDecoration(
                          label: 'Mô tả',
                          icon: Icons.description_outlined,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedWorkspaceId,
                        decoration: adminInputDecoration(
                          label: 'Workspace',
                          icon: Icons.workspaces_outline,
                        ),
                        items: workspaces.map((workspace) {
                          return DropdownMenuItem(
                            value: workspace.id,
                            child: Text(workspace.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setSheetState(() {
                            selectedWorkspaceId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: selectedDeadline,
                            firstDate: DateTime.now().subtract(
                              const Duration(days: 365),
                            ),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365 * 2),
                            ),
                          );
                          if (pickedDate == null) return;
                          setSheetState(() {
                            selectedDeadline = pickedDate;
                          });
                        },
                        child: InputDecorator(
                          decoration: adminInputDecoration(
                            label: 'Deadline',
                            icon: Icons.calendar_today_outlined,
                          ),
                          child: Text(_formatDeadline(selectedDeadline)),
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: isSaving
                              ? null
                              : () async {
                                  final name = nameController.text.trim();
                                  final code = codeController.text
                                      .trim()
                                      .toUpperCase();
                                  final description = descriptionController.text
                                      .trim();

                                  if (name.isEmpty || code.isEmpty) {
                                    showAdminMessage(
                                      context,
                                      'Tên dự án và mã dự án không được bỏ trống',
                                    );
                                    return;
                                  }

                                  setSheetState(() {
                                    isSaving = true;
                                  });

                                  try {
                                    final savedProject = isEditMode
                                        ? await AppDataService.updateProject(
                                            MockProject(
                                              id: project.id,
                                              workspaceId: selectedWorkspaceId,
                                              name: name,
                                              description: description,
                                              code: code,
                                              deadline: _formatDeadline(
                                                selectedDeadline,
                                              ),
                                              progress: project.progress,
                                              totalTasks: project.totalTasks,
                                              completedTasks:
                                                  project.completedTasks,
                                              members: project.members,
                                              status: project.status,
                                            ),
                                          )
                                        : await AppDataService.createProject(
                                            workspaceId: selectedWorkspaceId,
                                            name: name,
                                            code: code,
                                            description: description,
                                            deadline: _formatDeadline(
                                              selectedDeadline,
                                            ),
                                          );

                                    if (!mounted ||
                                        !bottomSheetContext.mounted) {
                                      return;
                                    }
                                    setState(() {
                                      if (isEditMode) {
                                        final index = projects.indexWhere(
                                          (item) => item.id == savedProject.id,
                                        );
                                        if (index != -1) {
                                          projects[index] = savedProject;
                                        }
                                      } else {
                                        projects.add(savedProject);
                                      }
                                    });

                                    Navigator.pop(bottomSheetContext);
                                    showAdminMessage(
                                      context,
                                      isEditMode
                                          ? 'Đã cập nhật project'
                                          : 'Đã tạo project mới',
                                    );
                                  } catch (error) {
                                    if (!mounted ||
                                        !bottomSheetContext.mounted) {
                                      return;
                                    }
                                    setSheetState(() {
                                      isSaving = false;
                                    });
                                    showAdminMessage(
                                      context,
                                      'Không thể lưu project: $error',
                                    );
                                  }
                                },
                          icon: isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(
                                  isEditMode
                                      ? Icons.save_rounded
                                      : Icons.add_rounded,
                                ),
                          label: Text(
                            isEditMode ? 'Lưu thay đổi' : 'Tạo project',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7C3AED),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
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
              ),
            );
          },
        );
      },
    );

    nameController.dispose();
    codeController.dispose();
    descriptionController.dispose();
  }

  Future<void> toggleArchiveProject(MockProject project) async {
    final newStatus = project.status == 'Active' ? 'Archived' : 'Active';
    final updatedProject = _copyProject(project, status: newStatus);
    final index = projects.indexWhere((item) => item.id == project.id);
    if (index == -1) return;

    setState(() {
      projects[index] = updatedProject;
    });

    try {
      final savedProject = await AppDataService.updateProject(updatedProject);
      if (!mounted) return;
      setState(() {
        projects[index] = savedProject;
      });
      showAdminMessage(
        context,
        newStatus == 'Archived' ? 'Đã archive project' : 'Đã khôi phục project',
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        projects[index] = project;
      });
      showAdminMessage(context, 'Không thể cập nhật project: $error');
    }
  }

  Future<void> deleteProject(MockProject project) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text('Xóa Project'),
          content: Text(
            project.totalTasks > 0
                ? 'Project "${project.name}" có ${project.totalTasks} task. Xóa project sẽ xóa task liên quan trong database. Bạn chắc chắn chứ?'
                : 'Bạn có chắc muốn xóa project "${project.name}" không?',
          ),
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
      await AppDataService.deleteProject(project.id);
      if (!mounted) return;
      setState(() {
        projects.removeWhere((item) => item.id == project.id);
      });
      showAdminMessage(context, 'Đã xóa project');
    } catch (error) {
      if (!mounted) return;
      showAdminMessage(context, 'Không thể xóa project: $error');
    }
  }

  void showProjectDetail(MockProject project) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
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
                  const CircleAvatar(
                    radius: 34,
                    backgroundColor: Color(0xFF7C3AED),
                    child: Icon(Icons.folder_open_rounded, color: Colors.white),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    project.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${project.code} - ${getWorkspaceName(project.workspaceId)}',
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
                        label: 'Tổng task',
                        value: '${project.totalTasks}',
                        icon: Icons.task_alt_rounded,
                        color: const Color(0xFF2563EB),
                      ),
                      AdminStat(
                        label: 'Hoàn thành',
                        value: '${project.completedTasks}',
                        icon: Icons.check_circle_rounded,
                        color: const Color(0xFF22C55E),
                      ),
                      AdminStat(
                        label: 'Tiến độ',
                        value: '${(project.progress * 100).round()}%',
                        icon: Icons.trending_up_rounded,
                        color: const Color(0xFF7C3AED),
                      ),
                      AdminStat(
                        label: 'Trạng thái',
                        value: project.status,
                        icon: Icons.verified_rounded,
                        color: const Color(0xFFF59E0B),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  AdminCard(
                    child: Text(
                      project.description.isEmpty
                          ? 'Chưa có mô tả cho project này.'
                          : project.description,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleProjects = filteredProjects;

    return AdminScreenScaffold(
      title: 'Quản lý Project',
      icon: Icons.folder_open_rounded,
      floatingActionButton: FloatingActionButton(
        onPressed: () => openProjectForm(),
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded, size: 30),
      ),
      child: RefreshIndicator(
        onRefresh: loadData,
        child: isLoading
            ? const AdminLoading()
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 90),
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
                          icon: Icons.folder_copy_rounded,
                          color: const Color(0xFF7C3AED),
                        ),
                        AdminStat(
                          label: 'Active',
                          value: '$activeProjects',
                          icon: Icons.play_circle_outline_rounded,
                          color: const Color(0xFF22C55E),
                        ),
                        AdminStat(
                          label: 'Archived',
                          value: '$archivedProjects',
                          icon: Icons.archive_outlined,
                          color: const Color(0xFF6B7280),
                        ),
                        AdminStat(
                          label: 'Task',
                          value: '$totalTasks',
                          icon: Icons.task_alt_rounded,
                          color: const Color(0xFFF59E0B),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _FilterPanel(
                      workspaces: workspaces,
                      searchController: projectSearchController,
                      selectedWorkspaceFilter: selectedWorkspaceFilter,
                      selectedStatusFilter: selectedStatusFilter,
                      selectedTaskCountFilter: selectedTaskCountFilter,
                      selectedSort: selectedProjectSort,
                      onSearchChanged: (_) => setState(() {}),
                      onWorkspaceChanged: (value) {
                        setState(() {
                          selectedWorkspaceFilter = value;
                        });
                      },
                      onStatusChanged: (value) {
                        setState(() {
                          selectedStatusFilter = value;
                        });
                      },
                      onTaskCountChanged: (value) {
                        setState(() {
                          selectedTaskCountFilter = value;
                        });
                      },
                      onSortChanged: (value) {
                        setState(() {
                          selectedProjectSort = value;
                        });
                      },
                    ),
                    const SizedBox(height: 18),
                    AdminSectionTitle(
                      title: 'Danh sách Project',
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
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ProjectAdminCard(
                            project: project,
                            workspaceName: getWorkspaceName(
                              project.workspaceId,
                            ),
                            onView: () => showProjectDetail(project),
                            onEdit: () => openProjectForm(project: project),
                            onArchive: () => toggleArchiveProject(project),
                            onDelete: () => deleteProject(project),
                          ),
                        );
                      }),
                  ],
                ),
              ),
      ),
    );
  }

  MockProject _copyProject(MockProject project, {String? status}) {
    return MockProject(
      id: project.id,
      workspaceId: project.workspaceId,
      name: project.name,
      description: project.description,
      code: project.code,
      deadline: project.deadline,
      progress: project.progress,
      totalTasks: project.totalTasks,
      completedTasks: project.completedTasks,
      members: project.members,
      status: status ?? project.status,
    );
  }

  DateTime _parseDeadline(String value) {
    final parts = value.split('/');
    if (parts.length == 3) {
      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }
    return DateTime.now().add(const Duration(days: 14));
  }

  String _formatDeadline(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

class _FilterPanel extends StatelessWidget {
  final List<MockWorkspace> workspaces;
  final TextEditingController searchController;
  final String selectedWorkspaceFilter;
  final String selectedStatusFilter;
  final String selectedTaskCountFilter;
  final String selectedSort;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onWorkspaceChanged;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onTaskCountChanged;
  final ValueChanged<String> onSortChanged;

  const _FilterPanel({
    required this.workspaces,
    required this.searchController,
    required this.selectedWorkspaceFilter,
    required this.selectedStatusFilter,
    required this.selectedTaskCountFilter,
    required this.selectedSort,
    required this.onSearchChanged,
    required this.onWorkspaceChanged,
    required this.onStatusChanged,
    required this.onTaskCountChanged,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: Column(
        children: [
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: adminInputDecoration(
              label: 'Tìm project theo tên',
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
            value: selectedTaskCountFilter,
            decoration: adminInputDecoration(
              label: 'Lọc theo số task',
              icon: Icons.filter_list_rounded,
            ),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('Tất cả số lượng')),
              DropdownMenuItem(value: 'none', child: Text('Chưa có task')),
              DropdownMenuItem(value: '1-5', child: Text('Từ 1 đến 5 task')),
              DropdownMenuItem(value: '6-20', child: Text('Từ 6 đến 20 task')),
              DropdownMenuItem(value: '21+', child: Text('Từ 21 task trở lên')),
            ],
            onChanged: (value) {
              if (value != null) onTaskCountChanged(value);
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: selectedStatusFilter,
            decoration: adminInputDecoration(
              label: 'Lọc theo trạng thái',
              icon: Icons.verified_rounded,
            ),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('Tất cả trạng thái')),
              DropdownMenuItem(value: 'Active', child: Text('Active')),
              DropdownMenuItem(value: 'Archived', child: Text('Archived')),
            ],
            onChanged: (value) {
              if (value != null) onStatusChanged(value);
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: selectedSort,
            decoration: adminInputDecoration(
              label: 'Sắp xếp project',
              icon: Icons.sort_by_alpha_rounded,
            ),
            items: const [
              DropdownMenuItem(value: 'az', child: Text('Tên A → Z')),
              DropdownMenuItem(value: 'za', child: Text('Tên Z → A')),
              DropdownMenuItem(
                value: 'tasksAsc',
                child: Text('Số task tăng dần'),
              ),
              DropdownMenuItem(
                value: 'tasksDesc',
                child: Text('Số task giảm dần'),
              ),
              DropdownMenuItem(
                value: 'progressAsc',
                child: Text('Tiến độ tăng dần'),
              ),
              DropdownMenuItem(
                value: 'progressDesc',
                child: Text('Tiến độ giảm dần'),
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

class _ProjectAdminCard extends StatelessWidget {
  final MockProject project;
  final String workspaceName;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onArchive;
  final VoidCallback onDelete;

  const _ProjectAdminCard({
    required this.project,
    required this.workspaceName,
    required this.onView,
    required this.onEdit,
    required this.onArchive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (project.progress * 100).round();
    final isArchived = project.status == 'Archived';

    return AdminCard(
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: isArchived
                    ? const Color(0xFF6B7280)
                    : const Color(0xFF7C3AED),
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
                label: project.status,
                color: isArchived
                    ? const Color(0xFF6B7280)
                    : const Color(0xFF22C55E),
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
                label: '${project.completedTasks}/${project.totalTasks} task',
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
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: const Text('Sửa'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onArchive,
                  icon: Icon(
                    isArchived
                        ? Icons.unarchive_outlined
                        : Icons.archive_outlined,
                    size: 18,
                  ),
                  label: Text(isArchived ? 'Khôi phục' : 'Archive'),
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
