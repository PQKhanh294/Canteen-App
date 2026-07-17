import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/enums/discount_type.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/promo_calculator.dart';
import '../../models/promo_model.dart';
import '../../viewmodels/promo_viewmodel.dart';
import '../../widgets/canteen_button.dart';
import '../../widgets/canteen_card.dart';
import '../../widgets/canteen_text_field.dart';

// ============================================================
// VIEW: views/student/voucher_screen.dart
// Owner: Member 3 — An
// Mô tả: Màn hình chọn mã giảm giá (Voucher Selector) cho sinh viên
// ============================================================

class VoucherScreen extends StatefulWidget {
  final int subtotal;
  final String? selectedPromoCode;

  const VoucherScreen({
    super.key,
    required this.subtotal,
    this.selectedPromoCode,
  });

  @override
  State<VoucherScreen> createState() => _VoucherScreenState();
}

class _VoucherScreenState extends State<VoucherScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isCheckingCode = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError ? AppColors.error : AppColors.success,
        ),
      );
  }

  Future<void> _handleApplyCode() async {
    if (_isCheckingCode) return;

    final code = _codeController.text.trim();

    if (code.isEmpty) {
      _showMessage('Vui lòng nhập mã giảm giá.', isError: true);
      return;
    }

    setState(() {
      _isCheckingCode = true;
    });

    final promo = await context.read<PromoViewModel>().findPromoByCode(code);

    if (!mounted) return;

    setState(() {
      _isCheckingCode = false;
    });

    if (promo == null) {
      final errorMessage = context.read<PromoViewModel>().errorMessage;
      _showMessage(
        errorMessage ?? 'Mã giảm giá không tồn tại hoặc không hợp lệ.',
        isError: true,
      );
      return;
    }

    _trySelectPromo(promo);
  }

  void _trySelectPromo(PromoModel promo) {
    final validation = PromoCalculator.validate(
      promo: promo,
      subtotal: widget.subtotal,
    );

    if (!validation.isValid) {
      _showMessage(validation.message, isError: true);
      return;
    }

    Navigator.pop(context, promo);
  }

  String _discountLabel(PromoModel promo) {
    switch (promo.discountType) {
      case DiscountType.percentage:
        return 'Giảm ${promo.discountValue.toInt()}%';
      case DiscountType.fixed:
        return 'Giảm ${CurrencyFormatter.format(promo.discountValue)}';
    }
  }

  String _disabledButtonText(PromoValidationStatus status) {
    switch (status) {
      case PromoValidationStatus.inactive:
        return 'Tạm dừng';
      case PromoValidationStatus.notStarted:
        return 'Chưa đến hạn';
      case PromoValidationStatus.expired:
        return 'Hết hạn';
      case PromoValidationStatus.minimumOrderNotMet:
        return 'Chưa đủ điều kiện';
      case PromoValidationStatus.usageLimitReached:
        return 'Hết lượt';
      case PromoValidationStatus.invalidConfiguration:
        return 'Không khả dụng';
      default:
        return 'Không thể dùng';
    }
  }

  Color _statusColor(PromoValidationStatus status) {
    switch (status) {
      case PromoValidationStatus.valid:
        return AppColors.success;
      case PromoValidationStatus.minimumOrderNotMet:
        return AppColors.pending;
      case PromoValidationStatus.inactive:
      case PromoValidationStatus.expired:
      case PromoValidationStatus.usageLimitReached:
      case PromoValidationStatus.invalidConfiguration:
        return AppColors.error;
      case PromoValidationStatus.notStarted:
        return AppColors.textSecondary;
    }
  }

  String _statusLabel(PromoValidationStatus status) {
    switch (status) {
      case PromoValidationStatus.valid:
        return 'Có thể áp dụng';
      case PromoValidationStatus.inactive:
        return 'Tạm dừng';
      case PromoValidationStatus.notStarted:
        return 'Chưa bắt đầu';
      case PromoValidationStatus.expired:
        return 'Hết hạn';
      case PromoValidationStatus.minimumOrderNotMet:
        return 'Chưa đủ điều kiện';
      case PromoValidationStatus.usageLimitReached:
        return 'Hết lượt';
      case PromoValidationStatus.invalidConfiguration:
        return 'Không khả dụng';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Mã Giảm Giá',
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Phần thông tin giá trị đơn hiện tại
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: CanteenCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.receipt_long,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Giá trị đơn hiện tại',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            CurrencyFormatter.format(widget.subtotal),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. Ô nhập mã thủ công
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: CanteenTextField(
                      controller: _codeController,
                      labelText: 'Nhập mã giảm giá',
                      hintText: 'Ví dụ: FPT10',
                      prefixIcon: Icons.local_offer_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 52,
                    child: CanteenButton(
                      text: 'Áp dụng',
                      width: 100,
                      isLoading: _isCheckingCode,
                      onPressed: _isCheckingCode ? null : _handleApplyCode,
                    ),
                  ),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Voucher hiện có',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
            ),

            // 3. Danh sách voucher từ Firestore
            Expanded(
              child: Consumer<PromoViewModel>(
                builder: (context, promoVM, child) {
                  if (promoVM.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    );
                  }

                  if (promoVM.errorMessage != null && promoVM.promos.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.cloud_off,
                              size: 64,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              promoVM.errorMessage!,
                              style: const TextStyle(
                                fontSize: 16,
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            CanteenButton(
                              text: 'Thử lại',
                              width: 150,
                              onPressed: () => promoVM.reloadPromos(),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (promoVM.promos.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.confirmation_number_outlined,
                                size: 64,
                                color: AppColors.textHint,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Chưa có mã giảm giá',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Các ưu đãi mới sẽ được cập nhật tại đây.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: promoVM.promos.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final promo = promoVM.promos[index];
                      final validation = PromoCalculator.validate(
                        promo: promo,
                        subtotal: widget.subtotal,
                      );
                      final isSelected = widget.selectedPromoCode == promo.code;
                      final statColor = _statusColor(validation.status);
                      final statLabel = _statusLabel(validation.status);

                      return CanteenCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.confirmation_number,
                                      color: AppColors.primary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      promo.code,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    statLabel,
                                    style: TextStyle(
                                      color: statColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              promo.description,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textPrimary,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _discountLabel(promo),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                        fontSize: 14,
                                      ),
                                    ),
                                    if (promo.maximumDiscount != null &&
                                        promo.discountType ==
                                            DiscountType.percentage)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 2.0,
                                        ),
                                        child: Text(
                                          'Giảm tối đa: ${CurrencyFormatter.format(promo.maximumDiscount!)}',
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Hết hạn: ${dateFormat.format(promo.expiresAt)}',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: 36,
                                  child: isSelected
                                      ? OutlinedButton(
                                          onPressed: null,
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(
                                              color: AppColors.primary,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: const Text(
                                            'Đã chọn',
                                            style: TextStyle(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        )
                                      : CanteenButton(
                                          text: validation.isValid
                                              ? 'Áp dụng'
                                              : _disabledButtonText(
                                                  validation.status,
                                                ),
                                          borderRadius: 8,
                                          onPressed: validation.isValid
                                              ? () => _trySelectPromo(promo)
                                              : null,
                                        ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
