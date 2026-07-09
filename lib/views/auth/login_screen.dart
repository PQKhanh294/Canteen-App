import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/canteen_button.dart';
import '../../widgets/canteen_text_field.dart';
import '../../core/constants/app_colors.dart';

// ============================================================
// VIEW: views/auth/login_screen.dart
// Owner: Member 1 — Khánh
// ============================================================

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Chào Mừng Trở Lại! 👋',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Đăng nhập để tiếp tục đặt món ăn tại căn tin trường',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 36),
                  
                  // Email input
                  CanteenTextField(
                    controller: _emailController,
                    labelText: 'Email sinh viên',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Password input
                  CanteenTextField(
                    controller: _passwordController,
                    labelText: 'Mật khẩu',
                    obscureText: true,
                    prefixIcon: Icons.lock_outline,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập mật khẩu';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  
                  // Quên mật khẩu
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/forgot-password'),
                      child: const Text(
                        'Quên mật khẩu?',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Nút Đăng nhập
                  CanteenButton(
                    text: 'Đăng Nhập',
                    isLoading: authVM.isLoading,
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        await authVM.login(
                          email: _emailController.text.trim(),
                          password: _passwordController.text.trim(),
                        );
                        
                        if (authVM.errorMessage != null) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(authVM.errorMessage!),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        } else if (authVM.currentUser != null) {
                          // Điều hướng dựa vào Role
                          final role = authVM.currentUser!.role;
                          if (role == 'admin') {
                            Navigator.pushReplacementNamed(context, '/admin');
                          } else {
                            // Tạm thời điều hướng qua profile để test đăng nhập/đăng xuất
                            Navigator.pushReplacementNamed(context, '/profile');
                          }
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // Chuyển sang Đăng ký
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Chưa có tài khoản? ',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/register'),
                        child: const Text(
                          'Đăng ký ngay',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
