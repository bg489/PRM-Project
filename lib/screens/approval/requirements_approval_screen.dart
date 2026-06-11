import 'package:flutter/material.dart';

import '../../data/mock_approval_requests.dart';
import '../../data/mock_tasks.dart';
import '../../data/mock_workspaces.dart';
import '../../services/app_data_service.dart';
import '../admin/admin_widgets.dart';

class RequirementsApprovalScreen extends StatefulWidget {
  final MockProject project;
  final List<MockTask> tasks;

  const RequirementsApprovalScreen({
    super.key,
    required this.project,
    this.tasks = const [],
  });

  @override
  State<RequirementsApprovalScreen> createState() =>
      _RequirementsApprovalScreenState();
}

class _RequirementsApprovalScreenState
    extends State<RequirementsApprovalScreen> {
  List<MockApprovalRequest> approvalRequests = const [];
  bool isLoading = true;
  String? errorMessage;

  int get waitingCount {
    return approvalRequests.where((item) => item.status == 'WAITING').length;
  }

  int get approvedCount {
    return approvalRequests.where((item) => item.status == 'APPROVED').length;
  }

  int get rejectedCount {
    return approvalRequests.where((item) => item.status == 'REJECTED').length;
  }

  @override
  void initState() {
    super.initState();
    loadRequests();
  }

  Future<void> loadRequests() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final loadedRequests = await AppDataService.fetchApprovalRequests(
        projectId: widget.project.id,
      );
      if (!mounted) return;
      setState(() {
        approvalRequests = loadedRequests;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        approvalRequests = mockApprovalRequests
            .where((request) => request.projectId == widget.project.id)
            .toList();
        errorMessage = 'Chưa kết nối được backend, đang hiển thị yêu cầu dự phòng.';
        isLoading = false;
      });
    }
  }

  Future<void> approveRequest(MockApprovalRequest request) async {
    await reviewRequest(request, status: 'APPROVED');
  }

  Future<void> rejectRequest(MockApprovalRequest request) async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: const Text('Nhập lý do từ chối'),
          content: TextField(
            controller: reasonController,
            maxLines: 4,
            decoration: adminInputDecoration(
              label: 'Lý do từ chối',
              icon: Icons.report_problem_outlined,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = reasonController.text.trim();
                if (value.isEmpty) return;
                Navigator.pop(dialogContext, value);
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

    reasonController.dispose();
    if (reason == null || reason.isEmpty) return;
    await reviewRequest(request, status: 'REJECTED', rejectReason: reason);
  }

  Future<void> reviewRequest(
    MockApprovalRequest request, {
    required String status,
    String? rejectReason,
  }) async {
    try {
      final savedRequest = await AppDataService.reviewApprovalRequest(
        id: request.id,
        status: status,
        rejectReason: rejectReason,
      );
      if (!mounted) return;
      setState(() {
        final index = approvalRequests.indexWhere((item) => item.id == request.id);
        if (index != -1) {
          approvalRequests[index] = savedRequest;
        }
      });
      showAdminMessage(
        context,
        status == 'APPROVED'
            ? 'Đã phê duyệt yêu cầu'
            : 'Đã từ chối và gửi lý do cho nhân viên',
      );
    } catch (error) {
      if (!mounted) return;
      showAdminMessage(context, 'Không thể duyệt yêu cầu: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScreenScaffold(
      title: 'Phê duyệt yêu cầu',
      icon: Icons.fact_check_rounded,
      child: RefreshIndicator(
        onRefresh: loadRequests,
        child: isLoading
            ? const AdminLoading()
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AdminCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.project.name,
                            style: const TextStyle(
                              color: Color(0xFF111827),
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.project.code,
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (errorMessage != null) ...[
                      AdminErrorBanner(
                        message: errorMessage!,
                        onRetry: loadRequests,
                      ),
                      const SizedBox(height: 16),
                    ],
                    AdminStatGrid(
                      stats: [
                        AdminStat(
                          label: 'Chờ duyệt',
                          value: '$waitingCount',
                          icon: Icons.hourglass_top_rounded,
                          color: const Color(0xFFF59E0B),
                        ),
                        AdminStat(
                          label: 'Đã duyệt',
                          value: '$approvedCount',
                          icon: Icons.check_circle_rounded,
                          color: const Color(0xFF22C55E),
                        ),
                        AdminStat(
                          label: 'Từ chối',
                          value: '$rejectedCount',
                          icon: Icons.cancel_rounded,
                          color: const Color(0xFFEF4444),
                        ),
                        AdminStat(
                          label: 'Tổng',
                          value: '${approvalRequests.length}',
                          icon: Icons.fact_check_outlined,
                          color: const Color(0xFF7C3AED),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    AdminSectionTitle(
                      title: 'Danh sách yêu cầu',
                      countLabel: '${approvalRequests.length} yêu cầu',
                    ),
                    const SizedBox(height: 14),
                    if (approvalRequests.isEmpty)
                      const AdminEmptyState(
                        icon: Icons.fact_check_outlined,
                        message: 'Không có yêu cầu nào trong project này.',
                      )
                    else
                      ...approvalRequests.map((request) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ApprovalCard(
                            request: request,
                            onApprove: () => approveRequest(request),
                            onReject: () => rejectRequest(request),
                          ),
                        );
                      }),
                  ],
                ),
              ),
      ),
    );
  }
}

