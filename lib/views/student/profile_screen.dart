import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/canteen_button.dart';
import '../../widgets/canteen_card.dart';
import '../../core/constants/app_colors.dart';
import '../../viewmodels/order_viewmodel.dart';
import '../../core/utils/currency_formatter.dart';

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
  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final orderVM = context.watch<OrderViewModel>();
    final user = authVM.currentUser;

    final totalOrdersText = orderVM.isLoading
        ? '...'
        : '${orderVM.totalOrders}';
    final totalSpendingText = orderVM.isLoading
        ? '...'
        : CurrencyFormatter.format(orderVM.totalCompletedSpending);
    final mostOrderedText = orderVM.isLoading
        ? '...'
        : (orderVM.mostOrderedFoodName ?? 'Chưa có');

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Không tìm thấy thông tin đăng nhập.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Thông Tin Cá Nhân')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // 1. Phần thông tin Avatar + Tên
              CanteenCard(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: AppColors.primaryLight.withOpacity(0.3),
                      backgroundImage: user.avatarUrl.isNotEmpty
                          ? NetworkImage(user.avatarUrl)
                          : null,
                      child: user.avatarUrl.isEmpty
                          ? const Icon(
                              Icons.person,
                              size: 36,
                              color: AppColors.primary,
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.displayName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.email,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              user.role == 'admin'
                                  ? 'Nhân viên căn tin'
                                  : 'Sinh viên',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: AppColors.primary),
                      onPressed: () {
                        Navigator.pushNamed(context, '/edit-profile');
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 2. Thống kê chi tiêu (Stats)
              CanteenCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      'Đơn hàng',
                      totalOrdersText,
                      Icons.receipt_long_outlined,
                    ),
                    Container(height: 40, width: 1, color: AppColors.divider),
                    _buildStatItem(
                      'Đã chi',
                      totalSpendingText,
                      Icons.account_balance_wallet_outlined,
                    ),
                    Container(height: 40, width: 1, color: AppColors.divider),
                    _buildStatItem(
                      'Món yêu thích',
                      mostOrderedText,
                      Icons.thumb_up_alt_outlined,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 3. Menu cài đặt
              CanteenCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _buildMenuTile(
                      icon: Icons.favorite_border,
                      title: 'Món ăn yêu thích',
                      onTap: () => Navigator.pushNamed(context, '/favorites'),
                    ),
                    const Divider(height: 1),
                    _buildMenuTile(
                      icon: Icons.vpn_key_outlined,
                      title: 'Đổi mật khẩu',
                      onTap: () =>
                          Navigator.pushNamed(context, '/change-password'),
                    ),
                    const Divider(height: 1),
                    _buildMenuTile(
                      icon: Icons.notifications_none_outlined,
                      title: 'Cài đặt thông báo',
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/notification-settings',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 4. Nút Đăng xuất
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

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: AppColors.textHint,
      ),
      onTap: onTap,
    );
  }
}
