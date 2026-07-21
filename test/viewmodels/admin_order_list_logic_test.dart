import 'package:canteen_app/core/enums/order_status.dart';
import 'package:canteen_app/core/enums/payment_method.dart';
import 'package:canteen_app/core/enums/payment_status.dart';
import 'package:canteen_app/models/order_model.dart';
import 'package:canteen_app/viewmodels/admin_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdminOrderListLogic', () {
    final orders = [
      _order('pending-1', OrderStatus.pending),
      _order('pending-2', OrderStatus.pending),
      _order('ready-1', OrderStatus.ready),
      _order('cancelled-1', OrderStatus.cancelled),
      _order('unknown-1', OrderStatus.unknown),
    ];

    test('counts every supported status from the source list', () {
      final counts = AdminOrderListLogic.countByStatus(orders);

      expect(counts[OrderStatus.pending], 2);
      expect(counts[OrderStatus.ready], 1);
      expect(counts[OrderStatus.cancelled], 1);
      expect(counts[OrderStatus.completed], 0);
      expect(counts.containsKey(OrderStatus.unknown), isFalse);
    });

    test('returns all orders when no filter is selected', () {
      final result = AdminOrderListLogic.filterByStatus(orders, null);

      expect(result, hasLength(orders.length));
      expect(result.map((order) => order.id), orders.map((order) => order.id));
    });

    test('filters cancelled orders without mutating the source list', () {
      final originalIds = orders.map((order) => order.id).toList();
      final result = AdminOrderListLogic.filterByStatus(
        orders,
        OrderStatus.cancelled,
      );

      expect(result.map((order) => order.id), ['cancelled-1']);
      expect(orders.map((order) => order.id), originalIds);
    });

    test('returns an empty list for a status without orders', () {
      final result = AdminOrderListLogic.filterByStatus(
        orders,
        OrderStatus.completed,
      );

      expect(result, isEmpty);
    });
  });
}

OrderModel _order(String id, OrderStatus status) {
  final timestamp = DateTime(2026, 7, 21, 10);
  return OrderModel(
    id: id,
    displayCode: id,
    userId: 'student-1',
    userName: 'Student',
    userEmail: 'student@example.com',
    items: const [],
    subtotal: 10000,
    discountAmount: 0,
    finalTotal: 10000,
    pickupAt: timestamp,
    paymentMethod: PaymentMethod.cash,
    paymentStatus: PaymentStatus.unpaid,
    status: status,
    createdAt: timestamp,
    statusTimestamps: const {},
  );
}
