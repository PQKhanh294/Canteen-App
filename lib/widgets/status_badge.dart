import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/enums/order_status.dart';

// ============================================================
// WIDGET: StatusBadge
// Owner: ALL (Dùng chung cho toàn bộ app)
// Mô tả: Huy hiệu trạng thái đơn hàng (đơn hàng đang chuẩn bị, chờ lấy...)
// ============================================================

class StatusBadge extends StatelessWidget {
  final OrderStatus status;

  const StatusBadge({super.key, required this.status});

  factory StatusBadge.fromValue(String? value) {
    return StatusBadge(status: OrderStatus.fromValue(value));
  }

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor = Colors.white;
    String label;

    switch (status) {
      case OrderStatus.pending:
        backgroundColor = AppColors.pending;
        textColor = Colors.black87;
        label = 'Chờ xác nhận';
        break;
      case OrderStatus.confirmed:
        backgroundColor = AppColors.preparing;
        label = 'Đã xác nhận';
        break;
      case OrderStatus.preparing:
        backgroundColor = AppColors.preparing;
        label = 'Đang chuẩn bị';
        break;
      case OrderStatus.ready:
        backgroundColor = AppColors.ready;
        label = 'Sẵn sàng lấy';
        break;
      case OrderStatus.completed:
        backgroundColor = AppColors.completed;
        label = 'Hoàn thành';
        break;
      case OrderStatus.cancelled:
        backgroundColor = AppColors.cancelled;
        label = 'Đã hủy';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
