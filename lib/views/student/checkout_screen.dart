import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/enums/payment_method.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/promo_model.dart';
import '../../models/cart_item_model.dart';
import '../../viewmodels/cart_viewmodel.dart';
import '../../viewmodels/checkout_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/canteen_button.dart';
import '../../widgets/canteen_card.dart';
import '../../widgets/canteen_text_field.dart';
import 'voucher_screen.dart';
import 'order_success_screen.dart';

// ============================================================
// VIEW: views/student/checkout_screen.dart
// Owner: Member 3 — An
// Mô tả: Giao diện thanh toán (Checkout Screen) cho sinh viên
// ============================================================

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final TextEditingController _promoCodeController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _promoCodeController.dispose();
    _noteController.dispose();
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

  Future<void> _handleApplyPromoCode(CheckoutViewModel checkout) async {
    final code = _promoCodeController.text.trim();
    if (code.isEmpty) {
      _showMessage('Vui lòng nhập mã giảm giá.', isError: true);
      return;
    }

    final result = await checkout.applyPromoCode(code);
    if (!mounted) return;

    if (result != null) {
      _showMessage(result.message, isError: !result.isValid);
      if (result.isValid) {
        _promoCodeController.clear();
      }
    } else {
      _showMessage(
        checkout.errorMessage ?? 'Không thể áp dụng mã.',
        isError: true,
      );
    }
  }

  Future<void> _handleSubmitOrder() async {
    final checkout = context.read<CheckoutViewModel>();
    final cart = context.read<CartViewModel>();
    final auth = context.read<AuthViewModel>();
    final user = auth.currentUser;

    if (user == null) {
      _showMessage('Vui lòng đăng nhập lại để đặt món.', isError: true);
      return;
    }

    final result = await checkout.submitOrder(
      userId: user.uid,
      userName: user.displayName,
      userEmail: user.email,
      cartItems: cart.items,
      note: _noteController.text.trim(),
    );

    if (!mounted) return;

    if (result == null) {
      final errorMsg = checkout.errorMessage ?? 'Không thể tạo đơn hàng. Vui lòng thử lại.';
      _showMessage(errorMsg, isError: true);

      // Nếu phát hiện món ăn cũ không còn tồn tại trong Firestore, tự động dọn món đó khỏi giỏ hàng
      if (errorMsg.contains('không còn tồn tại')) {
        await cart.clearCart();
      }
      return;
    }

    // Clear cart only after order creation succeeds
    await cart.clearCart();
    if (!mounted) return;

    await _handleCheckoutSuccess(result);
  }

  Future<void> _handleCheckoutSuccess(CheckoutResult result) async {
    final action = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => OrderSuccessScreen(result: result)),
    );
    if (!mounted) return;
    Navigator.pop(context, action ?? 'go_to_home');
  }

  @override
  Widget build(BuildContext context) {
    final cartVM = context.watch<CartViewModel>();
    final checkoutVM = context.watch<CheckoutViewModel>();

    // Synchronize subtotal if cart items change
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CheckoutViewModel>().updateSubtotal(
          cartVM.subtotal.toInt(),
        );
      }
    });

    final availableDates = checkoutVM.getAvailablePickupDates();
    final availableSlots = checkoutVM.getAvailablePickupSlots();

    return PopScope(
      canPop: !checkoutVM.isSubmitting,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text(
            'Thanh Toán',
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
            onPressed: checkoutVM.isSubmitting
                ? null
                : () => Navigator.pop(context),
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
                    // 1. Tóm tắt danh sách món ăn
                    _buildSectionHeader('Món ăn đã chọn'),
                    CanteenCard(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: cartVM.items.length,
                            separatorBuilder: (context, index) =>
                                const Divider(height: 16),
                            itemBuilder: (context, index) {
                              final item = cartVM.items[index];
                              return Row(
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
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${CurrencyFormatter.format(item.unitPrice)} × ${item.quantity}',
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    CurrencyFormatter.format(item.lineTotal),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 2. Chọn slot nhận món
                    _buildSectionHeader('Thời gian nhận món'),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12.0),
                      child: Text(
                        'Chọn ngày và khung giờ bạn sẽ đến nhận món tại căn tin.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (availableDates.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Hiện không còn khung giờ nhận món trong 7 ngày tới.',
                          style: TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      )
                    else ...[
                      CanteenCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: availableDates.map((date) {
                                  final selected = DateUtils.isSameDay(
                                    checkoutVM.selectedPickupDate,
                                    date,
                                  );
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ChoiceChip(
                                      label: Text(
                                        DateUtils.isSameDay(
                                              date,
                                              DateTime.now(),
                                            )
                                            ? 'Hôm nay ${DateFormat('dd/MM').format(date)}'
                                            : 'Ngày ${DateFormat('dd/MM').format(date)}',
                                      ),
                                      selected: selected,
                                      onSelected: checkoutVM.isSubmitting
                                          ? null
                                          : (value) {
                                              if (value) {
                                                checkoutVM.selectPickupDate(
                                                  date,
                                                );
                                              }
                                            },
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            const Divider(height: 24),
                            if (availableSlots.isEmpty)
                              const Text(
                                'Ngày này không còn khung giờ trống.',
                                style: TextStyle(color: AppColors.error),
                              )
                            else
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: availableSlots.map((slot) {
                                  final selected =
                                      checkoutVM.selectedPickupAt == slot;
                                  return ChoiceChip(
                                    label: Text(
                                      DateFormat('HH:mm').format(slot),
                                    ),
                                    selected: selected,
                                    onSelected: checkoutVM.isSubmitting
                                        ? null
                                        : (value) {
                                            if (value) {
                                              checkoutVM.selectPickupAt(slot);
                                            }
                                          },
                                    selectedColor: AppColors.primary,
                                    labelStyle: TextStyle(
                                      color: selected
                                          ? Colors.white
                                          : AppColors.textPrimary,
                                      fontWeight: selected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                    backgroundColor: AppColors.surfaceVariant,
                                  );
                                }).toList(),
                              ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),

                    // 3. Phần nhập và chọn voucher
                    _buildSectionHeader('Khuyến mãi'),
                    CanteenCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: CanteenTextField(
                                  controller: _promoCodeController,
                                  labelText: 'Mã giảm giá',
                                  hintText: 'Nhập mã giảm giá',
                                  obscureText: false,
                                  prefixIcon: Icons.local_offer_outlined,
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                height: 52,
                                child: CanteenButton(
                                  text: 'Áp dụng',
                                  width: 110,
                                  isLoading: checkoutVM.isCheckingPromo,
                                  onPressed:
                                      (checkoutVM.isCheckingPromo ||
                                          checkoutVM.isSubmitting)
                                      ? null
                                      : () => _handleApplyPromoCode(checkoutVM),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: TextButton.icon(
                              onPressed: checkoutVM.isSubmitting
                                  ? null
                                  : () async {
                                      final selectedPromo =
                                          await Navigator.push<PromoModel>(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => VoucherScreen(
                                                subtotal: checkoutVM.subtotal,
                                                selectedPromoCode: checkoutVM
                                                    .appliedPromo
                                                    ?.code,
                                              ),
                                            ),
                                          );

                                      if (!mounted || selectedPromo == null) {
                                        return;
                                      }

                                      final validation = checkoutVM.applyPromo(
                                        selectedPromo,
                                      );
                                      _showMessage(
                                        validation.message,
                                        isError: !validation.isValid,
                                      );
                                    },
                              icon: const Icon(
                                Icons.confirmation_number_outlined,
                                size: 18,
                              ),
                              label: const Text('Xem các mã giảm giá hiện có'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          if (checkoutVM.appliedPromo != null) ...[
                            const Divider(height: 24),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.05),
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.3),
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.stars,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          checkoutVM.appliedPromo!.code,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Tiết kiệm: -${CurrencyFormatter.format(checkoutVM.discountAmount)}',
                                          style: const TextStyle(
                                            color: AppColors.primary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.cancel,
                                      color: AppColors.textSecondary,
                                    ),
                                    onPressed: checkoutVM.isSubmitting
                                        ? null
                                        : () => checkoutVM.removePromo(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 4. Ghi chú cho căn tin
                    _buildSectionHeader('Ghi chú đơn hàng (không bắt buộc)'),
                    CanteenCard(
                      padding: const EdgeInsets.all(12),
                      child: TextField(
                        controller: _noteController,
                        enabled: !checkoutVM.isSubmitting,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: 'Ví dụ: Ít cay, không lấy đũa, nhiều đá...',
                          hintStyle: TextStyle(color: AppColors.textHint, fontSize: 13),
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 5. Chọn phương thức thanh toán
                    _buildSectionHeader('Phương thức thanh toán'),
                    CanteenCard(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        children: [
                          RadioListTile<PaymentMethod>(
                            value: PaymentMethod.cash,
                            groupValue: checkoutVM.selectedPaymentMethod,
                            onChanged: checkoutVM.isSubmitting
                                ? null
                                : (value) {
                                    if (value != null) {
                                      checkoutVM.selectPaymentMethod(value);
                                    }
                                  },
                            activeColor: AppColors.primary,
                            title: const Text('Tiền mặt khi nhận món'),
                            subtitle: const Text(
                              'Thanh toán trực tiếp tại quầy.',
                            ),
                            secondary: const Icon(
                              Icons.payments_outlined,
                              color: AppColors.primary,
                            ),
                          ),
                          const Divider(height: 1, indent: 16, endIndent: 16),
                          RadioListTile<PaymentMethod>(
                            value: PaymentMethod.eWalletMock,
                            groupValue: checkoutVM.selectedPaymentMethod,
                            onChanged: checkoutVM.isSubmitting
                                ? null
                                : (value) {
                                    if (value != null) {
                                      checkoutVM.selectPaymentMethod(value);
                                    }
                                  },
                            activeColor: AppColors.primary,
                            title: const Text('Ví điện tử — Demo'),
                            subtitle: const Text(
                              'Mô phỏng thanh toán, không phát sinh giao dịch thật.',
                            ),
                            secondary: const Icon(
                              Icons.account_balance_wallet_outlined,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
              _buildCheckoutSummary(checkoutVM),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildCheckoutSummary(CheckoutViewModel checkoutVM) {
    return Container(
      padding: const EdgeInsets.all(16.0),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tạm tính:',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              Text(
                CurrencyFormatter.format(checkoutVM.subtotal),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Giảm giá:',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              Text(
                '-${CurrencyFormatter.format(checkoutVM.discountAmount)}',
                style: const TextStyle(
                  color: AppColors.success,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tổng thanh toán:',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                CurrencyFormatter.format(checkoutVM.finalTotal),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CanteenButton(
            text: 'XÁC NHẬN ĐẶT HÀNG',
            isLoading: checkoutVM.isSubmitting,
            onPressed: checkoutVM.canSubmit ? _handleSubmitOrder : null,
          ),
        ],
      ),
    );
  }
}
