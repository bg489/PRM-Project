import 'package:flutter/material.dart';

import '../../data/mock_tasks.dart';
import '../../data/mock_users.dart';
import '../../data/mock_workspaces.dart';
import '../../services/app_data_service.dart';
import '../auth/login_screen.dart';
import 'admin_activity_log_screen.dart';
import 'admin_approval_project_selection_screen.dart';
import 'admin_project_management_screen.dart';
import 'admin_task_management_screen.dart';
import 'admin_user_management_screen.dart';
import 'admin_widgets.dart';
import 'admin_workspace_management_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final MockUser admin;

  const AdminDashboardScreen({
    super.key,
    required this.admin,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late AdminSummary summary;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    summary = _fallbackSummary();
    loadSummary();
  }

  Future<void> loadSummary() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final loadedSummary = await AppDataService.fetchAdminSummary();
      if (!mounted) return;
      setState(() {
        summary = loadedSummary;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        summary = _fallbackSummary();
        errorMessage = 'Chưa kết nối được backend, đang hiển thị dữ liệu dự phòng.';
        isLoading = false;
      });
    }
  }

  AdminSummary _fallbackSummary() {
    final completed = mockTasks.where((task) => task.status == kanbanColumns.last).length;
    return AdminSummary(
      totalUsers: mockUsers.length,
      totalWorkspaces: mockWorkspaces.length,
      totalProjects: mockProjects.length,
      totalTasks: mockTasks.length,
      completedTasks: completed,
      pendingTasks: mockTasks.length - completed,
    );
  }

  Future<void> logout() async {
    await AppDataService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: loadSummary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AdminHeader(admin: widget.admin),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                  child: Column(
                    children: [
                      if (isLoading)
                        const LinearProgressIndicator(color: Color(0xFF7C3AED)),
                      if (errorMessage != null) ...[
                        AdminErrorBanner(
                          message: errorMessage!,
                          onRetry: loadSummary,
                        ),
                        const SizedBox(height: 16),
                      ],
                      AdminStatGrid(
                        stats: [
                          AdminStat(
                            label: 'Người dùng',
                            value: '${summary.totalUsers}',
                            icon: Icons.people_alt_rounded,
                            color: const Color(0xFF2563EB),
                          ),
                          AdminStat(
                            label: 'Workspace',
                            value: '${summary.totalWorkspaces}',
                            icon: Icons.workspaces_rounded,
                            color: const Color(0xFF7C3AED),
                          ),
                          AdminStat(
                            label: 'Dự án',
                            value: '${summary.totalProjects}',
                            icon: Icons.folder_open_rounded,
                            color: const Color(0xFFF59E0B),
                          ),
                          AdminStat(
                            label: 'Tổng task',
                            value: '${summary.totalTasks}',
                            icon: Icons.task_alt_rounded,
                            color: const Color(0xFF22C55E),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      AdminCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tổng quan hệ thống',
                              style: TextStyle(
                                color: Color(0xFF111827),
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 14),
                            _ProgressRow(
                              label: 'Task đã hoàn thành',
                              value: summary.completedTasks,
                              total: summary.totalTasks,
                              color: const Color(0xFF22C55E),
                            ),
                            const SizedBox(height: 14),
                            _ProgressRow(
                              label: 'Task đang xử lý',
                              value: summary.pendingTasks,
                              total: summary.totalTasks,
                              color: const Color(0xFFF59E0B),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      AdminCard(
                        child: Column(
                          children: [
                            _AdminMenuTile(
                              icon: Icons.people_alt_outlined,
                              title: 'Quản lý người dùng',
                              subtitle: 'Xem user, đổi role, khóa/mở khóa tài khoản',
                              color: const Color(0xFF2563EB),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AdminUserManagementScreen(
                                    admin: widget.admin,
                                  ),
                                ),
                              ),
                            ),
                            const Divider(height: 1),
                            _AdminMenuTile(
                              icon: Icons.workspaces_outline,
                              title: 'Quản lý Workspace',
                              subtitle: 'Xem, tạo, sửa và xóa workspace',
                              color: const Color(0xFF7C3AED),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AdminWorkspaceManagementScreen(),
                                ),
                              ),
                            ),
                            const Divider(height: 1),
                            _AdminMenuTile(
                              icon: Icons.folder_open_outlined,
                              title: 'Quản lý Project',
                              subtitle: 'Xem, tạo, sửa, archive và xóa project',
                              color: const Color(0xFFF59E0B),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AdminProjectManagementScreen(),
                                ),
                              ),
                            ),
                            const Divider(height: 1),
                            _AdminMenuTile(
                              icon: Icons.task_alt_outlined,
                              title: 'Quản lý Task',
                              subtitle: 'Xem toàn bộ task, lọc và đổi trạng thái',
                              color: const Color(0xFF2563EB),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AdminTaskManagementScreen(),
                                ),
                              ),
                            ),
                            const Divider(height: 1),
                            _AdminMenuTile(
                              icon: Icons.fact_check_outlined,
                              title: 'Duyệt yêu cầu kỹ thuật',
                              subtitle: 'Duyệt requirement đã gửi từ nhân viên',
                              color: const Color(0xFF22C55E),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AdminApprovalProjectSelectionScreen(),
                                ),
                              ),
                            ),
                            const Divider(height: 1),
                            _AdminMenuTile(
                              icon: Icons.history_rounded,
                              title: 'Activity Log',
                              subtitle: 'Theo dõi hoạt động của thành viên',
                              color: const Color(0xFFEF4444),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AdminActivityLogScreen(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: logout,
                          icon: const Icon(Icons.logout_rounded),
                          label: const Text('Đăng xuất Admin'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFEF4444),
                            side: const BorderSide(color: Color(0xFFEF4444)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            textStyle: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminHeader extends StatelessWidget {
  final MockUser admin;

  const _AdminHeader({required this.admin});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF111827), Color(0xFF7C3AED)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withOpacity(0.18),
            child: Text(
              admin.avatarText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Admin Dashboard',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  admin.fullName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final String label;
  final int value;
  final int total;
  final Color color;

  const _ProgressRow({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : value / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF374151),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              '$value/$total',
              style: TextStyle(color: color, fontWeight: FontWeight.w900),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: const Color(0xFFE5E7EB),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _AdminMenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _AdminMenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF111827),
          fontWeight: FontWeight.w900,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: Color(0xFF6B7280),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF)),
      onTap: onTap,
    );
  }
}
