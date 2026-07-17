import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/food_model.dart';
import '../models/cart_item_model.dart';
import '../models/order_model.dart';
import '../services/cart_storage_service.dart';
import '../services/firestore_service.dart';
import '../core/enums/order_status.dart';
import '../core/enums/payment_method.dart';
import '../core/enums/payment_status.dart';
import '../core/enums/cart_action_result.dart';

// ============================================================
// VIEWMODEL: CartViewModel
// Owner: Member 3 — An
// Mô tả: Quản lý trạng thái giỏ hàng và lưu trữ local của sinh viên
// ============================================================

class CartViewModel extends ChangeNotifier {
  final CartStorageService _storageService;
  final FirestoreService _firestoreService;

  CartViewModel({
    required CartStorageService storageService,
    required FirestoreService firestoreService,
  })  : _storageService = storageService,
        _firestoreService = firestoreService;

  static const int maxQuantityPerItem = 99;

  List<CartItemModel> _items = <CartItemModel>[];
  String? _currentUserId;

  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;
  int _initializationToken = 0;

  String _pickupTime = '12:00';
  String _paymentMethod = 'cash';

  // Getters
  List<CartItemModel> get items => List<CartItemModel>.unmodifiable(_items);
  String? get currentUserId => _currentUserId;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;
  String? get errorMessage => _error; // Alias
  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;

  String get pickupTime => _pickupTime;
  String get paymentMethod => _paymentMethod;

  int get totalQuantity {
    return _items.fold(0, (total, item) => total + item.quantity);
  }

  double get subtotal {
    return _items.fold(0.0, (total, item) => total + item.lineTotal);
  }

  // Compatibility aliases for Module 1
  int get itemCount => totalQuantity;
  double get totalPrice => subtotal;

  // Setters for order parameters
  void setPickupTime(String time) {
    _pickupTime = time;
    notifyListeners();
  }

  void setPaymentMethod(String method) {
    _paymentMethod = method;
    notifyListeners();
  }

  // User synchronization for ProxyProvider
  void syncUser(String? userId) {
    final normalizedUserId = userId?.trim();
    final nextUserId = normalizedUserId == null || normalizedUserId.isEmpty
        ? null
        : normalizedUserId;

    if (_currentUserId == nextUserId && (_isInitialized || _isLoading)) {
      return;
    }

    unawaited(initializeForUser(nextUserId));
  }

