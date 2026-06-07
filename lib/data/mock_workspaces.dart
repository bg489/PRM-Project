class MockWorkspace {
  final String id;
  final String name;
  final String description;
  final int memberCount;
  final int projectCount;
  final String iconText;

  const MockWorkspace({
    required this.id,
    required this.name,
    required this.description,
    required this.memberCount,
    required this.projectCount,
    required this.iconText,
  });
}

class MockProject {
  final String id;
  final String workspaceId;
  final String name;
  final String code;
  final String deadline;
  final double progress;
  final int totalTasks;
  final int completedTasks;
  final List<String> members;
  final String status;

  const MockProject({
    required this.id,
    required this.workspaceId,
    required this.name,
    required this.code,
    required this.deadline,
    required this.progress,
    required this.totalTasks,
    required this.completedTasks,
    required this.members,
    required this.status,
  });
}

const List<MockWorkspace> mockWorkspaces = [
  MockWorkspace(
    id: 'ws001',
    name: 'Phát triển Sản phẩm',
    description: 'Không gian dành cho team sản phẩm và kỹ thuật',
    memberCount: 12,
    projectCount: 5,
    iconText: 'SP',
  ),
  MockWorkspace(
    id: 'ws002',
    name: 'Marketing & Truyền thông',
    description: 'Quản lý campaign, content và truyền thông',
    memberCount: 8,
    projectCount: 3,
    iconText: 'MK',
  ),
  MockWorkspace(
    id: 'ws003',
    name: 'Vận hành Nội bộ',
    description: 'Theo dõi các task vận hành công ty',
    memberCount: 6,
    projectCount: 2,
    iconText: 'VH',
  ),
];

const List<MockProject> mockProjects = [
  MockProject(
    id: 'p001',
    workspaceId: 'ws001',
    name: 'Mobile App v2.0',
    code: 'MOB-001',
    deadline: '30/06/2026',
    progress: 0.65,
    totalTasks: 48,
    completedTasks: 32,
    members: ['A', 'B', 'C', 'D', 'E'],
    status: 'Active',
  ),
  MockProject(
    id: 'p002',
    workspaceId: 'ws001',
    name: 'CRM Integration',
    code: 'CRM-014',
    deadline: '18/06/2026',
    progress: 0.42,
    totalTasks: 31,
    completedTasks: 13,
    members: ['TM', 'LC', 'HN'],
    status: 'Active',
  ),
  MockProject(
    id: 'p003',
    workspaceId: 'ws001',
    name: 'Backend API Upgrade',
    code: 'API-022',
    deadline: '25/06/2026',
    progress: 0.78,
    totalTasks: 36,
    completedTasks: 28,
    members: ['NV', 'TM', 'HN'],
    status: 'Active',
  ),
  MockProject(
    id: 'p004',
    workspaceId: 'ws002',
    name: 'TikTok Launch Campaign',
    code: 'MKT-009',
    deadline: '20/06/2026',
    progress: 0.55,
    totalTasks: 22,
    completedTasks: 12,
    members: ['LC', 'A', 'B'],
    status: 'Active',
  ),
  MockProject(
    id: 'p005',
    workspaceId: 'ws002',
    name: 'Facebook Content Plan',
    code: 'FB-012',
    deadline: '28/06/2026',
    progress: 0.35,
    totalTasks: 20,
    completedTasks: 7,
    members: ['MK', 'NV'],
    status: 'Active',
  ),
  MockProject(
    id: 'p006',
    workspaceId: 'ws003',
    name: 'Internal Workflow Setup',
    code: 'OPS-004',
    deadline: '15/06/2026',
    progress: 0.80,
    totalTasks: 15,
    completedTasks: 12,
    members: ['VH', 'TM'],
    status: 'Active',
  ),
];

List<MockProject> getProjectsByWorkspace(String workspaceId) {
  return mockProjects
      .where((project) => project.workspaceId == workspaceId)
      .toList();
}