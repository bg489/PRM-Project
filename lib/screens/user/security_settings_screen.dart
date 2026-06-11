import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/mock_users.dart';
import '../../services/app_data_service.dart';

class SecuritySettingsScreen extends StatefulWidget {
  final MockUser user;

  const SecuritySettingsScreen({
    super.key,
    required this.user,
  });

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  final TextEditingController currentPasswordController =
  TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
  TextEditingController();

  bool obscureCurrentPassword = true;
  bool obscureNewPassword = true;
  bool obscureConfirmPassword = true;

  bool twoStepEnabled = false;
  bool biometricEnabled = false;
  bool isSavingPassword = false;
  String? apiToken;

  String get sessionToken => apiToken ?? 'Chưa có token đăng nhập';

  @override
  void initState() {
    super.initState();
    loadSecuritySettings();
  }

  Future<void> loadSecuritySettings() async {
    final token = await AppDataService.currentToken();

    if (!mounted) return;

    setState(() {
      twoStepEnabled = widget.user.twoStepEnabled;
      biometricEnabled = widget.user.biometricEnabled;
      apiToken = token;
    });
  }

  @override
  void dispose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> changePassword() async {
    final currentPassword = currentPasswordController.text.trim();
    final newPassword = newPasswordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      showMessage('Vui lòng nhập đầy đủ thông tin mật khẩu');
      return;
    }

    if (newPassword.length < 6) {
      showMessage('Mật khẩu mới phải có ít nhất 6 ký tự');
      return;
    }

    if (newPassword != confirmPassword) {
      showMessage('Mật khẩu xác nhận không khớp');
      return;
    }

    setState(() {
      isSavingPassword = true;
    });

    try {
      await AppDataService.changePassword(
        userId: widget.user.id,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      if (!mounted) return;

      setState(() {
        isSavingPassword = false;
        currentPasswordController.clear();
        newPasswordController.clear();
        confirmPasswordController.clear();
      });

      showMessage('Đã đổi mật khẩu thành công');
    } catch (error) {
      if (!mounted) return;
      setState(() {
        isSavingPassword = false;
      });
      showMessage('Không thể đổi mật khẩu: $error');
    }
  }

  Future<void> updateTwoStep(bool value) async {
    final previousValue = twoStepEnabled;
    setState(() => twoStepEnabled = value);

    try {
      final updatedUser = await AppDataService.updateSecurity(
        userId: widget.user.id,
        twoStepEnabled: value,
      );
      if (!mounted) return;
      setState(() {
        twoStepEnabled = updatedUser.twoStepEnabled;
      });
      showMessage(
        value ? 'Đã bật bảo mật 2 bước' : 'Đã tắt bảo mật 2 bước',
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => twoStepEnabled = previousValue);
      showMessage('Không thể cập nhật bảo mật 2 bước: $error');
    }
  }

  Future<void> updateBiometric(bool value) async {
    final previousValue = biometricEnabled;
    setState(() => biometricEnabled = value);

    try {
      final updatedUser = await AppDataService.updateSecurity(
        userId: widget.user.id,
        biometricEnabled: value,
      );
      if (!mounted) return;
      setState(() {
        biometricEnabled = updatedUser.biometricEnabled;
      });
      showMessage(
        value ? 'Đã bật mở khóa sinh trắc học' : 'Đã tắt mở khóa sinh trắc học',
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => biometricEnabled = previousValue);
      showMessage('Không thể cập nhật sinh trắc học: $error');
    }
  }

  void copyToken() {
    Clipboard.setData(
      ClipboardData(text: sessionToken),
    );

    showMessage('Đã copy token phiên đăng nhập');
  }

