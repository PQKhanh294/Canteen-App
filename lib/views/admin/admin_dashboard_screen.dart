import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/enums/order_status.dart';
import '../../models/order_model.dart';
import '../../viewmodels/admin_viewmodel.dart';
import '../../widgets/canteen_card.dart';
import '../../widgets/status_badge.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final vm = context.read<AdminViewModel>();
    return StreamBuilder<List<OrderModel>>(
      stream: vm.ordersStream,
      builder: (context, ordersSnap) => StreamBuilder(
        stream: vm.foodsStream,
        builder: (context, foodsSnap) {
          if (ordersSnap.hasError || foodsSnap.hasError) {
            return Center(
              child: Text(
                'Không tải được tổng quan: '
                '${ordersSnap.error ?? foodsSnap.error}',
              ),
            );
          }
          if (!ordersSnap.hasData || !foodsSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final now = DateTime.now();
          final today = ordersSnap.data!
              .where(
                (o) =>
                    o.createdAt.year == now.year &&
                    o.createdAt.month == now.month &&
                    o.createdAt.day == now.day,
              )
              .toList();
          final revenue = today
              .where((o) => o.status == OrderStatus.completed)
              .fold<double>(0, (s, o) => s + o.totalPrice);
          final foods = foodsSnap.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.45,
                children: [
                  _Stat(
                    'Đơn hôm nay',
                    '${today.length}',
                    Icons.receipt,
                    AppColors.primary,
                  ),
                  _Stat(
                    'Doanh thu',
                    NumberFormat.compactCurrency(
                      locale: 'vi',
                      symbol: '₫',
                    ).format(revenue),
                    Icons.payments,
                    AppColors.success,
                  ),
                  _Stat(
                    'Tổng món',
                    '${foods.length}',
                    Icons.restaurant,
                    AppColors.preparing,
                  ),
                  _Stat(
                    'Hết hàng',
                    '${foods.where((f) => !f.available).length}',
                    Icons.warning_amber,
                    AppColors.error,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Thao tác nhanh',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/admin/food-form'),
                      icon: const Icon(Icons.add),
                      label: const Text('Thêm món'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/admin/orders'),
                      icon: const Icon(Icons.receipt_long),
                      label: const Text('Đơn mới'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Đơn hàng gần nhất',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...ordersSnap.data!
                  .take(5)
                  .map(
                    (o) => CanteenCard(
                      margin: const EdgeInsets.only(bottom: 8),
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/admin/order-detail',
                        arguments: o,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  o.userName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${o.items.length} món · ${DateFormat('HH:mm').format(o.createdAt)}',
                                ),
                              ],
                            ),
                          ),
                          StatusBadge(status: o.status),
                        ],
                      ),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, this.icon, this.color);
  final String label, value;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => CanteenCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Icon(icon, color: color),
        Text(
          value,
          maxLines: 1,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
      ],
    ),
  );
}
