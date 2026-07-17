import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/enums/cart_action_result.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/cart_item_model.dart';
import '../../models/promo_model.dart';
import '../../viewmodels/cart_viewmodel.dart';
import '../../widgets/canteen_button.dart';
import '../../widgets/canteen_card.dart';
import 'voucher_screen.dart';
import '../../viewmodels/checkout_viewmodel.dart';
import 'checkout_screen.dart';
import '../../services/firestore_service.dart';

// ============================================================
// VIEW: views/student/cart_screen.dart
// Owner: Member 3 — An
// Mô tả: Màn hình giỏ hàng của sinh viên, hỗ trợ sửa đổi số lượng
// ============================================================

class CartScreen extends StatefulWidget {
  final VoidCallback onExploreMenu;

  const CartScreen({super.key, required this.onExploreMenu});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final Set<String> _updatingFoodIds = <String>{};

  // Helper method to wrap async actions and prevent double clicks
  Future<void> _runItemAction(
    String foodId,
    Future<CartActionResult> Function() action,
  ) async {
    if (_updatingFoodIds.contains(foodId)) return;

    setState(() {
      _updatingFoodIds.add(foodId);
    });

    try {
      final result = await action();
      if (!mounted) return;

      if (result == CartActionResult.maximumQuantityReached) {
        _showSnackBar('Số lượng tối đa cho mỗi món là 99.', isError: true);
      } else if (result == CartActionResult.minimumQuantityReached) {
        _showSnackBar('Số lượng tối thiểu là 1.', isError: true);
      } else if (result == CartActionResult.persistenceFailed) {
        _showSnackBar(
          'Không thể cập nhật giỏ hàng. Vui lòng thử lại.',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _updatingFoodIds.remove(foodId);
        });
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
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

  // Confirmation dialog for deleting an item
  Future<bool> _showDeleteConfirmation(CartItemModel item) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Xóa món khỏi giỏ hàng?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Bạn có chắc muốn xóa "${item.foodName}" khỏi giỏ hàng?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Hủy',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  void _handleCheckout() {
    final cart = context.read<CartViewModel>();
    if (cart.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (routeContext) {
          return ChangeNotifierProvider(
            create: (_) {
              final checkoutViewModel = CheckoutViewModel(
                firestoreService: context.read<FirestoreService>(),
              );

              checkoutViewModel.updateSubtotal(
                context.read<CartViewModel>().subtotal.toInt(),
              );

              return checkoutViewModel;
            },
            child: const CheckoutScreen(),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartVM = context.watch<CartViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Giỏ Hàng',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Builder(
          builder: (context) {
            if (cartVM.isLoading && !cartVM.isInitialized) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            if (cartVM.errorMessage != null && cartVM.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      cartVM.errorMessage!,
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
                      onPressed: () =>
                          cartVM.initializeForUser(cartVM.currentUserId),
                    ),
                  ],
                ),
              );
            }

            if (cartVM.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.shopping_cart_outlined,
                          size: 72,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Giỏ hàng của bạn đang trống',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Hãy khám phá thực đơn và thêm những món bạn yêu thích.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      CanteenButton(
                        text: 'Khám phá thực đơn',
                        width: 200,
                        onPressed: widget.onExploreMenu,
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: cartVM.items.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = cartVM.items[index];
                      return _buildCartItemTile(item, cartVM);
                    },
                  ),
                ),
                _buildCheckoutSummary(cartVM),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCartItemTile(CartItemModel item, CartViewModel cartVM) {
    final isUpdating = _updatingFoodIds.contains(item.foodId);

    return Dismissible(
      key: ValueKey(item.foodId),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        final confirmed = await _showDeleteConfirmation(item);
        if (!confirmed) return false;

        bool deleteSuccess = false;
        await _runItemAction(item.foodId, () async {
          final res = await cartVM.removeItem(item.foodId);
          if (res == CartActionResult.success) {
            deleteSuccess = true;
          }
          return res;
        });

        return deleteSuccess;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Xóa',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.delete_outline, color: Colors.white),
          ],
        ),
      ),
      child: CanteenCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Ảnh món ăn
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: item.imageUrl.isNotEmpty
                    ? item.imageUrl
                    : 'https://via.placeholder.com/150',
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 80,
                  height: 80,
                  color: AppColors.surfaceVariant,
                  child: const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 80,
                  height: 80,
                  color: AppColors.surfaceVariant,
                  child: const Icon(Icons.fastfood, color: AppColors.textHint),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Tên, giá, nút tăng giảm
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.foodName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(
                          Icons.delete_outline,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        onPressed: isUpdating
                            ? null
                            : () async {
                                final confirmed = await _showDeleteConfirmation(
                                  item,
                                );
                                if (confirmed) {
                                  await _runItemAction(
                                    item.foodId,
                                    () => cartVM.removeItem(item.foodId),
                                  );
                                }
                              },
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.format(item.unitPrice),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Bộ tăng giảm số lượng
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              icon: const Icon(Icons.remove, size: 16),
                              onPressed: (item.quantity <= 1 || isUpdating)
                                  ? null
                                  : () => _runItemAction(
                                      item.foodId,
                                      () =>
                                          cartVM.decreaseQuantity(item.foodId),
                                    ),
                            ),
                            SizedBox(
                              width: 24,
                              child: isUpdating
                                  ? const Center(
                                      child: SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 1.5,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    )
                                  : Text(
                                      '${item.quantity}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                            ),
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              icon: const Icon(Icons.add, size: 16),
                              onPressed:
                                  (item.quantity >=
                                          CartViewModel.maxQuantityPerItem ||
                                      isUpdating)
                                  ? null
                                  : () => _runItemAction(
                                      item.foodId,
                                      () =>
                                          cartVM.increaseQuantity(item.foodId),
                                    ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(item.lineTotal),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          fontSize: 15,
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
    );
  }

  Widget _buildCheckoutSummary(CartViewModel cartVM) {
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
          // Xem mã giảm giá hiện có
          GestureDetector(
            onTap: () async {
              final selectedPromo = await Navigator.push<PromoModel>(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      VoucherScreen(subtotal: cartVM.subtotal.toInt()),
                ),
              );
              if (selectedPromo != null && mounted) {
                _showSnackBar(
                  'Đã chọn mã ${selectedPromo.code}. Mã sẽ được áp dụng ở bước thanh toán.',
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: 12.0,
                horizontal: 16.0,
              ),
              margin: const EdgeInsets.only(bottom: 16.0),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(
                        Icons.local_offer,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Xem mã giảm giá hiện có',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: AppColors.textSecondary,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tổng số lượng (${cartVM.totalQuantity} món):',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              Text(
                CurrencyFormatter.format(cartVM.subtotal),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CanteenButton(
            text: 'Tiến hành thanh toán',
            onPressed: cartVM.isEmpty ? null : _handleCheckout,
          ),
        ],
      ),
    );
  }
}
