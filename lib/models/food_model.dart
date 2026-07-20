import '../core/utils/model_parsers.dart';

class FoodModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final String imageUrl;
  final bool available;
  final double avgRating;
  final int totalReviews;
  final DateTime createdAt;

  FoodModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    this.imageUrl = '',
    this.available = true,
    this.avgRating = 0.0,
    this.totalReviews = 0,
    required this.createdAt,
  });

  factory FoodModel.fromMap(Map<String, dynamic> map, String id) {
    return FoodModel(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: parseDouble(map['price']),
      category: map['category'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      available: map['available'] ?? true,
      avgRating: parseDouble(map['avgRating']),
      totalReviews: parseInt(map['totalReviews']),
      createdAt: parseDateTime(map['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'imageUrl': imageUrl,
      'available': available,
      'avgRating': avgRating,
      'totalReviews': totalReviews,
      'createdAt': createdAt,
    };
  }

  FoodModel copyWith({
    String? name,
    String? description,
    double? price,
    String? category,
    String? imageUrl,
    bool? available,
    double? avgRating,
    int? totalReviews,
  }) {
    return FoodModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      available: available ?? this.available,
      avgRating: avgRating ?? this.avgRating,
      totalReviews: totalReviews ?? this.totalReviews,
      createdAt: createdAt,
    );
  }
}