  // Initialize and load cart from storage
  Future<void> initializeForUser(String? userId) async {
    final normalizedUserId = userId?.trim();
    final nextUserId = normalizedUserId == null || normalizedUserId.isEmpty
        ? null
        : normalizedUserId;

    if (_currentUserId == nextUserId && (_isInitialized || _isLoading)) {
      return;
    }

    final currentToken = ++_initializationToken;

    // Reset current state immediately to avoid data leakage
    _currentUserId = nextUserId;
    _items = <CartItemModel>[];
    _error = null;
    _isInitialized = false;

    if (nextUserId == null) {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final loadedItems = await _storageService.loadCart(nextUserId);

      // Verify that user hasn't changed during load operation
      if (currentToken != _initializationToken || _currentUserId != nextUserId) {
        return;
      }

      _items = _sanitizeItems(loadedItems);
      _isInitialized = true;
    } catch (e, stackTrace) {
      if (currentToken != _initializationToken || _currentUserId != nextUserId) {
        return;
      }

      debugPrint('Could not initialize cart: $e\n$stackTrace');
      _items = <CartItemModel>[];
      _error = 'Không thể khôi phục giỏ hàng.';
      _isInitialized = true;
    } finally {
      if (currentToken == _initializationToken && _currentUserId == nextUserId) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  // Sanitize and deduplicate items from storage
  List<CartItemModel> _sanitizeItems(List<CartItemModel> loadedItems) {
    final itemsByFoodId = <String, CartItemModel>{};

    for (final item in loadedItems) {
      final foodId = item.foodId.trim();

      if (foodId.isEmpty || item.unitPrice < 0) {
        continue;
      }

      final safeQuantity = item.quantity.clamp(1, maxQuantityPerItem).toInt();
      final existing = itemsByFoodId[foodId];

      if (existing == null) {
        itemsByFoodId[foodId] = item.copyWith(
          foodId: foodId,
          quantity: safeQuantity,
        );
        continue;
      }

      final mergedQuantity = (existing.quantity + safeQuantity)
          .clamp(1, maxQuantityPerItem)
          .toInt();

      itemsByFoodId[foodId] = item.copyWith(quantity: mergedQuantity);
    }

    return itemsByFoodId.values.toList();
  }

  // Persistence helper
  Future<bool> _saveAndApply(List<CartItemModel> nextItems) async {
    final userId = _currentUserId;

    if (userId == null || !_isInitialized) {
      _error = 'Giỏ hàng chưa sẵn sàng.';
      notifyListeners();
      return false;
    }

    try {
      await _storageService.saveCart(userId, nextItems);
      _items = List<CartItemModel>.from(nextItems);
      _error = null;
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      debugPrint('Could not save cart: $e\n$stackTrace');
      _error = 'Không thể lưu thay đổi giỏ hàng.';
      notifyListeners();
      return false;
    }
  }

  // Add Item to Cart
  Future<CartActionResult> addItem(FoodModel food, {int quantity = 1}) async {
    if (!_isInitialized || _currentUserId == null) {
      return CartActionResult.notInitialized;
    }

    if (food.id.trim().isEmpty || food.price < 0) {
      return CartActionResult.invalidItem;
    }

    if (!food.available) {
      return CartActionResult.unavailable;
    }

    if (quantity < 1 || quantity > maxQuantityPerItem) {
      return CartActionResult.invalidQuantity;
    }

    final index = _items.indexWhere((item) => item.foodId == food.id);
    final nextItems = List<CartItemModel>.from(_items);

    if (index == -1) {
      nextItems.add(CartItemModel(
        foodId: food.id,
        foodName: food.name,
        imageUrl: food.imageUrl,
        unitPrice: food.price,
        quantity: quantity,
        available: food.available,
      ));

      final saved = await _saveAndApply(nextItems);
      return saved ? CartActionResult.success : CartActionResult.persistenceFailed;
    }

    final currentItem = nextItems[index];
    final nextQuantity = currentItem.quantity + quantity;

    if (nextQuantity > maxQuantityPerItem) {
      return CartActionResult.maximumQuantityReached;
    }

    nextItems[index] = currentItem.copyWith(
      foodName: food.name,
      imageUrl: food.imageUrl,
      unitPrice: food.price,
      quantity: nextQuantity,
      available: food.available,
    );

    final saved = await _saveAndApply(nextItems);
    return saved ? CartActionResult.success : CartActionResult.persistenceFailed;
  }

  // Wrapper for Module 2 compatibility
  Future<CartActionResult> addToCart(FoodModel food, {int quantity = 1}) {
    return addItem(food, quantity: quantity);
  }

  // Remove Item
  Future<CartActionResult> removeItem(String foodId) async {
    final normalizedFoodId = foodId.trim();

    if (normalizedFoodId.isEmpty) {
      return CartActionResult.invalidItem;
    }

    if (!contains(normalizedFoodId)) {
      return CartActionResult.itemNotFound;
    }

    final nextItems = _items.where((item) => item.foodId != normalizedFoodId).toList();
    final saved = await _saveAndApply(nextItems);

    return saved ? CartActionResult.success : CartActionResult.persistenceFailed;
  }

  // Increase quantity
  Future<CartActionResult> increaseQuantity(String foodId) async {
    final index = _items.indexWhere((item) => item.foodId == foodId);
    if (index == -1) {
      return CartActionResult.itemNotFound;
    }

    final currentItem = _items[index];
    if (currentItem.quantity >= maxQuantityPerItem) {
      return CartActionResult.maximumQuantityReached;
    }

    return updateQuantity(foodId, currentItem.quantity + 1);
  }

  // Decrease quantity
  Future<CartActionResult> decreaseQuantity(String foodId) async {
    final index = _items.indexWhere((item) => item.foodId == foodId);
    if (index == -1) {
      return CartActionResult.itemNotFound;
    }

    final currentItem = _items[index];
    if (currentItem.quantity <= 1) {
      return CartActionResult.minimumQuantityReached;
    }

    return updateQuantity(foodId, currentItem.quantity - 1);
  }

  // Update quantity
  Future<CartActionResult> updateQuantity(String foodId, int quantity) async {
    if (quantity < 1) {
      return CartActionResult.invalidQuantity;
    }

    if (quantity > maxQuantityPerItem) {
      return CartActionResult.maximumQuantityReached;
    }

    final index = _items.indexWhere((item) => item.foodId == foodId);
    if (index == -1) {
      return CartActionResult.itemNotFound;
    }

    if (_items[index].quantity == quantity) {
      return CartActionResult.success;
    }

    final nextItems = List<CartItemModel>.from(_items);
    nextItems[index] = nextItems[index].copyWith(quantity: quantity);

    final saved = await _saveAndApply(nextItems);
    return saved ? CartActionResult.success : CartActionResult.persistenceFailed;
  }

  // Clear Cart
  Future<CartActionResult> clearCart() async {
    final userId = _currentUserId;

    if (userId == null || !_isInitialized) {
      return CartActionResult.notInitialized;
    }

    try {
      await _storageService.clearCart(userId);
      _items = <CartItemModel>[];
      _error = null;
      notifyListeners();
      return CartActionResult.success;
    } catch (e, stackTrace) {
      debugPrint('Could not clear cart: $e\n$stackTrace');
      _error = 'Không thể xóa giỏ hàng.';
      notifyListeners();
      return CartActionResult.persistenceFailed;
    }
  }

  bool contains(String foodId) {
    final normalizedFoodId = foodId.trim();
    return _items.any((item) => item.foodId == normalizedFoodId);
  }

  CartItemModel? findItem(String foodId) {
    final normalizedFoodId = foodId.trim();
    for (final item in _items) {
      if (item.foodId == normalizedFoodId) {
        return item;
      }
    }
    return null;
  }

  // Checkout (Legacy compatibility/placeholder logic)
  Future<String?> checkout({
    required String userId,
    required String userName,
  }) async {
    if (_items.isEmpty) return null;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final timeParts = _pickupTime.split(':');
      final now = DateTime.now();
      final hour = timeParts.isNotEmpty ? (int.tryParse(timeParts[0]) ?? 12) : 12;
      final minute = timeParts.length > 1 ? (int.tryParse(timeParts[1]) ?? 0) : 0;
      final pickupAt = DateTime(now.year, now.month, now.day, hour, minute);

      final order = OrderModel(
        id: '',
        displayCode: '',
        userId: userId,
        userName: userName,
        userEmail: '',
        items: _items.map((item) => OrderItemModel(
          foodId: item.foodId,
          foodName: item.foodName,
          imageUrl: item.imageUrl,
          unitPrice: item.unitPrice,
          quantity: item.quantity,
        )).toList(),
        subtotal: totalPrice,
        discountAmount: 0.0,
        finalTotal: totalPrice,
        pickupAt: pickupAt,
        paymentMethod: PaymentMethod.fromValue(_paymentMethod),
        paymentStatus: PaymentStatus.unpaid,
        status: OrderStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        statusTimestamps: {'pending': DateTime.now()},
      );
      final orderId = await _firestoreService.createOrder(order);
      await clearCart();
      return orderId;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
