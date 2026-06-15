import 'package:flutter/material.dart';

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

  bool isLoading = false;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  Future<void> handleRegister() async {
    final fullName = fullNameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (fullName.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      showMessage('Vui lòng nhập đầy đủ thông tin');
      return;
    }

    if (!email.contains('@')) {
      showMessage('Email không đúng định dạng');
      return;
    }

    if (password.length < 6) {
      showMessage('Mật khẩu phải có ít nhất 6 ký tự');
      return;
    }

    if (password != confirmPassword) {
      showMessage('Mật khẩu xác nhận không khớp');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final user = await AppDataService.register(
        fullName: fullName,
        email: email,
        password: password,
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => WorkspaceDashboardScreen(user: user),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      final message = error.toString().contains('409')
          ? 'Email này đã tồn tại'
          : 'Không thể đăng ký tài khoản: $error';

      showMessage(message);
    }
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
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
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
                      colors: [
                        Color(0xFF2563EB),
                        Color(0xFF9333EA),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withOpacity(0.25),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person_add_alt_1_rounded,
                    color: Colors.white,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Tạo tài khoản',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Đăng ký để sử dụng Productivity Manager',
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.07),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Họ và tên',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: fullNameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: inputDecoration(
                          hintText: 'Nguyễn Văn A',
                          icon: Icons.person_outline_rounded,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Email',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: inputDecoration(
                          hintText: 'email@company.com',
                          icon: Icons.email_outlined,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Mật khẩu',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: passwordController,
                        obscureText: obscurePassword,
                        decoration: inputDecoration(
                          hintText: 'Nhập mật khẩu',
                          icon: Icons.lock_outline_rounded,
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                obscurePassword = !obscurePassword;
                              });
                            },
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Xác nhận mật khẩu',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: confirmPasswordController,
                        obscureText: obscureConfirmPassword,
                        decoration: inputDecoration(
                          hintText: 'Nhập lại mật khẩu',
                          icon: Icons.lock_reset_rounded,
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
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : handleRegister,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF2563EB),
                                  Color(0xFF9333EA),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: isLoading
                                  ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                                  : const Text(
                                'Đăng ký',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton(
                          onPressed: isLoading
                              ? null
                              : () {
                            Navigator.pop(context);
                          },
                          child: const Text('Đã có tài khoản? Đăng nhập'),
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