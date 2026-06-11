import 'package:flutter/material.dart';

import '../../data/mock_users.dart';
import '../../services/app_data_service.dart';
import 'admin_widgets.dart';

class AdminUserManagementScreen extends StatefulWidget {
  final MockUser admin;

  const AdminUserManagementScreen({
    super.key,
    required this.admin,
  });

  @override
  State<AdminUserManagementScreen> createState() =>
      _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  List<MockUser> users = List.from(mockUsers);
  bool isLoading = true;
  String? errorMessage;

  int get activeUsers => users.where((user) => user.isActive).length;
  int get adminUsers => users.where((user) => user.role == 'Admin').length;
  int get memberUsers => users.where((user) => user.role == 'Member').length;

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  Future<void> loadUsers() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final loadedUsers = await AppDataService.fetchUsers();
      if (!mounted) return;
      setState(() {
        users = loadedUsers;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        users = List.from(mockUsers);
        errorMessage = 'Chưa kết nối được backend, đang hiển thị user dự phòng.';
        isLoading = false;
      });
    }
  }

  Future<void> changeRole(int index, String role) async {
    final oldUser = users[index];
    final updatedUser = oldUser.copyWith(role: role);

    setState(() {
      users[index] = updatedUser;
    });

    try {
      final savedUser = await AppDataService.updateUser(updatedUser);
      if (!mounted) return;
      setState(() {
        users[index] = savedUser;
      });
      showAdminMessage(context, 'Đã đổi role thành $role');
    } catch (error) {
      if (!mounted) return;
      setState(() {
        users[index] = oldUser;
      });
      showAdminMessage(context, 'Không thể cập nhật role: $error');
    }
  }

  Future<void> toggleUserStatus(int index) async {
    final oldUser = users[index];
    final updatedUser = oldUser.copyWith(isActive: !oldUser.isActive);

    setState(() {
      users[index] = updatedUser;
    });

    try {
      final savedUser = await AppDataService.updateUser(updatedUser);
      if (!mounted) return;
      setState(() {
        users[index] = savedUser;
      });
      showAdminMessage(
        context,
        savedUser.isActive ? 'Đã mở khóa tài khoản' : 'Đã khóa tài khoản',
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        users[index] = oldUser;
      });
      showAdminMessage(context, 'Không thể cập nhật trạng thái: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScreenScaffold(
      title: 'Quản lý người dùng',
      icon: Icons.people_alt_rounded,
      child: RefreshIndicator(
        onRefresh: loadUsers,
        child: isLoading
            ? const AdminLoading()
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                child: Column(
                  children: [
                    if (errorMessage != null) ...[
                      AdminErrorBanner(
                        message: errorMessage!,
                        onRetry: loadUsers,
                      ),
                      const SizedBox(height: 16),
                    ],
                    AdminStatGrid(
                      stats: [
                        AdminStat(
                          label: 'Active',
                          value: '$activeUsers',
                          icon: Icons.verified_user_rounded,
                          color: const Color(0xFF22C55E),
                        ),
                        AdminStat(
                          label: 'Admin',
                          value: '$adminUsers',
                          icon: Icons.admin_panel_settings_rounded,
                          color: const Color(0xFF7C3AED),
                        ),
                        AdminStat(
                          label: 'Member',
                          value: '$memberUsers',
                          icon: Icons.person_rounded,
                          color: const Color(0xFF2563EB),
                        ),
                        AdminStat(
                          label: 'Tổng',
                          value: '${users.length}',
                          icon: Icons.groups_rounded,
                          color: const Color(0xFFF59E0B),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    AdminSectionTitle(
                      title: 'Danh sách người dùng',
                      countLabel: '${users.length} user',
                    ),
                    const SizedBox(height: 14),
                    if (users.isEmpty)
                      const AdminEmptyState(
                        icon: Icons.person_off_outlined,
                        message: 'Chưa có người dùng nào.',
                      )
                    else
                      ...List.generate(users.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _UserAdminCard(
                            user: users[index],
                            onRoleChanged: (role) => changeRole(index, role),
                            onToggleStatus: () => toggleUserStatus(index),
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

class _UserAdminCard extends StatelessWidget {
  final MockUser user;
  final ValueChanged<String> onRoleChanged;
  final VoidCallback onToggleStatus;

  const _UserAdminCard({
    required this.user,
    required this.onRoleChanged,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    final roleColor = _roleColor(user.role);

    return AdminCard(
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: roleColor,
                child: Text(
                  user.avatarText,
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
                      user.fullName,
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              AdminPill(
                label: user.isActive ? 'Active' : 'Locked',
                color: user.isActive
                    ? const Color(0xFF16A34A)
                    : const Color(0xFFDC2626),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: user.role,
                  decoration: adminInputDecoration(label: 'Role'),
                  items: const [
                    DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                    DropdownMenuItem(value: 'Manager', child: Text('Manager')),
                    DropdownMenuItem(value: 'Member', child: Text('Member')),
                  ],
                  onChanged: (value) {
                    if (value != null && value != user.role) {
                      onRoleChanged(value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 56,
                child: OutlinedButton(
                  onPressed: onToggleStatus,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: user.isActive
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF22C55E),
                    side: BorderSide(
                      color: user.isActive
                          ? const Color(0xFFFECACA)
                          : const Color(0xFFBBF7D0),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(user.isActive ? 'Khóa' : 'Mở'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'Admin':
        return const Color(0xFF7C3AED);
      case 'Manager':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF2563EB);
    }
  }
}
