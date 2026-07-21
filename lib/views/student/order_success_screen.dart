import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../viewmodels/checkout_viewmodel.dart';
import '../../widgets/canteen_button.dart';
import '../../widgets/canteen_card.dart';
import 'order_tracking_screen.dart';

// ============================================================
// VIEW: views/student/order_success_screen.dart
// Owner: Member 3 — An
// Mô tả: Giao diện hiển thị khi đặt hàng thành công
// ============================================================

class OrderSuccessScreen extends StatefulWidget {
  const OrderSuccessScreen({super.key, required this.result});

  final CheckoutResult result;

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen> {
  bool _showSuccessIcon = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _showSuccessIcon = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeFormat = DateFormat('HH:mm');
    final dateFormat = DateFormat('dd/MM/yyyy');

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context, 'go_to_home');
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Animated Success Circle
                        AnimatedScale(
                          scale: _showSuccessIcon ? 1.0 : 0.6,
                          duration: const Duration(milliseconds: 450),
                          curve: Curves.easeOutBack,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 350),
                            width: 112,
                            height: 112,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: theme.colorScheme.primaryContainer
                                  .withOpacity(0.2),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.2),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.check_circle,
                              size: 80,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Success Message Header
                        const Text(
                          'Đặt hàng thành công!',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Đơn hàng của bạn đã được gửi đến căn tin.\nVui lòng theo dõi trạng thái và đến nhận món đúng giờ.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        // Order info Summary Card
                        CanteenCard(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Chi tiết đơn hàng',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const Divider(height: 24),
                              _buildSummaryRow(
                                'Mã đơn hàng:',
                                widget.result.displayCode,
                                isBold: true,
                              ),
                              const SizedBox(height: 12),
                              _buildSummaryRow(
                                'Ngày đặt:',
                                dateFormat.format(DateTime.now()),
                              ),
                              const SizedBox(height: 12),
                              _buildSummaryRow(
                                'Nhận món:',
                                '${dateFormat.format(widget.result.pickupAt)} ${timeFormat.format(widget.result.pickupAt)}',
                                isBold: true,
                              ),
                              const SizedBox(height: 12),
                              _buildSummaryRow(
                                'Trạng thái:',
                                'Chờ xác nhận',
                                valueColor: AppColors.pending,
                                isBold: true,
                              ),
                              const Divider(height: 24),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Tổng thanh toán:',
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    CurrencyFormatter.format(
                                      widget.result.finalTotal,
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
                      ],
                    ),
                  ),
                ),
              ),

              // Sticky footer containing action buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CanteenButton(
                      text: 'Theo dõi đơn hàng',
                      onPressed: () async {
                        final result = await Navigator.push<String>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OrderTrackingScreen(
                              orderId: widget.result.orderId,
                              popToHistory: true,
                            ),
                          ),
                        );
                        if (context.mounted && result == 'go_to_orders') {
                          Navigator.pop(context, 'go_to_orders');
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, 'go_to_home'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          foregroundColor: AppColors.primary,
                        ),
                        child: const Text(
                          'Về trang chủ',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
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
}
