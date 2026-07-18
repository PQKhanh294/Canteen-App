import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/enums/order_status.dart';
import '../../core/enums/payment_method.dart';
import '../../core/enums/payment_status.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/order_model.dart';
import '../../viewmodels/order_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../services/firestore_service.dart';
import '../../widgets/canteen_button.dart';
import '../../widgets/canteen_card.dart';
import '../../widgets/status_badge.dart';
import 'order_tracking_screen.dart';
import 'write_review_screen.dart';
import '../../viewmodels/cart_viewmodel.dart';

// ============================================================
// VIEW: views/student/order_detail_screen.dart
// Owner: Member 3 — An
// Mô tả: Giao diện chi tiết đơn hàng (Order Detail Screen)
// ============================================================

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  String _formatCreatedAt(DateTime? date) {
    if (date == null) {
      return 'Đang cập nhật thời gian';
    }
    return DateFormat('dd/MM/yyyy • HH:mm').format(date);
  }

  String _formatPickupAt(DateTime date) {
    return DateFormat('dd/MM/yyyy lúc HH:mm').format(date);
  }

  String _mapPaymentMethod(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Tiền mặt khi nhận món';
      case PaymentMethod.eWalletMock:
        return 'Ví điện tử — Demo';
    }
  }

  String _mapPaymentStatus(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.unpaid:
        return 'Chưa thanh toán';
      case PaymentStatus.mockPaid:
        return 'Đã thanh toán mô phỏng';
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderVM = context.watch<OrderViewModel>();
    final authVM = context.watch<AuthViewModel>();
    final user = authVM.currentUser;

    final order = orderVM.findOrder(orderId);

    if (order == null) {
      if (orderVM.isLoading) {
        return const Scaffold(
          backgroundColor: AppColors.background,
          body: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        );
      }

      if (orderVM.errorMessage != null) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Chi tiết đơn hàng'),
            elevation: 0,
            backgroundColor: Colors.transparent,
          ),
          body: Center(
            child: Text(
              orderVM.errorMessage ?? 'Có lỗi xảy ra khi tải dữ liệu.',
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        );
      }

      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Chi tiết đơn hàng'),
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.textPrimary,
        ),
        body: const Center(
          child: Text(
            'Không tìm thấy đơn hàng.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Chi tiết đơn hàng',
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
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                children: [
                  // 1. Trạng thái và mã đơn
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
                        const SizedBox(height: 12),
                        _buildRow(
                          'Ngày đặt:',
                          _formatCreatedAt(order.createdAt),
                        ),
                        const SizedBox(height: 8),
                        _buildRow(
                          'Giờ nhận món:',
                          _formatPickupAt(order.pickupAt),
                          isBold: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. Thanh toán & Voucher
                  CanteenCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Thông tin thanh toán',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Divider(height: 24),
                        _buildRow(
                          'Phương thức:',
                          _mapPaymentMethod(order.paymentMethod),
                        ),
                        const SizedBox(height: 8),
                        _buildRow(
                          'Trạng thái:',
                          _mapPaymentStatus(order.paymentStatus),
                          valueColor:
                              order.paymentStatus == PaymentStatus.mockPaid
                              ? AppColors.success
                              : AppColors.error,
                          isBold: true,
                        ),
                        if (order.promoCode != null) ...[
                          const Divider(height: 24),
                          _buildRow(
                            'Mã giảm giá:',
                            order.promoCode!,
                            isBold: true,
                          ),
                          const SizedBox(height: 8),
                          _buildRow(
                            'Đã giảm:',
                            '-${CurrencyFormatter.format(order.discountAmount.toInt())}',
                            valueColor: AppColors.success,
                            isBold: true,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. Thông tin hủy đơn (nếu có)
                  if (order.status == OrderStatus.cancelled) ...[
                    CanteenCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Đơn hàng đã bị hủy',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.error,
                            ),
                          ),
                          const Divider(height: 24),
                          _buildRow(
                            'Lý do hủy:',
                            order.cancelReason ?? 'Không có lý do cụ thể.',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 4. Danh sách món ăn
                  _buildSectionHeader('Món ăn đã đặt'),
                  CanteenCard(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: order.items.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 24),
                          itemBuilder: (context, index) {
                            final item = order.items[index];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: CachedNetworkImage(
                                        imageUrl: item.imageUrl.isNotEmpty
                                            ? item.imageUrl
                                            : 'https://via.placeholder.com/100',
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.foodName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${CurrencyFormatter.format(item.unitPrice.toInt())} × ${item.quantity}',
                                            style: const TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      CurrencyFormatter.format(
                                        item.lineTotal.toInt(),
                                      ),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                if (order.status == OrderStatus.completed &&
                                    user != null) ...[
                                  const SizedBox(height: 8),
                                  _ReviewButton(
                                    orderId: order.id,
                                    foodId: item.foodId,
                                    foodName: item.foodName,
                                    userId: user.uid,
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 5. Tổng chi phí
                  CanteenCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildRow(
                          'Tạm tính:',
                          CurrencyFormatter.format(order.subtotal.toInt()),
                        ),
                        const SizedBox(height: 8),
                        _buildRow(
                          'Giảm giá:',
                          '-${CurrencyFormatter.format(order.discountAmount.toInt())}',
                          valueColor: AppColors.success,
                          isBold: order.discountAmount > 0,
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Tổng thanh toán:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              CurrencyFormatter.format(
                                order.finalTotal.toInt(),
                              ),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),

            // 6. Sticky buttons footer
            _buildActionArea(
              context,
              order,
              orderVM.isCancellingOrder(order.id),
              orderVM.isReorderingOrder(order.id),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
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

  Widget _buildRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? AppColors.textPrimary,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildActionArea(
    BuildContext context,
    OrderModel order,
    bool isCancelling,
    bool isReordering,
  ) {
    final showTracking =
        order.status == OrderStatus.pending ||
        order.status == OrderStatus.confirmed ||
        order.status == OrderStatus.preparing ||
        order.status == OrderStatus.ready;

    // Hủy đơn chỉ hiển thị khi pending
    final showCancel = order.canCancel;

    // Đặt lại hiển thị khi completed hoặc cancelled
    final showReorder =
        order.status == OrderStatus.completed ||
        order.status == OrderStatus.cancelled;

    if (!showTracking && !showCancel && !showReorder) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showTracking)
            CanteenButton(
              text: 'Theo dõi đơn hàng',
              onPressed: isCancelling || isReordering
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              OrderTrackingScreen(orderId: order.id),
                        ),
                      );
                    },
            ),
          if (showCancel) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: isCancelling || isReordering
                    ? null
                    : () => _handleCancelOrder(context, order),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledForegroundColor: AppColors.error.withOpacity(0.4),
                  foregroundColor: AppColors.error,
                ),
                child: isCancelling
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                          color: AppColors.error,
                        ),
                      )
                    : const Text(
                        'Hủy đơn hàng',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
          if (showReorder)
            CanteenButton(
              text: 'Đặt lại đơn hàng',
              isLoading: isReordering,
              onPressed: isCancelling || isReordering
                  ? null
                  : () => _handleReorder(context, order),
            ),
        ],
      ),
    );
  }

  Future<String?> _showCancelReasonSheet(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return const _CancelReasonSheet();
      },
    );
  }

  Future<void> _handleCancelOrder(
    BuildContext context,
    OrderModel order,
  ) async {
    final reason = await _showCancelReasonSheet(context);
    if (reason == null || reason.isEmpty) return;

    final auth = context.read<AuthViewModel>();
    final user = auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đăng nhập lại.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final success = await context.read<OrderViewModel>().cancelOrder(
      orderId: order.id,
      userId: user.uid,
      reason: reason,
    );

    if (!success) {
      final orderVM = context.read<OrderViewModel>();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(orderVM.errorMessage ?? 'Không thể hủy đơn hàng.'),
          backgroundColor: AppColors.error,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đơn hàng đã được hủy thành công.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _handleReorder(BuildContext context, OrderModel order) async {
    final cartVM = context.read<CartViewModel>();
    final orderVM = context.read<OrderViewModel>();

    final result = await orderVM.reorder(order: order, cartViewModel: cartVM);

    if (!result.hasAddedItems) {
      await _showReorderResultSheet(context, result, hasAddedItems: false);
      return;
    }

    if (result.hasSkippedItems) {
      await _showReorderResultSheet(context, result, hasAddedItems: true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã đặt lại đơn hàng thành công.'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, 'go_to_cart');
    }
  }

  Future<void> _showReorderResultSheet(
    BuildContext context,
    ReorderResult result, {
    required bool hasAddedItems,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      hasAddedItems
                          ? Icons.check_circle_outline
                          : Icons.error_outline,
                      color: hasAddedItems
                          ? AppColors.success
                          : AppColors.error,
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        hasAddedItems
                            ? 'Đặt lại đơn hàng một phần'
                            : 'Không thể đặt lại đơn hàng',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (hasAddedItems)
                  Text(
                    'Đã thêm ${result.addedQuantity} món vào giỏ hàng thành công. Các món dưới đây bị bỏ qua:',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  )
                else
                  const Text(
                    'Các món trong đơn hiện không còn được bán hoặc đang hết hàng.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                const SizedBox(height: 16),
                if (result.deletedFoods.isNotEmpty) ...[
                  const Text(
                    'Món ăn đã ngừng kinh doanh:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  ...result.deletedFoods.map(
                    (name) => Padding(
                      padding: const EdgeInsets.only(left: 12.0, top: 4.0),
                      child: Text(
                        '• $name',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (result.unavailableFoods.isNotEmpty) ...[
                  const Text(
                    'Món ăn hiện đã hết hàng:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  ...result.unavailableFoods.map(
                    (name) => Padding(
                      padding: const EdgeInsets.only(left: 12.0, top: 4.0),
                      child: Text(
                        '• $name',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (result.failedFoods.isNotEmpty) ...[
                  const Text(
                    'Món ăn không thể thêm (Vượt giới hạn 99 món):',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  ...result.failedFoods.map(
                    (name) => Padding(
                      padding: const EdgeInsets.only(left: 12.0, top: 4.0),
                      child: Text(
                        '• $name',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.divider),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'Đóng',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    if (hasAddedItems) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: CanteenButton(
                          text: 'Xem giỏ hàng',
                          onPressed: () {
                            Navigator.pop(context); // Close result sheet
                            Navigator.pop(
                              context,
                              'go_to_cart',
                            ); // Return back to trigger tab change
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CancelReasonSheet extends StatefulWidget {
  const _CancelReasonSheet();

  @override
  State<_CancelReasonSheet> createState() => _CancelReasonSheetState();
}

class _CancelReasonSheetState extends State<_CancelReasonSheet> {
  String? _selectedReason;
  final _otherReasonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final List<String> _reasons = ['Đặt nhầm', 'Đổi ý', 'Không thể đến lấy'];

  @override
  void dispose() {
    _otherReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final isOtherSelected = _selectedReason == 'Khác';
    bool canSubmit = _selectedReason != null;
    if (isOtherSelected) {
      canSubmit = _otherReasonController.text.trim().isNotEmpty;
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Hủy đơn hàng',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Vui lòng cho chúng tôi biết lý do bạn muốn hủy đơn.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ..._reasons.map((reason) {
              return RadioListTile<String>(
                title: Text(
                  reason,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                value: reason,
                groupValue: _selectedReason,
                activeColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
                onChanged: (value) {
                  setState(() {
                    _selectedReason = value;
                  });
                },
              );
            }),
            RadioListTile<String>(
              title: const Text(
                'Khác',
                style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
              ),
              value: 'Khác',
              groupValue: _selectedReason,
              activeColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
              onChanged: (value) {
                setState(() {
                  _selectedReason = value;
                });
              },
            ),
            if (isOtherSelected) ...[
              const SizedBox(height: 8),
              TextFormField(
                controller: _otherReasonController,
                maxLength: 200,
                maxLines: 3,
                autofocus: true,
                onChanged: (_) {
                  setState(() {}); // Rebuild to update button enabled
                },
                decoration: InputDecoration(
                  hintText: 'Nhập lý do hủy cụ thể...',
                  hintStyle: const TextStyle(
                    color: AppColors.textHint,
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: isDark ? Colors.grey[850] : Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.divider),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Giữ đơn hàng',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CanteenButton(
                    text: 'Xác nhận hủy',
                    onPressed: canSubmit
                        ? () {
                            final finalReason = isOtherSelected
                                ? _otherReasonController.text.trim()
                                : _selectedReason;
                            Navigator.pop(context, finalReason);
                          }
                        : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Widget Stateful tự kiểm tra và quản lý trạng thái hiển thị của nút đánh giá
class _ReviewButton extends StatefulWidget {
  const _ReviewButton({
    required this.orderId,
    required this.foodId,
    required this.foodName,
    required this.userId,
  });

  final String orderId;
  final String foodId;
  final String foodName;
  final String userId;

  @override
  State<_ReviewButton> createState() => _ReviewButtonState();
}

class _ReviewButtonState extends State<_ReviewButton> {
  late Future<bool> _checkFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _checkFuture = context.read<FirestoreService>().hasReviewed(
      widget.userId,
      widget.foodId,
      orderId: widget.orderId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          );
        }

        final hasReviewed = snapshot.data ?? false;
        if (hasReviewed) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
            child: Text(
              'Đã đánh giá',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }

        return TextButton(
          onPressed: () async {
            final reviewed = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => WriteReviewScreen(
                  orderId: widget.orderId,
                  foodId: widget.foodId,
                  foodName: widget.foodName,
                ),
              ),
            );

            if (reviewed == true) {
              setState(() {
                _load();
              });
            }
          },
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          child: const Text('Đánh giá'),
        );
      },
    );
  }
}
