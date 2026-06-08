import 'package:flutter/material.dart';

import '../../data/mock_users.dart';
import '../../data/mock_workspaces.dart';
import '../../data/mock_tasks.dart';
import '../auth/login_screen.dart';
import 'admin_user_management_screen.dart';
import 'admin_workspace_management_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  final MockUser admin;

  const AdminDashboardScreen({
    super.key,
    required this.admin,
  });

  @override
  Widget build(BuildContext context) {
    final totalUsers = mockUsers.length;
    final totalWorkspaces = mockWorkspaces.length;
    final totalProjects = mockProjects.length;
    final totalTasks = mockTasks.length;
    final completedTasks =
        mockTasks.where((task) => task.status == 'Đã xong').length;
    final pendingTasks =
        mockTasks.where((task) => task.status != 'Đã xong').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AdminHeader(admin: admin),
              const SizedBox(height: 18),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.35,
                  children: [
                    _StatCard(
                      title: 'Người dùng',
                      value: '$totalUsers',
                      icon: Icons.people_alt_rounded,
                      color: const Color(0xFF2563EB),
                    ),
                    _StatCard(
                      title: 'Workspace',
                      value: '$totalWorkspaces',
                      icon: Icons.workspaces_rounded,
                      color: const Color(0xFF7C3AED),
                    ),
                    _StatCard(
                      title: 'Dự án',
                      value: '$totalProjects',
                      icon: Icons.folder_open_rounded,
                      color: const Color(0xFFF59E0B),
                    ),
                    _StatCard(
                      title: 'Tổng task',
                      value: '$totalTasks',
                      icon: Icons.task_alt_rounded,
                      color: const Color(0xFF22C55E),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _SectionCard(
                  title: 'Tổng quan hệ thống',
                  icon: Icons.insights_rounded,
                  child: Column(
                    children: [
                      _ProgressRow(
                        label: 'Task đã hoàn thành',
                        value: completedTasks,
                        total: totalTasks,
                        color: const Color(0xFF22C55E),
                      ),
                      const SizedBox(height: 16),
                      _ProgressRow(
                        label: 'Task đang xử lý',
                        value: pendingTasks,
                        total: totalTasks,
                        color: const Color(0xFFF59E0B),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _SectionCard(
                  title: 'Chức năng Admin',
                  icon: Icons.admin_panel_settings_rounded,
                  child: Column(
                    children: [
                      _AdminMenuTile(
                        icon: Icons.people_alt_outlined,
                        title: 'Quản lý người dùng',
                        subtitle: 'Xem user, đổi role, khóa/mở khóa tài khoản',
                        color: const Color(0xFF2563EB),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  AdminUserManagementScreen(admin: admin),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      _AdminMenuTile(
                        icon: Icons.workspaces_outline,
                        title: 'Quản lý Workspace',
                        subtitle: 'Xem, tạo, sửa và xóa workspace',
                        color: const Color(0xFF7C3AED),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminWorkspaceManagementScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      _AdminMenuTile(
                        icon: Icons.folder_open_outlined,
                        title: 'Quản lý Project',
                        subtitle: 'Theo dõi dự án, deadline và tiến độ',
                        color: const Color(0xFFF59E0B),
                        onTap: () {
                          _showMockMessage(context, 'Quản lý Project');
                        },
                      ),
                      const Divider(height: 1),
                      _AdminMenuTile(
                        icon: Icons.fact_check_outlined,
                        title: 'Duyệt yêu cầu kỹ thuật',
                        subtitle: 'Xem các yêu cầu đang chờ duyệt',
                        color: const Color(0xFF22C55E),
                        onTap: () {
                          _showMockMessage(context, 'Duyệt yêu cầu kỹ thuật');
                        },
                      ),
                      const Divider(height: 1),
                      _AdminMenuTile(
                        icon: Icons.history_rounded,
                        title: 'Activity Log',
                        subtitle: 'Theo dõi hoạt động của thành viên',
                        color: const Color(0xFFEF4444),
                        onTap: () {
                          _showMockMessage(context, 'Activity Log');
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoginScreen(),
                        ),
                            (route) => false,
                      );
                    },
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Đăng xuất Admin'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      side: const BorderSide(
                        color: Color(0xFFEF4444),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMockMessage(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature đang là mock UI'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _AdminHeader extends StatelessWidget {
  final MockUser admin;

  const _AdminHeader({
    required this.admin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
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

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.055),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              icon,
              color: color,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
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

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
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
          Row(
            children: [
              Icon(
                icon,
                color: const Color(0xFF7C3AED),
              ),
              const SizedBox(width: 9),
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
            ],
          ),
          const SizedBox(height: 14),
          child,
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
    final percent = (progress * 100).round();

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
              '$value/$total • $percent%',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
              ),
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
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          icon,
          color: color,
        ),
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
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Color(0xFF9CA3AF),
      ),
      onTap: onTap,
    );
  }
}