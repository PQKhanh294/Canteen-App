import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';

// ============================================================
// WIDGET: StatusBadge
// Owner: ALL (Dùng chung cho toàn bộ app)
// Mô tả: Huy hiệu trạng thái đơn hàng (đơn hàng đang chuẩn bị, chờ lấy...)
// ============================================================

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor = Colors.white;
    String label;

    switch (status) {
      case AppConstants.statusPending:
        backgroundColor = AppColors.pending;
        textColor = Colors.black87;
        label = 'Chờ xác nhận';
        break;
      case AppConstants.statusPreparing:
        backgroundColor = AppColors.preparing;
        label = 'Đang làm';
        break;
      case AppConstants.statusReady:
        backgroundColor = AppColors.ready;
        label = 'Sẵn sàng lấy';
        break;
      case AppConstants.statusCompleted:
        backgroundColor = AppColors.completed;
        label = 'Đã nhận đồ';
        break;
      case AppConstants.statusCancelled:
        backgroundColor = AppColors.cancelled;
        label = 'Đã hủy';
        break;
      default:
        backgroundColor = AppColors.textSecondary;
        label = 'Không rõ';
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
