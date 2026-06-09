import 'package:flutter/material.dart';

import '../../data/mock_users.dart';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import 'avatar_crop_screen.dart';

class EditProfileScreen extends StatefulWidget {
  final MockUser user;

  const EditProfileScreen({
    super.key,
    required this.user,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController fullNameController;
  late TextEditingController avatarTextController;
  Uint8List? avatarImageBytes;

  @override
  void initState() {
    super.initState();

    fullNameController = TextEditingController(
      text: widget.user.fullName,
    );

    avatarTextController = TextEditingController(
      text: widget.user.avatarText,
    );

    avatarImageBytes = widget.user.avatarImageBytes;


  }

  Future<void> pickAndCropAvatar() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final imageBytes = result.files.single.bytes;

    if (imageBytes == null) {
      showMessage('Không đọc được dữ liệu ảnh. Vui lòng chọn ảnh khác.');
      return;
    }

    if (!mounted) return;

    final croppedBytes = await Navigator.push<Uint8List>(
      context,
      MaterialPageRoute(
        builder: (_) => AvatarCropScreen(
          imageBytes: imageBytes,
        ),
      ),
    );

    if (!mounted || croppedBytes == null) return;

    setState(() {
      avatarImageBytes = croppedBytes;
    });

    showMessage('Đã cập nhật ảnh đại diện');
  }

  @override
  void dispose() {
    fullNameController.dispose();
    avatarTextController.dispose();
    super.dispose();
  }

  void saveProfile() {
    final fullName = fullNameController.text.trim();
    final avatarText = avatarTextController.text.trim().toUpperCase();

    if (fullName.isEmpty) {
      showMessage('Họ tên không được bỏ trống');
      return;
    }

    if (avatarText.isEmpty) {
      showMessage('Ký hiệu avatar không được bỏ trống');
      return;
    }

    final updatedUser = widget.user.copyWith(
      fullName: fullName,
      avatarText: avatarText.length > 2 ? avatarText.substring(0, 2) : avatarText,
      avatarImageBytes: avatarImageBytes,
    );

    Navigator.pop(context, updatedUser);
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
    final previewName = fullNameController.text.trim().isEmpty
        ? widget.user.fullName
        : fullNameController.text.trim();

    final previewAvatar = avatarTextController.text.trim().isEmpty
        ? widget.user.avatarText
        : avatarTextController.text.trim().toUpperCase();

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
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProfilePreviewCard(
                      fullName: previewName,
                      email: widget.user.email,
                      role: widget.user.role,
                      avatarText: previewAvatar.length > 2
                          ? previewAvatar.substring(0, 2)
                          : previewAvatar,
                      avatarImageBytes: avatarImageBytes,
                      onPickAvatar: pickAndCropAvatar,
                    ),

                    const SizedBox(height: 18),

                    _FormCard(
                      title: 'Thông tin cá nhân',
                      icon: Icons.person_outline_rounded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _FieldLabel(
                            label: 'Họ và tên',
                            requiredField: true,
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: fullNameController,
                            onChanged: (_) => setState(() {}),
                            decoration: _inputDecoration(
                              hintText: 'Nhập họ và tên',
                              icon: Icons.badge_outlined,
                            ),
                          ),

                          const SizedBox(height: 16),

                          const _FieldLabel(
                            label: 'Ký hiệu avatar',
                            requiredField: true,
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: avatarTextController,
                            maxLength: 2,
                            textCapitalization: TextCapitalization.characters,
                            onChanged: (_) => setState(() {}),
                            decoration: _inputDecoration(
                              hintText: 'VD: US',
                              icon: Icons.account_circle_outlined,
                            ).copyWith(counterText: ''),
                          ),

                          const SizedBox(height: 16),

                          const _FieldLabel(label: 'Email'),
                          const SizedBox(height: 8),
                          TextField(
                            enabled: false,
                            controller: TextEditingController(
                              text: widget.user.email,
                            ),
                            decoration: _inputDecoration(
                              hintText: 'Email',
                              icon: Icons.email_outlined,
                            ),
                          ),

                          const SizedBox(height: 16),

                          const _FieldLabel(label: 'Vai trò'),
                          const SizedBox(height: 8),
                          TextField(
                            enabled: false,
                            controller: TextEditingController(
                              text: widget.user.role,
                            ),
                            decoration: _inputDecoration(
                              hintText: 'Role',
                              icon: Icons.verified_user_outlined,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    _FormCard(
                      title: 'Ghi chú mock',
                      icon: Icons.info_outline_rounded,
                      child: const Text(
                        'Màn này chỉ cập nhật dữ liệu local trong UI. Sau này khi gắn backend, nút Lưu sẽ gọi API cập nhật hồ sơ người dùng.',
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
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: saveProfile,
            icon: const Icon(Icons.save_rounded),
            label: const Text('Lưu hồ sơ'),
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
              'Chỉnh sửa hồ sơ',
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
              Icons.edit_rounded,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfilePreviewCard extends StatelessWidget {
  final String fullName;
  final String email;
  final String role;
  final String avatarText;
  final Uint8List? avatarImageBytes;
  final VoidCallback onPickAvatar;

  const _ProfilePreviewCard({
    required this.fullName,
    required this.email,
    required this.role,
    required this.avatarText,
    required this.avatarImageBytes,
    required this.onPickAvatar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2563EB),
            Color(0xFF9333EA),
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
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 46,
                backgroundColor: const Color(0xFF6366F1),
                backgroundImage: avatarImageBytes == null
                    ? null
                    : MemoryImage(avatarImageBytes!),
                child: avatarImageBytes == null
                    ? Text(
                  avatarText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                )
                    : null,
              ),
              Positioned(
                right: -4,
                bottom: -4,
                child: InkWell(
                  onTap: onPickAvatar,
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.16),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Color(0xFF7C3AED),
                      size: 19,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Text(
            fullName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            email,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              role,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: onPickAvatar,
              icon: const Icon(Icons.upload_file_rounded),
              label: const Text('Chọn ảnh từ máy'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(
                  color: Colors.white.withOpacity(0.6),
                ),
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
    );
  }
}

class _FormCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _FormCard({
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