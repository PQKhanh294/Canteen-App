import 'package:flutter/material.dart';
import '../models/food_model.dart';
import '../models/order_model.dart';
import '../services/firestore_service.dart';

// ============================================================
// LIB: viewmodels/cart_viewmodel.dart
// Owner: Member 3 — An
// ============================================================

class CartViewModel extends ChangeNotifier {
  final FirestoreService _firestoreService;

  CartViewModel(this._firestoreService);

  final List<OrderItem> _items = [];
  String _pickupTime = '12:00';
  String _paymentMethod = 'cash';
  bool _isLoading = false;
  String? _error;

  List<OrderItem> get items => List.unmodifiable(_items);
  String get pickupTime => _pickupTime;
  String get paymentMethod => _paymentMethod;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  double get totalPrice =>
      _items.fold(0.0, (sum, item) => sum + item.subtotal);
  bool get isEmpty => _items.isEmpty;

  void addItem(FoodModel food) {
    final existingIndex =
        _items.indexWhere((item) => item.foodId == food.id);
    if (existingIndex >= 0) {
      _items[existingIndex].quantity++;
    } else {
      _items.add(OrderItem(
        foodId: food.id,
        foodName: food.name,
        price: food.price,
        quantity: 1,
      ));
    }
    notifyListeners();
  }

  void removeItem(String foodId) {
    _items.removeWhere((item) => item.foodId == foodId);
    notifyListeners();
  }

  void decreaseQuantity(String foodId) {
    final index = _items.indexWhere((item) => item.foodId == foodId);
    if (index >= 0) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  void setPickupTime(String time) {
    _pickupTime = time;
    notifyListeners();
  }

  void setPaymentMethod(String method) {
    _paymentMethod = method;
    notifyListeners();
  }

  Future<String?> checkout({
    required String userId,
    required String userName,
  }) async {
    if (_items.isEmpty) return null;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final order = OrderModel(
        id: '',
        userId: userId,
        userName: userName,
        items: List.from(_items),
        totalPrice: totalPrice,
        pickupTime: _pickupTime,
        paymentMethod: _paymentMethod,
        status: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final orderId = await _firestoreService.createOrder(order);
      clearCart();
      return orderId;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    _pickupTime = '12:00';
    _paymentMethod = 'cash';
    notifyListeners();
  }
}
