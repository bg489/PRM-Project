import 'package:flutter/material.dart';
import '../../data/mock_tasks.dart';
import '../../data/mock_users.dart';
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
  late List<_ChecklistItem> checklistItems;
  late List<_RequirementItem> requirements;
  late List<_CommentItem> comments;

  final TextEditingController commentController = TextEditingController();

  bool get canApproveRequirement {
    final user = widget.currentUser;

    if (user == null) return false;

    return RolePermissions.canApproveRequirements(user);
  }

  @override
  void initState() {
    super.initState();

    checklistItems = List.generate(
      widget.task.checklistTotal,
          (index) => _ChecklistItem(
        title: _mockChecklistTitles[index % _mockChecklistTitles.length],
        isDone: index < widget.task.checklistDone,
      ),
    );

    requirements = [
      _RequirementItem(
        title: 'Giao diện phải đúng layout mobile đã thống nhất',
        status: 'Đang chờ duyệt',
      ),
      _RequirementItem(
        title: 'Task card phải hiển thị priority, deadline và assignee',
        status: 'Đã duyệt',
      ),
      _RequirementItem(
        title: 'Checklist phải cập nhật tiến độ ngay khi tick chọn',
        status: 'Chưa gửi',
      ),
    ];

    comments = [
      _CommentItem(
        name: 'Nguyễn Văn A',
        avatar: 'NA',
        content: 'Phần UI đang ổn, kiểm tra thêm spacing giữa các card.',
        time: '09:20',
        isMine: false,
      ),
      _CommentItem(
        name: widget.task.assigneeName,
        avatar: widget.task.assigneeAvatar,
        content: 'Em đã cập nhật checklist và gửi yêu cầu duyệt.',
        time: '10:05',
        isMine: true,
      ),
    ];
  }

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  int get completedChecklistCount {
    return checklistItems.where((item) => item.isDone).length;
  }

  double get checklistProgress {
    if (checklistItems.isEmpty) return 0;
    return completedChecklistCount / checklistItems.length;
  }

  void toggleChecklist(int index) {
    setState(() {
      checklistItems[index].isDone = !checklistItems[index].isDone;
    });
  }

  void submitRequirement(int index) {
    setState(() {
      requirements[index].status = 'Đang chờ duyệt';
      requirements[index].rejectReason = null;
    });

    showMessage('Đã gửi yêu cầu duyệt cho quản lý');
  }

  void approveRequirement(int index) {
    setState(() {
      requirements[index].status = 'Đã duyệt';
      requirements[index].rejectReason = null;
    });

    showMessage('Đã phê duyệt yêu cầu');
  }

  void rejectRequirement(int index) {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text('Lý do từ chối'),
          content: TextField(
            controller: reasonController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Ví dụ: Giao diện bị lệch font, cần chỉnh lại...',
              filled: true,
              fillColor: const Color(0xFFF3F4F6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                final reason = reasonController.text.trim();

                if (reason.isEmpty) {
                  return;
                }

                setState(() {
                  requirements[index].status = 'Bị từ chối';
                  requirements[index].rejectReason = reason;
                });

                Navigator.pop(dialogContext);
                showMessage('Đã từ chối yêu cầu');
              },
              child: const Text('Xác nhận'),
            ),
          ],
        );
      },
    );
  }

  void addComment() {
    final content = commentController.text.trim();

    if (content.isEmpty) {
      showMessage('Vui lòng nhập nội dung bình luận');
      return;
    }

    setState(() {
      comments.add(
        _CommentItem(
          name: widget.task.assigneeName,
          avatar: widget.task.assigneeAvatar,
          content: content,
          time: 'Vừa xong',
          isMine: true,
        ),
      );
      commentController.clear();
    });
  }

  void saveChanges() {
    showMessage('Đã lưu thay đổi mock và cập nhật ra bảng Kanban');
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
    final priorityConfig = _getPriorityConfig(widget.task.priority);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: Column(
          children: [
            _DetailHeader(
              title: widget.task.title,
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _OverviewCard(
                      task: widget.task,
                      priorityLabel: priorityConfig.label,
                      priorityColor: priorityConfig.color,
                    ),
                    const SizedBox(height: 16),

                    _SectionCard(
                      title: 'Mô tả công việc',
                      icon: Icons.description_outlined,
                      child: Text(
                        widget.task.description,
                        style: const TextStyle(
                          color: Color(0xFF4B5563),
                          height: 1.45,
                          fontSize: 14,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    _SectionCard(
                      title: 'Yêu cầu kỹ thuật từ Quản lý',
                      icon: Icons.verified_user_outlined,
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: canApproveRequirement
                              ? const Color(0xFFEDE9FE)
                              : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          canApproveRequirement ? 'Manager/Admin' : 'Member',
                          style: TextStyle(
                            color: canApproveRequirement
                                ? const Color(0xFF6D28D9)
                                : const Color(0xFF6B7280),
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      child: Column(
                        children: List.generate(requirements.length, (index) {
                          return _RequirementTile(
                            requirement: requirements[index],
                            managerMode: canApproveRequirement,
                            onSubmit: () => submitRequirement(index),
                            onApprove: () => approveRequirement(index),
                            onReject: () => rejectRequirement(index),
                          );
                        }),
                      ),
                    ),

                    const SizedBox(height: 16),

                    _SectionCard(
                      title: 'Checklist',
                      icon: Icons.checklist_rounded,
                      trailing: Text(
                        '$completedChecklistCount/${checklistItems.length}',
                        style: const TextStyle(
                          color: Color(0xFF7C3AED),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: checklistProgress,
                              minHeight: 8,
                              backgroundColor: const Color(0xFFE5E7EB),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF7C3AED),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          ...List.generate(checklistItems.length, (index) {
                            final item = checklistItems[index];

                            return CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              activeColor: const Color(0xFF7C3AED),
                              value: item.isDone,
                              onChanged: (_) => toggleChecklist(index),
                              title: Text(
                                item.title,
                                style: TextStyle(
                                  color: const Color(0xFF374151),
                                  fontWeight: FontWeight.w600,
                                  decoration: item.isDone
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                ),
                              ),
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
                          ...comments.map(
                                (comment) => _CommentBubble(comment: comment),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: commentController,
                                  decoration: InputDecoration(
                                    hintText: 'Nhập bình luận...',
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
                              InkWell(
                                onTap: addComment,
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
                                    Icons.send_rounded,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
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
          child: ElevatedButton(
            onPressed: saveChanges,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Lưu thay đổi',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  _PriorityConfig _getPriorityConfig(String priority) {
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

class _DetailHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const _DetailHeader({
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chi tiết công việc',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
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
              Icons.more_horiz_rounded,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final MockTask task;
  final String priorityLabel;
  final Color priorityColor;

  const _OverviewCard({
    required this.task,
    required this.priorityLabel,
    required this.priorityColor,
  });

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
              height: 1.25,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _InfoBadge(
                icon: Icons.flag_outlined,
                label: priorityLabel,
                color: priorityColor,
              ),
              const SizedBox(width: 8),
              _InfoBadge(
                icon: Icons.calendar_today_outlined,
                label: task.dueDate,
                color: const Color(0xFF2563EB),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF6366F1),
                child: Text(
                  task.assigneeAvatar,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.assigneeName,
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Người phụ trách',
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE9FE),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  task.status,
                  style: const TextStyle(
                    color: Color(0xFF6D28D9),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoBadge({
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
  final _RequirementItem requirement;
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
    final config = _getStatusConfig(requirement.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            requirement.title,
            style: const TextStyle(
              color: Color(0xFF374151),
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: config.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  requirement.status,
                  style: TextStyle(
                    color: config.color,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              if (!managerMode && requirement.status == 'Chưa gửi')
                TextButton(
                  onPressed: onSubmit,
                  child: const Text('Gửi duyệt'),
                ),
              if (managerMode && requirement.status == 'Đang chờ duyệt') ...[
                TextButton(
                  onPressed: onReject,
                  child: const Text(
                    'Từ chối',
                    style: TextStyle(color: Color(0xFFEF4444)),
                  ),
                ),
                const SizedBox(width: 4),
                ElevatedButton(
                  onPressed: onApprove,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Text('Duyệt'),
                ),
              ],
            ],
          ),
          if (requirement.rejectReason != null) ...[
            const SizedBox(height: 8),
            Text(
              'Lý do: ${requirement.rejectReason}',
              style: const TextStyle(
                color: Color(0xFFEF4444),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  _StatusConfig _getStatusConfig(String status) {
    switch (status) {
      case 'Đã duyệt':
        return _StatusConfig(const Color(0xFF22C55E));
      case 'Bị từ chối':
        return _StatusConfig(const Color(0xFFEF4444));
      case 'Đang chờ duyệt':
        return _StatusConfig(const Color(0xFFF59E0B));
      default:
        return _StatusConfig(const Color(0xFF6B7280));
    }
  }
}

class _CommentBubble extends StatelessWidget {
  final _CommentItem comment;

  const _CommentBubble({
    required this.comment,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: comment.isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: const BoxConstraints(maxWidth: 280),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment:
          comment.isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!comment.isMine) ...[
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF6366F1),
                child: Text(
                  comment.avatar,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: comment.isMine
                      ? const Color(0xFF7C3AED)
                      : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.content,
                      style: TextStyle(
                        color: comment.isMine
                            ? Colors.white
                            : const Color(0xFF374151),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      comment.time,
                      style: TextStyle(
                        color: comment.isMine
                            ? Colors.white70
                            : const Color(0xFF9CA3AF),
                        fontSize: 11,
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

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(26),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.06),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ],
  );
}

class _ChecklistItem {
  final String title;
  bool isDone;

  _ChecklistItem({
    required this.title,
    required this.isDone,
  });
}

class _RequirementItem {
  final String title;
  String status;
  String? rejectReason;

  _RequirementItem({
    required this.title,
    required this.status,
    this.rejectReason,
  });
}

class _CommentItem {
  final String name;
  final String avatar;
  final String content;
  final String time;
  final bool isMine;

  _CommentItem({
    required this.name,
    required this.avatar,
    required this.content,
    required this.time,
    required this.isMine,
  });
}

class _PriorityConfig {
  final String label;
  final Color color;

  _PriorityConfig(this.label, this.color);
}

class _StatusConfig {
  final Color color;

  _StatusConfig(this.color);
}

const List<String> _mockChecklistTitles = [
  'Kiểm tra layout trên màn hình mobile',
  'Hoàn thiện component chính',
  'Cập nhật mock data',
  'Test thao tác người dùng',
  'Đồng bộ UI với Kanban board',
  'Kiểm tra màu sắc và spacing',
  'Chuẩn bị demo cho quản lý',
];