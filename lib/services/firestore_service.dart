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

  /// Tự động seeding dữ liệu món ăn và voucher phong phú nếu collections chưa đủ dữ liệu
  Future<void> seedDataIfNeeded({bool forceRefresh = false}) async {
    try {
      final foodSnap = await _db
          .collection(AppConstants.foodsCollection)
          .get();

      if (foodSnap.docs.length < 50 || forceRefresh) {
        // Nếu bắt buộc refresh, xóa bớt dữ liệu cũ
        if (forceRefresh) {
          for (final doc in foodSnap.docs) {
            await doc.reference.delete();
          }
        }

        final foods = [
          // =====================================================
          // CƠM (10 món)
          // =====================================================
          {
            'name': 'Cơm Tấm Sườn Bì Chả Đặc Biệt',
            'category': 'Cơm',
            'price': 35000.0,
            'available': true,
            'avgRating': 4.8,
            'totalReviews': 42,
            'imageUrl': 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8e/Com-Tam-2008.jpg/600px-Com-Tam-2008.jpg',
            'description': 'Cơm tấm thơm dẻo, sườn nướng mật ong đậm đà kẹp bì thính dai giòn và chả trứng hấp béo ngậy.',
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Cơm Gà Xối Mỡ Da Giòn',
            'category': 'Cơm',
            'price': 40000.0,
            'available': true,
            'avgRating': 4.9,
            'totalReviews': 58,
            'imageUrl': 'https://images.unsplash.com/photo-1562967914-608f82629710?auto=format&fit=crop&q=80&w=600',
            'description': 'Đùi gà góc tư chiên xối mỡ da giòn rụm, cơm chiên dưa hồng thơm lừng kèm dưa leo cà chua.',
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Cơm Thịt Kho Trứng Nước Dừa',
            'category': 'Cơm',
            'price': 32000.0,
            'available': true,
            'avgRating': 4.6,
            'totalReviews': 29,
            'imageUrl': 'https://images.unsplash.com/photo-1512058564366-18510be2db19?auto=format&fit=crop&q=80&w=600',
            'description': 'Thịt rọi rút xương kho nước dừa tươi thấm vị béo ngậy, kèm trứng kho và dưa giá bóp xổi.',
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Cơm Gà Áp Chảo Sốt Nấm',
            'category': 'Cơm',
            'price': 38000.0,
            'available': true,
            'avgRating': 4.7,
            'totalReviews': 35,
            'imageUrl': 'https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?auto=format&fit=crop&q=80&w=600',
            'description': 'Ức gà áp chảo sốt nấm kem tươi béo ngậy, phục vụ cùng cơm dẻo và rau củ luộc thanh mát.',
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Cơm Chiên Dương Châu',
            'category': 'Cơm',
            'price': 30000.0,
            'available': true,
            'avgRating': 4.5,
            'totalReviews': 47,
            'imageUrl': 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/cf/Com_chien_duong_chau.jpg/600px-Com_chien_duong_chau.jpg',
            'description': 'Cơm chiên kiểu Dương Châu truyền thống với tôm, trứng, lạp xưởng, hành lá thơm nức vàng giòn.',
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Cơm Sườn Cốt Lết Nướng Than',
            'category': 'Cơm',
            'price': 45000.0,
            'available': true,
            'avgRating': 4.8,
            'totalReviews': 63,
            'imageUrl': 'https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&q=80&w=600',
            'description': 'Sườn cốt lết heo nướng than hoa nguyên miếng thơm nức, ăn kèm cơm trắng dẻo và dưa leo muối chua.',
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Cơm Bò Lúc Lắc Sốt Tiêu',
            'category': 'Cơm',
            'price': 50000.0,
            'available': true,
            'avgRating': 4.9,
            'totalReviews': 71,
            'imageUrl': 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&q=80&w=600',
            'description': 'Thịt bò thăn Úc xào lúc lắc sốt tiêu đen Campuchia đậm đà, ăn kèm cơm trắng và rau xà lách.',
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Cơm Cá Kho Tộ',
            'category': 'Cơm',
            'price': 33000.0,
            'available': true,
            'avgRating': 4.6,
            'totalReviews': 38,
            'imageUrl': 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&q=80&w=600',
            'description': 'Cá basa kho tộ nước dừa đặc sệt ngọt thơm, vị béo ngậy đậm đà ăn kèm cơm trắng và canh chua.',
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Cơm Tôm Rang Muối Ớt',
            'category': 'Cơm',
            'price': 42000.0,
            'available': true,
            'avgRating': 4.7,
            'totalReviews': 44,
            'imageUrl': 'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?auto=format&fit=crop&q=80&w=600',
            'description': 'Tôm sú rang muối ớt tươi cay thơm giòn vỏ, ăn kèm cơm trắng dẻo và nước mắm tỏi ớt chua ngọt.',
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Cơm Trứng Chiên Thịt Băm',
            'category': 'Cơm',
            'price': 28000.0,
            'available': true,
            'avgRating': 4.4,
            'totalReviews': 52,
            'imageUrl': 'https://images.unsplash.com/photo-1598515214211-89d3c73ae83b?auto=format&fit=crop&q=80&w=600',
            'description': 'Trứng gà ốp la vàng giòn viền, thịt heo băm xào hành tiêu đậm đà, phục vụ cùng cơm nóng hổi.',
            'createdAt': FieldValue.serverTimestamp(),
          },
          // =====================================================
          // BÚN / PHỞ (10 món)
          // =====================================================
          {
            'name': 'Bún Bò Huế Đặc Biệt',
            'category': 'Bún/Phở',
            'price': 40000.0,
            'available': true,
            'avgRating': 4.8,
            'totalReviews': 64,
            'imageUrl': 'https://upload.wikimedia.org/wikipedia/commons/f/f5/Bun-Bo-Hue-2008.jpg',
            'description': 'Bún bò chuẩn vị xứ Huế nước dùng hầm xương đượm vị mắm ruốc sả thơm lừng, kèm nạm bò, chả cua và giò heo.',
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Phở Bò Tái Nạm Hà Nội',
            'category': 'Bún/Phở',
            'price': 45000.0,
            'available': true,
            'avgRating': 4.9,
            'totalReviews': 87,
            'imageUrl': 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2e/Pho_noodle_soup.jpg/600px-Pho_noodle_soup.jpg',
            'description': 'Bánh phở tươi mềm, nước dùng ninh từ xương ống bò 12 tiếng trong vắt thơm mùi hoa hồi thảo quả, kèm thịt bò tái nạm dẻo ngọt.',
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Bún Chả Hà Nội Nướng Than Hoa',
            'category': 'Bún/Phở',
            'price': 38000.0,
            'available': true,
            'avgRating': 4.7,
            'totalReviews': 41,
            'imageUrl': 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f9/B%C3%BAn_ch%E1%BA%A3_H%C3%A0_N%E1%BB%99i_%28th%C3%A1ng_7_n%C4%83m_2018%29_%281%29.jpg/600px-B%C3%BAn_ch%E1%BA%A3_H%C3%A0_N%E1%BB%99i_%28th%C3%A1ng_7_n%C4%83m_2018%29_%281%29.jpg',
            'description': 'Chả viên và chả miếng nướng than hoa thơm nức mũi, nước chấm chua ngọt kèm đu đủ ướp giòn và bún tươi.',
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Bún Riêu Cua Đồng Giò Sụn',
            'category': 'Bún/Phở',
            'price': 35000.0,
            'available': true,
            'avgRating': 4.5,
            'totalReviews': 33,
            'imageUrl': 'https://images.unsplash.com/photo-1617093727343-374698b1b08d?auto=format&fit=crop&q=80&w=600',
            'description': 'Nước dùng vị chua dịu từ dấm bỗng, riêu cua nguyên chất thơm ngon kèm giò sụn sần sật và đậu rán vàng giòn.',
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Bún Thịt Nướng Sài Gòn',
            'category': 'Bún/Phở',
            'price': 35000.0,
            'available': true,
            'avgRating': 4.7,
            'totalReviews': 55,
            'imageUrl': 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d8/Saigon_Bun_thit_nuong.jpg/600px-Saigon_Bun_thit_nuong.jpg',
            'description': 'Bún tươi trắng ngần kèm thịt heo nướng mật ong thơm khói, chả giò giòn rụm, đồ chua và nước mắm pha.',
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Mì Quảng Đà Nẵng Tôm Thịt',
            'category': 'Bún/Phở',
            'price': 38000.0,
            'available': true,
            'avgRating': 4.8,
            'totalReviews': 49,
            'imageUrl': 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c3/M%C3%AC_Qu%E1%BA%A3ng%2C_Da_Nang%2C_Vietnam.jpg/600px-M%C3%AC_Qu%E1%BA%A3ng%2C_Da_Nang%2C_Vietnam.jpg',
            'description': 'Mì sợi to mềm dai vàng nghệ chan nước dùng tôm thịt đậm ngọt, phủ bánh tráng nướng giòn và rau sống tươi.',
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Hủ Tiếu Nam Vang Khô',
            'category': 'Bún/Phở',
            'price': 40000.0,
            'available': true,
            'avgRating': 4.6,
            'totalReviews': 37,
            'imageUrl': 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/50/Hu-Tieu-Kho-2008.jpg/600px-Hu-Tieu-Kho-2008.jpg',
            'description': 'Hủ tiếu dai giòn trộn dầu hào xào khô kèm tôm cua mực hải sản tươi ngon, ăn kèm nước dùng trong ngọt.',
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Bánh Cuốn Hà Nội Chả Lụa',
            'category': 'Bún/Phở',
            'price': 32000.0,
            'available': true,
            'avgRating': 4.6,
            'totalReviews': 42,
            'imageUrl': 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4e/Banh_Cuon_2.jpg/600px-Banh_Cuon_2.jpg',
            'description': 'Bánh cuốn tráng tay mỏng mịn nhân thịt heo mộc nhĩ, phủ hành phi thơm và chả lụa dai ngọt.',
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Cao Lầu Hội An Đặc Sản',
            'category': 'Bún/Phở',
            'price': 42000.0,
            'available': true,
            'avgRating': 4.9,
            'totalReviews': 61,
            'imageUrl': 'https://upload.wikimedia.org/wikipedia/commons/c/c5/Cao_l%E1%BA%A7u.jpg',
            'description': 'Mì cao lầu đặc sản Hội An dai vàng đặc trưng ngâm nước giếng Bá Lễ, chan nước xá xíu đậm đà và thịt heo quay giòn da.',
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Phở Gà Ta Nước Trong',
            'category': 'Bún/Phở',
            'price': 40000.0,
            'available': true,
            'avgRating': 4.7,
            'totalReviews': 45,
            'imageUrl': 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&q=80&w=600',
            'description': 'Nước dùng gà ta hầm thảo quả hoa hồi trong vắt ngọt thanh, bánh phở tươi mềm và gà ta xé thơm mềm mịn.',
            'createdAt': FieldValue.serverTimestamp(),
          },
          // =====================================================
          // NƯỚC UỐNG (10 món)
          // =====================================================
          {
            'name': 'Trà Sữa Trân Châu Đường Đen',
            'category': 'Nước',
            'price': 25000.0,
            'available': true,
            'avgRating': 4.8,
            'totalReviews': 112,
            'imageUrl': 'https://images.unsplash.com/photo-1558857563-b371033873b8?auto=format&fit=crop&q=80&w=600',
            'description': 'Trà sữa Đài Loan đậm vị trà Earl Grey kết hợp sữa tươi thanh trùng và trân châu đường đen nấu dẻo thơm béo.',
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Nước Cam Ép Nguyên Chất',
            'category': 'Nước',
            'price': 20000.0,
            'available': true,
            'avgRating': 4.7,
            'totalReviews': 53,
            'imageUrl': 'https://images.unsplash.com/photo-1613478223719-2ab802602423?auto=format&fit=crop&q=80&w=600',
            'description': '100% cam sành tươi mọng nước ép nguyên chất không pha nước, bổ sung Vitamin C tăng sức đề kháng.',
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Trà Đào Cam Sả Tươi',
            'category': 'Nước',
            'price': 22000.0,
            'available': true,
            'avgRating': 4.6,
            'totalReviews': 76,
            'imageUrl': 'https://images.unsplash.com/photo-1556679343-c7306c1976bc?auto=format&fit=crop&q=80&w=600',
            'description': 'Trà đen ngâm hương cam sả thơm dịu mát kết hợp miếng đào ngâm giòn ngọt đậm đà.',
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Cà Phê Sữa Đá Sài Gòn',
            'category': 'Nước',
            'price': 18000.0,
            'available': true,
            'avgRating': 4.9,
            'totalReviews': 95,
            'imageUrl': 'https://images.unsplash.com/photo-1517701604599-bb29b565090c?auto=format&fit=crop&q=80&w=600',
            'description': 'Cà phê Robusta phin nguyên chất thơm nồng nặc hòa quyện cùng sữa đặc béo ngọt và đá lạnh sảng khoái.',
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Nước Mía Vắt Tắc Tươi',
            'category': 'Nước',
            'price': 15000.0,
            'available': true,
            'avgRating': 4.8,
            'totalReviews': 88,
            'imageUrl': 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7f/N%C6%B0%E1%BB%9Bc_m%C3%ADa_Vi%E1%BB%87t_Nam_si%C3%AAu_to_kh%E1%BB%95ng_l%E1%BB%93_20201201.jpg/600px-N%C6%B0%E1%BB%9Bc_m%C3%ADa_Vi%E1%BB%87t_Nam_si%C3%AAu_to_kh%E1%BB%95ng_l%E1%BB%93_20201201.jpg',
            'description': 'Mía ép tươi nguyên cây giải nhiệt mát lạnh kết hợp tắc vắt chua ngọt dịu, thêm đá viên sảng khoái.',
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Sinh Tố Bơ Mật Ong',
            'category': 'Nước',
            'price': 28000.0,
            'available': true,
            'avgRating': 4.7,
            'totalReviews': 67,
            'imageUrl': 'https://images.unsplash.com/photo-1540420773420-3366772f4999?auto=format&fit=crop&q=80&w=600',
            'description': 'Bơ Đắk Lắk chín dẻo xay nhuyễn cùng sữa tươi và mật ong rừng nguyên chất, béo ngậy ngọt thanh tự nhiên.',
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Trà Xanh Đá Chanh Mật Ong',
            'category': 'Nước',
            'price': 20000.0,
            'available': true,
            'avgRating': 4.5,
            'totalReviews': 49,
            'imageUrl': 'https://images.unsplash.com/photo-1627435601361-ec25f5b1d0e5?auto=format&fit=crop&q=80&w=600',
            'description': 'Trà xanh Thái Nguyên pha lạnh vắt chanh tươi và mật ong nguyên chất, thanh mát dịu nhẹ bổ dưỡng.',
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Soda Chanh Muối Bạc Hà',
            'category': 'Nước',
            'price': 18000.0,
            'available': true,
            'avgRating': 4.6,
            'totalReviews': 73,
            'imageUrl': 'https://images.unsplash.com/photo-1544145945-f90425340c7e?auto=format&fit=crop&q=80&w=600',
            'description': 'Soda tươi vị chanh muối đặc biệt có lá bạc hà tươi, ga nhiều sảng khoái và cực kỳ giải nhiệt mùa hè.',
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Hồng Trà Sữa Nóng',
            'category': 'Nước',
            'price': 20000.0,
            'available': true,
            'avgRating': 4.5,
            'totalReviews': 41,
            'imageUrl': 'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?auto=format&fit=crop&q=80&w=600',
            'description': 'Hồng trà Sri Lanka pha nóng kết hợp sữa đặc Ông Thọ thơm béo, uống nóng ấm lòng những ngày mưa.',
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Nước Dừa Xiêm Tươi Nguyên Trái',
            'category': 'Nước',
            'price': 25000.0,
            'available': true,
            'avgRating': 4.9,
            'totalReviews': 94,
            'imageUrl': 'https://images.unsplash.com/photo-1559181567-c3190ca9d70f?auto=format&fit=crop&q=80&w=600',
            'description': 'Dừa xiêm xanh Bến Tre nguyên trái chặt tươi ngay tại quán, nước dừa ngọt mát thanh và cùi mỏng giòn.',
            'createdAt': FieldValue.serverTimestamp(),
          },
          // =====================================================
          // ĂN VẶT (10 món)
          // =====================================================
          {
            'name': 'Bánh Mì Kẹp Thịt Nướng Xiên',
            'category': 'Ăn vặt',
            'price': 18000.0,
            'available': true,
            'avgRating': 4.6,
            'totalReviews': 48,
            'imageUrl': 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4e/B%C3%A1nh_m%C3%AC_Vi%E1%BB%87t_Anh%2C_Th%C3%A0nh_ph%E1%BB%91_H%E1%BB%93_Ch%C3%AD_Minh.jpg/600px-B%C3%A1nh_m%C3%AC_Vi%E1%BB%87t_Anh%2C_Th%C3%A0nh_ph%E1%BB%91_H%E1%BB%93_Ch%C3%AD_Minh.jpg',
            'description': 'Vỏ bánh mì nướng giòn rụm kẹp thịt nướng xiên thơm nức, đồ chua, dưa leo và sốt bơ trứng nhà làm.',
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Bánh Tráng Trộn Sài Gòn',
            'category': 'Ăn vặt',
            'price': 20000.0,
            'available': true,
            'avgRating': 4.5,
            'totalReviews': 62,
            'imageUrl': 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/63/Vietnamese_%22banh_trang_tron%22.JPG/600px-Vietnamese_%22banh_trang_tron%22.JPG',
            'description': 'Bánh tráng tây ninh thấm vị bò khô, mực xé, trứng cút, xoài bào sợi, rau răm và sốt me tắc đậm đà.',
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Xúc Xích Đức Nướng Căn Tin',
            'category': 'Ăn vặt',
            'price': 15000.0,
            'available': true,
            'avgRating': 4.4,
            'totalReviews': 38,
            'imageUrl': 'https://images.unsplash.com/photo-1599599810769-bcde5a160d32?auto=format&fit=crop&q=80&w=600',
            'description': 'Xúc xích xông khói nướng nóng hổi giòn sần sật châm cùng sốt tương ớt mù tạt vàng.',
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Bánh Xèo Miền Nam Tôm Thịt',
            'category': 'Ăn vặt',
            'price': 30000.0,
            'available': true,
            'avgRating': 4.8,
            'totalReviews': 54,
            'imageUrl': 'https://upload.wikimedia.org/wikipedia/commons/thumb/0/0b/B%C3%A1nh_x%C3%A8o_with_n%C6%B0%E1%BB%9Bc_m%E1%BA%AFm.jpg/600px-B%C3%A1nh_x%C3%A8o_with_n%C6%B0%E1%BB%9Bc_m%E1%BA%AFm.jpg',
            'description': 'Bánh xèo giòn rụm nhân tôm thịt béo giá đỗ mập, cuốn rau sống chấm nước mắm chua ngọt đặc biệt.',
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Gỏi Cuốn Tôm Thịt Truyền Thống',
            'category': 'Ăn vặt',
            'price': 25000.0,
            'available': true,
            'avgRating': 4.7,
            'totalReviews': 59,
            'imageUrl': 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?auto=format&fit=crop&q=80&w=600',
            'description': 'Bánh tráng cuốn tươi nhân tôm luộc đỏ hồng, thịt heo thái mỏng, bún tươi và rau xà lách thơm.',
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Chả Giò Chiên Giòn Nhân Tôm',
            'category': 'Ăn vặt',
            'price': 22000.0,
            'available': true,
            'avgRating': 4.6,
            'totalReviews': 46,
            'imageUrl': 'https://images.unsplash.com/photo-1541544741938-0af808871cc0?auto=format&fit=crop&q=80&w=600',
            'description': 'Chả giò chiên vàng giòn rụm nhân tôm thịt miến mộc nhĩ, ăn kèm rau sống và nước chấm tỏi ớt chua ngọt.',
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Bắp Nướng Bơ Muối Ớt',
            'category': 'Ăn vặt',
            'price': 15000.0,
            'available': true,
            'avgRating': 4.5,
            'totalReviews': 67,
            'imageUrl': 'https://images.unsplash.com/photo-1570913149827-d2ac84ab3f9a?auto=format&fit=crop&q=80&w=600',
            'description': 'Bắp nếp Đà Lạt nướng than hoa phết bơ mặn thơm và muối ớt tây nguyên, ngọt dẻo thơm nức mũi.',
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Trứng Cút Chiên Muối Ớt Xanh',
            'category': 'Ăn vặt',
            'price': 12000.0,
            'available': true,
            'avgRating': 4.4,
            'totalReviews': 78,
            'imageUrl': 'https://images.unsplash.com/photo-1607532941433-304659e8198a?auto=format&fit=crop&q=80&w=600',
            'description': 'Trứng cút chiên vàng giòn lớp ngoài ngậy bùi, nêm muối ớt xanh cay nồng thơm lừng ăn vặt mỗi ngày.',
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Khoai Tây Chiên Sốt Phô Mai',
            'category': 'Ăn vặt',
            'price': 20000.0,
            'available': true,
            'avgRating': 4.6,
            'totalReviews': 85,
            'imageUrl': 'https://images.unsplash.com/photo-1541592106381-b31e9677c0e5?auto=format&fit=crop&q=80&w=600',
            'description': 'Khoai tây thái que chiên vàng giòn rụm phủ sốt phô mai béo ngậy và phủ bơ tỏi thơm nức.',
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Bò Viên Đặc Biệt Sốt Sa Tế',
            'category': 'Ăn vặt',
            'price': 18000.0,
            'available': true,
            'avgRating': 4.7,
            'totalReviews': 93,
            'imageUrl': 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a2/Grilled_pork_and_beef_balls.jpg/600px-Grilled_pork_and_beef_balls.jpg',
            'description': 'Bò viên Sài Gòn dai giòn sần sật chấm sa tế tôm khô cay thơm nồng hấp dẫn từng miếng một.',
            'createdAt': FieldValue.serverTimestamp(),
          },
          // =====================================================
          // TRÁNG MIỆNG (10 món)
          // =====================================================
          {
            'name': 'Bánh Flan Trứng Sữa Caramen',
            'category': 'Tráng miệng',
            'price': 12000.0,
            'available': true,
            'avgRating': 4.7,
            'totalReviews': 44,
            'imageUrl': 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6a/Creme_Caramel.jpg/600px-Creme_Caramel.jpg',
            'description': 'Bánh flan làm từ trứng gà tươi và sữa đặc mềm mịn tan trong miệng kết hợp lớp đắng nhẹ caramen dừa.',
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Chè Bưởi An Giang Béo Ngậy',
            'category': 'Tráng miệng',
            'price': 20000.0,
            'available': true,
            'avgRating': 4.8,
            'totalReviews': 57,
            'imageUrl': 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e0/Chendol2.jpg/600px-Chendol2.jpg',
            'description': 'Cùi bưởi chiên giòn dai sần sật không đắng, đỗ xanh đồ kỹ sánh mịn hòa quyện cùng cốt dừa tươi béo ngậy.',
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Sữa Chua Nếp Cẩm Điện Biên',
            'category': 'Tráng miệng',
            'price': 18000.0,
            'available': true,
            'avgRating': 4.6,
            'totalReviews': 39,
            'imageUrl': 'https://images.unsplash.com/photo-1488477181946-6428a0291777?auto=format&fit=crop&q=80&w=600',
            'description': 'Sữa chua lên men tự nhiên sánh dẻo mịn mát ăn kèm nếp cẩm ủ men thơm nồng ngọt thanh.',
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Bánh Da Lợn Lá Dứa',
            'category': 'Tráng miệng',
            'price': 15000.0,
            'available': true,
            'avgRating': 4.5,
            'totalReviews': 36,
            'imageUrl': 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c4/Green_Leaf_Cake_b%C3%A1nh_da_l%E1%BB%A3n.jpg/600px-Green_Leaf_Cake_b%C3%A1nh_da_l%E1%BB%A3n.jpg',
            'description': 'Bánh da lợn miền Nam nhiều lớp xanh trắng trong suốt, dẻo dai thơm lá dứa và vị béo bùi đậu xanh.',
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Chè Ba Màu Đặc Biệt',
            'category': 'Tráng miệng',
            'price': 20000.0,
            'available': true,
            'avgRating': 4.7,
            'totalReviews': 63,
            'imageUrl': 'https://images.unsplash.com/photo-1567206563114-c179706b0175?auto=format&fit=crop&q=80&w=600',
            'description': 'Chè đậu đỏ đậu xanh thạch lá dứa ba tầng màu sắc bắt mắt chan nước cốt dừa tươi béo ngậy.',
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Kem Tươi Dừa Sầu Riêng',
            'category': 'Tráng miệng',
            'price': 22000.0,
            'available': true,
            'avgRating': 4.8,
            'totalReviews': 71,
            'imageUrl': 'https://images.unsplash.com/photo-1551024506-0bccd828d307?auto=format&fit=crop&q=80&w=600',
            'description': 'Kem tươi nguyên kem dừa Bến Tre béo ngậy kết hợp sầu riêng Ri6 nguyên cơm vàng thơm nức.',
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Bánh Tiêu Nhân Đậu Xanh',
            'category': 'Tráng miệng',
            'price': 10000.0,
            'available': true,
            'avgRating': 4.4,
            'totalReviews': 55,
            'imageUrl': 'https://images.unsplash.com/photo-1559181567-c3190ca9d70f?auto=format&fit=crop&q=80&w=600',
            'description': 'Bánh tiêu chiên xù phồng to giòn vỏ ngoài, nhân đậu xanh chà bông ngọt bùi ăn nóng tuyệt vời.',
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Thạch Sương Sâm Nước Dừa',
            'category': 'Tráng miệng',
            'price': 15000.0,
            'available': true,
            'avgRating': 4.6,
            'totalReviews': 49,
            'imageUrl': 'https://images.unsplash.com/photo-1536304929831-ee1ca9d44906?auto=format&fit=crop&q=80&w=600',
            'description': 'Thạch sương sâm đen mát lạnh mát gan giải nhiệt, chan nước dừa tươi và mật ong thanh đạm.',
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Chè Đậu Đỏ Bánh Lọt',
            'category': 'Tráng miệng',
            'price': 18000.0,
            'available': true,
            'avgRating': 4.6,
            'totalReviews': 43,
            'imageUrl': 'https://images.unsplash.com/photo-1488477181946-6428a0291777?auto=format&fit=crop&q=80&w=600',
            'description': 'Đậu đỏ nấu mềm bùi với bánh lọt lá dứa xanh dẻo dai, chan nước cốt dừa béo và đường thốt nốt.',
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Kem Xôi Nếp Tím Nước Dừa',
            'category': 'Tráng miệng',
            'price': 20000.0,
            'available': true,
            'avgRating': 4.7,
            'totalReviews': 58,
            'imageUrl': 'https://images.unsplash.com/photo-1567206563114-c179706b0175?auto=format&fit=crop&q=80&w=600',
            'description': 'Xôi nếp tím Điện Biên dẻo thơm bên dưới, kem vanilla mát lạnh phía trên, rưới nước cốt dừa béo ngậy.',
            'createdAt': FieldValue.serverTimestamp(),
          },
        ];

        // Nếu chưa forceRefresh thì cập nhật/thêm các món
        if (!forceRefresh && foodSnap.docs.isNotEmpty) {
          final existingDocs = {
            for (var d in foodSnap.docs)
              (d.data()['name'] ?? '').toString(): d
          };
          for (final f in foods) {
            final name = f['name'].toString();
            if (!existingDocs.containsKey(name)) {
              await _db.collection(AppConstants.foodsCollection).add(f);
            } else {
              // Cập nhật lại imageUrl & description nếu hình ảnh/mô tả cũ bị sai
              final doc = existingDocs[name]!;
              final currentImg = (doc.data()['imageUrl'] ?? '').toString();
              if (currentImg != f['imageUrl']) {
                await doc.reference.update({
                  'imageUrl': f['imageUrl'],
                  'description': f['description'],
                  'category': f['category'],
                });
              }
            }
          }
        } else {
          for (final f in foods) {
            await _db.collection(AppConstants.foodsCollection).add(f);
          }
        }
        debugPrint('Seeded foods successfully');
      }

      final promoSnap = await _db
          .collection(AppConstants.promosCollection)
          .limit(1)
          .get();
      if (promoSnap.docs.isEmpty || forceRefresh) {
        final now = DateTime.now();
        final start = now.subtract(const Duration(days: 2));
        final end = now.add(const Duration(days: 30));

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
          {
            'code': 'HELLOSMILE',
            'description': 'Giảm 15.000 đ trực tiếp cho đơn hàng từ 30.000 đ',
            'discountType': 'fixed',
            'discountValue': 15000.0,
            'maximumDiscount': 15000.0,
            'minimumOrderAmount': 30000.0,
            'usageLimit': 200,
            'usedCount': 0,
            'isActive': true,
            'startAt': Timestamp.fromDate(start),
            'expiresAt': Timestamp.fromDate(end),
          },
          {
            'code': 'FREESHIP30',
            'description': 'Giảm 30% tối đa 15.000 đ cho món Ăn Vặt & Nước Uống',
            'discountType': 'percentage',
            'discountValue': 30.0,
            'maximumDiscount': 15000.0,
            'minimumOrderAmount': 20000.0,
            'usageLimit': 150,
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