  void logoutOtherSessions() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text('Đăng xuất phiên khác'),
          content: const Text(
            'Backend hiện dùng JWT stateless. Khi cần quản lý nhiều thiết bị, có thể bổ sung bảng refresh token/session để thu hồi từng phiên.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                showMessage('Chưa có phiên khác cần thu hồi trên backend hiện tại');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
              ),
              child: const Text('Xác nhận'),
            ),
          ],
        );
      },
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

  InputDecoration inputDecoration({
    required String hintText,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(icon),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF3F4F6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SecurityOverviewCard(
                      user: widget.user,
                      twoStepEnabled: twoStepEnabled,
                      biometricEnabled: biometricEnabled,
                    ),

                    const SizedBox(height: 18),

                    _SectionCard(
                      title: 'Đổi mật khẩu',
                      icon: Icons.lock_reset_rounded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _FieldLabel(label: 'Mật khẩu hiện tại'),
                          const SizedBox(height: 8),
                          TextField(
                            controller: currentPasswordController,
                            obscureText: obscureCurrentPassword,
                            decoration: inputDecoration(
                              hintText: 'Nhập mật khẩu hiện tại',
                              icon: Icons.lock_outline_rounded,
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    obscureCurrentPassword =
                                    !obscureCurrentPassword;
                                  });
                                },
                                icon: Icon(
                                  obscureCurrentPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          const _FieldLabel(label: 'Mật khẩu mới'),
                          const SizedBox(height: 8),
                          TextField(
                            controller: newPasswordController,
                            obscureText: obscureNewPassword,
                            decoration: inputDecoration(
                              hintText: 'Tối thiểu 6 ký tự',
                              icon: Icons.password_rounded,
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    obscureNewPassword = !obscureNewPassword;
                                  });
                                },
                                icon: Icon(
                                  obscureNewPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          const _FieldLabel(label: 'Xác nhận mật khẩu mới'),
                          const SizedBox(height: 8),
                          TextField(
                            controller: confirmPasswordController,
                            obscureText: obscureConfirmPassword,
                            decoration: inputDecoration(
                              hintText: 'Nhập lại mật khẩu mới',
                              icon: Icons.verified_user_outlined,
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    obscureConfirmPassword =
                                    !obscureConfirmPassword;
                                  });
                                },
                                icon: Icon(
                                  obscureConfirmPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed:
                              isSavingPassword ? null : changePassword,
                              icon: isSavingPassword
                                  ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                                  : const Icon(Icons.save_rounded),
                              label: Text(
                                isSavingPassword
                                    ? 'Đang lưu...'
                                    : 'Cập nhật mật khẩu',
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

                    const SizedBox(height: 18),

                    _SectionCard(
                      title: 'Tùy chọn bảo mật',
                      icon: Icons.security_rounded,
                      child: Column(
                        children: [
                          _SecuritySwitchTile(
                            icon: Icons.phonelink_lock_rounded,
                            title: 'Bảo mật 2 bước',
                            subtitle:
                            'Yêu cầu xác minh thêm khi đăng nhập',
                            value: twoStepEnabled,
                            onChanged: updateTwoStep,
                          ),
                          const Divider(height: 1),
                          _SecuritySwitchTile(
                            icon: Icons.fingerprint_rounded,
                            title: 'Sinh trắc học',
                            subtitle:
                            'Mở khóa bằng vân tay/khuôn mặt',
                            value: biometricEnabled,
                            onChanged: updateBiometric,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    _SectionCard(
                      title: 'Phiên đăng nhập',
                      icon: Icons.key_rounded,
                      child: Column(
                        children: [
                          _InfoBlock(
                            icon: Icons.devices_rounded,
                            title: 'Thiết bị hiện tại',
                            content:
                            'Android Emulator / Smartphone • Đang hoạt động',
                          ),
                          const SizedBox(height: 12),
                          _InfoBlock(
                            icon: Icons.token_rounded,
                            title: 'JWT Token',
                            content: sessionToken,
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: copyToken,
                                  icon: const Icon(
                                    Icons.copy_rounded,
                                    size: 18,
                                  ),
                                  label: const Text('Copy token'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF7C3AED),
                                    side: const BorderSide(
                                      color: Color(0xFFC4B5FD),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: logoutOtherSessions,
                                  icon: const Icon(
                                    Icons.logout_rounded,
                                    size: 18,
                                  ),
                                  label: const Text('Đăng xuất khác'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFFEF4444),
                                    side: const BorderSide(
                                      color: Color(0xFFFECACA),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    _SectionCard(
                      title: 'Ghi chú bảo mật',
                      icon: Icons.info_outline_rounded,
                      child: const Text(
                        'Mật khẩu và tùy chọn bảo mật được cập nhật qua backend. JWT hiện được lưu trên thiết bị để gọi API.',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w600,
                          height: 1.45,
                        ),
                      ),
                    ),
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
              'Bảo mật',
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
              Icons.shield_rounded,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityOverviewCard extends StatelessWidget {
  final MockUser user;
  final bool twoStepEnabled;
  final bool biometricEnabled;

  const _SecurityOverviewCard({
    required this.user,
    required this.twoStepEnabled,
    required this.biometricEnabled,
  });

  @override
  Widget build(BuildContext context) {
    final activeCount =
        [twoStepEnabled, biometricEnabled].where((item) => item).length;

    return Container(
      width: double.infinity,
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
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withOpacity(0.18),
            child: Text(
              user.avatarText,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$activeCount/2 lớp bảo mật đang bật',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.verified_user_rounded,
            color: Colors.white,
            size: 32,
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

class _FieldLabel extends StatelessWidget {
  final String label;

  const _FieldLabel({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFF374151),
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _SecuritySwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SecuritySwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      secondary: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFEDE9FE),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          icon,
          color: const Color(0xFF7C3AED),
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
          fontWeight: FontWeight.w600,
        ),
      ),
      value: value,
      activeColor: const Color(0xFF7C3AED),
      onChanged: onChanged,
    );
  }
}

class _InfoBlock extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;

  const _InfoBlock({
    required this.icon,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: const Color(0xFF7C3AED),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  content,
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
    );
  }
}
