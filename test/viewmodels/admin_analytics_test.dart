import 'package:canteen_app/core/enums/order_status.dart';
import 'package:canteen_app/core/enums/payment_method.dart';
import 'package:canteen_app/core/enums/payment_status.dart';
import 'package:canteen_app/models/order_model.dart';
import 'package:canteen_app/viewmodels/admin_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdminAnalytics', () {
    test('averagePerDay includes days without completed orders', () {
      final order = OrderModel(
        id: 'order-1',
        displayCode: 'CF-001',
        userId: 'student-1',
        userName: 'Student',
        userEmail: 'student@example.com',
        items: const [],
        subtotal: 140000,
        discountAmount: 0,
        finalTotal: 140000,
        pickupAt: DateTime(2026, 7, 21, 12),
        paymentMethod: PaymentMethod.cash,
        paymentStatus: PaymentStatus.mockPaid,
        status: OrderStatus.completed,
        createdAt: DateTime(2026, 7, 21, 10),
        statusTimestamps: {
          OrderStatus.completed.value: DateTime(2026, 7, 21, 12),
        },
      );
      final analytics = AdminAnalytics(
        orders: [order],
        revenueByDay: {DateTime(2026, 7, 21): 140000},
        ordersByHour: const {12: 1},
        topFoods: const [],
        dayCount: 7,
      );

      expect(analytics.revenue, 140000);
      expect(analytics.averagePerDay, 20000);
    });

    test('averagePerDay safely handles an empty date range', () {
      const analytics = AdminAnalytics(
        orders: [],
        revenueByDay: {},
        ordersByHour: {},
        topFoods: [],
        dayCount: 0,
      );

      expect(analytics.averagePerDay, 0);
    });
  });
}
