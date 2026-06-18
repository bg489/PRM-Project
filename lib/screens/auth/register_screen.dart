import 'package:flutter/material.dart';

import '../../data/mock_users.dart';
import '../../services/app_data_service.dart';
import '../dashboard/workspace_dashboard_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final otpController = TextEditingController();

  RegistrationChallenge? challenge;
  String verificationMethod = 'OTP';
  bool isLoading = false;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  bool get hasMinimumLength => passwordController.text.length >= 6;
  bool get hasUppercase => RegExp(r'[A-Z]').hasMatch(passwordController.text);
  bool get hasSpecialCharacter =>
      RegExp(r'[^A-Za-z0-9]').hasMatch(passwordController.text);

  Future<void> requestVerification() async {
    final fullName = fullNameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (fullName.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      showMessage('Vui lòng nhập đầy đủ thông tin');
      return;
    }

    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      showMessage('Email không đúng định dạng');
      return;
    }

    final passwordError = validatePassword(password);
    if (passwordError != null) {
      showMessage(passwordError);
      return;
    }

    if (password != confirmPassword) {
      showMessage('Mật khẩu xác nhận không khớp');
      return;
    }

    setState(() => isLoading = true);

    try {
      final result = await AppDataService.requestRegistration(
        fullName: fullName,
        email: email,
        password: password,
        verificationMethod: verificationMethod,
      );
      if (!mounted) return;

      setState(() {
        challenge = result;
        isLoading = false;
        otpController.clear();
      });

      showMessage('Thông tin xác thực đã được gửi tới ${result.email}');
    } catch (error) {
      if (!mounted) return;
      setState(() => isLoading = false);
      showMessage(
        error.toString().contains('409')
            ? 'Email này đã tồn tại'
            : 'Không thể gửi xác thực: $error',
      );
    }
  }

  Future<void> verifyOtp() async {
    final currentChallenge = challenge;
    final otp = otpController.text.trim();
    if (currentChallenge == null || otp.length != 6) {
      showMessage('Vui lòng nhập mã OTP gồm 6 chữ số');
      return;
    }

    setState(() => isLoading = true);
    try {
      final user = await AppDataService.verifyRegistration(
        verificationId: currentChallenge.verificationId,
        otp: otp,
      );
      if (!mounted) return;
      openDashboard(user);
    } catch (error) {
      if (!mounted) return;
      setState(() => isLoading = false);
      showMessage('OTP không hợp lệ hoặc đã hết hạn: $error');
    }
  }

  Future<void> loginAfterExternalLink() async {
    setState(() => isLoading = true);
    try {
      final user = await AppDataService.login(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      if (!mounted) return;
      openDashboard(user);
    } catch (_) {
      if (!mounted) return;
      setState(() => isLoading = false);
      showMessage('Email chưa được xác thực. Hãy mở link trong email trước.');
    }
  }

  void openDashboard(MockUser user) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => WorkspaceDashboardScreen(user: user)),
      (route) => false,
    );
  }

  String? validatePassword(String password) {
    if (password.length < 6) {
      return 'Mật khẩu phải có ít nhất 6 ký tự';
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Mật khẩu phải có ít nhất 1 chữ hoa';
    }
    if (!RegExp(r'[^A-Za-z0-9]').hasMatch(password)) {
      return 'Mật khẩu phải có ít nhất 1 ký tự đặc biệt';
    }
    return null;
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF9333EA)],
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Icon(
                    challenge == null
                        ? Icons.person_add_alt_1_rounded
                        : Icons.mark_email_read_rounded,
                    color: Colors.white,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  challenge == null ? 'Tạo tài khoản' : 'Xác thực email',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  challenge == null
                      ? 'Đăng ký để sử dụng Productivity Manager'
                      : 'Hoàn tất xác thực cho ${emailController.text.trim()}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.07),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: challenge == null
                      ? _buildRegistrationForm()
                      : _buildVerificationForm(challenge!),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegistrationForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: fullNameController,
          textCapitalization: TextCapitalization.words,
          decoration: inputDecoration(
            label: 'Họ và tên',
            icon: Icons.person_outline_rounded,
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: inputDecoration(
            label: 'Email',
            icon: Icons.email_outlined,
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: passwordController,
          obscureText: obscurePassword,
          onChanged: (_) => setState(() {}),
          decoration: inputDecoration(
            label: 'Mật khẩu',
            icon: Icons.lock_outline_rounded,
            suffixIcon: IconButton(
              onPressed: () {
                setState(() => obscurePassword = !obscurePassword);
              },
              icon: Icon(
                obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _PasswordRequirement(met: hasMinimumLength, label: 'Ít nhất 6 ký tự'),
        _PasswordRequirement(met: hasUppercase, label: 'Có ít nhất 1 chữ hoa'),
        _PasswordRequirement(
          met: hasSpecialCharacter,
          label: 'Có ít nhất 1 ký tự đặc biệt',
        ),
        const SizedBox(height: 14),
        TextField(
          controller: confirmPasswordController,
          obscureText: obscureConfirmPassword,
          decoration: inputDecoration(
            label: 'Xác nhận mật khẩu',
            icon: Icons.lock_reset_rounded,
            suffixIcon: IconButton(
              onPressed: () {
                setState(
                  () => obscureConfirmPassword = !obscureConfirmPassword,
                );
              },
              icon: Icon(
                obscureConfirmPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          value: verificationMethod,
          decoration: inputDecoration(
            label: 'Phương thức xác thực',
            icon: Icons.verified_user_outlined,
          ),
          items: const [
            DropdownMenuItem(value: 'OTP', child: Text('Mã OTP qua email')),
            DropdownMenuItem(value: 'LINK', child: Text('Link qua email')),
          ],
          onChanged: (value) {
            if (value != null) setState(() => verificationMethod = value);
          },
        ),
        const SizedBox(height: 20),
        _PrimaryButton(
          isLoading: isLoading,
          label: 'Gửi xác thực',
          onPressed: requestVerification,
        ),
        const SizedBox(height: 10),
        Center(
          child: TextButton(
            onPressed: isLoading ? null : () => Navigator.pop(context),
            child: const Text('Đã có tài khoản? Đăng nhập'),
          ),
        ),
      ],
    );
  }

  Widget _buildVerificationForm(RegistrationChallenge currentChallenge) {
    final isOtp = currentChallenge.verificationMethod != 'LINK';
    final minutes = (currentChallenge.expiresInSeconds / 60).ceil();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            isOtp
                ? 'Nhập OTP đã gửi qua email. Mã hết hạn sau $minutes phút.'
                : 'Mở link trong email để xác thực. Link hết hạn sau $minutes phút.',
            style: const TextStyle(
              color: Color(0xFF1D4ED8),
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
        ),
        if (isOtp) ...[
          const SizedBox(height: 16),
          TextField(
            controller: otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 8,
            ),
            decoration: inputDecoration(
              label: 'Mã OTP',
              icon: Icons.password_rounded,
            ).copyWith(counterText: ''),
          ),
          const SizedBox(height: 18),
          _PrimaryButton(
            isLoading: isLoading,
            label: 'Xác thực OTP',
            onPressed: verifyOtp,
          ),
        ] else ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFDDD6FE)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.open_in_new_rounded, color: Color(0xFF7C3AED)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Mở email, bấm nút xác thực trong thư rồi quay lại ứng dụng để đăng nhập.',
                    style: TextStyle(
                      color: Color(0xFF5B21B6),
                      fontWeight: FontWeight.w700,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: isLoading ? null : loginAfterExternalLink,
              icon: const Icon(Icons.login_rounded),
              label: const Text('Tôi đã bấm link, đăng nhập'),
            ),
          ),
        ],
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: isLoading ? null : requestVerification,
                child: const Text('Gửi lại'),
              ),
            ),
            Expanded(
              child: TextButton(
                onPressed: isLoading
                    ? null
                    : () {
                        setState(() {
                          challenge = null;
                          otpController.clear();
                        });
                      },
                child: const Text('Sửa thông tin'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  InputDecoration inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
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
}

class _PasswordRequirement extends StatelessWidget {
  final bool met;
  final String label;

  const _PasswordRequirement({required this.met, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 17,
            color: met ? const Color(0xFF16A34A) : const Color(0xFF9CA3AF),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: met ? const Color(0xFF16A34A) : const Color(0xFF6B7280),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final bool isLoading;
  final String label;
  final VoidCallback onPressed;

  const _PrimaryButton({
    required this.isLoading,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7C3AED),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }
}
