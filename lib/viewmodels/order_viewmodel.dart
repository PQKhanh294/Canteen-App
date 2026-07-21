import 'dart:async';
import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../core/enums/order_status.dart';
import '../services/firestore_service.dart';
import 'cart_viewmodel.dart';

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

  String? _cancellingOrderId;
  String? _reorderingOrderId;

  // Getters
  List<OrderModel> get orders => List<OrderModel>.unmodifiable(_orders);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get currentUserId => _currentUserId;
  bool get isEmpty => _orders.isEmpty;
  String? get cancellingOrderId => _cancellingOrderId;
  String? get reorderingOrderId => _reorderingOrderId;

  int get totalOrders => _orders.length;

  double get totalCompletedSpending {
    return _orders
        .where((order) => order.status == OrderStatus.completed)
        .fold(0.0, (total, order) => total + order.finalTotal);
  }

  String? get mostOrderedFoodName {
    final quantityByFoodId = <String, int>{};
    final foodNameById = <String, String>{};

    for (final order in _orders) {
      if (order.status != OrderStatus.completed) {
        continue;
      }

      for (final item in order.items) {
        quantityByFoodId.update(
          item.foodId,
          (quantity) => quantity + item.quantity,
          ifAbsent: () => item.quantity,
        );

        foodNameById[item.foodId] = item.foodName;
      }
    }

    if (quantityByFoodId.isEmpty) {
      return null;
    }

    final mostOrderedFoodId = quantityByFoodId.entries
        .reduce((first, second) => first.value >= second.value ? first : second)
        .key;

    return foodNameById[mostOrderedFoodId];
  }

  bool isCancellingOrder(String orderId) {
    return _cancellingOrderId == orderId;
  }

  bool isReorderingOrder(String orderId) {
    return _reorderingOrderId == orderId;
  }

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

  /// Thực hiện hủy đơn hàng sử dụng transaction trong Firestore
  Future<bool> cancelOrder({
    required String orderId,
    required String userId,
    required String reason,
  }) async {
    if (_cancellingOrderId != null) {
      return false;
    }

    _cancellingOrderId = orderId;
    _errorMessage = null;
    notifyListeners();

    try {
      await _firestoreService.cancelOrder(
        orderId: orderId,
        userId: userId,
        reason: reason,
      );
      return true;
    } catch (error, stackTrace) {
      debugPrint('Could not cancel order: $error\n$stackTrace');
      _errorMessage = _mapCancelError(error);
      return false;
    } finally {
      _cancellingOrderId = null;
      notifyListeners();
    }
  }

  String _mapCancelError(Object error) {
    final message = error.toString();

    if (message.contains('ORDER_NOT_FOUND')) {
      return 'Không tìm thấy đơn hàng.';
    }

    if (message.contains('ORDER_ACCESS_DENIED')) {
      return 'Bạn không có quyền hủy đơn hàng này.';
    }

    if (message.contains('CANCEL_REASON_REQUIRED')) {
      return 'Vui lòng chọn lý do hủy đơn.';
    }

    if (message.contains('ORDER_CANNOT_CANCEL')) {
      return 'Đơn hàng đã được căn tin xử lý và không thể hủy.';
    }

    return 'Không thể hủy đơn hàng. Vui lòng thử lại.';
  }

  /// Đặt lại đơn hàng cũ: lấy thông tin món hiện tại từ Firestore,
  /// bỏ qua món ngừng bán/hết hàng, dùng giá mới và gộp vào giỏ hàng.
  Future<ReorderResult> reorder({
    required OrderModel order,
    required CartViewModel cartViewModel,
  }) async {
    if (_reorderingOrderId != null) {
      return const ReorderResult(
        addedFoodCount: 0,
        addedQuantity: 0,
        deletedFoods: [],
        unavailableFoods: [],
        failedFoods: [],
      );
    }

    _reorderingOrderId = order.id;
    _errorMessage = null;
    notifyListeners();

    final deletedFoods = <String>[];
    final unavailableFoods = <String>[];
    final requests = <CartAddRequest>[];

    try {
      // Đọc thông tin món ăn song song để tối ưu hóa
      final results = await Future.wait(
        order.items.map((orderItem) async {
          final food = await _firestoreService.getFoodById(orderItem.foodId);
          return (orderItem: orderItem, food: food);
        }),
      );

      for (final result in results) {
        final orderItem = result.orderItem;
        final food = result.food;

        if (food == null) {
          deletedFoods.add(orderItem.foodName);
          continue;
        }

        if (!food.available) {
          unavailableFoods.add(food.name);
          continue;
        }

        requests.add(CartAddRequest(food: food, quantity: orderItem.quantity));
      }

      final batchResult = await cartViewModel.addItems(requests);

      final requestByFoodId = {
        for (final request in requests) request.food.id: request,
      };

      final failedFoods = batchResult.failedFoodIds
          .map((foodId) => requestByFoodId[foodId]?.food.name ?? foodId)
          .toList();

      final addedQuantity = batchResult.addedFoodIds.fold<int>(0, (
        total,
        foodId,
      ) {
        return total + (requestByFoodId[foodId]?.quantity ?? 0);
      });

      return ReorderResult(
        addedFoodCount: batchResult.addedFoodIds.length,
        addedQuantity: addedQuantity,
        deletedFoods: deletedFoods,
        unavailableFoods: unavailableFoods,
        failedFoods: failedFoods,
      );
    } catch (error, stackTrace) {
      debugPrint('Could not reorder: $error\n$stackTrace');
      _errorMessage = 'Không thể đặt lại đơn hàng. Vui lòng thử lại.';

      return ReorderResult(
        addedFoodCount: 0,
        addedQuantity: 0,
        deletedFoods: deletedFoods,
        unavailableFoods: unavailableFoods,
        failedFoods: order.items.map((item) => item.foodName).toList(),
      );
    } finally {
      _reorderingOrderId = null;
      notifyListeners();
    }
  }
}

class ReorderResult {
  const ReorderResult({
    required this.addedFoodCount,
    required this.addedQuantity,
    required this.deletedFoods,
    required this.unavailableFoods,
    required this.failedFoods,
  });

  final int addedFoodCount;
  final int addedQuantity;

  final List<String> deletedFoods;
  final List<String> unavailableFoods;
  final List<String> failedFoods;

  bool get hasAddedItems => addedFoodCount > 0;

  bool get hasSkippedItems {
    return deletedFoods.isNotEmpty ||
        unavailableFoods.isNotEmpty ||
        failedFoods.isNotEmpty;
  }
}
