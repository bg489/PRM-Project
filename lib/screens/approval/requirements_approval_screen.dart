import 'package:flutter/material.dart';
import '../../data/mock_tasks.dart';
import '../../data/mock_workspaces.dart';

class RequirementsApprovalScreen extends StatefulWidget {
  final MockProject project;
  final List<MockTask> tasks;

  const RequirementsApprovalScreen({
    super.key,
    required this.project,
    required this.tasks,
  });

  @override
  State<RequirementsApprovalScreen> createState() =>
      _RequirementsApprovalScreenState();
}

class _RequirementsApprovalScreenState
    extends State<RequirementsApprovalScreen> {
  late List<_ApprovalItem> approvalItems;

  @override
  void initState() {
    super.initState();

    approvalItems = widget.tasks
        .where((task) => task.status != 'Đã xong')
        .take(5)
        .map((task) {
      return _ApprovalItem(
        id: task.id,
        taskName: task.title,
        employeeName: task.assigneeName,
        employeeAvatar: task.assigneeAvatar,
        priority: task.priority,
        status: 'Đang chờ duyệt',
        requirements: [
          'Hoàn thành đúng yêu cầu kỹ thuật từ quản lý',
          'Checklist đã được cập nhật đầy đủ',
          'Giao diện hoặc chức năng đã sẵn sàng để kiểm tra',
        ],
      );
    }).toList();
  }

  int get waitingCount {
    return approvalItems
        .where((item) => item.status == 'Đang chờ duyệt')
        .length;
  }

  int get approvedCount {
    return approvalItems.where((item) => item.status == 'Đã duyệt').length;
  }

  int get rejectedCount {
    return approvalItems.where((item) => item.status == 'Bị từ chối').length;
  }

  void approveItem(int index) {
    setState(() {
      approvalItems[index].status = 'Đã duyệt';
      approvalItems[index].rejectReason = null;
    });

    showMessage(
      'Đã phê duyệt. Task đủ điều kiện chuyển sang Đã xong nếu hoàn thành tất cả yêu cầu.',
    );
  }

  void rejectItem(int index) {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text('Nhập lý do từ chối'),
          content: TextField(
            controller: reasonController,
            maxLines: 4,
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
                  approvalItems[index].status = 'Bị từ chối';
                  approvalItems[index].rejectReason = reason;
                });

                Navigator.pop(dialogContext);
                showMessage('Đã từ chối và gửi lý do cho nhân viên');
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

  void resetItem(int index) {
    setState(() {
      approvalItems[index].status = 'Đang chờ duyệt';
      approvalItems[index].rejectReason = null;
    });

    showMessage('Đã đưa yêu cầu về trạng thái chờ duyệt');
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
      body: SafeArea(
        child: Column(
          children: [
            _ApprovalHeader(
              projectName: widget.project.name,
              projectCode: widget.project.code,
              waitingCount: waitingCount,
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 90),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SummaryPanel(
                      waiting: waitingCount,
                      approved: approvedCount,
                      rejected: rejectedCount,
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Danh sách chờ phê duyệt',
                            style: TextStyle(
                              color: Color(0xFF111827),
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDE9FE),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${approvalItems.length} yêu cầu',
                            style: const TextStyle(
                              color: Color(0xFF6D28D9),
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Manager kiểm tra từng task, duyệt nếu đạt hoặc từ chối kèm lý do để nhân viên chỉnh sửa.',
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 16),

                    if (approvalItems.isEmpty)
                      const _EmptyApprovalList()
                    else
                      ...List.generate(approvalItems.length, (index) {
                        return _ApprovalCard(
                          item: approvalItems[index],
                          onApprove: () => approveItem(index),
                          onReject: () => rejectItem(index),
                          onReset: () => resetItem(index),
                        );
                      }),
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

class _ApprovalHeader extends StatelessWidget {
  final String projectName;
  final String projectCode;
  final int waitingCount;
  final VoidCallback onBack;

  const _ApprovalHeader({
    required this.projectName,
    required this.projectCode,
    required this.waitingCount,
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
      child: Column(
        children: [
          Row(
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
                    Text(
                      projectCode,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Text(
                      'Phê duyệt yêu cầu',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.fact_check_rounded,
                      color: Colors.white,
                    ),
                  ),
                  if (waitingCount > 0)
                    Positioned(
                      top: -6,
                      right: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF97316),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '$waitingCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              projectName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryPanel extends StatelessWidget {
  final int waiting;
  final int approved;
  final int rejected;

  const _SummaryPanel({
    required this.waiting,
    required this.approved,
    required this.rejected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: 'Chờ duyệt',
            value: '$waiting',
            icon: Icons.hourglass_top_rounded,
            color: const Color(0xFFF59E0B),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            label: 'Đã duyệt',
            value: '$approved',
            icon: Icons.check_circle_rounded,
            color: const Color(0xFF22C55E),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            label: 'Từ chối',
            value: '$rejected',
            icon: Icons.cancel_rounded,
            color: const Color(0xFFEF4444),
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
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
          Icon(
            icon,
            color: color,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ApprovalCard extends StatelessWidget {
  final _ApprovalItem item;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onReset;

  const _ApprovalCard({
    required this.item,
    required this.onApprove,
    required this.onReject,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final statusConfig = _getStatusConfig(item.status);
    final priorityConfig = _getPriorityConfig(item.priority);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: statusConfig.color.withOpacity(0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.055),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF6366F1),
                child: Text(
                  item.employeeAvatar,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.taskName,
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Nhân viên: ${item.employeeName}',
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              _SmallBadge(
                label: statusConfig.label,
                color: statusConfig.color,
                icon: statusConfig.icon,
              ),
              const SizedBox(width: 8),
              _SmallBadge(
                label: priorityConfig.label,
                color: priorityConfig.color,
                icon: Icons.flag_rounded,
              ),
            ],
          ),

          const SizedBox(height: 14),

          const Text(
            'Yêu cầu cần xác nhận',
            style: TextStyle(
              color: Color(0xFF111827),
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),

          const SizedBox(height: 10),

          ...List.generate(item.requirements.length, (index) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFE5E7EB),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
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
                      item.requirements[index],
                      style: const TextStyle(
                        color: Color(0xFF374151),
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          if (item.rejectReason != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.report_problem_outlined,
                    color: Color(0xFFEF4444),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Lý do từ chối: ${item.rejectReason}',
                      style: const TextStyle(
                        color: Color(0xFFB91C1C),
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          if (item.status == 'Đang chờ duyệt')
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Từ chối'),
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
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Phê duyệt'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22C55E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onReset,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Đưa về chờ duyệt'),
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
        ],
      ),
    );
  }

  _StatusConfig _getStatusConfig(String status) {
    switch (status) {
      case 'Đã duyệt':
        return _StatusConfig(
          label: 'Đã duyệt',
          color: const Color(0xFF22C55E),
          icon: Icons.check_circle_rounded,
        );
      case 'Bị từ chối':
        return _StatusConfig(
          label: 'Bị từ chối',
          color: const Color(0xFFEF4444),
          icon: Icons.cancel_rounded,
        );
      default:
        return _StatusConfig(
          label: 'Đang chờ duyệt',
          color: const Color(0xFFF59E0B),
          icon: Icons.hourglass_top_rounded,
        );
    }
  }

  _PriorityConfig _getPriorityConfig(String priority) {
    switch (priority) {
      case 'High':
        return _PriorityConfig(
          label: 'Ưu tiên cao',
          color: const Color(0xFFEF4444),
        );
      case 'Medium':
        return _PriorityConfig(
          label: 'Trung bình',
          color: const Color(0xFFF59E0B),
        );
      default:
        return _PriorityConfig(
          label: 'Ưu tiên thấp',
          color: const Color(0xFF22C55E),
        );
    }
  }
}

class _SmallBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _SmallBadge({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
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
            color: color,
            size: 15,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyApprovalList extends StatelessWidget {
  const _EmptyApprovalList();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
      child: const Column(
        children: [
          Icon(
            Icons.fact_check_outlined,
            size: 48,
            color: Color(0xFF9CA3AF),
          ),
          SizedBox(height: 12),
          Text(
            'Không có yêu cầu nào đang chờ duyệt',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ApprovalItem {
  final String id;
  final String taskName;
  final String employeeName;
  final String employeeAvatar;
  final String priority;
  final List<String> requirements;
  String status;
  String? rejectReason;

  _ApprovalItem({
    required this.id,
    required this.taskName,
    required this.employeeName,
    required this.employeeAvatar,
    required this.priority,
    required this.requirements,
    required this.status,
    this.rejectReason,
  });
}

class _StatusConfig {
  final String label;
  final Color color;
  final IconData icon;

  _StatusConfig({
    required this.label,
    required this.color,
    required this.icon,
  });
}

class _PriorityConfig {
  final String label;
  final Color color;

  _PriorityConfig({
    required this.label,
    required this.color,
  });
}