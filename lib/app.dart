import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'views/auth/login_screen.dart';

// ============================================================
// LIB: app.dart
// Owner: ALL (Quản lý Route chính của ứng dụng)
// ============================================================

class CanteenApp extends StatelessWidget {
  const CanteenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Canteen App',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      // Khi mới khởi chạy, dẫn tới trang Login làm màn hình mặc định
      home: const LoginScreen(),
      // Đăng ký routes cơ bản tại đây nếu không dùng go_router
      routes: {
        '/login': (context) => const LoginScreen(),
        // Các thành viên tự đăng ký route của màn hình mình làm vào đây
      },
    );
  }
}
