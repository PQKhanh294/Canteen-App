import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/enums/order_status.dart';
import '../../services/firestore_service.dart';
import '../../models/order_model.dart';
import '../../widgets/canteen_card.dart';
import '../../widgets/status_badge.dart';

// ============================================================
// VIEW: views/student/order_tracking_screen.dart
// Owner: Member 3 — An
// Mô tả: Màn hình theo dõi trạng thái đơn hàng thời gian thực
// ============================================================

class OrderTrackingScreen extends StatelessWidget {
  const OrderTrackingScreen({
    super.key,
    required this.orderId,
    this.popToHistory = false,
  });

  final String orderId;
  final bool popToHistory;

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.read<FirestoreService>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Theo dõi đơn hàng',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () =>
              Navigator.pop(context, popToHistory ? 'go_to_orders' : null),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<OrderModel>(
          stream: firestoreService.watchOrder(orderId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            if (snapshot.hasError) {
              final errStr = snapshot.error.toString();
              if (errStr.contains('ORDER_NOT_FOUND')) {
                return _buildNotFoundState();
              }
              return _buildErrorState();
            }

            final order = snapshot.data;
            if (order == null) {
              return _buildNotFoundState();
            }

            if (order.status == OrderStatus.cancelled) {
              return _buildCancelledState(order);
            }

            return _buildTrackingContent(context, order);
          },
        ),
      ),
    );
  }

  Widget _buildNotFoundState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_outlined,
              size: 64,
              color: AppColors.textHint,
            ),
            SizedBox(height: 16),
            Text(
              'Không tìm thấy đơn hàng',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Đơn hàng có thể đã bị xóa hoặc không tồn tại.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            SizedBox(height: 16),
            Text(
              'Không thể tải trạng thái đơn hàng',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Vui lòng kiểm tra kết nối mạng của bạn và thử lại.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCancelledState(OrderModel order) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          const Icon(Icons.cancel_outlined, size: 80, color: AppColors.error),
          const SizedBox(height: 24),
          const Text(
            'Đơn hàng đã bị hủy',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Mã đơn: ${order.displayCode}',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          CanteenCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lý do hủy đơn hàng:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  order.cancelReason ?? 'Không có lý do cụ thể.',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.error,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingContent(BuildContext context, OrderModel order) {
    final pickupTimeStr = DateFormat(
      'dd/MM/yyyy • HH:mm',
    ).format(order.pickupAt);

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // 1. Tóm tắt nhanh mã đơn, trạng thái
        CanteenCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    order.displayCode,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  StatusBadge(status: order.status),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Thời gian nhận món:',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    pickupTimeStr,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 2. Ready Banner
        if (order.status == OrderStatus.ready) ...[
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.success.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.notifications_active,
                  color: AppColors.success,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Đơn hàng đã sẵn sàng!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.counterNumber != null
                            ? 'Vui lòng đến lấy món tại quầy số ${order.counterNumber}.'
                            : 'Vui lòng đến quầy căn tin để nhận món.',
                        style: TextStyle(
                          color: AppColors.success.withOpacity(0.8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // 3. Completed State Banner
        if (order.status == OrderStatus.completed) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: AppColors.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Đơn hàng đã hoàn thành.',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Cảm ơn bạn đã sử dụng dịch vụ căn tin.',
                        style: TextStyle(
                          color: AppColors.primary.withOpacity(0.8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // 4. Stepper dọc theo dõi đơn hàng
        _buildSectionHeader('Tiến trình đơn hàng'),
        CanteenCard(
          padding: const EdgeInsets.all(20),
          child: _OrderStatusStepper(order: order),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4.0, top: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _TrackingStepData {
  _TrackingStepData({
    required this.title,
    required this.description,
    this.timestamp,
  });

  final String title;
  final String description;
  final DateTime? timestamp;
}

class _OrderStatusStepper extends StatelessWidget {
  const _OrderStatusStepper({required this.order});

  final OrderModel order;

  int _currentStepForStatus(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 0;
      case OrderStatus.confirmed:
      case OrderStatus.preparing:
        return 1;
      case OrderStatus.ready:
        return 2;
      case OrderStatus.completed:
        return 3;
      case OrderStatus.cancelled:
        return -1;
      case OrderStatus.unknown:
        return -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentStep = _currentStepForStatus(order.status);

    final steps = <_TrackingStepData>[
      _TrackingStepData(
        title: 'Chờ xác nhận',
        description: 'Căn tin đang tiếp nhận đơn hàng của bạn.',
        timestamp: order.statusTimestamps['pending'],
      ),
      _TrackingStepData(
        title: 'Đang chuẩn bị',
        description: 'Căn tin đang chuẩn bị các món trong đơn hàng.',
        timestamp:
            order.statusTimestamps['preparing'] ??
            order.statusTimestamps['confirmed'],
      ),
      _TrackingStepData(
        title: 'Sẵn sàng lấy',
        description: 'Đơn hàng đã được chuẩn bị xong.',
        timestamp: order.statusTimestamps['ready'],
      ),
      _TrackingStepData(
        title: 'Hoàn thành',
        description: 'Bạn đã nhận đơn hàng.',
        timestamp: order.statusTimestamps['completed'],
      ),
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: steps.length,
      itemBuilder: (context, index) {
        final step = steps[index];
        final isCompleted = index < currentStep;
        final isCurrent = index == currentStep;
        final isFuture = index > currentStep;

        Color dotColor;
        double dotSize;
        Widget? dotChild;

        if (isCompleted) {
          dotColor = AppColors.success;
          dotSize = 24.0;
          dotChild = const Icon(Icons.check, size: 14, color: Colors.white);
        } else if (isCurrent) {
          dotColor = AppColors.primary;
          dotSize = 24.0;
          dotChild = Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          );
        } else {
          dotColor = AppColors.textHint.withOpacity(0.5);
          dotSize = 16.0;
        }

        final timeStr = step.timestamp != null
            ? DateFormat('dd/MM/yyyy • HH:mm').format(step.timestamp!)
            : null;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cột chứa vòng tròn trạng thái và đường kết nối dọc
              Column(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: dotSize,
                      height: dotSize,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                      ),
                      child: dotChild,
                    ),
                  ),
                  if (index < steps.length - 1)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: isCompleted
                            ? AppColors.success
                            : AppColors.divider,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),

              // Cột chứa tiêu đề, mô tả và thời gian của step
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isFuture
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        step.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: isFuture
                              ? AppColors.textHint
                              : AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      if (timeStr != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          timeStr,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
