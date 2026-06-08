import 'package:flutter/material.dart';

import '../../data/mock_workspaces.dart';

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

  String selectedWorkspaceFilter = 'all';
  String selectedStatusFilter = 'all';

  List<MockProject> get filteredProjects {
    return projects.where((project) {
      final matchWorkspace = selectedWorkspaceFilter == 'all' ||
          project.workspaceId == selectedWorkspaceFilter;

      final matchStatus = selectedStatusFilter == 'all' ||
          project.status == selectedStatusFilter;

      return matchWorkspace && matchStatus;
    }).toList();
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

  String getWorkspaceName(String workspaceId) {
    try {
      return workspaces.firstWhere((item) => item.id == workspaceId).name;
    } catch (_) {
      return 'Không rõ workspace';
    }
  }

  void openProjectForm({
    MockProject? project,
    int? index,
  }) {
    final isEditMode = project != null;

    final nameController = TextEditingController(text: project?.name ?? '');
    final codeController = TextEditingController(text: project?.code ?? '');

    String selectedWorkspaceId = project?.workspaceId ?? workspaces.first.id;
    DateTime selectedDeadline =
    project == null ? DateTime.now().add(const Duration(days: 14)) : _parseDeadline(project.deadline);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
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
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
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

                      Text(
                        isEditMode ? 'Chỉnh sửa Project' : 'Tạo Project mới',
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),

                      const SizedBox(height: 18),

                      const _FieldLabel(
                        label: 'Tên dự án',
                        requiredField: true,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: nameController,
                        decoration: _inputDecoration(
                          hintText: 'Ví dụ: Mobile App v3.0',
                          icon: Icons.title_rounded,
                        ),
                      ),

                      const SizedBox(height: 16),

                      const _FieldLabel(
                        label: 'Mã dự án',
                        requiredField: true,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: codeController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: _inputDecoration(
                          hintText: 'Ví dụ: MOB-003',
                          icon: Icons.qr_code_2_rounded,
                        ),
                      ),

                      const SizedBox(height: 16),

                      const _FieldLabel(label: 'Workspace'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: selectedWorkspaceId,
                        decoration: _inputDecoration(
                          hintText: 'Chọn workspace',
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

                      const SizedBox(height: 16),

                      const _FieldLabel(label: 'Deadline'),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: selectedDeadline,
                            firstDate: DateTime.now()
                                .subtract(const Duration(days: 365)),
                            lastDate: DateTime.now()
                                .add(const Duration(days: 365 * 2)),
                          );

                          if (pickedDate == null) return;

                          setSheetState(() {
                            selectedDeadline = pickedDate;
                          });
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_outlined,
                                color: Color(0xFF7C3AED),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _formatDeadline(selectedDeadline),
                                  style: const TextStyle(
                                    color: Color(0xFF111827),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: Color(0xFF9CA3AF),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final name = nameController.text.trim();
                            final code = codeController.text.trim().toUpperCase();

                            if (name.isEmpty) {
                              showMessage('Tên dự án không được bỏ trống');
                              return;
                            }

                            if (code.isEmpty) {
                              showMessage('Mã dự án không được bỏ trống');
                              return;
                            }

                            final newProject = MockProject(
                              id: project?.id ??
                                  'p${DateTime.now().millisecondsSinceEpoch}',
                              workspaceId: selectedWorkspaceId,
                              name: name,
                              code: code,
                              deadline: _formatDeadline(selectedDeadline),
                              progress: project?.progress ?? 0,
                              totalTasks: project?.totalTasks ?? 0,
                              completedTasks: project?.completedTasks ?? 0,
                              members: project?.members ?? const ['AD'],
                              status: project?.status ?? 'Active',
                            );

                            setState(() {
                              if (isEditMode && index != null) {
                                projects[index] = newProject;
                              } else {
                                projects.add(newProject);
                              }
                            });

                            Navigator.pop(bottomSheetContext);

                            showMessage(
                              isEditMode
                                  ? 'Đã cập nhật project'
                                  : 'Đã tạo project mới',
                            );
                          },
                          icon: Icon(
                            isEditMode ? Icons.save_rounded : Icons.add_rounded,
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
                              fontSize: 16,
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
  }

  void toggleArchiveProject(int index) {
    final project = filteredProjects[index];
    final realIndex = projects.indexWhere((item) => item.id == project.id);

    if (realIndex == -1) return;

    final newStatus = project.status == 'Active' ? 'Archived' : 'Active';

    final updatedProject = MockProject(
      id: project.id,
      workspaceId: project.workspaceId,
      name: project.name,
      code: project.code,
      deadline: project.deadline,
      progress: project.progress,
      totalTasks: project.totalTasks,
      completedTasks: project.completedTasks,
      members: project.members,
      status: newStatus,
    );

    setState(() {
      projects[realIndex] = updatedProject;
    });

    showMessage(
      newStatus == 'Archived'
          ? 'Đã archive project'
          : 'Đã khôi phục project',
    );
  }

  void deleteProject(int index) {
    final project = filteredProjects[index];

    if (project.totalTasks > 0) {
      showDialog(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            title: const Text('Không nên xóa Project'),
            content: Text(
              'Project "${project.name}" đang có ${project.totalTasks} task. '
                  'Trong hệ thống thật, Admin nên archive project thay vì xóa cứng.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Đóng'),
              ),
            ],
          );
        },
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text('Xóa Project'),
          content: Text(
            'Bạn có chắc muốn xóa project "${project.name}" không?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  projects.removeWhere((item) => item.id == project.id);
                });

                Navigator.pop(dialogContext);
                showMessage('Đã xóa project mock');
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

  void showProjectDetail(MockProject project) {
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
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
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

                    Container(
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
                        Icons.folder_open_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
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
                      '${project.code} • ${getWorkspaceName(project.workspaceId)}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 18),

                    Row(
                      children: [
                        Expanded(
                          child: _DetailStatBox(
                            label: 'Tổng task',
                            value: '${project.totalTasks}',
                            icon: Icons.task_alt_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DetailStatBox(
                            label: 'Hoàn thành',
                            value: '${project.completedTasks}',
                            icon: Icons.check_circle_rounded,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _DetailStatBox(
                            label: 'Tiến độ',
                            value: '${(project.progress * 100).round()}%',
                            icon: Icons.trending_up_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DetailStatBox(
                            label: 'Trạng thái',
                            value: project.status,
                            icon: Icons.verified_rounded,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    _ProjectProgressBox(project: project),

                    const SizedBox(height: 18),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            color: Color(0xFF7C3AED),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Deadline: ${project.deadline}',
                              style: const TextStyle(
                                color: Color(0xFF374151),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
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

  DateTime _parseDeadline(String value) {
    try {
      final parts = value.split('/');
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = parts.length >= 3 ? int.parse(parts[2]) : 2026;

      return DateTime(year, month, day);
    } catch (_) {
      return DateTime.now().add(const Duration(days: 14));
    }
  }

  String _formatDeadline(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
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
    final visibleProjects = filteredProjects;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      floatingActionButton: FloatingActionButton(
        onPressed: () => openProjectForm(),
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded, size: 30),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 90),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _OverviewPanel(
                      projectCount: projects.length,
                      activeCount: activeProjects,
                      archivedCount: archivedProjects,
                      taskCount: totalTasks,
                    ),

                    const SizedBox(height: 20),

                    _FilterPanel(
                      workspaces: workspaces,
                      selectedWorkspaceFilter: selectedWorkspaceFilter,
                      selectedStatusFilter: selectedStatusFilter,
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
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Danh sách Project',
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

                    const SizedBox(height: 14),

                    if (visibleProjects.isEmpty)
                      const _EmptyProjectList()
                    else
                      ...List.generate(visibleProjects.length, (index) {
                        final project = visibleProjects[index];
                        final realIndex = projects.indexWhere(
                              (item) => item.id == project.id,
                        );

                        return _ProjectAdminCard(
                          project: project,
                          workspaceName: getWorkspaceName(project.workspaceId),
                          onView: () => showProjectDetail(project),
                          onEdit: () => openProjectForm(
                            project: project,
                            index: realIndex,
                          ),
                          onArchive: () => toggleArchiveProject(index),
                          onDelete: () => deleteProject(index),
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
              'Quản lý Project',
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
              Icons.folder_open_rounded,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewPanel extends StatelessWidget {
  final int projectCount;
  final int activeCount;
  final int archivedCount;
  final int taskCount;

  const _OverviewPanel({
    required this.projectCount,
    required this.activeCount,
    required this.archivedCount,
    required this.taskCount,
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
                Icons.folder_copy_rounded,
                color: Colors.white,
                size: 30,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tổng quan Project',
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
                  value: '$projectCount',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _OverviewMiniStat(
                  label: 'Active',
                  value: '$activeCount',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _OverviewMiniStat(
                  label: 'Archived',
                  value: '$archivedCount',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _OverviewMiniStat(
                  label: 'Task',
                  value: '$taskCount',
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
  final List<MockWorkspace> workspaces;
  final String selectedWorkspaceFilter;
  final String selectedStatusFilter;
  final ValueChanged<String> onWorkspaceChanged;
  final ValueChanged<String> onStatusChanged;

  const _FilterPanel({
    required this.workspaces,
    required this.selectedWorkspaceFilter,
    required this.selectedStatusFilter,
    required this.onWorkspaceChanged,
    required this.onStatusChanged,
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
                'Bộ lọc',
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
            decoration: _inputDecoration(
              hintText: 'Lọc theo workspace',
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
              if (value == null) return;
              onWorkspaceChanged(value);
            },
          ),

          const SizedBox(height: 12),

          DropdownButtonFormField<String>(
            value: selectedStatusFilter,
            decoration: _inputDecoration(
              hintText: 'Lọc theo trạng thái',
              icon: Icons.verified_rounded,
            ),
            items: const [
              DropdownMenuItem(
                value: 'all',
                child: Text('Tất cả trạng thái'),
              ),
              DropdownMenuItem(
                value: 'Active',
                child: Text('Active'),
              ),
              DropdownMenuItem(
                value: 'Archived',
                child: Text('Archived'),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;
              onStatusChanged(value);
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

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration().copyWith(
        border: Border.all(
          color: isArchived ? const Color(0xFFE5E7EB) : Colors.transparent,
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isArchived
                        ? [
                      const Color(0xFF9CA3AF),
                      const Color(0xFF6B7280),
                    ]
                        : [
                      const Color(0xFF2563EB),
                      const Color(0xFF9333EA),
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
              _StatusBadge(status: project.status),
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
                label: '${project.completedTasks}/${project.totalTasks} task',
              ),
              const SizedBox(width: 8),
              _SmallInfoChip(
                icon: Icons.calendar_today_outlined,
                label: project.deadline,
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
                  style: _buttonStyle(const Color(0xFF2563EB)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: const Text('Sửa'),
                  style: _buttonStyle(const Color(0xFF7C3AED)),
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
                  style: _buttonStyle(const Color(0xFFF59E0B)),
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

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = status == 'Active';
    final color = isActive ? const Color(0xFF22C55E) : const Color(0xFF6B7280);

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
        status,
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
              fontSize: 18,
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

class _ProjectProgressBox extends StatelessWidget {
  final MockProject project;

  const _ProjectProgressBox({
    required this.project,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (project.progress * 100).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tiến độ dự án',
            style: TextStyle(
              color: Color(0xFF111827),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: project.progress,
              minHeight: 9,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF7C3AED),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$percent% hoàn thành',
            style: const TextStyle(
              color: Color(0xFF7C3AED),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
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

class _FieldLabel extends StatelessWidget {
  final String label;
  final bool requiredField;

  const _FieldLabel({
    required this.label,
    this.requiredField = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF374151),
            fontWeight: FontWeight.w800,
          ),
        ),
        if (requiredField)
          const Text(
            ' *',
            style: TextStyle(
              color: Color(0xFFEF4444),
              fontWeight: FontWeight.w900,
            ),
          ),
      ],
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