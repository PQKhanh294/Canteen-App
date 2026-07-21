import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/enums/order_status.dart';
import '../../core/enums/payment_method.dart';
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
    final next = order.status.nextAdminStatus;
    const labels = {
      OrderStatus.confirmed: 'Xác nhận đơn hàng',
      OrderStatus.preparing: 'Bắt đầu chuẩn bị',
      OrderStatus.ready: 'Đánh dấu sẵn sàng',
      OrderStatus.completed: 'Hoàn thành',
    };
    return Scaffold(
      appBar: AppBar(title: Text('Đơn ${order.displayCode}')),
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
                Text(
                  'Nhận món: ${DateFormat('dd/MM/yyyy HH:mm').format(order.pickupAt)}',
                ),
                Text(
                  'Thanh toán: ${order.paymentMethod == PaymentMethod.cash ? 'Tiền mặt' : 'Ví điện tử (mô phỏng)'}',
                ),
                if (order.counterNumber != null)
                  Text('Quầy nhận món: ${order.counterNumber}'),
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
                  String? counterNumber;
                  if (next == OrderStatus.ready) {
                    counterNumber = await _requestCounterNumber(context);
                    if (counterNumber == null || counterNumber.isEmpty) return;
                  }
                  if (!context.mounted) return;
                  await context.read<AdminViewModel>().updateOrderStatus(
                    order,
                    next,
                    counterNumber: counterNumber,
                  );
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('$e')));
                  }
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  Future<String?> _requestCounterNumber(BuildContext context) async {
    var counterNumber = '';

    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Chọn quầy nhận món'),
        content: TextFormField(
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Số hoặc tên quầy',
            hintText: 'Ví dụ: 2',
          ),
          onChanged: (value) => counterNumber = value,
          onFieldSubmitted: (value) =>
              Navigator.pop(dialogContext, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, counterNumber.trim()),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }
}
