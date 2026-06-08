import 'package:flutter/material.dart';
import '../../data/mock_workspaces.dart';

class CreateWorkspaceScreen extends StatefulWidget {
  const CreateWorkspaceScreen({super.key});

  @override
  State<CreateWorkspaceScreen> createState() => _CreateWorkspaceScreenState();
}

class _CreateWorkspaceScreenState extends State<CreateWorkspaceScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController iconController = TextEditingController(text: 'WS');

  void createWorkspace() {
    final name = nameController.text.trim();
    final description = descriptionController.text.trim();
    final iconText = iconController.text.trim().toUpperCase();

    if (name.isEmpty) {
      showMessage('Tên workspace không được bỏ trống');
      return;
    }

    final workspace = MockWorkspace(
      id: 'ws${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: description.isEmpty
          ? 'Không gian làm việc mới'
          : description,
      memberCount: 1,
      projectCount: 0,
      iconText: iconText.isEmpty ? 'WS' : iconText.substring(0, iconText.length > 2 ? 2 : iconText.length),
    );

    Navigator.pop(context, workspace);
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
    nameController.dispose();
    descriptionController.dispose();
    iconController.dispose();
    super.dispose();
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
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PreviewCard(
                      nameController: nameController,
                      descriptionController: descriptionController,
                      iconController: iconController,
                      onChanged: () {
                        setState(() {});
                      },
                    ),

                    const SizedBox(height: 18),

                    _FormCard(
                      title: 'Thông tin Workspace',
                      icon: Icons.workspaces_outline,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _FieldLabel(
                            label: 'Tên workspace',
                            requiredField: true,
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: nameController,
                            onChanged: (_) => setState(() {}),
                            decoration: _inputDecoration(
                              hintText: 'Ví dụ: Team Mobile App',
                              icon: Icons.title_rounded,
                            ),
                          ),

                          const SizedBox(height: 16),

                          const _FieldLabel(label: 'Mô tả'),
                          const SizedBox(height: 8),
                          TextField(
                            controller: descriptionController,
                            onChanged: (_) => setState(() {}),
                            maxLines: 4,
                            decoration: _inputDecoration(
                              hintText: 'Mô tả ngắn về workspace này',
                              icon: Icons.description_outlined,
                            ),
                          ),

                          const SizedBox(height: 16),

                          const _FieldLabel(label: 'Ký hiệu icon'),
                          const SizedBox(height: 8),
                          TextField(
                            controller: iconController,
                            maxLength: 2,
                            textCapitalization: TextCapitalization.characters,
                            onChanged: (_) => setState(() {}),
                            decoration: _inputDecoration(
                              hintText: 'VD: MB',
                              icon: Icons.badge_outlined,
                            ).copyWith(counterText: ''),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    _FormCard(
                      title: 'Mock mặc định',
                      icon: Icons.info_outline_rounded,
                      child: Column(
                        children: [
                          _InfoRow(
                            icon: Icons.group_outlined,
                            label: 'Số thành viên',
                            value: '1 thành viên',
                          ),
                          const Divider(height: 24),
                          _InfoRow(
                            icon: Icons.folder_open_outlined,
                            label: 'Số dự án',
                            value: '0 dự án',
                          ),
                          const Divider(height: 24),
                          _InfoRow(
                            icon: Icons.cloud_done_outlined,
                            label: 'Trạng thái',
                            value: 'Mock local',
                          ),
                        ],
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
            onPressed: createWorkspace,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Tạo workspace'),
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
              'Tạo workspace',
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
              Icons.workspaces_rounded,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final TextEditingController iconController;
  final VoidCallback onChanged;

  const _PreviewCard({
    required this.nameController,
    required this.descriptionController,
    required this.iconController,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final name = nameController.text.trim().isEmpty
        ? 'Workspace mới'
        : nameController.text.trim();

    final description = descriptionController.text.trim().isEmpty
        ? 'Không gian làm việc mới'
        : descriptionController.text.trim();

    final iconText = iconController.text.trim().isEmpty
        ? 'WS'
        : iconController.text.trim().toUpperCase();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                iconText.length > 2 ? iconText.substring(0, 2) : iconText,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: const Color(0xFF7C3AED),
        ),
        const SizedBox(width: 12),
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
          value,
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}