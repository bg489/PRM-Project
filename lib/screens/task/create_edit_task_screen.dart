import 'package:flutter/material.dart';
import '../../data/mock_tasks.dart';

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
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController requirementController = TextEditingController();
  final TextEditingController checklistController = TextEditingController();

  String selectedAssignee = 'Nguyễn Văn A';
  String selectedAssigneeAvatar = 'NA';
  String selectedPriority = 'Medium';
  DateTime selectedDate = DateTime.now().add(const Duration(days: 5));

  final List<String> requirements = [];
  final List<String> checklistItems = [];

  final List<_AssigneeOption> assignees = [
    _AssigneeOption(name: 'Nguyễn Văn A', avatar: 'NA'),
    _AssigneeOption(name: 'Trần Minh', avatar: 'TM'),
    _AssigneeOption(name: 'Lê Thị C', avatar: 'LC'),
    _AssigneeOption(name: 'Hà Nhi', avatar: 'HN'),
  ];

  final List<String> priorities = ['Low', 'Medium', 'High'];

  bool get isEditMode => widget.existingTask != null;

  @override
  void initState() {
    super.initState();

    final task = widget.existingTask;

    if (task != null) {
      titleController.text = task.title;
      descriptionController.text = task.description;
      selectedAssignee = task.assigneeName;
      selectedAssigneeAvatar = task.assigneeAvatar;
      selectedPriority = task.priority;
      checklistItems.addAll(
        List.generate(
          task.checklistTotal,
              (index) => 'Checklist ${index + 1}',
        ),
      );
    } else {
      requirements.add('Yêu cầu kỹ thuật từ quản lý');
      checklistItems.add('Kiểm tra giao diện mobile');
    }
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

  void removeRequirement(int index) {
    setState(() {
      requirements.removeAt(index);
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

  void removeChecklistItem(int index) {
    setState(() {
      checklistItems.removeAt(index);
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

  void saveTask() {
    final title = titleController.text.trim();
    final description = descriptionController.text.trim();

    if (title.isEmpty) {
      showMessage('Tiêu đề công việc không được bỏ trống');
      return;
    }

    final newTask = MockTask(
      id: widget.existingTask?.id ??
          't${DateTime.now().millisecondsSinceEpoch}',
      projectId: widget.projectId,
      title: title,
      description: description.isEmpty
          ? 'Chưa có mô tả cho công việc này.'
          : description,
      assigneeName: selectedAssignee,
      assigneeAvatar: selectedAssigneeAvatar,
      priority: selectedPriority,
      status: widget.existingTask?.status ?? 'Cần làm',
      dueDate: formatDate(selectedDate),
      checklistDone: widget.existingTask?.checklistDone ?? 0,
      checklistTotal: checklistItems.isEmpty ? 1 : checklistItems.length,
      commentCount: widget.existingTask?.commentCount ?? 0,
    );

    Navigator.pop(context, newTask);
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
    final priorityConfig = getPriorityConfig(selectedPriority);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: Column(
          children: [
            _CreateTaskHeader(
              title: isEditMode ? 'Chỉnh sửa công việc' : 'Tạo công việc mới',
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionCard(
                      title: 'Thông tin công việc',
                      icon: Icons.task_alt_rounded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FieldLabel(
                            label: 'Tiêu đề',
                            requiredField: true,
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: titleController,
                            decoration: _inputDecoration(
                              hintText: 'Nhập tiêu đề công việc',
                              icon: Icons.title_rounded,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _FieldLabel(label: 'Mô tả'),
                          const SizedBox(height: 8),
                          TextField(
                            controller: descriptionController,
                            maxLines: 4,
                            decoration: _inputDecoration(
                              hintText: 'Nhập mô tả chi tiết',
                              icon: Icons.description_outlined,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    _SectionCard(
                      title: 'Phân công & Deadline',
                      icon: Icons.group_outlined,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FieldLabel(label: 'Người xử lý'),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: selectedAssignee,
                            decoration: _inputDecoration(
                              hintText: 'Chọn thành viên',
                              icon: Icons.person_outline_rounded,
                            ),
                            items: assignees.map((assignee) {
                              return DropdownMenuItem(
                                value: assignee.name,
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor: const Color(0xFF6366F1),
                                      child: Text(
                                        assignee.avatar,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(assignee.name),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value == null) return;

                              final assignee = assignees.firstWhere(
                                    (item) => item.name == value,
                              );

                              setState(() {
                                selectedAssignee = assignee.name;
                                selectedAssigneeAvatar = assignee.avatar;
                              });
                            },
                          ),

                          const SizedBox(height: 16),

                          _FieldLabel(label: 'Mức độ ưu tiên'),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: selectedPriority,
                            decoration: _inputDecoration(
                              hintText: 'Chọn độ ưu tiên',
                              icon: Icons.flag_outlined,
                            ),
                            items: priorities.map((priority) {
                              final config = getPriorityConfig(priority);

                              return DropdownMenuItem(
                                value: priority,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: config.color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(config.label),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value == null) return;

                              setState(() {
                                selectedPriority = value;
                              });
                            },
                          ),

                          const SizedBox(height: 16),

                          _FieldLabel(label: 'Ngày hạn chót'),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: pickDueDate,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 15,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today_outlined,
                                    color: Color(0xFF6B7280),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    formatDate(selectedDate),
                                    style: const TextStyle(
                                      color: Color(0xFF111827),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: priorityConfig.color.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      priorityConfig.label,
                                      style: TextStyle(
                                        color: priorityConfig.color,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12,
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

                    const SizedBox(height: 16),

                    _SectionCard(
                      title: 'Yêu cầu kỹ thuật từ Quản lý',
                      icon: Icons.verified_user_outlined,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: requirementController,
                                  decoration: _inputDecoration(
                                    hintText: 'Thêm yêu cầu kỹ thuật',
                                    icon: Icons.rule_rounded,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              _AddButton(onTap: addRequirement),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (requirements.isEmpty)
                            const _EmptyText(
                              text: 'Chưa có yêu cầu kỹ thuật nào',
                            )
                          else
                            ...List.generate(requirements.length, (index) {
                              return _ListItemChip(
                                title: requirements[index],
                                index: index,
                                onRemove: () => removeRequirement(index),
                              );
                            }),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    _SectionCard(
                      title: 'Checklist',
                      icon: Icons.checklist_rounded,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: checklistController,
                                  decoration: _inputDecoration(
                                    hintText: 'Thêm checklist',
                                    icon: Icons.add_task_rounded,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              _AddButton(onTap: addChecklistItem),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (checklistItems.isEmpty)
                            const _EmptyText(
                              text: 'Chưa có checklist nào',
                            )
                          else
                            ...List.generate(checklistItems.length, (index) {
                              return _ListItemChip(
                                title: checklistItems[index],
                                index: index,
                                onRemove: () => removeChecklistItem(index),
                              );
                            }),
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
          child: ElevatedButton(
            onPressed: saveTask,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              isEditMode ? 'Lưu chỉnh sửa' : 'Tạo mới công việc',
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

  _PriorityConfig getPriorityConfig(String priority) {
    switch (priority) {
      case 'High':
        return _PriorityConfig('Cao', const Color(0xFFEF4444));
      case 'Medium':
        return _PriorityConfig('Trung bình', const Color(0xFFF59E0B));
      default:
        return _PriorityConfig('Thấp', const Color(0xFF22C55E));
    }
  }
}

class _CreateTaskHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const _CreateTaskHeader({
    required this.title,
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
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
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
        crossAxisAlignment: CrossAxisAlignment.start,
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

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddButton({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF2563EB),
              Color(0xFF9333EA),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.add_rounded,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _ListItemChip extends StatelessWidget {
  final String title;
  final int index;
  final VoidCallback onRemove;

  const _ListItemChip({
    required this.title,
    required this.index,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: const Color(0xFFEDE9FE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Color(0xFF7C3AED),
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFF374151),
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(
              Icons.close_rounded,
              color: Color(0xFFEF4444),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyText extends StatelessWidget {
  final String text;

  const _EmptyText({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF9CA3AF),
          fontWeight: FontWeight.w600,
        ),
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

class _PriorityConfig {
  final String label;
  final Color color;

  _PriorityConfig(this.label, this.color);
}