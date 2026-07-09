// ============================================================
// LIB: models/order_model.dart
// Owner: Member 3 — An
// ============================================================

class OrderItem {
  final String foodId;
  final String foodName;
  final double price;
  int quantity;

  OrderItem({
    required this.foodId,
    required this.foodName,
    required this.price,
    required this.quantity,
  });

  double get subtotal => price * quantity;

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      foodId: map['foodId'] ?? '',
      foodName: map['foodName'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      quantity: map['quantity'] ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'foodId': foodId,
      'foodName': foodName,
      'price': price,
      'quantity': quantity,
    };
  }
}

class OrderModel {
  final String id;
  final String userId;
  final String userName;
  final List<OrderItem> items;
  final double totalPrice;
  final String pickupTime;
  final String paymentMethod; // 'cash' | 'ewallet'
  final String status; // pending | preparing | ready | completed | cancelled
  final DateTime createdAt;
  final DateTime updatedAt;

  OrderModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.items,
    required this.totalPrice,
    required this.pickupTime,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map, String id) {
    return OrderModel(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      items: (map['items'] as List<dynamic>? ?? [])
          .map((e) => OrderItem.fromMap(e as Map<String, dynamic>))
          .toList(),
      totalPrice: (map['totalPrice'] as num?)?.toDouble() ?? 0.0,
      pickupTime: map['pickupTime'] ?? '',
      paymentMethod: map['paymentMethod'] ?? 'cash',
      status: map['status'] ?? 'pending',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as dynamic).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'items': items.map((e) => e.toMap()).toList(),
      'totalPrice': totalPrice,
      'pickupTime': pickupTime,
      'paymentMethod': paymentMethod,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  OrderModel copyWith({String? status, DateTime? updatedAt}) {
    return OrderModel(
      id: id,
      userId: userId,
      userName: userName,
      items: items,
      totalPrice: totalPrice,
      pickupTime: pickupTime,
      paymentMethod: paymentMethod,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
