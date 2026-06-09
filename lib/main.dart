import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';
import 'utils/app_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppNotificationService.init();

  runApp(const ProductivityManagerApp());
}

class ProductivityManagerApp extends StatelessWidget {
  const ProductivityManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Productivity Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F46E5),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}