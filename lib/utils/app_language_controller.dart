import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage {
  vi,
  en,
}

class AppLanguageController extends ChangeNotifier {
  static const String _languageKey = 'app_language_code';

  AppLanguage _language = AppLanguage.vi;

  AppLanguage get language => _language;

  Locale get locale {
    switch (_language) {
      case AppLanguage.en:
        return const Locale('en');
      case AppLanguage.vi:
        return const Locale('vi');
    }
  }

  String get languageLabel {
    switch (_language) {
      case AppLanguage.en:
        return 'English';
      case AppLanguage.vi:
        return 'Tiếng Việt';
    }
  }

  Future<void> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString(_languageKey);

    _language = savedCode == 'en' ? AppLanguage.en : AppLanguage.vi;
    notifyListeners();
  }

  Future<void> setLanguage(AppLanguage value) async {
    _language = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _languageKey,
      value == AppLanguage.en ? 'en' : 'vi',
    );
  }
}

final AppLanguageController appLanguageController = AppLanguageController();