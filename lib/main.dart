import 'package:flutter/material.dart';

void main() {
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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4F46E5)),
      ),
      home: const Scaffold(
        body: Center(
          child: Text(
            'Productivity Manager Ready!',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
