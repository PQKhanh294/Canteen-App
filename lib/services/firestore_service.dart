import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/food_model.dart';
import '../models/order_model.dart';
import '../models/review_model.dart';
import '../models/promo_model.dart';
import '../models/cart_item_model.dart';
import '../core/constants/app_constants.dart';
import '../core/enums/payment_method.dart';
import '../core/enums/payment_status.dart';
import '../core/enums/order_status.dart';
import '../core/utils/model_parsers.dart';
import '../core/utils/pickup_schedule.dart';
import '../core/utils/promo_calculator.dart';
import '../viewmodels/checkout_viewmodel.dart';
import '../viewmodels/cart_viewmodel.dart';

// ============================================================
// LIB: services/firestore_service.dart
// Owner: SHARED — báo nhóm trước khi sửa file này!
// ============================================================

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  // ─── FOODS ──────────────────────────────────────────────

  /// Stream danh sách tất cả món ăn available
  Stream<List<FoodModel>> getFoodsStream({String? category}) {
    Query<Map<String, dynamic>> query = _db
        .collection(AppConstants.foodsCollection)
        .where('available', isEqualTo: true);
    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }
    return query.snapshots().map(
      (snap) => snap.docs
          .map((doc) => FoodModel.fromMap(doc.data(), doc.id))
          .toList(),
    );
  }

  /// Lấy 1 món ăn theo id
  Future<FoodModel?> getFoodById(String foodId) async {
    final doc = await _db
        .collection(AppConstants.foodsCollection)
        .doc(foodId)
        .get();
    if (!doc.exists) return null;
    return FoodModel.fromMap(doc.data()!, doc.id);
  }

  /// Thêm món ăn (Admin)
  Future<void> addFood(FoodModel food) async {
    await _db.collection(AppConstants.foodsCollection).add(food.toMap());
  }

  /// Cập nhật món ăn (Admin)
  Future<void> updateFood(FoodModel food) async {
    await _db
        .collection(AppConstants.foodsCollection)
        .doc(food.id)
        .update(food.toMap());
  }

  /// Xóa món ăn (Admin)
  Future<void> deleteFood(String foodId) async {
    await _db.collection(AppConstants.foodsCollection).doc(foodId).delete();
  }

  // ─── ORDERS ─────────────────────────────────────────────

  Stream<List<OrderModel>> getOrdersByUserStream(String userId) {
    return _db
        .collection(AppConstants.ordersCollection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  /// Stream TẤT CẢ đơn hàng (Admin, realtime)
  Stream<List<OrderModel>> getAllOrdersStream() {
    return _db
        .collection(AppConstants.ordersCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // ─── REVIEWS ────────────────────────────────────────────

  /// Thêm đánh giá
  Future<void> addReview(ReviewModel review) async {
    final batch = _db.batch();
    // Thêm review
    final reviewRef = _db.collection(AppConstants.reviewsCollection).doc();
    batch.set(reviewRef, review.toMap());
    // Cập nhật avgRating trên food (dùng transaction cho chính xác)
    batch.commit();
    await _updateFoodRating(review.foodId);
  }

  /// Stream đánh giá của 1 món ăn
  Stream<List<ReviewModel>> getReviewsByFoodStream(String foodId) {
    return _db
        .collection(AppConstants.reviewsCollection)
        .where('foodId', isEqualTo: foodId)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((doc) => ReviewModel.fromMap(doc.data(), doc.id))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  /// Kiểm tra user đã review món này chưa
  Future<bool> hasReviewed(
    String userId,
    String foodId, {
    String? orderId,
  }) async {
    Query query = _db
        .collection(AppConstants.reviewsCollection)
        .where('userId', isEqualTo: userId)
        .where('foodId', isEqualTo: foodId);

    if (orderId != null && orderId.trim().isNotEmpty) {
      query = query.where('orderId', isEqualTo: orderId.trim());
    }

    final snap = await query.limit(1).get();
    return snap.docs.isNotEmpty;
  }

  /// Cập nhật avgRating sau khi thêm review
  Future<void> _updateFoodRating(String foodId) async {
    final reviews = await _db
        .collection(AppConstants.reviewsCollection)
        .where('foodId', isEqualTo: foodId)
        .get();
    if (reviews.docs.isEmpty) return;
    final total = reviews.docs.fold<int>(
      0,
      (prev, doc) => prev + ((doc.data()['rating'] as num?)?.toInt() ?? 0),
    );
    final avg = total / reviews.docs.length;
    await _db.collection(AppConstants.foodsCollection).doc(foodId).update({
      'avgRating': avg,
      'totalReviews': reviews.docs.length,
    });
  }

  // ─── STATS (Admin) ───────────────────────────────────────

  /// Lấy đơn hàng trong khoảng ngày (cho thống kê)
  Future<List<OrderModel>> getOrdersByDateRange(
    DateTime from,
    DateTime to,
  ) async {
    final snap = await _db
        .collection(AppConstants.ordersCollection)
        .where('createdAt', isGreaterThanOrEqualTo: from)
        .where('createdAt', isLessThanOrEqualTo: to)
        .where('status', isEqualTo: AppConstants.statusCompleted)
        .get();
    return snap.docs
        .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  // ─── PROMOS ──────────────────────────────────────────────

  /// Stream danh sách tất cả mã giảm giá đang active
  Stream<List<PromoModel>> getActivePromos() {
    return _db
        .collection(AppConstants.promosCollection)
        .snapshots()
        .map((snapshot) => _parseActivePromos(snapshot.docs));
  }

  /// Đọc một lần khi mở màn hình voucher để không phụ thuộc hoàn toàn vào
  /// trạng thái cache của realtime listener.
  Future<List<PromoModel>> getActivePromosOnce() async {
    final snapshot = await _db.collection(AppConstants.promosCollection).get();
    return _parseActivePromos(snapshot.docs);
  }

  List<PromoModel> _parseActivePromos(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    final promosByCode = <String, PromoModel>{};

    for (final document in documents) {
      try {
        final promo = PromoModel.fromMap(document.data(), document.id);
        if (promo.code.isEmpty || !promo.isActive) continue;

        // Dữ liệu cũ có thể tồn tại document ID ngẫu nhiên trùng code.
        // Ưu tiên document chuẩn có ID chính là code.
        final current = promosByCode[promo.code];
        if (current == null || document.id == promo.code) {
          promosByCode[promo.code] = promo;
        }
      } catch (error, stackTrace) {
        // Một document cũ bị lỗi không được phép làm mất toàn bộ danh sách.
        debugPrint(
          'Skipping invalid promo document ${document.id}: '
          '$error\n$stackTrace',
        );
      }
    }

    final promos = promosByCode.values.toList()
      ..sort((first, second) => first.expiresAt.compareTo(second.expiresAt));
    return promos;
  }

  /// Lấy voucher theo mã code. Ưu tiên document ID chuẩn, sau đó fallback
  /// query trường code để hỗ trợ dữ liệu Admin cũ dùng ID ngẫu nhiên.
  Future<PromoModel?> getPromoByCode(String code) async {
    final normalizedCode = code.trim().toUpperCase();

    if (normalizedCode.isEmpty) {
      return null;
    }

    try {
      final document = await _db
          .collection(AppConstants.promosCollection)
          .doc(normalizedCode)
          .get();

      if (document.exists && document.data() != null) {
        return PromoModel.fromMap(document.data()!, document.id);
      }

      final query = await _db
          .collection(AppConstants.promosCollection)
          .where('code', isEqualTo: normalizedCode)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;
      final fallbackDocument = query.docs.first;
      return PromoModel.fromMap(fallbackDocument.data(), fallbackDocument.id);
    } on FirebaseException catch (error, stackTrace) {
      // Ghi nhận lỗi và rethrow (Không nuốt lỗi)
      print('Could not find promo $normalizedCode: $error\n$stackTrace');
      rethrow;
    }
  }

  // ─── CHECKOUT ───────────────────────────────────────────

  /// Tạo đơn hàng từ luồng Checkout sử dụng Transaction để đảm bảo tính nhất quán dữ liệu
  Future<CheckoutResult> createOrderFromCheckout({
    required String userId,
    required String userName,
    required String userEmail,
    required List<CartItemModel> cartItems,
    required DateTime pickupAt,
    required PaymentMethod paymentMethod,
    PromoModel? promo,
  }) async {
    if (userId.trim().isEmpty) throw StateError('INVALID_USER_ID');
    if (cartItems.isEmpty) throw StateError('EMPTY_CART');
    if (!PickupSchedule.isValidPickupAt(pickupAt)) {
      throw StateError('INVALID_PICKUP_SLOT');
    }

    final orderReference = _db.collection(AppConstants.ordersCollection).doc();
    final orderId = orderReference.id;
    final displayCode = _generateDisplayCode(orderId);
    final pickupSlotId = PickupSchedule.slotId(pickupAt);
    final pickupSlotReference = _db
        .collection('pickup_slots')
        .doc(pickupSlotId);

    return _db.runTransaction<CheckoutResult>((transaction) async {
      final freshItems = <OrderItemModel>[];
      var freshSubtotal = 0;

      // 1. Kiểm tra từng món ăn trong giỏ hàng
      for (final cartItem in cartItems) {
        if (cartItem.quantity < 1 ||
            cartItem.quantity > CartViewModel.maxQuantityPerItem) {
          throw StateError('INVALID_QUANTITY:${cartItem.foodName}');
        }

        final foodReference = _db
            .collection(AppConstants.foodsCollection)
            .doc(cartItem.foodId);
        final foodSnapshot = await transaction.get(foodReference);

        if (!foodSnapshot.exists || foodSnapshot.data() == null) {
          throw StateError('FOOD_NOT_FOUND:${cartItem.foodName}');
        }

        final food = FoodModel.fromMap(foodSnapshot.data()!, foodSnapshot.id);

        if (!food.available) {
          throw StateError('FOOD_UNAVAILABLE:${food.name}');
        }

        final lineTotal = food.price * cartItem.quantity;
        final int lineTotalInt = lineTotal.toInt();

        freshItems.add(
          OrderItemModel(
            foodId: food.id,
            foodName: food.name,
            imageUrl: food.imageUrl,
            unitPrice: food.price,
            quantity: cartItem.quantity,
          ),
        );

        freshSubtotal += lineTotalInt;
      }

      // 2. Kiểm tra lại voucher/promo trong transaction
      PromoModel? freshPromo;
      DocumentReference<Map<String, dynamic>>? promoReference;
      var discountAmount = 0;

      if (promo != null) {
        promoReference = _db
            .collection(AppConstants.promosCollection)
            .doc(promo.id);
        final promoSnapshot = await transaction.get(promoReference);

        if (!promoSnapshot.exists || promoSnapshot.data() == null) {
          throw StateError('PROMO_NOT_FOUND');
        }

        freshPromo = PromoModel.fromMap(
          promoSnapshot.data()!,
          promoSnapshot.id,
        );

        final validation = PromoCalculator.validate(
          promo: freshPromo,
          subtotal: freshSubtotal,
        );

        if (!validation.isValid) {
          throw StateError('PROMO_INVALID:${validation.message}');
        }

        discountAmount = PromoCalculator.calculateDiscount(
          promo: freshPromo,
          subtotal: freshSubtotal,
        );
      }

      // 3. Giữ chỗ cho khung giờ nhận món. Mỗi slot có giới hạn để tránh
      // căn tin nhận quá nhiều đơn trong cùng thời điểm.
      final pickupSlotSnapshot = await transaction.get(pickupSlotReference);
      final pickupSlotCount = pickupSlotSnapshot.exists
          ? parseInt(pickupSlotSnapshot.data()?['orderCount'])
          : 0;
      if (pickupSlotCount >= PickupSchedule.maxOrdersPerSlot) {
        throw StateError('PICKUP_SLOT_FULL');
      }

      // Tất cả transaction reads đã hoàn tất; bắt đầu ghi dữ liệu.
      if (promoReference != null) {
        transaction.update(promoReference, {
          'usedCount': FieldValue.increment(1),
        });
      }

      // 4. Tính toán tổng thanh toán cuối cùng
      final finalTotal = (freshSubtotal - discountAmount).clamp(
        0,
        freshSubtotal,
      );

      // 5. Trạng thái thanh toán
      final paymentStatus = paymentMethod == PaymentMethod.eWalletMock
          ? PaymentStatus.mockPaid
          : PaymentStatus.unpaid;

      // 6. Cấu trúc dữ liệu đơn hàng lưu Firestore
      final orderData = <String, dynamic>{
        'displayCode': displayCode,
        'userId': userId,
        'userName': userName,
        'userEmail': userEmail,
        'items': freshItems.map((item) => item.toMap()).toList(),
        'subtotal': freshSubtotal.toDouble(),
        'discountAmount': discountAmount.toDouble(),
        'finalTotal': finalTotal.toDouble(),
        'promoId': freshPromo?.id,
        'promoCode': freshPromo?.code,
        'promoUsageReleased': freshPromo == null ? null : false,
        'pickupAt': Timestamp.fromDate(pickupAt),
        'pickupSlotId': pickupSlotId,
        'paymentMethod': paymentMethod.value,
        'paymentStatus': paymentStatus.value,
        'status': OrderStatus.pending.value,
        'counterNumber': null,
        'cancelReason': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'statusTimestamps': {
          OrderStatus.pending.value: FieldValue.serverTimestamp(),
        },
      };

      transaction.set(orderReference, orderData);
      transaction.set(pickupSlotReference, {
        'pickupAt': Timestamp.fromDate(pickupAt),
        'orderCount': pickupSlotCount + 1,
        'capacity': PickupSchedule.maxOrdersPerSlot,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return CheckoutResult(
        orderId: orderId,
        displayCode: displayCode,
        subtotal: freshSubtotal,
        discountAmount: discountAmount,
        finalTotal: finalTotal,
        pickupAt: pickupAt,
      );
    });
  }

  String _generateDisplayCode(String orderId) {
    final now = DateTime.now();
    final year = now.year.toString().substring(2);
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');

    final suffix = orderId
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')
        .substring(0, 4)
        .toUpperCase();

    return 'CF-$year$month$day-$suffix';
  }

  /// Lắng nghe realtime danh sách đơn hàng của một User, sắp xếp theo thời gian tạo mới nhất
  Stream<List<OrderModel>> watchUserOrders(String userId) {
    final normalizedUserId = userId.trim();

    if (normalizedUserId.isEmpty) {
      return Stream<List<OrderModel>>.value(const <OrderModel>[]);
    }

    return _db
        .collection(AppConstants.ordersCollection)
        .where('userId', isEqualTo: normalizedUserId)
        .snapshots()
        .map((snapshot) {
          final orders = snapshot.docs
              .map(
                (document) => OrderModel.fromMap(document.data(), document.id),
              )
              .toList();
          orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return orders;
        });
  }

  /// Lắng nghe realtime một đơn hàng cụ thể theo ID
  Stream<OrderModel> watchOrder(String orderId) {
    final normalizedOrderId = orderId.trim();

    if (normalizedOrderId.isEmpty) {
      return Stream<OrderModel>.error(
        ArgumentError.value(orderId, 'orderId', 'Order ID must not be empty.'),
      );
    }

    return _db
        .collection(AppConstants.ordersCollection)
        .doc(normalizedOrderId)
        .snapshots()
        .map((document) {
          final data = document.data();

          if (!document.exists || data == null) {
            throw StateError('ORDER_NOT_FOUND');
          }

          return OrderModel.fromMap(data, document.id);
        });
  }

  /// Hủy đơn hàng sử dụng transaction đảm bảo an toàn trạng thái
  Future<void> cancelOrder({
    required String orderId,
    required String userId,
    required String reason,
  }) async {
    final normalizedOrderId = orderId.trim();
    final normalizedUserId = userId.trim();
    final normalizedReason = reason.trim();

    if (normalizedOrderId.isEmpty) {
      throw StateError('INVALID_ORDER_ID');
    }

    if (normalizedUserId.isEmpty) {
      throw StateError('INVALID_USER_ID');
    }

    if (normalizedReason.isEmpty) {
      throw StateError('CANCEL_REASON_REQUIRED');
    }

    if (normalizedReason.length > 200) {
      throw StateError('CANCEL_REASON_TOO_LONG');
    }

    final orderReference = _db
        .collection(AppConstants.ordersCollection)
        .doc(normalizedOrderId);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(orderReference);
      final data = snapshot.data();

      if (!snapshot.exists || data == null) {
        throw StateError('ORDER_NOT_FOUND');
      }

      final ownerId = data['userId'] as String? ?? '';

      if (ownerId != normalizedUserId) {
        throw StateError('ORDER_ACCESS_DENIED');
      }

      final currentStatus = OrderStatus.fromValue(data['status'] as String?);

      if (currentStatus != OrderStatus.pending) {
        throw StateError('ORDER_CANNOT_CANCEL:${currentStatus.value}');
      }

      final promoId = (data['promoId'] as String?)?.trim();
      final promoAlreadyReleased = data['promoUsageReleased'] as bool? ?? false;
      DocumentReference<Map<String, dynamic>>? promoReference;
      DocumentSnapshot<Map<String, dynamic>>? promoSnapshot;

      if (promoId != null && promoId.isNotEmpty && !promoAlreadyReleased) {
        promoReference = _db
            .collection(AppConstants.promosCollection)
            .doc(promoId);
        promoSnapshot = await transaction.get(promoReference);
      }

      final storedPickupAt = parseDateTime(data['pickupAt']);
      final storedPickupSlotId = data['pickupSlotId'] as String?;
      final pickupSlotId = storedPickupSlotId?.isNotEmpty == true
          ? storedPickupSlotId!
          : storedPickupAt == null
          ? null
          : PickupSchedule.slotId(storedPickupAt);
      DocumentReference<Map<String, dynamic>>? pickupSlotReference;
      DocumentSnapshot<Map<String, dynamic>>? pickupSlotSnapshot;

      if (pickupSlotId != null) {
        pickupSlotReference = _db.collection('pickup_slots').doc(pickupSlotId);
        pickupSlotSnapshot = await transaction.get(pickupSlotReference);
      }

      final shouldReleasePromo =
          promoReference != null && promoSnapshot?.exists == true;
      final currentPromoUsedCount = shouldReleasePromo
          ? parseInt(promoSnapshot!.data()?['usedCount'])
          : 0;
      final shouldReleasePickupSlot = pickupSlotSnapshot?.exists == true;
      final currentPickupSlotCount = shouldReleasePickupSlot
          ? parseInt(pickupSlotSnapshot!.data()?['orderCount'])
          : 0;

      transaction.update(orderReference, {
        'status': OrderStatus.cancelled.value,
        'cancelReason': normalizedReason,
        'cancelledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'statusTimestamps.${OrderStatus.cancelled.value}':
            FieldValue.serverTimestamp(),
        if (promoId != null && promoId.isNotEmpty)
          'promoUsageReleased': shouldReleasePromo,
        if (shouldReleasePromo)
          'promoUsageReleasedAt': FieldValue.serverTimestamp(),
      });

      if (shouldReleasePromo && currentPromoUsedCount > 0) {
        transaction.update(promoReference, {
          'usedCount': PromoCalculator.releaseUsage(currentPromoUsedCount),
        });
      }

      if (shouldReleasePickupSlot && currentPickupSlotCount > 0) {
        transaction.update(pickupSlotReference!, {
          'orderCount': currentPickupSlotCount - 1,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  /// Tự động seeding dữ liệu món ăn và voucher nếu các collections đang trống
  Future<void> seedDataIfNeeded() async {
    try {
      final foodSnap = await _db
          .collection(AppConstants.foodsCollection)
          .limit(1)
          .get();
      if (foodSnap.docs.isEmpty) {
        final foods = [
          {
            'name': 'Cơm Tấm Sườn Bì Chả',
            'category': 'Cơm',
            'price': 35000.0,
            'available': true,
            'avgRating': 4.8,
            'totalReviews': 15,
            'imageUrl':
                'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&q=80&w=400',
            'description':
                'Cơm tấm thơm dẻo kèm sườn nướng đậm đà, bì thính và chả trứng chưng.',
          },
          {
            'name': 'Bún Bò Huế Đặc Biệt',
            'category': 'Bún/Phở',
            'price': 40000.0,
            'available': true,
            'avgRating': 4.7,
            'totalReviews': 22,
            'imageUrl':
                'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?auto=format&fit=crop&q=80&w=400',
            'description':
                'Bún bò nước dùng chuẩn vị Huế đậm đà thơm mùi sả, kèm thịt bò nạm, giò heo.',
          },
          {
            'name': 'Bánh Mì Kẹp Thịt Nướng',
            'category': 'Ăn vặt',
            'price': 15000.0,
            'available': true,
            'avgRating': 4.2,
            'totalReviews': 10,
            'imageUrl':
                'https://images.unsplash.com/photo-1484723091739-30a097e8f929?auto=format&fit=crop&q=80&w=200',
            'description':
                'Bánh mì giòn nóng hổi kẹp thịt nướng xiên thơm ngon kèm dưa góp.',
          },
          {
            'name': 'Nước Cam Ép Nguyên Chất',
            'category': 'Nước',
            'price': 18000.0,
            'available': true,
            'avgRating': 4.5,
            'totalReviews': 18,
            'imageUrl':
                'https://images.unsplash.com/photo-1613478223719-2ab802602423?auto=format&fit=crop&q=80&w=400',
            'description':
                'Nước cam ép tươi nguyên chất giàu vitamin C giải nhiệt cực tốt.',
          },
          {
            'name': 'Trà Sữa Chân Trâu Đường Đen',
            'category': 'Nước',
            'price': 25000.0,
            'available': true,
            'avgRating': 4.6,
            'totalReviews': 31,
            'imageUrl':
                'https://images.unsplash.com/photo-1541658016709-82535e94bc69?auto=format&fit=crop&q=80&w=400',
            'description':
                'Trà sữa ngọt béo thơm lừng kết hợp trân châu đường đen dai giòn.',
          },
          {
            'name': 'Bánh Flan Trứng Sữa',
            'category': 'Tráng miệng',
            'price': 12000.0,
            'available': true,
            'avgRating': 4.0,
            'totalReviews': 9,
            'imageUrl':
                'https://images.unsplash.com/photo-1528975604071-b4dc52a2d18c?auto=format&fit=crop&q=80&w=400',
            'description': 'Bánh flan mềm mịn thơm béo ngậy mùi trứng sữa.',
          },
        ];

        for (final f in foods) {
          await _db.collection(AppConstants.foodsCollection).add({
            ...f,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
        debugPrint('Seeded foods successfully');
      }

      final promoSnap = await _db
          .collection(AppConstants.promosCollection)
          .limit(1)
          .get();
      if (promoSnap.docs.isEmpty) {
        final now = DateTime.now();
        final start = now.subtract(const Duration(days: 2));
        final end = now.add(const Duration(days: 10));

        final promos = [
          {
            'code': 'FPT10',
            'description': 'Giảm 10% tối đa 20.000 đ cho đơn hàng từ 50.000 đ',
            'discountType': 'percentage',
            'discountValue': 10.0,
            'maximumDiscount': 20000.0,
            'minimumOrderAmount': 50000.0,
            'usageLimit': 100,
            'usedCount': 0,
            'isActive': true,
            'startAt': Timestamp.fromDate(start),
            'expiresAt': Timestamp.fromDate(end),
          },
          {
            'code': 'CANTEEN50',
            'description': 'Giảm 50.000 đ cho đơn hàng từ 100.000 đ',
            'discountType': 'fixed',
            'discountValue': 50000.0,
            'maximumDiscount': 50000.0,
            'minimumOrderAmount': 100000.0,
            'usageLimit': 50,
            'usedCount': 0,
            'isActive': true,
            'startAt': Timestamp.fromDate(start),
            'expiresAt': Timestamp.fromDate(end),
          },
        ];
        for (final p in promos) {
          await _db
              .collection(AppConstants.promosCollection)
              .doc(p['code'] as String)
              .set(p);
        }
        debugPrint('Seeded promos successfully');
      }
    } catch (e) {
      debugPrint('Failed to seed data: $e');
    }
  }
}
