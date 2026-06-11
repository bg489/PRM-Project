import '../data/mock_users.dart';

class RolePermissions {
  static bool isAdmin(MockUser user) {
    return user.role == 'Admin';
  }

  static bool isManager(MockUser user) {
    return user.role == 'Manager';
  }

  static bool isMember(MockUser user) {
    return user.role == 'Member';
  }

  static bool canCreateWorkspace(MockUser user) {
    return isAdmin(user);
  }

  static bool canCreateProject(MockUser user) {
    return isAdmin(user) || isManager(user);
  }

  static bool canCreateTask(MockUser user) {
    return isAdmin(user) || isManager(user);
  }

  static bool canManageBoard(MockUser user) {
    return isAdmin(user) || isManager(user);
  }

  static bool canApproveRequirements(MockUser user) {
    return isAdmin(user) || isManager(user);
  }

  static bool canAccessAdminScreens(MockUser user) {
    return isAdmin(user);
  }
}