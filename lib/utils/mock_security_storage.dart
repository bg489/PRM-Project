import 'package:shared_preferences/shared_preferences.dart';

import '../data/mock_users.dart';

class MockSecurityStorage {
  static String _passwordKey(String userId) => 'security_${userId}_password';
  static String _twoStepKey(String userId) => 'security_${userId}_two_step';
  static String _biometricKey(String userId) => 'security_${userId}_biometric';

  static Future<MockUser?> login({
    required String email,
    required String password,
  }) async {
    try {
      final user = mockUsers.firstWhere(
            (item) => item.email.toLowerCase() == email.toLowerCase().trim(),
      );

      if (!user.isActive) return null;

      final savedPassword = await getCurrentPassword(user);

      if (savedPassword != password.trim()) {
        return null;
      }

      return user;
    } catch (_) {
      return null;
    }
  }

  static Future<String> getCurrentPassword(MockUser user) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_passwordKey(user.id)) ?? user.password;
  }

  static Future<bool> verifyPassword(
      MockUser user,
      String inputPassword,
      ) async {
    final currentPassword = await getCurrentPassword(user);
    return currentPassword == inputPassword.trim();
  }

  static Future<void> savePassword({
    required String userId,
    required String newPassword,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_passwordKey(userId), newPassword.trim());
  }

  static Future<bool> getTwoStepEnabled(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_twoStepKey(userId)) ?? false;
  }

  static Future<void> setTwoStepEnabled({
    required String userId,
    required bool value,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_twoStepKey(userId), value);
  }

  static Future<bool> getBiometricEnabled(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricKey(userId)) ?? false;
  }

  static Future<void> setBiometricEnabled({
    required String userId,
    required bool value,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricKey(userId), value);
  }
}