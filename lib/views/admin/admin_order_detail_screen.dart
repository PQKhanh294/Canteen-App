import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../models/order_model.dart';
import '../../viewmodels/admin_viewmodel.dart';
import '../../widgets/canteen_button.dart';
import '../../widgets/canteen_card.dart';
import '../../widgets/status_badge.dart';

class AdminOrderDetailScreen extends StatelessWidget {
  const AdminOrderDetailScreen({super.key, required this.order});
  final OrderModel order;
  @override
  Widget build(BuildContext context) {
    final next = {
      AppConstants.statusPending: AppConstants.statusPreparing,
      AppConstants.statusPreparing: AppConstants.statusReady,
      AppConstants.statusReady: AppConstants.statusCompleted,
    }[order.status];
    final labels = {
      AppConstants.statusPreparing: 'Xác nhận & bắt đầu làm',
      AppConstants.statusReady: 'Đánh dấu sẵn sàng',
      AppConstants.statusCompleted: 'Hoàn thành',
    };
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Đơn #${order.id.substring(0, order.id.length.clamp(0, 8))}',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CanteenCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Trạng thái',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    StatusBadge(status: order.status),
                  ],
                ),
                const Divider(),
                Text('Khách: ${order.userName}'),
                Text('Giờ nhận: ${order.pickupTime}'),
                Text('Thanh toán: ${order.paymentMethod}'),
                Text(
                  'Đặt lúc: ${DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt)}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          CanteenCard(
            child: Column(
              children: [
                ...order.items.map(
                  (i) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(i.foodName),
                    subtitle: Text(
                      '${i.quantity} × ${NumberFormat.currency(locale: 'vi', symbol: '₫').format(i.price)}',
                    ),
                    trailing: Text(
                      NumberFormat.currency(
                        locale: 'vi',
                        symbol: '₫',
                      ).format(i.subtotal),
                    ),
                  ),
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tổng cộng',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      NumberFormat.currency(
                        locale: 'vi',
                        symbol: '₫',
                      ).format(order.totalPrice),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (next != null) ...[
            const SizedBox(height: 20),
            CanteenButton(
              text: labels[next]!,
              isLoading: context.watch<AdminViewModel>().isLoading,
              onPressed: () async {
                try {
                  await context.read<AdminViewModel>().updateOrderStatus(
                    order,
                    next,
                  );
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted)
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('$e')));
                }
              },
            ),
          ],
        ],
      ),
    );
  }
}
