import 'app_language_controller.dart';

class AppText {
  static String t(String key) {
    final isEnglish = appLanguageController.language == AppLanguage.en;

    final vi = _vi[key];
    final en = _en[key];

    if (isEnglish) {
      return en ?? vi ?? key;
    }

    return vi ?? en ?? key;
  }

  static const Map<String, String> _vi = {
    'profile_settings': 'Hồ sơ & Cài đặt',
    'profile': 'Hồ sơ',
    'settings': 'Cài đặt',
    'notifications': 'Thông báo',
    'push_notifications': 'Thông báo đẩy',
    'push_notifications_desc':
    'Nhận thông báo khi được giao việc hoặc có bình luận mới',
    'dark_mode': 'Chế độ tối',
    'dark_mode_desc': 'Giao diện tối cho buổi tối',
    'account_settings': 'Cài đặt tài khoản',
    'personal_account': 'Tài khoản cá nhân',
    'personal_account_desc': 'Cập nhật họ tên, avatar, thông tin hồ sơ',
    'security': 'Bảo mật',
    'security_desc': 'Đổi mật khẩu và quản lý phiên đăng nhập',
    'language': 'Ngôn ngữ',
    'help_support': 'Trợ giúp & hỗ trợ',
    'help_support_desc': 'FAQ, hướng dẫn sử dụng và liên hệ hỗ trợ',
    'session': 'Phiên làm việc',
    'logout': 'Đăng xuất',
    'select_language': 'Chọn ngôn ngữ',
    'vietnamese': 'Tiếng Việt',
    'english': 'Tiếng Anh',
    'vietnamese_desc': 'Sử dụng giao diện tiếng Việt',
    'english_desc': 'Use English interface',
    'language_saved': 'Đã cập nhật ngôn ngữ',
    'edit_profile': 'Chỉnh sửa hồ sơ',
    'save_profile': 'Lưu hồ sơ',
    'full_name': 'Họ và tên',
    'avatar_symbol': 'Ký hiệu avatar',
    'email': 'Email',
    'role': 'Vai trò',
  };

  static const Map<String, String> _en = {
    'profile_settings': 'Profile & Settings',
    'profile': 'Profile',
    'settings': 'Settings',
    'notifications': 'Notifications',
    'push_notifications': 'Push notifications',
    'push_notifications_desc':
    'Receive notifications when assigned tasks or new comments',
    'dark_mode': 'Dark mode',
    'dark_mode_desc': 'Dark interface for evening use',
    'account_settings': 'Account settings',
    'personal_account': 'Personal account',
    'personal_account_desc': 'Update name, avatar and profile information',
    'security': 'Security',
    'security_desc': 'Change password and manage login sessions',
    'language': 'Language',
    'help_support': 'Help & Support',
    'help_support_desc': 'FAQ, user guide and support contact',
    'session': 'Session',
    'logout': 'Log out',
    'select_language': 'Select language',
    'vietnamese': 'Vietnamese',
    'english': 'English',
    'vietnamese_desc': 'Use Vietnamese interface',
    'english_desc': 'Use English interface',
    'language_saved': 'Language updated',
    'edit_profile': 'Edit profile',
    'save_profile': 'Save profile',
    'full_name': 'Full name',
    'avatar_symbol': 'Avatar symbol',
    'email': 'Email',
    'role': 'Role',
  };
}