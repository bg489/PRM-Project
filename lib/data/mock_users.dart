import 'dart:typed_data';

class MockUser {
  final String id;
  final String email;
  final String password;
  final String fullName;
  final String role;
  final String avatarText;
  final bool isActive;
  final bool notificationEnabled;
  final bool twoStepEnabled;
  final bool biometricEnabled;
  final Uint8List? avatarImageBytes;

  const MockUser({
    required this.id,
    required this.email,
    this.password = '',
    required this.fullName,
    required this.role,
    required this.avatarText,
    this.isActive = true,
    this.notificationEnabled = true,
    this.twoStepEnabled = false,
    this.biometricEnabled = false,
    this.avatarImageBytes,
  });

  factory MockUser.fromJson(Map<String, dynamic> json) {
    return MockUser(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      password: json['password']?.toString() ?? '',
      fullName: json['fullName']?.toString() ??
          json['full_name']?.toString() ??
          '',
      role: json['role']?.toString() ?? 'Member',
      avatarText: json['avatarText']?.toString() ??
          json['avatar_text']?.toString() ??
          'NA',
      isActive: json['isActive'] != false && json['is_active'] != 0,
      notificationEnabled: json['notificationEnabled'] != false,
      twoStepEnabled: json['twoStepEnabled'] == true,
      biometricEnabled: json['biometricEnabled'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'role': role,
      'avatarText': avatarText,
      'isActive': isActive,
      'notificationEnabled': notificationEnabled,
      'twoStepEnabled': twoStepEnabled,
      'biometricEnabled': biometricEnabled,
    };
  }

  MockUser copyWith({
    String? fullName,
    String? avatarText,
    String? role,
    bool? isActive,
    bool? notificationEnabled,
    bool? twoStepEnabled,
    bool? biometricEnabled,
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
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      twoStepEnabled: twoStepEnabled ?? this.twoStepEnabled,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
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
    email: 'nguyenvana@company.com',
    password: '123456',
    fullName: 'Nguyễn Văn A',
    role: 'Member',
    avatarText: 'NA',
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
  MockUser(
    id: 'u006',
    email: 'hani@company.com',
    password: '123456',
    fullName: 'Hà Nhi',
    role: 'Member',
    avatarText: 'HN',
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
