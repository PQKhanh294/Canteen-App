import 'package:flutter_test/flutter_test.dart';
import 'package:canteen_app/models/order_model.dart';
import 'package:canteen_app/core/enums/order_status.dart';
import 'package:canteen_app/core/enums/payment_method.dart';
import 'package:canteen_app/core/enums/payment_status.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('OrderModel Serialization Tests', () {
    test('fromMap should parse detailed order structures safely', () {
      final map = {
        'displayCode': 'CF-260716-1A',
        'userId': 'uid_1',
        'userName': 'John Doe',
        'userEmail': 'john@gmail.com',
        'items': [
          {
            'foodId': 'food_1',
            'foodName': 'Cơm gà',
            'imageUrl': 'http://img.png',
            'unitPrice': 35000.0,
            'quantity': 2,
            'lineTotal': 70000.0,
          }
        ],
        'subtotal': 70000.0,
        'discountAmount': 7000.0,
        'finalTotal': 63000.0,
        'promoId': 'promo_1',
        'promoCode': 'PROMO10',
        'pickupAt': Timestamp.fromDate(DateTime(2026, 7, 16, 12, 0)),
        'paymentMethod': 'cash',
        'paymentStatus': 'unpaid',
        'status': 'pending',
        'counterNumber': '2',
        'cancelReason': null,
        'createdAt': Timestamp.fromDate(DateTime(2026, 7, 16, 11, 45)),
        'updatedAt': Timestamp.fromDate(DateTime(2026, 7, 16, 11, 46)),
        'statusTimestamps': {
          'pending': Timestamp.fromDate(DateTime(2026, 7, 16, 11, 45)),
        },
      };

      final order = OrderModel.fromMap(map, 'order_id_abc');

      expect(order.id, 'order_id_abc');
      expect(order.displayCode, 'CF-260716-1A');
      expect(order.totalPrice, 63000.0);
      expect(order.status, OrderStatus.pending);
      expect(order.paymentMethod, PaymentMethod.cash);
      expect(order.paymentStatus, PaymentStatus.unpaid);
      expect(order.items.length, 1);
      expect(order.items.first.foodName, 'Cơm gà');
      expect(order.items.first.price, 35000.0);
      expect(order.totalQuantity, 2);
      expect(order.canCancel, true);
      expect(order.canReview, false);
      expect(order.statusTimestamps.containsKey('pending'), true);
    });

    test('fromMap should parse legacy order structure compatible with double/int mix', () {
      final map = {
        'userId': 'uid_2',
        'userName': 'Smith',
        'totalPrice': 45000, // Legacy field and int type
        'pickupTime': '11:30', // Legacy pickupTime string
        'status': 'preparing',
        'paymentMethod': 'e_wallet_mock',
      };

      final order = OrderModel.fromMap(map, 'order_id_legacy');

      expect(order.userId, 'uid_2');
      expect(order.finalTotal, 45000.0); // mapped correctly to finalTotal
      expect(order.paymentMethod, PaymentMethod.eWalletMock);
      expect(order.status, OrderStatus.preparing);
      expect(order.pickupAt.hour, 11);
      expect(order.pickupAt.minute, 30);
    });

    test('toMap and fromMap should round-trip cleanly', () {
      final original = OrderModel(
        id: 'id_1',
        displayCode: 'DISPLAY_1',
        userId: 'user_1',
        userName: 'User One',
        userEmail: 'user1@gmail.com',
        items: [
          OrderItemModel(
            foodId: 'food_1',
            foodName: 'Nước',
            imageUrl: 'img_url',
            unitPrice: 10000.0,
            quantity: 1,
          )
        ],
        subtotal: 10000.0,
        discountAmount: 1000.0,
        finalTotal: 9000.0,
        pickupAt: DateTime(2026, 7, 16, 17, 30),
        paymentMethod: PaymentMethod.cash,
        paymentStatus: PaymentStatus.unpaid,
        status: OrderStatus.confirmed,
        statusTimestamps: {
          'pending': DateTime(2026, 7, 16, 17, 0),
          'confirmed': DateTime(2026, 7, 16, 17, 5),
        },
      );

      final map = original.toMap();
      final parsed = OrderModel.fromMap(map, 'id_1');

      expect(parsed.displayCode, original.displayCode);
      expect(parsed.finalTotal, original.finalTotal);
      expect(parsed.status, original.status);
      expect(parsed.paymentMethod, original.paymentMethod);
      expect(parsed.pickupAt, original.pickupAt);
      expect(parsed.statusTimestamps.length, 2);
    });

    test('statusTime should return correct timestamp for matching status', () {
      final now = DateTime.now();
      final order = OrderModel(
        id: 'id_test',
        displayCode: 'CF-123',
        userId: 'user_1',
        userName: 'User One',
        userEmail: 'user_one@gmail.com',
        items: const [],
        subtotal: 0.0,
        discountAmount: 0.0,
        finalTotal: 0.0,
        pickupAt: now,
        paymentMethod: PaymentMethod.cash,
        paymentStatus: PaymentStatus.unpaid,
        status: OrderStatus.pending,
        statusTimestamps: {
          'pending': now,
        },
      );

      expect(order.statusTime(OrderStatus.pending), now);
      expect(order.statusTime(OrderStatus.cancelled), null);
    });
  });
}
