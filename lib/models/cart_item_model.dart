import 'food_model.dart';
import '../core/utils/model_parsers.dart';

class CartItemModel {
  final String foodId;
  final String foodName;
  final String imageUrl;
  final double unitPrice;
  final int quantity;
  final bool available;

  const CartItemModel({
    required this.foodId,
    required this.foodName,
    required this.imageUrl,
    required this.unitPrice,
    required this.quantity,
    required this.available,
  });

  double get lineTotal => unitPrice * quantity;

  factory CartItemModel.fromFood(FoodModel food, {int quantity = 1}) {
    return CartItemModel(
      foodId: food.id,
      foodName: food.name,
      imageUrl: food.imageUrl,
      unitPrice: food.price,
      quantity: quantity,
      available: food.available,
    );
  }

  CartItemModel copyWith({
    String? foodId,
    String? foodName,
    String? imageUrl,
    double? unitPrice,
    int? quantity,
    bool? available,
  }) {
    return CartItemModel(
      foodId: foodId ?? this.foodId,
      foodName: foodName ?? this.foodName,
      imageUrl: imageUrl ?? this.imageUrl,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      available: available ?? this.available,
    );
  }

  factory CartItemModel.fromMap(Map<String, dynamic> map) {
    return CartItemModel(
      foodId: map['foodId'] as String? ?? '',
      foodName: map['foodName'] as String? ?? '',
      imageUrl: map['imageUrl'] as String? ?? '',
      unitPrice: parseDouble(map['unitPrice']),
      quantity: parseInt(map['quantity'], defaultValue: 1),
      available: map['available'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'foodId': foodId,
      'foodName': foodName,
      'imageUrl': imageUrl,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'available': available,
    };
  }
}
