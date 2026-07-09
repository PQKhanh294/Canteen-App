import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/canteen_button.dart';
import '../../widgets/canteen_card.dart';
import '../../core/constants/app_colors.dart';

// ============================================================
// VIEW: views/student/profile_screen.dart
// Owner: Member 1 — Khánh
// ============================================================

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  bool _isEditing = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final user = authVM.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Không tìm thấy thông tin đăng nhập.')),
      );
    }

    if (!_isEditing) {
      _nameController.text = user.displayName;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông Tin Cá Nhân'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Avatar
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: AppColors.primaryLight.withOpacity(0.3),
                      backgroundImage: user.avatarUrl.isNotEmpty
                          ? NetworkImage(user.avatarUrl)
                          : null,
                      child: user.avatarUrl.isEmpty
                          ? const Icon(
                              Icons.person,
                              size: 60,
                              color: AppColors.primary,
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        height: 36,
                        width: 36,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                          onPressed: () {
                            // Sẽ được mở rộng ở Module 4 của Quý (Upload Storage)
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Tính năng upload ảnh đang phát triển')),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Chi tiết User Info
              CanteenCard(
                child: Column(
                  children: [
                    // Email (Readonly)
                    _buildInfoTile(
                      icon: Icons.email_outlined,
                      label: 'Email tài khoản',
                      value: user.email,
                    ),
                    const Divider(height: 24),
                    
                    // Vai trò (Readonly)
                    _buildInfoTile(
                      icon: Icons.shield_outlined,
                      label: 'Vai trò hệ thống',
                      value: user.role == 'admin' ? 'Nhân viên căn tin' : 'Sinh viên',
                    ),
                    const Divider(height: 24),
                    
                    // Tên hiển thị
                    Row(
                      children: [
                        const Icon(Icons.badge_outlined, color: AppColors.textSecondary),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _isEditing
                              ? TextField(
                                  controller: _nameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Họ và tên',
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                                  ),
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Họ và tên',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      user.displayName,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                        IconButton(
                          icon: Icon(
                            _isEditing ? Icons.check : Icons.edit,
                            color: AppColors.primary,
                          ),
                          onPressed: () async {
                            if (_isEditing) {
                              // Lưu tên mới (Cập nhật Firestore - mock hoặc qua Viewmodel)
                              // Tạm thời chỉ toggle state ở local view
                              setState(() {
                                _isEditing = false;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Đã cập nhật họ tên thành công!')),
                              );
                            } else {
                              setState(() {
                                _isEditing = true;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              
              // Nút Đăng xuất
              CanteenButton(
                text: 'Đăng Xuất',
                backgroundColor: AppColors.error.withOpacity(0.1),
                textColor: AppColors.error,
                onPressed: () async {
                  await authVM.logout();
                  if (mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/login',
                      (route) => false,
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
