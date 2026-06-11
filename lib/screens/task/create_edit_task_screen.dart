import 'package:flutter/material.dart';

import '../../data/mock_tasks.dart';
import '../../services/app_data_service.dart';

class CreateEditTaskScreen extends StatefulWidget {
  final String projectId;
  final MockTask? existingTask;

  const CreateEditTaskScreen({
    super.key,
    required this.projectId,
    this.existingTask,
  });

  @override
  State<CreateEditTaskScreen> createState() => _CreateEditTaskScreenState();
}

class _CreateEditTaskScreenState extends State<CreateEditTaskScreen> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final requirementController = TextEditingController();
  final checklistController = TextEditingController();

  String selectedAssignee = 'Nguyễn Văn A';
  String selectedAssigneeAvatar = 'NA';
  String selectedPriority = 'Medium';
  DateTime selectedDate = DateTime.now().add(const Duration(days: 5));
  bool isSaving = false;

  final List<String> requirements = [];
  final List<String> checklistItems = [];

  final List<_AssigneeOption> assignees = [
    _AssigneeOption(name: 'Nguyễn Văn A', avatar: 'NA'),
    _AssigneeOption(name: 'Trần Minh', avatar: 'TM'),
    _AssigneeOption(name: 'Lê Thị C', avatar: 'LC'),
    _AssigneeOption(name: 'Hà Nhi', avatar: 'HN'),
  ];

  final List<String> priorities = const ['Low', 'Medium', 'High'];

  bool get isEditMode => widget.existingTask != null;

  @override
  void initState() {
    super.initState();

    final task = widget.existingTask;
    if (task == null) {
      requirements.add('Yêu cầu kỹ thuật từ quản lý');
      checklistItems.add('Kiểm tra giao diện mobile');
      return;
    }

    titleController.text = task.title;
    descriptionController.text = task.description;
    selectedAssignee = task.assigneeName;
    selectedAssigneeAvatar = task.assigneeAvatar;
    selectedPriority = task.priority;
    checklistItems.addAll(
      List.generate(task.checklistTotal, (index) => 'Checklist ${index + 1}'),
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    requirementController.dispose();
    checklistController.dispose();
    super.dispose();
  }

  void addRequirement() {
    final value = requirementController.text.trim();
    if (value.isEmpty) {
      showMessage('Vui lòng nhập yêu cầu kỹ thuật');
      return;
    }

    setState(() {
      requirements.add(value);
      requirementController.clear();
    });
  }

  void addChecklistItem() {
    final value = checklistController.text.trim();
    if (value.isEmpty) {
      showMessage('Vui lòng nhập checklist');
      return;
    }

    setState(() {
      checklistItems.add(value);
      checklistController.clear();
    });
  }

  Future<void> pickDueDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate == null) return;

    setState(() {
      selectedDate = pickedDate;
    });
  }

  Future<void> saveTask() async {
    final title = titleController.text.trim();
    final description = descriptionController.text.trim();

    if (title.isEmpty) {
      showMessage('Tiêu đề công việc không được bỏ trống');
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final normalizedDescription =
          description.isEmpty ? 'Chưa có mô tả cho công việc này.' : description;

      final savedTask = isEditMode
          ? await AppDataService.updateTask(
              MockTask(
                id: widget.existingTask!.id,
                listId: widget.existingTask!.listId,
                projectId: widget.projectId,
                title: title,
                description: normalizedDescription,
                creatorId: widget.existingTask!.creatorId,
                assigneeId: widget.existingTask!.assigneeId,
                assigneeName: selectedAssignee,
                assigneeAvatar: selectedAssigneeAvatar,
                priority: selectedPriority,
                status: widget.existingTask!.status,
                dueDate: formatDate(selectedDate),
                checklistDone: widget.existingTask!.checklistDone,
                checklistTotal:
                    checklistItems.isEmpty ? 1 : checklistItems.length,
                commentCount: widget.existingTask!.commentCount,
              ),
            )
          : await AppDataService.createTask(
              projectId: widget.projectId,
              title: title,
              description: normalizedDescription,
              assigneeName: selectedAssignee,
              priority: selectedPriority,
              dueDate: formatDate(selectedDate),
              checklistItems: checklistItems,
              requirements: requirements,
            );

      if (!mounted) return;
      Navigator.pop(context, savedTask);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        isSaving = false;
      });
      showMessage('Không thể lưu task: $error');
    }
  }

  String formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month';
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: Text(isEditMode ? 'Chỉnh sửa công việc' : 'Tạo công việc mới'),
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
          children: [
            _SectionCard(
              title: 'Thông tin công việc',
              child: Column(
                children: [
                  TextField(
                    controller: titleController,
                    decoration: _inputDecoration(
                      label: 'Tiêu đề',
                      icon: Icons.title_rounded,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: descriptionController,
                    maxLines: 4,
                    decoration: _inputDecoration(
                      label: 'Mô tả',
                      icon: Icons.description_outlined,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Phân công & Deadline',
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedAssignee,
                    decoration: _inputDecoration(
                      label: 'Người xử lý',
                      icon: Icons.person_outline_rounded,
                    ),
                    items: assignees.map((assignee) {
                      return DropdownMenuItem(
                        value: assignee.name,
                        child: Text('${assignee.name} (${assignee.avatar})'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      final assignee =
                          assignees.firstWhere((item) => item.name == value);
                      setState(() {
                        selectedAssignee = assignee.name;
                        selectedAssigneeAvatar = assignee.avatar;
                      });
                    },
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: selectedPriority,
                    decoration: _inputDecoration(
                      label: 'Mức độ ưu tiên',
                      icon: Icons.flag_outlined,
                    ),
                    items: priorities.map((priority) {
                      return DropdownMenuItem(
                        value: priority,
                        child: Text(_priorityLabel(priority)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        selectedPriority = value;
                      });
                    },
                  ),
                  const SizedBox(height: 14),
                  ListTile(
                    onTap: pickDueDate,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    tileColor: const Color(0xFFF3F4F6),
                    leading: const Icon(Icons.calendar_today_outlined),
                    title: Text('Hạn chót: ${formatDate(selectedDate)}'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _EditableListSection(
              title: 'Yêu cầu kỹ thuật từ quản lý',
              controller: requirementController,
              hint: 'Thêm yêu cầu kỹ thuật',
              items: requirements,
              onAdd: addRequirement,
              onRemove: (index) {
                setState(() {
                  requirements.removeAt(index);
                });
              },
            ),
            const SizedBox(height: 16),
            _EditableListSection(
              title: 'Checklist',
              controller: checklistController,
              hint: 'Thêm checklist',
              items: checklistItems,
              onAdd: addChecklistItem,
              onRemove: (index) {
                setState(() {
                  checklistItems.removeAt(index);
                });
              },
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        color: Colors.white,
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: isSaving ? null : saveTask,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              isSaving
                  ? 'Đang lưu...'
                  : isEditMode
                      ? 'Lưu chỉnh sửa'
                      : 'Tạo mới công việc',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: const Color(0xFFF3F4F6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }

  String _priorityLabel(String priority) {
    switch (priority) {
      case 'High':
        return 'Cao';
      case 'Medium':
        return 'Trung bình';
      default:
        return 'Thấp';
    }
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _EditableListSection extends StatelessWidget {
  final String title;
  final TextEditingController controller;
  final String hint;
  final List<String> items;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  const _EditableListSection({
    required this.title,
    required this.controller,
    required this.hint,
    required this.items,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: title,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: hint,
                    filled: true,
                    fillColor: const Color(0xFFF3F4F6),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const Text(
              'Chưa có dữ liệu',
              style: TextStyle(
                color: Color(0xFF9CA3AF),
                fontWeight: FontWeight.w600,
              ),
            )
          else
            ...List.generate(items.length, (index) {
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: 14,
                  child: Text('${index + 1}'),
                ),
                title: Text(items[index]),
                trailing: IconButton(
                  onPressed: () => onRemove(index),
                  icon: const Icon(Icons.close_rounded),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _AssigneeOption {
  final String name;
  final String avatar;

  _AssigneeOption({
    required this.name,
    required this.avatar,
  });
}
