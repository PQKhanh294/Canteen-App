import '../core/enums/order_status.dart';
import '../core/enums/payment_method.dart';
import '../core/enums/payment_status.dart';
import '../core/utils/model_parsers.dart';
import 'cart_item_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItemModel {
  final String foodId;
  final String foodName;
  final String imageUrl;
  final double unitPrice;
  int quantity;

  OrderItemModel({
    required this.foodId,
    required this.foodName,
    this.imageUrl = '',
    required this.unitPrice,
    required this.quantity,
  });

  // Compatibility getters for old OrderItem references
  double get price => unitPrice;
  double get subtotal => lineTotal;
  double get lineTotal => unitPrice * quantity;

  factory OrderItemModel.fromCartItem(CartItemModel item) {
    return OrderItemModel(
      foodId: item.foodId,
      foodName: item.foodName,
      imageUrl: item.imageUrl,
      unitPrice: item.unitPrice,
      quantity: item.quantity,
    );
  }

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    final double uPrice = parseDouble(map['unitPrice'] ?? map['price']);
    final int qty = parseInt(map['quantity'], defaultValue: 1);
    return OrderItemModel(
      foodId: map['foodId'] as String? ?? '',
      foodName: map['foodName'] ?? '',
      imageUrl: map['imageUrl'] as String? ?? '',
      unitPrice: uPrice,
      quantity: qty,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'foodId': foodId,
      'foodName': foodName,
      'imageUrl': imageUrl,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'lineTotal': lineTotal,
    };
  }
}

// Compatibility typedef to prevent breaking changes in other files
typedef OrderItem = OrderItemModel;

class OrderModel {
  final String id;
  final String displayCode;
  final String userId;
  final String userName;
  final String userEmail;
  final List<OrderItemModel> items;
  final double subtotal;
  final double discountAmount;
  final double finalTotal;
  final String? promoId;
  final String? promoCode;
  final DateTime pickupAt;
  final PaymentMethod paymentMethod;
  final PaymentStatus paymentStatus;
  final OrderStatus status;
  final String? counterNumber;
  final String? cancelReason;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, DateTime> statusTimestamps;

  const OrderModel({
    required this.id,
    required this.displayCode,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.items,
    required this.subtotal,
    required this.discountAmount,
    required this.finalTotal,
    this.promoId,
    this.promoCode,
    required this.pickupAt,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.status,
    this.counterNumber,
    this.cancelReason,
    required this.createdAt,
    this.updatedAt,
    required this.statusTimestamps,
  });

  // Compatibility getters for old OrderModel properties
  double get totalPrice => finalTotal;
  String get pickupTime =>
      '${pickupAt.hour.toString().padLeft(2, '0')}:${pickupAt.minute.toString().padLeft(2, '0')}';

  int get totalQuantity {
    return items.fold(0, (total, item) => total + item.quantity);
  }

  bool get canCancel => status == OrderStatus.pending;
  bool get canReview => status == OrderStatus.completed;

  bool get isProcessing {
    return status == OrderStatus.pending ||
        status == OrderStatus.confirmed ||
        status == OrderStatus.preparing ||
        status == OrderStatus.ready;
  }

  bool get isCompleted {
    return status == OrderStatus.completed;
  }

  bool get isCancelled {
    return status == OrderStatus.cancelled;
  }

  DateTime? statusTime(OrderStatus status) {
    return statusTimestamps[status.value];
  }

  factory OrderModel.fromMap(Map<String, dynamic> map, String id) {
    final rawItems = map['items'] as List<dynamic>? ?? const [];
    final rawStatusTimestamps =
        map['statusTimestamps'] as Map<String, dynamic>? ?? const {};

    final double parsedSubtotal = parseDouble(
      map['subtotal'] ?? map['totalPrice'],
    );
    final double parsedDiscount = parseDouble(map['discountAmount']);
    final double parsedFinalTotal = parseDouble(
      map['finalTotal'] ?? map['totalPrice'],
    );

    // Handle legacy pickupTime (String) if pickupAt is null
    DateTime parsedPickupAt;
    if (map['pickupAt'] != null) {
      parsedPickupAt = parseDateTime(map['pickupAt']) ?? DateTime.now();
    } else if (map['pickupTime'] != null) {
      final parts = (map['pickupTime'] as String).split(':');
      final now = DateTime.now();
      final hour = parts.isNotEmpty ? (int.tryParse(parts[0]) ?? 12) : 12;
      final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
      parsedPickupAt = DateTime(now.year, now.month, now.day, hour, minute);
    } else {
      parsedPickupAt = DateTime.now();
    }

    final Map<String, DateTime> parsedTimestamps = {};
    rawStatusTimestamps.forEach((key, value) {
      final parsed = parseDateTime(value);
      if (parsed != null) {
        parsedTimestamps[key] = parsed;
      }
    });

    return OrderModel(
      id: id,
      displayCode: map['displayCode'] as String? ?? id,
      userId: map['userId'] as String? ?? '',
      userName: map['userName'] as String? ?? '',
      userEmail: map['userEmail'] as String? ?? '',
      items: rawItems
          .map(
            (e) => OrderItemModel.fromMap(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
      subtotal: parsedSubtotal,
      discountAmount: parsedDiscount,
      finalTotal: parsedFinalTotal,
      promoId: map['promoId'] as String?,
      promoCode: map['promoCode'] as String?,
      pickupAt: parsedPickupAt,
      paymentMethod: PaymentMethod.fromValue(map['paymentMethod'] as String?),
      paymentStatus: PaymentStatus.fromValue(map['paymentStatus'] as String?),
      status: OrderStatus.fromValue(map['status']),
      counterNumber: map['counterNumber']?.toString(),
      cancelReason: map['cancelReason'] as String?,
      createdAt: parseDateTime(map['createdAt']) ?? DateTime.now(),
      updatedAt: parseDateTime(map['updatedAt']),
      statusTimestamps: parsedTimestamps,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayCode': displayCode,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'discountAmount': discountAmount,
      'finalTotal': finalTotal,
      'promoId': promoId,
      'promoCode': promoCode,
      'pickupAt': Timestamp.fromDate(pickupAt),
      'paymentMethod': paymentMethod.value,
      'paymentStatus': paymentStatus.value,
      'status': status.value,
      'counterNumber': counterNumber,
      'cancelReason': cancelReason,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'statusTimestamps': statusTimestamps.map(
        (key, value) => MapEntry(key, Timestamp.fromDate(value)),
      ),
    };
  }

  OrderModel copyWith({
    OrderStatus? status,
    PaymentStatus? paymentStatus,
    String? counterNumber,
    String? cancelReason,
    DateTime? updatedAt,
    Map<String, DateTime>? statusTimestamps,
  }) {
    return OrderModel(
      id: id,
      displayCode: displayCode,
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      items: items,
      subtotal: subtotal,
      discountAmount: discountAmount,
      finalTotal: finalTotal,
      promoId: promoId,
      promoCode: promoCode,
      pickupAt: pickupAt,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      status: status ?? this.status,
      counterNumber: counterNumber ?? this.counterNumber,
      cancelReason: cancelReason ?? this.cancelReason,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      statusTimestamps: statusTimestamps ?? this.statusTimestamps,
    );
  }
}
