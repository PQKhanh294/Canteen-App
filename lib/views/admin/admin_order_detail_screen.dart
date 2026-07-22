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
    return StreamBuilder<OrderModel?>(
      stream: context.read<AdminViewModel>().orderStream(order.id),
      initialData: order,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: Text('Đơn ${order.displayCode}')),
            body: Center(
              child: Text('Không tải được đơn hàng: ${snapshot.error}'),
            ),
          );
        }
        final currentOrder = snapshot.data;
        if (currentOrder == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Chi tiết đơn hàng')),
            body: const Center(child: Text('Đơn hàng không còn tồn tại')),
          );
        }
        return _buildOrderDetail(context, currentOrder);
      },
    );
  }

  Widget _buildOrderDetail(BuildContext context, OrderModel currentOrder) {
    final nextStatus = currentOrder.status.nextAdminStatus;
    final actionLabel = nextStatus?.adminActionLabel;

    return Scaffold(
      appBar: AppBar(title: Text('Đơn ${currentOrder.displayCode}')),
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
                    StatusBadge(status: currentOrder.status),
                  ],
                ),
                const Divider(),
                Text('Khách: ${currentOrder.userName}'),
                Text(
                  'Nhận món: ${DateFormat('dd/MM/yyyy HH:mm').format(currentOrder.pickupAt)}',
                ),
                Text(
                  'Thanh toán: ${currentOrder.paymentMethod == PaymentMethod.cash ? 'Tiền mặt' : 'Ví điện tử (mô phỏng)'}',
                ),
                if (currentOrder.counterNumber != null)
                  Text('Quầy nhận món: ${currentOrder.counterNumber}'),
                Text(
                  'Đặt lúc: ${DateFormat('dd/MM/yyyy HH:mm').format(currentOrder.createdAt)}',
                ),
                if (currentOrder.note != null && currentOrder.note!.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade600),
                    ),
                    child: Text(
                      '📌 Ghi chú khách: ${currentOrder.note}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          CanteenCard(
            child: Column(
              children: [
                ...currentOrder.items.map(
                  (item) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.foodName),
                    subtitle: Text(
                      '${item.quantity} × ${NumberFormat.currency(locale: 'vi', symbol: '₫').format(item.price)}',
                    ),
                    trailing: Text(
                      NumberFormat.currency(
                        locale: 'vi',
                        symbol: '₫',
                      ).format(item.subtotal),
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
                      ).format(currentOrder.totalPrice),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (nextStatus != null && actionLabel != null) ...[
            const SizedBox(height: 20),
            CanteenButton(
              text: actionLabel,
              isLoading: context.watch<AdminViewModel>().isLoading,
              onPressed: () => _updateStatus(context, currentOrder, nextStatus),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _updateStatus(
    BuildContext context,
    OrderModel currentOrder,
    OrderStatus nextStatus,
  ) async {
    try {
      String? counterNumber;
      if (nextStatus == OrderStatus.ready) {
        counterNumber = await _requestCounterNumber(context);
        if (counterNumber == null || counterNumber.isEmpty) return;
      }
      if (!context.mounted) return;
      await context.read<AdminViewModel>().updateOrderStatus(
        currentOrder,
        nextStatus,
        counterNumber: counterNumber,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật trạng thái đơn hàng')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    }
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
