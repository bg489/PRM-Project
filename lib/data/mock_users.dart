class MockUser {
  final String id;
  final String email;
  final String password;
  final String fullName;
  final String role;
  final String avatarText;

  const MockUser({
    required this.id,
    required this.email,
    required this.password,
    required this.fullName,
    required this.role,
    required this.avatarText,
  });
}

const List<MockUser> mockUsers = [
  MockUser(
    id: 'u001',
    email: 'nguyenvana@company.com',
    password: '123456',
    fullName: 'Nguyễn Văn A',
    role: 'Team Lead',
    avatarText: 'NV',
  ),
  MockUser(
    id: 'u002',
    email: 'tranminh@company.com',
    password: '123456',
    fullName: 'Trần Minh',
    role: 'Backend Dev',
    avatarText: 'TM',
  ),
  MockUser(
    id: 'u003',
    email: 'lethic@company.com',
    password: '123456',
    fullName: 'Lê Thị C',
    role: 'UI/UX Designer',
    avatarText: 'LC',
  ),
];

MockUser? mockLogin(String email, String password) {
  try {
    return mockUsers.firstWhere(
          (user) =>
      user.email.toLowerCase() == email.toLowerCase().trim() &&
          user.password == password.trim(),
    );
  } catch (_) {
    return null;
  }
}