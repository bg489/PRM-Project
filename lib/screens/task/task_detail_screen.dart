import 'package:flutter/material.dart';

import '../../data/mock_tasks.dart';
import '../../data/mock_users.dart';
import '../../services/app_data_service.dart';
import '../../utils/role_permissions.dart';

class TaskDetailScreen extends StatefulWidget {
  final MockTask task;
  final MockUser? currentUser;

  const TaskDetailScreen({
    super.key,
    required this.task,
    this.currentUser,
  });

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late MockTask task;
  List<ChecklistItemData> checklistItems = const [];
  List<RequirementData> requirements = const [];
  List<CommentData> comments = const [];
  bool isLoading = true;

  final commentController = TextEditingController();

  bool get canApproveRequirement {
    final user = widget.currentUser;
    return user != null && RolePermissions.canApproveRequirements(user);
  }

  @override
  void initState() {
    super.initState();
    task = widget.task;
    loadDetail();
  }

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  Future<void> loadDetail() async {
    try {
      final detail = await AppDataService.fetchTaskDetail(task.id);
      if (!mounted) return;
      setState(() {
        task = detail.task;
        checklistItems = detail.checklistItems;
        requirements = detail.requirements;
        comments = detail.comments;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        checklistItems = List.generate(
          task.checklistTotal,
          (index) => ChecklistItemData(
            id: 'local_$index',
            taskId: task.id,
            title: 'Checklist ${index + 1}',
            isCompleted: index < task.checklistDone,
            position: index + 1,
          ),
        );
        requirements = const [];
        comments = const [];
        isLoading = false;
      });
    }
  }

  Future<void> toggleChecklist(ChecklistItemData item) async {
    final updatedValue = !item.isCompleted;
    setState(() {
      checklistItems = checklistItems.map((current) {
        if (current.id != item.id) return current;
        return ChecklistItemData(
          id: current.id,
          taskId: current.taskId,
          title: current.title,
          isCompleted: updatedValue,
          position: current.position,
        );
      }).toList();
    });

    try {
      await AppDataService.updateChecklistItem(
        id: item.id,
        isCompleted: updatedValue,
      );
    } catch (error) {
      showMessage('Không thể cập nhật checklist: $error');
      loadDetail();
    }
  }

  Future<void> submitRequirement(RequirementData requirement) async {
    try {
      await AppDataService.submitRequirement(requirement.id);
      await loadDetail();
      showMessage('Đã gửi yêu cầu duyệt cho quản lý');
    } catch (error) {
      showMessage('Không thể gửi yêu cầu duyệt: $error');
    }
  }

  Future<void> approveRequirement(RequirementData requirement) async {
    try {
      await AppDataService.reviewRequirement(
        requirementId: requirement.id,
        status: 'APPROVED',
      );
      await loadDetail();
      showMessage('Đã phê duyệt yêu cầu');
    } catch (error) {
      showMessage('Không thể phê duyệt: $error');
    }
  }

