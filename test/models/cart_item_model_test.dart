import 'package:flutter_test/flutter_test.dart';
import 'package:canteen_app/models/cart_item_model.dart';
import 'package:canteen_app/models/food_model.dart';

void main() {
  group('CartItemModel Serialization and Logic Tests', () {
    final mockFood = FoodModel(
      id: 'food_1',
      name: 'Bánh Mì',
      description: 'Giòn ngon',
      price: 15000.0,
      category: 'Ăn vặt',
      imageUrl: 'http://banhmi.png',
      available: true,
      createdAt: DateTime.now(),
    );

    test('fromFood should initialize with default quantity 1', () {
      final cartItem = CartItemModel.fromFood(mockFood);

      expect(cartItem.foodId, 'food_1');
      expect(cartItem.foodName, 'Bánh Mì');
      expect(cartItem.unitPrice, 15000.0);
      expect(cartItem.quantity, 1);
      expect(cartItem.lineTotal, 15000.0);
      expect(cartItem.available, true);
    });

    test('lineTotal should scale with quantity', () {
      final cartItem = CartItemModel.fromFood(mockFood, quantity: 3);

      expect(cartItem.quantity, 3);
      expect(cartItem.lineTotal, 45000.0);
    });

    test('copyWith should clone and modify quantity/price safely', () {
      final original = CartItemModel.fromFood(mockFood);
      final updated = original.copyWith(quantity: 5, unitPrice: 16000.0);

      expect(updated.foodId, original.foodId);
      expect(updated.quantity, 5);
      expect(updated.unitPrice, 16000.0);
      expect(updated.lineTotal, 80000.0);
    });

    test('toMap and fromMap should round-trip correctly', () {
      final original = CartItemModel(
        foodId: 'food_2',
        foodName: 'Cà phê',
        imageUrl: 'http://coffee.jpg',
        unitPrice: 12000.0,
        quantity: 2,
        available: false,
      );

      final map = original.toMap();
      final parsed = CartItemModel.fromMap(map);

      expect(parsed.foodId, 'food_2');
      expect(parsed.foodName, 'Cà phê');
      expect(parsed.unitPrice, 12000.0);
      expect(parsed.quantity, 2);
      expect(parsed.lineTotal, 24000.0);
      expect(parsed.available, false);
    });
  });
}
