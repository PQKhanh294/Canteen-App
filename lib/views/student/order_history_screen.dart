import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/order_model.dart';
import '../../viewmodels/order_viewmodel.dart';
import '../../widgets/canteen_card.dart';
import '../../widgets/status_badge.dart';

// ============================================================
// VIEW: views/student/order_history_screen.dart
// Owner: Member 3 — An
// Mô tả: Giao diện Lịch sử đơn hàng của sinh viên
// ============================================================

enum OrderHistoryFilter { all, processing, completed, cancelled }

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key, this.onExploreMenu, this.onOpenOrder});

  final VoidCallback? onExploreMenu;
  final ValueChanged<String>? onOpenOrder;

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    final orderVM = context.watch<OrderViewModel>();

    if (orderVM.isLoading && orderVM.orders.isEmpty) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (orderVM.errorMessage != null && orderVM.orders.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text(
            'Đơn hàng',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 60,
                  color: AppColors.error,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Không thể tải lịch sử đơn hàng',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Vui lòng kiểm tra kết nối và thử lại.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => orderVM.retry(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text(
            'Đơn hàng',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          bottom: const TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: [
              Tab(text: 'Tất cả'),
              Tab(text: 'Đang xử lý'),
              Tab(text: 'Hoàn thành'),
              Tab(text: 'Đã hủy'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildOrderList(orderVM, OrderHistoryFilter.all),
            _buildOrderList(orderVM, OrderHistoryFilter.processing),
            _buildOrderList(orderVM, OrderHistoryFilter.completed),
            _buildOrderList(orderVM, OrderHistoryFilter.cancelled),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderList(OrderViewModel orderVM, OrderHistoryFilter filter) {
    final filteredOrders = _ordersForFilter(orderVM, filter);

    if (filteredOrders.isEmpty) {
      return _buildEmptyState(filter);
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: filteredOrders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = filteredOrders[index];
        return _OrderCard(order: order, onTap: () => _openOrder(order));
      },
    );
  }

  List<OrderModel> _ordersForFilter(
    OrderViewModel viewModel,
    OrderHistoryFilter filter,
  ) {
    switch (filter) {
      case OrderHistoryFilter.all:
        return viewModel.orders;
      case OrderHistoryFilter.processing:
        return viewModel.processingOrders;
      case OrderHistoryFilter.completed:
        return viewModel.completedOrders;
      case OrderHistoryFilter.cancelled:
        return viewModel.cancelledOrders;
    }
  }

  Widget _buildEmptyState(OrderHistoryFilter filter) {
    String title;
    String description;
    Widget? actionButton;

    switch (filter) {
      case OrderHistoryFilter.all:
        title = 'Bạn chưa có đơn hàng nào';
        description = 'Hãy chọn món yêu thích và đặt đơn đầu tiên.';
        if (widget.onExploreMenu != null) {
          actionButton = ElevatedButton(
            onPressed: widget.onExploreMenu,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Khám phá thực đơn'),
          );
        }
        break;
      case OrderHistoryFilter.processing:
        title = 'Không có đơn hàng';
        description = 'Không có đơn hàng nào đang trong quá trình chuẩn bị.';
        break;
      case OrderHistoryFilter.completed:
        title = 'Chưa có đơn hoàn thành';
        description = 'Bạn chưa có lịch sử đơn hàng đã hoàn tất tại canteen.';
        break;
      case OrderHistoryFilter.cancelled:
        title = 'Không có đơn đã hủy';
        description = 'Không ghi nhận đơn hàng nào bị hủy của bạn.';
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: AppColors.textHint.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionButton != null) ...[
              const SizedBox(height: 20),
              actionButton,
            ],
          ],
        ),
      ),
    );
  }

  void _openOrder(OrderModel order) {
    if (widget.onOpenOrder != null) {
      widget.onOpenOrder!(order.id);
      return;
    }

    // Fallback bottom sheet for Giai đoạn 5 placeholder detail
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final timeFormat = DateFormat('HH:mm');
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                      'Khung giờ nhận:',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    Text(
                      timeFormat.format(order.pickupAt),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tổng thanh toán:',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    Text(
                      CurrencyFormatter.format(order.finalTotal),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.1),
                    ),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.info_outline, color: AppColors.primary),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Chi tiết đơn hàng và Theo dõi Realtime sẽ được hoàn thiện ở giai đoạn tiếp theo.',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Đóng'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onTap});

  final OrderModel order;
  final VoidCallback onTap;

  String _formatCreatedAt(DateTime? date) {
    if (date == null) {
      return 'Đang cập nhật thời gian';
    }
    return DateFormat('dd/MM/yyyy • HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return CanteenCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      order.displayCode,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  StatusBadge(status: order.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _formatCreatedAt(order.createdAt),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${order.totalQuantity} món',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(order.finalTotal),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
