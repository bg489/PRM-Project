class MockApprovalRequest {
  final String id;
  final String userId;
  final String taskId;
  final String projectId;
  final String taskTitle;
  final String requirementTitle;
  final String status;
  final String submittedAt;
  final String? reviewedAt;
  final String? reviewerName;
  final String? rejectReason;

  const MockApprovalRequest({
    required this.id,
    required this.userId,
    required this.taskId,
    required this.projectId,
    required this.taskTitle,
    required this.requirementTitle,
    required this.status,
    required this.submittedAt,
    this.reviewedAt,
    this.reviewerName,
    this.rejectReason,
  });
}

const List<String> approvalRequestStatuses = [
  'WAITING',
  'APPROVED',
  'REJECTED',
];

const List<MockApprovalRequest> mockApprovalRequests = [
  MockApprovalRequest(
    id: 'ar001',
    userId: 'u003',
    taskId: 't001',
    projectId: 'p001',
    taskTitle: 'Thiết kế màn hình đăng nhập',
    requirementTitle: 'Giao diện phải đúng layout mobile đã thống nhất',
    status: 'WAITING',
    submittedAt: 'Hôm nay, 09:10',
  ),
  MockApprovalRequest(
    id: 'ar002',
    userId: 'u003',
    taskId: 't002',
    projectId: 'p001',
    taskTitle: 'Xây dựng dashboard dự án',
    requirementTitle: 'Dashboard phải hiển thị progress theo task',
    status: 'APPROVED',
    submittedAt: 'Hôm qua, 14:20',
    reviewedAt: 'Hôm qua, 16:00',
    reviewerName: 'Nguyễn Văn Quản Lý',
  ),
  MockApprovalRequest(
    id: 'ar003',
    userId: 'u003',
    taskId: 't003',
    projectId: 'p001',
    taskTitle: 'Tạo Kanban board',
    requirementTitle: 'Kéo thả task giữa các cột phải cập nhật UI ngay',
    status: 'REJECTED',
    submittedAt: 'Hôm qua, 10:45',
    reviewedAt: 'Hôm qua, 13:30',
    reviewerName: 'Nguyễn Văn Quản Lý',
    rejectReason: 'Cần chỉnh lại spacing giữa các task card và kiểm tra lại trạng thái sau khi kéo thả.',
  ),
  MockApprovalRequest(
    id: 'ar004',
    userId: 'u003',
    taskId: 't005',
    projectId: 'p001',
    taskTitle: 'Hoàn thiện theme app',
    requirementTitle: 'Màu sắc phải đồng bộ với thiết kế xanh tím',
    status: 'APPROVED',
    submittedAt: '2 ngày trước, 11:00',
    reviewedAt: '2 ngày trước, 15:15',
    reviewerName: 'Nguyễn Văn Quản Lý',
  ),
  MockApprovalRequest(
    id: 'ar005',
    userId: 'u004',
    taskId: 't006',
    projectId: 'p001',
    taskTitle: 'Tối ưu task card component',
    requirementTitle: 'Task card phải hiển thị priority, deadline và assignee',
    status: 'WAITING',
    submittedAt: 'Hôm nay, 10:05',
  ),
];