import 'package:flutter_test/flutter_test.dart';
import 'package:canteen_app/models/food_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('FoodModel Serialization Tests', () {
    test('fromMap should parse correctly with double price', () {
      final map = {
        'name': 'Cơm Gà',
        'description': 'Ngon tuyệt',
        'price': 35000.0,
        'category': 'Cơm',
        'imageUrl': 'http://image.jpg',
        'available': true,
        'avgRating': 4.5,
        'totalReviews': 10,
        'createdAt': Timestamp.fromDate(DateTime(2026, 7, 15)),
      };
      final food = FoodModel.fromMap(map, 'food_id_123');

      expect(food.id, 'food_id_123');
      expect(food.name, 'Cơm Gà');
      expect(food.price, 35000.0);
      expect(food.available, true);
      expect(food.totalReviews, 10);
    });

    test('fromMap should parse correctly with int price and format legacy data', () {
      final map = {
        'name': 'Bún Bò',
        'description': 'Cay nồng',
        'price': 40000,
        'category': 'Bún',
        'imageUrl': '',
        'available': null, // Test fallback default
        'avgRating': 4, // Int rating
        'totalReviews': 0,
        'createdAt': null,
      };
      final food = FoodModel.fromMap(map, 'bun_bo_123');

      expect(food.price, 40000.0);
      expect(food.available, true); // Fallback to true
      expect(food.avgRating, 4.0);
    });

    test('toMap and fromMap should be consistent', () {
      final origin = FoodModel(
        id: '1',
        name: 'Món A',
        description: 'Mô tả',
        price: 25000.0,
        category: 'Tráng miệng',
        imageUrl: 'url',
        available: false,
        avgRating: 5.0,
        totalReviews: 2,
        createdAt: DateTime(2026, 7, 16),
      );

      final map = origin.toMap();
      final parsed = FoodModel.fromMap(map, '1');

      expect(parsed.name, origin.name);
      expect(parsed.price, origin.price);
      expect(parsed.available, origin.available);
      expect(parsed.avgRating, origin.avgRating);
    });
  });
}
