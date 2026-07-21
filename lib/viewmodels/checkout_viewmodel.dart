import 'dart:async';
import 'package:flutter/material.dart';
import '../core/enums/payment_method.dart';
import '../core/utils/pickup_schedule.dart';
import '../core/utils/promo_calculator.dart';
import '../models/cart_item_model.dart';
import '../models/promo_model.dart';
import '../services/firestore_service.dart';

// ============================================================
// VIEWMODEL: CheckoutViewModel
// Owner: Member 3 — An
// Mô tả: Quản lý trạng thái và nghiệp vụ thanh toán (Checkout)
// ============================================================

class CheckoutResult {
  const CheckoutResult({
    required this.orderId,
    required this.displayCode,
    required this.subtotal,
    required this.discountAmount,
    required this.finalTotal,
    required this.pickupAt,
  });

  final String orderId;
  final String displayCode;
  final int subtotal;
  final int discountAmount;
  final int finalTotal;
  final DateTime pickupAt;
}

class CheckoutViewModel extends ChangeNotifier {
  CheckoutViewModel({
    required FirestoreService firestoreService,
    DateTime? initialTime,
  }) : _firestoreService = firestoreService,
       _selectedPickupDate = _initialPickupDate(initialTime ?? DateTime.now());

  final FirestoreService _firestoreService;

  int _subtotal = 0;
  int _discountAmount = 0;

  DateTime _selectedPickupDate;
  DateTime? _selectedPickupAt;
  PaymentMethod? _selectedPaymentMethod;
  PromoModel? _appliedPromo;

  bool _isCheckingPromo = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  // Getters
  int get subtotal => _subtotal;
  int get discountAmount => _discountAmount;
  int get finalTotal {
    final total = _subtotal - _discountAmount;
    return total < 0 ? 0 : total;
  }

  DateTime get selectedPickupDate => _selectedPickupDate;
  DateTime? get selectedPickupAt => _selectedPickupAt;
  PaymentMethod? get selectedPaymentMethod => _selectedPaymentMethod;
  PromoModel? get appliedPromo => _appliedPromo;
  bool get isCheckingPromo => _isCheckingPromo;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  bool get hasPromo => _appliedPromo != null;

  bool get canSubmit {
    return _subtotal > 0 &&
        _selectedPickupAt != null &&
        PickupSchedule.isValidPickupAt(_selectedPickupAt!) &&
        _selectedPaymentMethod != null &&
        !_isSubmitting;
  }

  // Update subtotal from cart and validate coupon
  void updateSubtotal(int value) {
    final safeValue = value < 0 ? 0 : value;

    if (_subtotal == safeValue) {
      return;
    }

    _subtotal = safeValue;
    _recalculateAppliedPromo();
    notifyListeners();
  }

  void _recalculateAppliedPromo() {
    final promo = _appliedPromo;

    if (promo == null) {
      _discountAmount = 0;
      return;
    }

    final validation = PromoCalculator.validate(
      promo: promo,
      subtotal: _subtotal,
    );

    if (!validation.isValid) {
      _appliedPromo = null;
      _discountAmount = 0;
      _errorMessage = validation.message;
      return;
    }

    _discountAmount = PromoCalculator.calculateDiscount(
      promo: promo,
      subtotal: _subtotal,
    );
  }

  List<DateTime> getAvailablePickupDates({DateTime? currentTime}) {
    final now = currentTime ?? DateTime.now();
    return PickupSchedule.availableDates(currentTime: now);
  }

  List<DateTime> getAvailablePickupSlots({
    DateTime? currentTime,
    DateTime? date,
  }) {
    final now = currentTime ?? DateTime.now();
    return PickupSchedule.slotsForDate(
      date ?? _selectedPickupDate,
      currentTime: now,
    );
  }

  void selectPickupDate(DateTime date, {DateTime? currentTime}) {
    final now = currentTime ?? DateTime.now();
    final normalizedDate = PickupSchedule.dateOnly(date);
    final slots = PickupSchedule.slotsForDate(normalizedDate, currentTime: now);
    if (slots.isEmpty) {
      _errorMessage = 'Ngày đã chọn không còn khung giờ nhận món.';
      notifyListeners();
      return;
    }

    _selectedPickupDate = normalizedDate;
    _selectedPickupAt = null;
    _errorMessage = null;
    notifyListeners();
  }

  void selectPickupAt(DateTime pickupAt, {DateTime? currentTime}) {
    final now = currentTime ?? DateTime.now();
    if (!PickupSchedule.isValidPickupAt(pickupAt, currentTime: now)) {
      _errorMessage = 'Khung giờ nhận món không hợp lệ hoặc đã quá hạn.';
      notifyListeners();
      return;
    }

    _selectedPickupDate = PickupSchedule.dateOnly(pickupAt);
    _selectedPickupAt = pickupAt;
    _errorMessage = null;
    notifyListeners();
  }

  void clearPickupSelection() {
    _selectedPickupAt = null;
    notifyListeners();
  }

