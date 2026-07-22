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
    final label = status.label;

    switch (status) {
      case OrderStatus.pending:
        backgroundColor = AppColors.pending;
        textColor = Colors.black87;
        break;
      case OrderStatus.confirmed:
        backgroundColor = AppColors.preparing;
        break;
      case OrderStatus.preparing:
        backgroundColor = AppColors.preparing;
        break;
      case OrderStatus.ready:
        backgroundColor = AppColors.ready;
        break;
      case OrderStatus.completed:
        backgroundColor = AppColors.completed;
        break;
      case OrderStatus.cancelled:
        backgroundColor = AppColors.cancelled;
        break;
      case OrderStatus.unknown:
        backgroundColor = AppColors.completed;
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