  Future<void> rejectRequirement(RequirementData requirement) async {
    final reasonController = TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Lý do từ chối'),
          content: TextField(
            controller: reasonController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Nhập lý do cần sửa đổi...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, reasonController.text.trim());
              },
              child: const Text('Xác nhận'),
            ),
          ],
        );
      },
    );

    if (reason == null || reason.isEmpty) return;

    try {
      await AppDataService.reviewRequirement(
        requirementId: requirement.id,
        status: 'REJECTED',
        rejectReason: reason,
      );
      await loadDetail();
      showMessage('Đã từ chối yêu cầu');
    } catch (error) {
      showMessage('Không thể từ chối: $error');
    }
  }

  Future<void> addComment() async {
    final content = commentController.text.trim();
    if (content.isEmpty) {
      showMessage('Vui lòng nhập nội dung bình luận');
      return;
    }

    try {
      final comment = await AppDataService.addComment(
        taskId: task.id,
        content: content,
      );
      setState(() {
        comments = [...comments, comment];
        commentController.clear();
      });
    } catch (error) {
      showMessage('Không thể thêm bình luận: $error');
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
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F7FB),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final checklistDone =
        checklistItems.where((item) => item.isCompleted).length;
    final checklistProgress = checklistItems.isEmpty
        ? 0.0
        : checklistDone / checklistItems.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: Text(task.title),
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: loadDetail,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
          children: [
            _OverviewCard(task: task),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Mô tả công việc',
              icon: Icons.description_outlined,
              child: Text(
                task.description,
                style: const TextStyle(
                  color: Color(0xFF4B5563),
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Yêu cầu kỹ thuật từ quản lý',
              icon: Icons.verified_user_outlined,
              child: requirements.isEmpty
                  ? const Text('Chưa có yêu cầu kỹ thuật')
                  : Column(
                      children: requirements.map((requirement) {
                        return _RequirementTile(
                          requirement: requirement,
                          managerMode: canApproveRequirement,
                          onSubmit: () => submitRequirement(requirement),
                          onApprove: () => approveRequirement(requirement),
                          onReject: () => rejectRequirement(requirement),
                        );
                      }).toList(),
                    ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Checklist',
              icon: Icons.checklist_rounded,
              trailing: Text(
                '$checklistDone/${checklistItems.length}',
                style: const TextStyle(
                  color: Color(0xFF7C3AED),
                  fontWeight: FontWeight.w900,
                ),
              ),
              child: Column(
                children: [
                  LinearProgressIndicator(value: checklistProgress),
                  const SizedBox(height: 12),
                  if (checklistItems.isEmpty)
                    const Text('Chưa có checklist')
                  else
                    ...checklistItems.map((item) {
                      return CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: item.isCompleted,
                        onChanged: (_) => toggleChecklist(item),
                        title: Text(item.title),
                      );
                    }),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Bình luận',
              icon: Icons.chat_bubble_outline_rounded,
              child: Column(
                children: [
                  if (comments.isEmpty)
                    const Text('Chưa có bình luận')
                  else
                    ...comments.map((comment) {
                      return _CommentBubble(comment: comment);
                    }),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: commentController,
                          decoration: const InputDecoration(
                            hintText: 'Nhập bình luận...',
                            filled: true,
                            fillColor: Color(0xFFF3F4F6),
                            border: OutlineInputBorder(
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton.filled(
                        onPressed: addComment,
                        icon: const Icon(Icons.send_rounded),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final MockTask task;

  const _OverviewCard({required this.task});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            task.title,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Badge(label: task.priority, color: _priorityColor(task.priority)),
              _Badge(label: task.status, color: const Color(0xFF7C3AED)),
              _Badge(label: 'Hạn: ${task.dueDate}', color: const Color(0xFF2563EB)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(child: Text(task.assigneeAvatar)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  task.assigneeName,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'High':
        return const Color(0xFFEF4444);
      case 'Medium':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF22C55E);
    }
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF7C3AED)),
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
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _RequirementTile extends StatelessWidget {
  final RequirementData requirement;
  final bool managerMode;
  final VoidCallback onSubmit;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _RequirementTile({
    required this.requirement,
    required this.managerMode,
    required this.onSubmit,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (requirement.status) {
      'APPROVED' => const Color(0xFF22C55E),
      'REJECTED' => const Color(0xFFEF4444),
      'WAITING' => const Color(0xFFF59E0B),
      _ => const Color(0xFF6B7280),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            requirement.title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _Badge(label: requirement.statusLabel, color: color),
              const Spacer(),
              if (!managerMode && requirement.status == 'NOT_SUBMITTED')
                TextButton(onPressed: onSubmit, child: const Text('Gửi duyệt')),
              if (managerMode && requirement.status == 'WAITING') ...[
                TextButton(
                  onPressed: onReject,
                  child: const Text(
                    'Từ chối',
                    style: TextStyle(color: Color(0xFFEF4444)),
                  ),
                ),
                ElevatedButton(
                  onPressed: onApprove,
                  child: const Text('Duyệt'),
                ),
              ],
            ],
          ),
          if (requirement.rejectReason != null) ...[
            const SizedBox(height: 8),
            Text(
              'Lý do: ${requirement.rejectReason}',
              style: const TextStyle(color: Color(0xFFEF4444)),
            ),
          ],
        ],
      ),
    );
  }
}

class _CommentBubble extends StatelessWidget {
  final CommentData comment;

  const _CommentBubble({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${comment.name} (${comment.avatar})',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(comment.content),
          const SizedBox(height: 4),
          Text(
            comment.time,
            style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.06),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ],
  );
}
