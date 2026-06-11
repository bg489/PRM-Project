import 'package:flutter/material.dart';

import '../../data/mock_approval_requests.dart';
import '../../data/mock_users.dart';
import '../../services/app_data_service.dart';
import '../task/task_detail_screen.dart';

class UserApprovalRequestsScreen extends StatefulWidget {
  final MockUser user;

  const UserApprovalRequestsScreen({
    super.key,
    required this.user,
  });

  @override
  State<UserApprovalRequestsScreen> createState() =>
      _UserApprovalRequestsScreenState();
}

class _UserApprovalRequestsScreenState
    extends State<UserApprovalRequestsScreen> {
  List<MockApprovalRequest> requests = const [];
  String selectedStatus = 'all';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadRequests();
  }

  Future<void> loadRequests() async {
    try {
      final fetchedRequests = await AppDataService.fetchApprovalRequests(
        userId: widget.user.id,
      );
      if (!mounted) return;
      setState(() {
        requests = fetchedRequests;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        requests = mockApprovalRequests
            .where((request) => request.userId == widget.user.id)
            .toList();
        isLoading = false;
      });
    }
  }

  List<MockApprovalRequest> get filteredRequests {
    return requests.where((request) {
      return selectedStatus == 'all' || request.status == selectedStatus;
    }).toList();
  }

  Future<void> openRelatedTask(MockApprovalRequest request) async {
    try {
      final detail = await AppDataService.fetchTaskDetail(request.taskId);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TaskDetailScreen(
            task: detail.task,
            currentUser: widget.user,
          ),
        ),
      );
    } catch (error) {
      showMessage('Không thể mở task liên quan: $error');
    }
  }

  void showRequestDetail(MockApprovalRequest request) {
    final config = _statusConfig(request.status);
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(config.icon, color: config.color),
                  const SizedBox(width: 10),
                  Text(
                    config.label,
                    style: TextStyle(
                      color: config.color,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                request.requirementTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text('Task: ${request.taskTitle}'),
              const SizedBox(height: 8),
              Text('Gửi lúc: ${request.submittedAt}'),
              if (request.reviewedAt != null) ...[
                const SizedBox(height: 8),
                Text('Duyệt lúc: ${request.reviewedAt}'),
                Text('Người duyệt: ${request.reviewerName ?? 'Không rõ'}'),
              ],
              if (request.rejectReason != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Lý do từ chối: ${request.rejectReason}',
                  style: const TextStyle(color: Color(0xFFB91C1C)),
                ),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    openRelatedTask(request);
                  },
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('Mở task liên quan'),
                ),
              ),
            ],
          ),
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

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F7FB),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final visibleRequests = filteredRequests;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Yêu cầu đã gửi'),
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: loadRequests,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _StatsCard(requests: requests),
            const SizedBox(height: 16),
            _FilterChips(
              selectedStatus: selectedStatus,
              onChanged: (value) {
                setState(() {
                  selectedStatus = value;
                });
              },
            ),
            const SizedBox(height: 18),
            if (visibleRequests.isEmpty)
              const _EmptyState()
            else
              ...visibleRequests.map((request) {
                final config = _statusConfig(request.status);
                return _RequestTile(
                  request: request,
                  config: config,
                  onTap: () => showRequestDetail(request),
                  onOpenTask: () => openRelatedTask(request),
                );
              }),
          ],
        ),
      ),
    );
  }

  _ApprovalStatusConfig _statusConfig(String status) {
    switch (status) {
      case 'APPROVED':
        return _ApprovalStatusConfig(
          label: 'Đã duyệt',
          color: const Color(0xFF22C55E),
          icon: Icons.check_circle_rounded,
        );
      case 'REJECTED':
        return _ApprovalStatusConfig(
          label: 'Từ chối',
          color: const Color(0xFFEF4444),
          icon: Icons.cancel_rounded,
        );
      default:
        return _ApprovalStatusConfig(
          label: 'Chờ duyệt',
          color: const Color(0xFFF59E0B),
          icon: Icons.hourglass_top_rounded,
        );
    }
  }
}

class _StatsCard extends StatelessWidget {
  final List<MockApprovalRequest> requests;

  const _StatsCard({required this.requests});

  @override
  Widget build(BuildContext context) {
    int count(String status) {
      return requests.where((request) => request.status == status).length;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          _Stat(label: 'Tổng', value: requests.length),
          _Stat(label: 'Chờ', value: count('WAITING')),
          _Stat(label: 'Duyệt', value: count('APPROVED')),
          _Stat(label: 'Từ chối', value: count('REJECTED')),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final int value;

  const _Stat({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(label),
        ],
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  final String selectedStatus;
  final ValueChanged<String> onChanged;

  const _FilterChips({
    required this.selectedStatus,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final filters = [
      _FilterOption('all', 'Tất cả'),
      _FilterOption('WAITING', 'Chờ duyệt'),
      _FilterOption('APPROVED', 'Đã duyệt'),
      _FilterOption('REJECTED', 'Từ chối'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              selected: selectedStatus == filter.value,
              label: Text(filter.label),
              onSelected: (_) => onChanged(filter.value),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  final MockApprovalRequest request;
  final _ApprovalStatusConfig config;
  final VoidCallback onTap;
  final VoidCallback onOpenTask;

  const _RequestTile({
    required this.request,
    required this.config,
    required this.onTap,
    required this.onOpenTask,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(config.icon, color: config.color),
                const SizedBox(width: 8),
                Text(
                  config.label,
                  style: TextStyle(
                    color: config.color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                Text(request.submittedAt),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              request.requirementTitle,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              request.taskTitle,
              style: const TextStyle(color: Color(0xFF6B7280)),
            ),
            if (request.rejectReason != null) ...[
              const SizedBox(height: 8),
              Text(
                request.rejectReason!,
                style: const TextStyle(color: Color(0xFFB91C1C)),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.remove_red_eye_outlined),
                    label: const Text('Chi tiết'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onOpenTask,
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: const Text('Mở task'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text('Không có yêu cầu nào phù hợp'),
      ),
    );
  }
}

class _FilterOption {
  final String value;
  final String label;

  _FilterOption(this.value, this.label);
}

class _ApprovalStatusConfig {
  final String label;
  final Color color;
  final IconData icon;

  _ApprovalStatusConfig({
    required this.label,
    required this.color,
    required this.icon,
  });
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.055),
        blurRadius: 16,
        offset: const Offset(0, 7),
      ),
    ],
  );
}
