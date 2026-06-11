import 'package:flutter/material.dart';
import '../../data/mock_users.dart';
import '../../data/mock_tasks.dart';
import '../../data/mock_workspaces.dart';
import '../../services/app_data_service.dart';
import '../auth/login_screen.dart';
import '../../utils/app_navigation.dart';
import '../user/edit_profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/app_notification_service.dart';
import '../../utils/app_theme_controller.dart';
import '../user/security_settings_screen.dart';
import '../../utils/app_language_controller.dart';
import '../../utils/app_text.dart';
import '../user/language_settings_screen.dart';

class ProfileSettingsScreen extends StatefulWidget {
  final MockUser user;
  final MockProject project;
  final List<MockTask> tasks;

  const ProfileSettingsScreen({
    super.key,
    required this.user,
    required this.project,
    required this.tasks,
  });

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  static const String notificationSettingKey =
      'productivity_manager_notification_enabled';

  bool notificationEnabled = true;
  bool darkModeEnabled = false;
  late MockUser currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = widget.user;
    notificationEnabled = currentUser.notificationEnabled;
    darkModeEnabled = appThemeController.isDarkMode;
    appThemeController.addListener(syncDarkModeState);
    loadNotificationSetting();
  }

  @override
  void dispose() {
    appThemeController.removeListener(syncDarkModeState);
    super.dispose();
  }

  void syncDarkModeState() {
    if (!mounted) return;

    setState(() {
      darkModeEnabled = appThemeController.isDarkMode;
    });
  }

  Future<void> updateDarkModeSetting(bool value) async {
    await appThemeController.setDarkMode(value);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value ? 'Đã bật chế độ tối' : 'Đã tắt chế độ tối'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> loadNotificationSetting() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      notificationEnabled =
          prefs.getBool(notificationSettingKey) ?? currentUser.notificationEnabled;
    });
  }

  Future<void> updateNotificationSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    if (value) {
      final granted = await AppNotificationService.requestPermission();

      if (!mounted) return;

      if (!granted) {
        setState(() {
          notificationEnabled = false;
        });

        await prefs.setBool(notificationSettingKey, false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bạn chưa cấp quyền thông báo cho ứng dụng'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      setState(() {
        notificationEnabled = true;
      });

      await prefs.setBool(notificationSettingKey, true);
      final updatedUser = await AppDataService.updateSecurity(
        userId: currentUser.id,
        notificationEnabled: true,
      );

      if (!mounted) return;

      setState(() {
        currentUser = updatedUser;
      });

      await AppNotificationService.showNotificationEnabledTest();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã bật thông báo đẩy'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      setState(() {
        notificationEnabled = false;
      });

      await prefs.setBool(notificationSettingKey, false);
      final updatedUser = await AppDataService.updateSecurity(
        userId: currentUser.id,
        notificationEnabled: false,
      );
      if (!mounted) return;
      setState(() {
        currentUser = updatedUser;
      });

      await AppNotificationService.cancelAll();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã tắt thông báo đẩy'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  int get completedTasks {
    return widget.tasks.where((task) => task.status == kanbanColumns.last).length;
  }

  int get pendingTasks {
    return widget.tasks.where((task) => task.status != kanbanColumns.last).length;
  }

  int get highPriorityTasks {
    return widget.tasks.where((task) => task.priority == 'High').length;
  }

  void logout() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text('Đăng xuất'),
          content: const Text(
            'Bạn có chắc muốn đăng xuất khỏi Productivity Manager không?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await AppDataService.logout();

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LoginScreen(),
                  ),
                      (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
              ),
              child: const Text('Đăng xuất'),
            ),
          ],
        );
      },
    );
  }

  void showFeatureMessage(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title đang được phát triển'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> openEditProfileScreen() async {
    final updatedUser = await Navigator.push<MockUser>(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          user: currentUser,
        ),
      ),
    );

    if (updatedUser == null) return;

    setState(() {
      currentUser = updatedUser;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã cập nhật hồ sơ'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
  return AnimatedBuilder(
    animation: appLanguageController,
    builder: (context, _) {
      return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      bottomNavigationBar: _ProfileBottomNavBar(
        user: currentUser,
        project: widget.project,
        tasks: widget.tasks,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 90),
          child: Column(
            children: [
              _ProfileHeader(
                user: currentUser,
                onBack: () => Navigator.pop(context),
                onSettingsTap: openEditProfileScreen,
              ),
              const SizedBox(height: 18),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _ProfileMainCard(
                  user: currentUser,
                  projectName: widget.project.name,
                ),
              ),

              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.35,
                  children: [
                    _StatisticCard(
                      title: 'Dự án hiện tại',
                      value: '1',
                      icon: Icons.folder_open_rounded,
                      color: const Color(0xFF2563EB),
                    ),
                    _StatisticCard(
                      title: 'Task hoàn thành',
                      value: '$completedTasks',
                      icon: Icons.check_circle_rounded,
                      color: const Color(0xFF22C55E),
                    ),
                    _StatisticCard(
                      title: 'Task đang chờ',
                      value: '$pendingTasks',
                      icon: Icons.pending_actions_rounded,
                      color: const Color(0xFFF59E0B),
                    ),
                    _StatisticCard(
                      title: 'Ưu tiên cao',
                      value: '$highPriorityTasks',
                      icon: Icons.flag_rounded,
                      color: const Color(0xFFEF4444),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _SectionCard(
                  title: AppText.t('notifications'),
                  icon: Icons.notifications_active_outlined,
                  child: Column(
                    children: [
                      _SwitchSettingTile(
                        icon: Icons.notifications_none_rounded,
                        title: AppText.t('push_notifications'),
                        subtitle: AppText.t('push_notifications_desc'),
                        value: notificationEnabled,
                        onChanged: updateNotificationSetting,
                      ),
                      const Divider(height: 1),
                      _SwitchSettingTile(
                        icon: Icons.dark_mode_outlined,
                        title: AppText.t('dark_mode'),
                        subtitle: AppText.t('dark_mode_desc'),
                        value: darkModeEnabled,
                        onChanged: updateDarkModeSetting,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _SectionCard(
                  title: AppText.t('account_settings'),
                  icon: Icons.settings_outlined,
                  child: Column(
                    children: [
                      _SettingTile(
                        icon: Icons.security_rounded,
                        title: AppText.t('security'),
                        subtitle: AppText.t('security_desc'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SecuritySettingsScreen(
                                user: currentUser,
                              ),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      _SettingTile(
                        icon: Icons.language_rounded,
                        title: AppText.t('language'),
                        subtitle: appLanguageController.languageLabel,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LanguageSettingsScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      _SettingTile(
                        icon: Icons.help_outline_rounded,
                        title: AppText.t('help_support'),
                        subtitle: AppText.t('help_support_desc'),
                        onTap: () => showFeatureMessage(AppText.t('help_support')),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _SectionCard(
                  title: 'Phiên làm việc',
                  icon: Icons.key_rounded,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: const Color(0xFFE5E7EB),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.verified_user_rounded,
                              color: Color(0xFF22C55E),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'JWT Token đang được ghi nhớ trên thiết bị',
                                style: TextStyle(
                                  color: Color(0xFF374151),
                                  fontWeight: FontWeight.w700,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: logout,
                          icon: const Icon(Icons.logout_rounded),
                          label: const Text('Đăng xuất'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFEF4444),
                            side: const BorderSide(
                              color: Color(0xFFEF4444),
                              width: 1.3,
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
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      );
      },
        );
          }
}

class _ProfileHeader extends StatelessWidget {
  final MockUser user;
  final VoidCallback onBack;
  final VoidCallback onSettingsTap;

  const _ProfileHeader({
    required this.user,
    required this.onBack,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
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
              'Hồ sơ & Cài đặt',
              style: TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          InkWell(
            onTap: onSettingsTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.16),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.settings_rounded,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileMainCard extends StatelessWidget {
  final MockUser user;
  final String projectName;

  const _ProfileMainCard({
    required this.user,
    required this.projectName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF2563EB),
                      Color(0xFF9333EA),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Center(
                  child: Text(
                    user.avatarText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white,
                      width: 3,
                    ),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 17,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            user.fullName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            user.email,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _ProfileChip(
                icon: Icons.badge_outlined,
                label: user.role,
                color: const Color(0xFF7C3AED),
              ),
              _ProfileChip(
                icon: Icons.folder_open_outlined,
                label: projectName,
                color: const Color(0xFF2563EB),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _ProfileChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatisticCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatisticCard({
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
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
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

class _SwitchSettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchSettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          _SettingIcon(icon: icon),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: const Color(0xFF7C3AED),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          children: [
            _SettingIcon(icon: icon),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 12,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF9CA3AF),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingIcon extends StatelessWidget {
  final IconData icon;

  const _SettingIcon({
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFFEDE9FE),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Icon(
        icon,
        color: const Color(0xFF7C3AED),
      ),
    );
  }
}

class _ProfileBottomNavBar extends StatelessWidget {
  final MockUser user;
  final MockProject project;
  final List<MockTask> tasks;

  const _ProfileBottomNavBar({
    required this.user,
    required this.project,
    required this.tasks,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: 4,
      height: 72,
      backgroundColor: Colors.white,
      indicatorColor: const Color(0xFFEDE9FE),
      onDestinationSelected: (index) {
        if (index == 0) {
          AppNavigation.goHome(context);
        }

        if (index == 1) {
          AppNavigation.goBoard(
            context: context,
            user: user,
            project: project,
          );
        }

        if (index == 2) {
          AppNavigation.goCalendar(
            context: context,
            user: user,
            project: project,
            tasks: tasks,
          );
        }

        if (index == 3) {
          AppNavigation.goAnalytics(
            context: context,
            user: user,
            project: project,
            tasks: tasks,
          );
        }

        if (index == 4) {
          return;
        }
      },
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Trang chủ'),
        NavigationDestination(icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view_rounded), label: 'Bảng'),
        NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month_rounded), label: 'Lịch'),
        NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart_rounded), label: 'Phân tích'),
        NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Cá nhân'),
      ],
    );
  }
}
