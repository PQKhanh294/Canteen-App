import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:canteen_app/models/order_model.dart';
import 'package:canteen_app/core/enums/order_status.dart';
import 'package:canteen_app/core/enums/payment_method.dart';
import 'package:canteen_app/core/enums/payment_status.dart';
import 'package:canteen_app/viewmodels/order_viewmodel.dart';
import 'package:canteen_app/services/firestore_service.dart';

class FakeFirestoreService extends Fake implements FirestoreService {
  final StreamController<List<OrderModel>> _controller =
      StreamController<List<OrderModel>>.broadcast();

  void emit(List<OrderModel> orders) {
    _controller.add(orders);
  }

  @override
  Stream<List<OrderModel>> watchUserOrders(String userId) {
    return _controller.stream;
  }
}

void main() {
  test('OrderViewModel stats getters should calculate correctly', () async {
    final fakeService = FakeFirestoreService();
    final orderVM = OrderViewModel(firestoreService: fakeService);

    // Trạng thái ban đầu
    expect(orderVM.totalOrders, 0);
    expect(orderVM.totalCompletedSpending, 0.0);
    expect(orderVM.mostOrderedFoodName, null);

    // Bắt đầu lắng nghe
    orderVM.syncUser('test_user');

    // Chờ đăng ký lắng nghe stream hoàn tất (tránh cuộc đua bất đồng bộ do cancel() là async)
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final now = DateTime.now();
    final completedOrder = OrderModel(
      id: 'o1',
      displayCode: 'CF-111',
      userId: 'test_user',
      userName: 'Test User',
      userEmail: 'test@gmail.com',
      items: [
        OrderItemModel(
          foodId: 'f1',
          foodName: 'Cơm gà',
          imageUrl: '',
          unitPrice: 35000.0,
          quantity: 2,
        ),
        OrderItemModel(
          foodId: 'f2',
          foodName: 'Nước cam',
          imageUrl: '',
          unitPrice: 15000.0,
          quantity: 1,
        ),
      ],
      subtotal: 85000.0,
      discountAmount: 10000.0,
      finalTotal: 75000.0,
      pickupAt: now,
      paymentMethod: PaymentMethod.cash,
      paymentStatus: PaymentStatus.unpaid,
      status: OrderStatus.completed,
      statusTimestamps: const {},
    );

    final pendingOrder = OrderModel(
      id: 'o2',
      displayCode: 'CF-222',
      userId: 'test_user',
      userName: 'Test User',
      userEmail: 'test@gmail.com',
      items: [
        OrderItemModel(
          foodId: 'f2',
          foodName: 'Nước cam',
          imageUrl: '',
          unitPrice: 15000.0,
          quantity: 3,
        ),
      ],
      subtotal: 45000.0,
      discountAmount: 0.0,
      finalTotal: 45000.0,
      pickupAt: now,
      paymentMethod: PaymentMethod.cash,
      paymentStatus: PaymentStatus.unpaid,
      status: OrderStatus.pending,
      statusTimestamps: const {},
    );

    fakeService.emit([completedOrder, pendingOrder]);

    // Chờ luồng xử lý nhận và phát sự kiện
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(orderVM.totalOrders, 2);
    expect(orderVM.totalCompletedSpending, 75000.0);
    // Món được mua nhiều nhất trong các đơn hoàn thành là 'Cơm gà' (số lượng 2)
    expect(orderVM.mostOrderedFoodName, 'Cơm gà');

    orderVM.dispose();
  });
}