class _ApprovalCard extends StatelessWidget {
  final MockApprovalRequest request;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _ApprovalCard({
    required this.request,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final statusConfig = _getStatusConfig(request.status);
    final employeeName = request.userName ?? request.userId;

    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF6366F1),
                child: Text(
                  _initials(employeeName),
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
                      request.taskTitle,
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Người gửi: $employeeName',
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              AdminPill(label: statusConfig.label, color: statusConfig.color),
            ],
          ),
          const SizedBox(height: 14),
          AdminCard(
            padding: const EdgeInsets.all(12),
            child: Text(
              request.requirementTitle,
              style: const TextStyle(
                color: Color(0xFF374151),
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              AdminPill(
                label: 'Gửi: ${request.submittedAt}',
                color: const Color(0xFF2563EB),
              ),
            ],
          ),
          if (request.reviewedAt != null || request.reviewerName != null) ...[
            const SizedBox(height: 8),
            Text(
              'Đã xử lý: ${request.reviewedAt ?? ''} ${request.reviewerName ?? ''}',
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (request.rejectReason != null &&
              request.rejectReason!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Lý do từ chối: ${request.rejectReason}',
                style: const TextStyle(
                  color: Color(0xFFB91C1C),
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ),
          ],
          if (request.status == 'WAITING') ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Từ chối'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      side: const BorderSide(color: Color(0xFFFECACA)),
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
            ),
          ],
        ],
      ),
    );
  }

  _StatusConfig _getStatusConfig(String status) {
    switch (status) {
      case 'APPROVED':
        return const _StatusConfig(
          label: 'Đã duyệt',
          color: Color(0xFF22C55E),
        );
      case 'REJECTED':
        return const _StatusConfig(
          label: 'Từ chối',
          color: Color(0xFFEF4444),
        );
      default:
        return const _StatusConfig(
          label: 'Chờ duyệt',
          color: Color(0xFFF59E0B),
        );
    }
  }

  String _initials(String value) {
    final text = value.trim();
    if (text.isEmpty) return 'NA';
    return text
        .split(RegExp(r'\s+'))
        .map((part) => part.isEmpty ? '' : part[0])
        .join()
        .toUpperCase()
        .padRight(2, 'A')
        .substring(0, 2);
  }
}

class _StatusConfig {
  final String label;
  final Color color;

  const _StatusConfig({
    required this.label,
    required this.color,
  });
}