  void selectPaymentMethod(PaymentMethod method) {
    _selectedPaymentMethod = method;
    _errorMessage = null;
    notifyListeners();
  }

  PromoValidationResult applyPromo(PromoModel promo) {
    final validation = PromoCalculator.validate(
      promo: promo,
      subtotal: _subtotal,
    );

    if (!validation.isValid) {
      _appliedPromo = null;
      _discountAmount = 0;
      _errorMessage = validation.message;
      notifyListeners();
      return validation;
    }

    _appliedPromo = promo;
    _discountAmount = PromoCalculator.calculateDiscount(
      promo: promo,
      subtotal: _subtotal,
    );

    _errorMessage = null;
    notifyListeners();

    return validation;
  }

  void removePromo() {
    _appliedPromo = null;
    _discountAmount = 0;
    _errorMessage = null;
    notifyListeners();
  }

  Future<PromoValidationResult?> applyPromoCode(String code) async {
    final normalizedCode = code.trim().toUpperCase();

    if (normalizedCode.isEmpty) {
      _errorMessage = 'Vui lòng nhập mã giảm giá.';
      notifyListeners();
      return null;
    }

    if (_isCheckingPromo) {
      return null;
    }

    _isCheckingPromo = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final promo = await _firestoreService.getPromoByCode(normalizedCode);

      if (promo == null) {
        _errorMessage = 'Mã giảm giá không tồn tại.';
        return null;
      }

      return applyPromo(promo);
    } catch (error, stackTrace) {
      debugPrint('Could not apply promo: $error\n$stackTrace');
      _errorMessage = 'Không thể kiểm tra mã giảm giá. Vui lòng thử lại.';
      return null;
    } finally {
      _isCheckingPromo = false;
      notifyListeners();
    }
  }

  // Submit order in transaction
  Future<CheckoutResult?> submitOrder({
    required String userId,
    required String userName,
    required String userEmail,
    required List<CartItemModel> cartItems,
  }) async {
    if (_isSubmitting) {
      return null;
    }

    final validationMessage = _validateBeforeSubmit(
      userId: userId,
      cartItems: cartItems,
    );

    if (validationMessage != null) {
      _errorMessage = validationMessage;
      notifyListeners();
      return null;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _firestoreService.createOrderFromCheckout(
        userId: userId,
        userName: userName,
        userEmail: userEmail,
        cartItems: cartItems,
        pickupAt: _selectedPickupAt!,
        paymentMethod: _selectedPaymentMethod!,
        promo: _appliedPromo,
      );

      return result;
    } catch (error, stackTrace) {
      debugPrint('Could not submit order: $error\n$stackTrace');
      _errorMessage = _mapCheckoutError(error);
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  String? _validateBeforeSubmit({
    required String userId,
    required List<CartItemModel> cartItems,
  }) {
    if (userId.trim().isEmpty) {
      return 'Không xác định được người dùng hiện tại.';
    }

    if (cartItems.isEmpty) {
      return 'Giỏ hàng đang trống.';
    }

    final pickupAt = _selectedPickupAt;

    if (pickupAt == null) {
      return 'Vui lòng chọn giờ nhận món.';
    }

    if (!PickupSchedule.isValidPickupAt(pickupAt)) {
      return 'Khung giờ nhận món không hợp lệ hoặc đã quá hạn.';
    }

    if (_selectedPaymentMethod == null) {
      return 'Vui lòng chọn phương thức thanh toán.';
    }

    return null;
  }

  String _mapCheckoutError(Object error) {
    final message = error.toString();

    if (message.contains('FOOD_NOT_FOUND:')) {
      final foodName = message.split(':').last;
      return 'Món “$foodName” không còn tồn tại.';
    }

    if (message.contains('FOOD_UNAVAILABLE:')) {
      final foodName = message.split(':').last;
      return 'Món “$foodName” hiện đã hết hàng.';
    }

    if (message.contains('INVALID_QUANTITY:')) {
      return 'Số lượng món ăn không hợp lệ.';
    }

    if (message.contains('PROMO_NOT_FOUND')) {
      return 'Mã giảm giá không còn tồn tại.';
    }

    if (message.contains('PROMO_INVALID:')) {
      return message.split('PROMO_INVALID:').last;
    }

    if (message.contains('INVALID_PICKUP_SLOT')) {
      return 'Khung giờ nhận món không hợp lệ hoặc đã quá hạn.';
    }

    if (message.contains('PICKUP_SLOT_FULL')) {
      return 'Khung giờ này đã đủ số lượng đơn. Vui lòng chọn giờ khác.';
    }

    return 'Không thể tạo đơn hàng. Vui lòng thử lại.';
  }

  static DateTime _initialPickupDate(DateTime now) {
    final dates = PickupSchedule.availableDates(currentTime: now);
    if (dates.isNotEmpty) return dates.first;
    return PickupSchedule.dateOnly(now.add(const Duration(days: 1)));
  }
}
