import 'dart:typed_data';

class MockUser {
  final String id;
  final String email;
  final String password;
  final String fullName;
  final String role;
  final String avatarText;
  final bool isActive;
  final Uint8List? avatarImageBytes;

  const MockUser({
    required this.id,
    required this.email,
    required this.password,
    required this.fullName,
    required this.role,
    required this.avatarText,
    this.isActive = true,
    this.avatarImageBytes,
  });

  MockUser copyWith({
    String? fullName,
    String? avatarText,
    String? role,
    bool? isActive,
    Uint8List? avatarImageBytes,
  }) {
    return MockUser(
      id: id,
      email: email,
      password: password,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      avatarText: avatarText ?? this.avatarText,
      isActive: isActive ?? this.isActive,
      avatarImageBytes: avatarImageBytes ?? this.avatarImageBytes,
    );
  }
}

const List<MockUser> mockUsers = [
  MockUser(
    id: 'u001',
    email: 'admin@company.com',
    password: '123456',
    fullName: 'Admin System',
    role: 'Admin',
    avatarText: 'AD',
  ),
  MockUser(
    id: 'u002',
    email: 'manager@company.com',
    password: '123456',
    fullName: 'Nguyễn Văn Quản Lý',
    role: 'Manager',
    avatarText: 'QL',
  ),
  MockUser(
    id: 'u003',
    email: 'user@company.com',
    password: '123456',
    fullName: 'Nguyễn Văn User',
    role: 'Member',
    avatarText: 'US',
  ),
  MockUser(
    id: 'u004',
    email: 'tranminh@company.com',
    password: '123456',
    fullName: 'Trần Minh',
    role: 'Member',
    avatarText: 'TM',
  ),
  MockUser(
    id: 'u005',
    email: 'lethic@company.com',
    password: '123456',
    fullName: 'Lê Thị C',
    role: 'Member',
    avatarText: 'LC',
  ),
];

MockUser? mockLogin(String email, String password) {
  try {
    final user = mockUsers.firstWhere(
          (user) =>
      user.email.toLowerCase() == email.toLowerCase().trim() &&
          user.password == password.trim(),
    );

    if (!user.isActive) {
      return null;
    }

    return user;
  } catch (_) {
    return null;
  }
}