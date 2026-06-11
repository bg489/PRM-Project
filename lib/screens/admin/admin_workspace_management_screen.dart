import 'package:flutter/material.dart';

import '../../data/mock_workspaces.dart';
import '../../services/app_data_service.dart';
import 'admin_widgets.dart';

class AdminWorkspaceManagementScreen extends StatefulWidget {
  const AdminWorkspaceManagementScreen({super.key});

  @override
  State<AdminWorkspaceManagementScreen> createState() =>
      _AdminWorkspaceManagementScreenState();
}

class _AdminWorkspaceManagementScreenState
    extends State<AdminWorkspaceManagementScreen> {
  List<MockWorkspace> workspaces = List.from(mockWorkspaces);
  List<MockProject> projects = List.from(mockProjects);
  bool isLoading = true;
  String? errorMessage;

  int get totalMembers {
    return workspaces.fold(0, (sum, workspace) => sum + workspace.memberCount);
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
        errorMessage = 'Chưa kết nối được backend, đang hiển thị workspace dự phòng.';
        isLoading = false;
      });
    }
  }

  Future<void> openWorkspaceForm({MockWorkspace? workspace}) async {
    final isEditMode = workspace != null;
    final nameController = TextEditingController(text: workspace?.name ?? '');
    final descriptionController = TextEditingController(
      text: workspace?.description ?? '',
    );
    final iconController = TextEditingController(text: workspace?.iconText ?? 'WS');

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
                        isEditMode ? 'Chỉnh sửa Workspace' : 'Tạo Workspace mới',
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
                          label: 'Tên Workspace',
                          icon: Icons.title_rounded,
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
                      TextField(
                        controller: iconController,
                        maxLength: 2,
                        textCapitalization: TextCapitalization.characters,
                        decoration: adminInputDecoration(
                          label: 'Ký hiệu icon',
                          icon: Icons.badge_outlined,
                        ).copyWith(counterText: ''),
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
                                  final description =
                                      descriptionController.text.trim();
                                  final iconText =
                                      iconController.text.trim().toUpperCase();

                                  if (name.isEmpty) {
                                    showAdminMessage(
                                      context,
                                      'Tên workspace không được bỏ trống',
                                    );
                                    return;
                                  }

                                  setSheetState(() {
                                    isSaving = true;
                                  });

                                  try {
                                    final savedWorkspace = isEditMode
                                        ? await AppDataService.updateWorkspace(
                                          MockWorkspace(
                                              id: workspace!.id,
                                              name: name,
                                              description: description,
                                              memberCount: workspace!.memberCount,
                                              projectCount: workspace!.projectCount,
                                              iconText: iconText.isEmpty
                                                  ? workspace!.iconText
                                                  : iconText,
                                            ),
                                          )
                                        : await AppDataService.createWorkspace(
                                            name: name,
                                            description: description,
                                            iconText:
                                                iconText.isEmpty ? 'WS' : iconText,
                                          );

                                    if (!mounted) return;

                                    Navigator.pop(bottomSheetContext);

                                    await loadData();

                                    if (!mounted) return;
                                    showAdminMessage(
                                      context,
                                      isEditMode ? 'Đã cập nhật workspace' : 'Đã tạo workspace mới',
                                    );

                                    Navigator.pop(bottomSheetContext);
                                    showAdminMessage(
                                      context,
                                      isEditMode
                                          ? 'Đã cập nhật workspace'
                                          : 'Đã tạo workspace mới',
                                    );
                                  } catch (error) {
                                    if (!mounted) return;
                                    setSheetState(() {
                                      isSaving = false;
                                    });
                                    showAdminMessage(
                                      context,
                                      'Không thể lưu workspace: $error',
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
                              : Icon(isEditMode ? Icons.save_rounded : Icons.add_rounded),
                          label: Text(isEditMode ? 'Lưu thay đổi' : 'Tạo workspace'),
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
    descriptionController.dispose();
    iconController.dispose();
  }

  Future<void> deleteWorkspace(MockWorkspace workspace) async {
    final projectCount = projects
        .where((project) => project.workspaceId == workspace.id)
        .length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: const Text('Xóa Workspace'),
          content: Text(
            projectCount > 0
                ? 'Workspace "${workspace.name}" có $projectCount dự án. Xóa workspace sẽ xóa dữ liệu liên quan trong database. Bạn chắc chắn chứ?'
                : 'Bạn có chắc muốn xóa workspace "${workspace.name}" không?',
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
      await AppDataService.deleteWorkspace(workspace.id);
      if (!mounted) return;
      setState(() {
        workspaces.removeWhere((item) => item.id == workspace.id);
        projects.removeWhere((item) => item.workspaceId == workspace.id);
      });
      showAdminMessage(context, 'Đã xóa workspace');
    } catch (error) {
      if (!mounted) return;
      showAdminMessage(context, 'Không thể xóa workspace: $error');
    }
  }

  void showWorkspaceDetail(MockWorkspace workspace) {
    final workspaceProjects = projects
        .where((project) => project.workspaceId == workspace.id)
        .toList();

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
                      workspace.iconText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    workspace.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    workspace.description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  AdminStatGrid(
                    stats: [
                      AdminStat(
                        label: 'Thành viên',
                        value: '${workspace.memberCount}',
                        icon: Icons.group_outlined,
                        color: const Color(0xFF2563EB),
                      ),
                      AdminStat(
                        label: 'Dự án',
                        value: '${workspaceProjects.length}',
                        icon: Icons.folder_open_outlined,
                        color: const Color(0xFF7C3AED),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Dự án trong workspace',
                    style: TextStyle(
                      color: Color(0xFF111827),
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (workspaceProjects.isEmpty)
                    const AdminEmptyState(
                      icon: Icons.folder_off_outlined,
                      message: 'Workspace này chưa có dự án.',
                    )
                  else
                    ...workspaceProjects.map((project) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: AdminCard(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.folder_open_rounded,
                                color: Color(0xFF7C3AED),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  project.name,
                                  style: const TextStyle(
                                    color: Color(0xFF374151),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              Text(
                                '${(project.progress * 100).round()}%',
                                style: const TextStyle(
                                  color: Color(0xFF2563EB),
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
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
    return AdminScreenScaffold(
      title: 'Quản lý Workspace',
      icon: Icons.workspaces_rounded,
      floatingActionButton: FloatingActionButton(
        onPressed: () => openWorkspaceForm(),
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
                          label: 'Workspace',
                          value: '${workspaces.length}',
                          icon: Icons.workspaces_rounded,
                          color: const Color(0xFF7C3AED),
                        ),
                        AdminStat(
                          label: 'Thành viên',
                          value: '$totalMembers',
                          icon: Icons.group_outlined,
                          color: const Color(0xFF2563EB),
                        ),
                        AdminStat(
                          label: 'Dự án',
                          value: '${projects.length}',
                          icon: Icons.folder_open_outlined,
                          color: const Color(0xFFF59E0B),
                        ),
                        AdminStat(
                          label: 'Backend',
                          value: errorMessage == null ? 'Live' : 'Fallback',
                          icon: Icons.cloud_done_rounded,
                          color: const Color(0xFF22C55E),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    AdminSectionTitle(
                      title: 'Danh sách Workspace',
                      countLabel: '${workspaces.length} workspace',
                    ),
                    const SizedBox(height: 14),
                    if (workspaces.isEmpty)
                      const AdminEmptyState(
                        icon: Icons.workspaces_outline,
                        message: 'Chưa có workspace nào.',
                      )
                    else
                      ...workspaces.map((workspace) {
                        final projectCount = projects
                            .where((project) => project.workspaceId == workspace.id)
                            .length;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _WorkspaceAdminCard(
                            workspace: workspace,
                            projectCount: projectCount,
                            onView: () => showWorkspaceDetail(workspace),
                            onEdit: () => openWorkspaceForm(workspace: workspace),
                            onDelete: () => deleteWorkspace(workspace),
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

class _WorkspaceAdminCard extends StatelessWidget {
  final MockWorkspace workspace;
  final int projectCount;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _WorkspaceAdminCard({
    required this.workspace,
    required this.projectCount,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFF7C3AED),
                child: Text(
                  workspace.iconText,
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
                      workspace.name,
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      workspace.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
          const SizedBox(height: 14),
          Row(
            children: [
              AdminPill(label: '${workspace.memberCount} thành viên'),
              const SizedBox(width: 8),
              AdminPill(
                label: '$projectCount dự án',
                color: const Color(0xFF2563EB),
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
