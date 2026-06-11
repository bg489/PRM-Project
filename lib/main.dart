import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';
import 'utils/app_notification_service.dart';
import 'utils/app_theme_controller.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'utils/app_language_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppNotificationService.init();

  await appThemeController.loadTheme();

  await appLanguageController.loadLanguage();

  runApp(const ProductivityManagerApp());
}

class ProductivityManagerApp extends StatelessWidget {
  const ProductivityManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appThemeController,
      builder: (context, _) {
        return MaterialApp(
          locale: appLanguageController.locale,
          supportedLocales: const [
            Locale('vi'),
            Locale('en'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          title: 'Productivity Manager',
          debugShowCheckedModeBanner: false,
          themeMode: appThemeController.themeMode,
          theme: ThemeData(
            useMaterial3: true,
            fontFamily: 'Roboto',
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF5F7FB),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF4F46E5),
              brightness: Brightness.light,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            fontFamily: 'Roboto',
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF0F172A),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF4F46E5),
              brightness: Brightness.dark,
            ),
          ),
          home: const LoginScreen(),
        );
      },
    );
  }
}