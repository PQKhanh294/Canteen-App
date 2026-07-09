// ============================================================
// LIB: models/review_model.dart
// Owner: Member 2 — Hài
// ============================================================

class ReviewModel {
  final String id;
  final String foodId;
  final String userId;
  final String userName;
  final String orderId;
  final int rating; // 1–5
  final String comment;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.foodId,
    required this.userId,
    required this.userName,
    required this.orderId,
    required this.rating,
    this.comment = '',
    required this.createdAt,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> map, String id) {
    return ReviewModel(
      id: id,
      foodId: map['foodId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      orderId: map['orderId'] ?? '',
      rating: map['rating'] ?? 5,
      comment: map['comment'] ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'foodId': foodId,
      'userId': userId,
      'userName': userName,
      'orderId': orderId,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt,
    };
  }
}
