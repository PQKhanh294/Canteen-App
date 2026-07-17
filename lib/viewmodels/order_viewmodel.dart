import 'dart:async';
import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../core/enums/order_status.dart';
import '../services/firestore_service.dart';

// ============================================================
// VIEWMODEL: OrderViewModel
// Owner: Member 3 — An
// Mô tả: Quản lý realtime stream danh sách đơn hàng của sinh viên
// ============================================================

class OrderViewModel extends ChangeNotifier {
  OrderViewModel({required FirestoreService firestoreService})
    : _firestoreService = firestoreService;

  final FirestoreService _firestoreService;

  List<OrderModel> _orders = <OrderModel>[];
  bool _isLoading = false;
  String? _errorMessage;

  String? _currentUserId;
  StreamSubscription<List<OrderModel>>? _subscription;

  // Getters
  List<OrderModel> get orders => List<OrderModel>.unmodifiable(_orders);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get currentUserId => _currentUserId;
  bool get isEmpty => _orders.isEmpty;

  // Trạng thái đơn hàng đang xử lý
  List<OrderModel> get processingOrders {
    return _orders
        .where(
          (order) =>
              order.status == OrderStatus.pending ||
              order.status == OrderStatus.confirmed ||
              order.status == OrderStatus.preparing ||
              order.status == OrderStatus.ready,
        )
        .toList(growable: false);
  }

  // Trạng thái đơn hàng hoàn thành
  List<OrderModel> get completedOrders {
    return _orders
        .where((order) => order.status == OrderStatus.completed)
        .toList(growable: false);
  }

  // Trạng thái đơn hàng đã hủy
  List<OrderModel> get cancelledOrders {
    return _orders
        .where((order) => order.status == OrderStatus.cancelled)
        .toList(growable: false);
  }

  // Đồng bộ hóa người dùng hiện tại từ AuthViewModel
  void syncUser(String? userId) {
    final normalizedUserId = userId?.trim();
    final nextUserId = (normalizedUserId == null || normalizedUserId.isEmpty)
        ? null
        : normalizedUserId;

    if (_currentUserId == nextUserId && _subscription != null) {
      return;
    }

    unawaited(listenUserOrders(nextUserId));
  }

  // Đăng ký lắng nghe realtime stream danh sách đơn hàng
  Future<void> listenUserOrders(String? userId) async {
    final normalizedUserId = userId?.trim();
    final nextUserId = (normalizedUserId == null || normalizedUserId.isEmpty)
        ? null
        : normalizedUserId;

    if (_currentUserId == nextUserId && _subscription != null) {
      return;
    }

    await _subscription?.cancel();
    _subscription = null;

    _currentUserId = nextUserId;
    _orders = <OrderModel>[];
    _errorMessage = null;

    if (nextUserId == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    _subscription = _firestoreService
        .watchUserOrders(nextUserId)
        .listen(
          (ordersList) {
            if (_currentUserId != nextUserId) {
              return;
            }
            _orders = ordersList;
            _isLoading = false;
            _errorMessage = null;
            notifyListeners();
          },
          onError: (Object error, StackTrace stackTrace) {
            if (_currentUserId != nextUserId) {
              return;
            }
            debugPrint('Could not load user orders: $error\n$stackTrace');
            _isLoading = false;
            _errorMessage = 'Không thể tải lịch sử đơn hàng.';
            notifyListeners();
          },
        );
  }

  // Tìm đơn hàng theo ID
  OrderModel? findOrder(String orderId) {
    final normalizedOrderId = orderId.trim();
    for (final order in _orders) {
      if (order.id == normalizedOrderId) {
        return order;
      }
    }
    return null;
  }

  // Thử lại khi gặp lỗi
  Future<void> retry() async {
    final userId = _currentUserId;
    if (userId == null) {
      return;
    }

    await _subscription?.cancel();
    _subscription = null;
    _currentUserId = null;

    await listenUserOrders(userId);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
