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
    String? note,
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
        'note': note?.trim().isNotEmpty == true ? note!.trim() : null,
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

            if (foodSnap.docs.length != 30 || forceRefresh) {
        // Dọn dẹp sạch dữ liệu cũ khi tổng số món khác 30 hoặc khi forceRefresh
        for (final doc in foodSnap.docs) {
          await doc.reference.delete();
        }

        final foods = [
          // =====================================================
          // 1. CƠM (6 món)
          // =====================================================
          {
            'name': 'Cơm Tấm Sườn Bì Chả Đặc Biệt',
            'category': 'Cơm',
            'price': 35000.0,
            'available': true,
            'avgRating': 4.8,
            'totalReviews': 42,
            'imageUrl': 'https://tse4.mm.bing.net/th/id/OIP.vCYEU05EQjca0a_b8bE2OAHaEK?r=0&rs=1&pid=ImgDetMain&o=7&rm=3',
            'description': 'Cơm tấm thơm dẻo, sườn nướng mật ong đậm đà kẹp bì thính dai giòn và chả trứng hấp béo ngậy.',
            'calories': 620,
            'protein': 32.0,
            'carbs': 68.0,
            'fat': 22.0,
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Cơm Gà Xối Mỡ Da Giòn',
            'category': 'Cơm',
            'price': 40000.0,
            'available': true,
            'avgRating': 4.9,
            'totalReviews': 58,
            'imageUrl': 'https://cdn.tgdd.vn/2021/01/CookRecipe/Avatar/com-chien-ga-xoi-mo-thumbnail.jpg',
            'description': 'Đùi gà góc tư chiên xối mỡ da giòn rụm, cơm chiên dưa hồng thơm lừng kèm dưa leo cà chua.',
            'calories': 580,
            'protein': 35.0,
            'carbs': 55.0,
            'fat': 20.0,
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Cơm Thịt Kho Trứng Nước Dừa',
            'category': 'Cơm',
            'price': 32000.0,
            'available': true,
            'avgRating': 4.6,
            'totalReviews': 29,
            'imageUrl': 'https://eurocook.com.vn/Data/upload/images/tintuc/mon-ngon-moi-ngay-thit-kho-nuoc-dua-02.jpg',
            'description': 'Thịt rọi rút xương kho nước dừa tươi thấm vị béo ngậy, kèm trứng kho và dưa giá bóp xổi.',
            'calories': 540,
            'protein': 28.0,
            'carbs': 62.0,
            'fat': 18.0,
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Cơm Gà Áp Chảo Sốt Nấm',
            'category': 'Cơm',
            'price': 38000.0,
            'available': true,
            'avgRating': 4.7,
            'totalReviews': 35,
            'imageUrl': 'https://th.bing.com/th/id/R.0b1af18fd70718c0b1da24afa4c572ba?rik=BirGGihKktNb%2bA&riu=http%3a%2f%2ffile.hstatic.net%2f200000385717%2farticle%2fcom_nieu_ga_sot_nam_0dd0ab11be1348b8a6faf3dba369c5bb.jpg&ehk=TuqjovsmUpLmW%2b%2f%2fah0ppTJCPxeCZ1H3IHNUWiaZ3pU%3d&risl=&pid=ImgRaw&r=0',
            'description': 'Ức gà áp chảo sốt nấm kem tươi béo ngậy, phục vụ cùng cơm dẻo và rau củ luộc thanh mát.',
            'calories': 490,
            'protein': 36.0,
            'carbs': 50.0,
            'fat': 14.0,
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Cơm Chiên Dương Châu',
            'category': 'Cơm',
            'price': 30000.0,
            'available': true,
            'avgRating': 4.5,
            'totalReviews': 47,
            'imageUrl': 'https://cdn.hstatic.net/files/200000700229/file/com-chien-duong-chau-chay-1.jpg',
            'description': 'Cơm chiên kiểu Dương Châu truyền thống với tôm, trứng, lạp xưởng, hành lá thơm nức vàng giòn.',
            'calories': 510,
            'protein': 18.0,
            'carbs': 72.0,
            'fat': 16.0,
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Cơm Bò Lúc Lắc Sốt Tiêu',
            'category': 'Cơm',
            'price': 50000.0,
            'available': true,
            'avgRating': 4.9,
            'totalReviews': 71,
            'imageUrl': 'https://product.hstatic.net/200000663503/product/com_bo_luc_lac_de84821d3256440db5861d2e4f1f53fa_master.jpg',
            'description': 'Thịt bò thăn Úc xào lúc lắc sốt tiêu đen Campuchia đậm đà, ăn kèm cơm trắng và rau xà lách.',
            'calories': 560,
            'protein': 38.0,
            'carbs': 52.0,
            'fat': 19.0,
            'createdAt': FieldValue.serverTimestamp(),
          },

          // =====================================================
          // 2. BÚN / PHỞ (6 món)
          // =====================================================
          {
            'name': 'Phở Bò Tái Nạm Hà Nội',
            'category': 'Bún/Phở',
            'price': 45000.0,
            'available': true,
            'avgRating': 4.9,
            'totalReviews': 87,
            'imageUrl': 'https://dienmaynguyenkhoi.vn/wp-content/uploads/2023/02/an-pho-tai-nam-khi-nong-1.jpg',
            'description': 'Bánh phở tươi mềm, nước dùng ninh từ xương ống bò 12 tiếng trong vắt thơm mùi hoa hồi thảo quả, kèm thịt bò tái nạm dẻo ngọt.',
            'calories': 420,
            'protein': 28.0,
            'carbs': 55.0,
            'fat': 10.0,
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Bún Bò Huế Đặc Biệt',
            'category': 'Bún/Phở',
            'price': 40000.0,
            'available': true,
            'avgRating': 4.8,
            'totalReviews': 64,
            'imageUrl': 'https://cdn.mediamart.vn/images/news/hc-cach-nu-bun-bo-hu-thom-ngon-dung-chun-huong-v_519e659c.jpg',
            'description': 'Bún bò chuẩn vị xứ Huế nước dùng hầm xương đượm vị mắm ruốc sả thơm lừng, kèm nạm bò, chả cua và giò heo.',
            'calories': 450,
            'protein': 30.0,
            'carbs': 52.0,
            'fat': 13.0,
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Bún Chả Hà Nội Nướng Than Hoa',
            'category': 'Bún/Phở',
            'price': 38000.0,
            'available': true,
            'avgRating': 4.7,
            'totalReviews': 41,
            'imageUrl': 'https://media.suckhoecong.vn/Images/2025/04/12/z6497364206170_e7cbdfbabe4a1becd8e462ce42b23e39-11031290-250412110312.jpg',
            'description': 'Chả viên và chả miếng nướng than hoa thơm nức mũi, nước chấm chua ngọt kèm đu đủ ướp giòn và bún tươi.',
            'calories': 480,
            'protein': 32.0,
            'carbs': 50.0,
            'fat': 15.0,
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Bún Thịt Nướng Sài Gòn',
            'category': 'Bún/Phở',
            'price': 35000.0,
            'available': true,
            'avgRating': 4.7,
            'totalReviews': 55,
            'imageUrl': 'https://cooponline.vn/tin-tuc/wp-content/uploads/2025/10/cach-lam-bun-thit-nuong-chuan-vi-sai-gon-thom-ngon-dam-da-kho-cuong.png',
            'description': 'Bún tươi trắng ngần kèm thịt heo nướng mật ong thơm khói, chả giò giòn rụm, đồ chua và nước mắm pha.',
            'calories': 460,
            'protein': 29.0,
            'carbs': 54.0,
            'fat': 13.0,
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Mì Quảng Đà Nẵng Tôm Thịt',
            'category': 'Bún/Phở',
            'price': 38000.0,
            'available': true,
            'avgRating': 4.8,
            'totalReviews': 49,
            'imageUrl': 'https://statics.vinpearl.com/cach-nau-mi-quang-tom-thit-8_1631330957.jpg',
            'description': 'Mì sợi to mềm dai vàng nghệ chan nước dùng tôm thịt đậm ngọt, phủ bánh tráng nướng giòn và rau sống tươi.',
            'calories': 440,
            'protein': 26.0,
            'carbs': 58.0,
            'fat': 11.0,
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Hủ Tiếu Nam Vang Khô',
            'category': 'Bún/Phở',
            'price': 40000.0,
            'available': true,
            'avgRating': 4.6,
            'totalReviews': 37,
            'imageUrl': 'https://th.bing.com/th/id/OIP.zH142w9jY9Oyl0IZkj3FMQHaE8?r=0&o=7rm=3&rs=1&pid=ImgDetMain&o=7&rm=3',
            'description': 'Hủ tiếu dai giòn trộn dầu hào xào khô kèm tôm cua mực hải sản tươi ngon, ăn kèm nước dùng trong ngọt.',
            'calories': 430,
            'protein': 24.0,
            'carbs': 60.0,
            'fat': 10.0,
            'createdAt': FieldValue.serverTimestamp(),
          },

          // =====================================================
          // 3. NƯỚC UỐNG (6 món)
          // =====================================================
          {
            'name': 'Cà Phê Sữa Đá Sài Gòn',
            'category': 'Nước',
            'price': 18000.0,
            'available': true,
            'avgRating': 4.9,
            'totalReviews': 95,
            'imageUrl': 'https://tse2.mm.bing.net/th/id/OIP.UIhmHTql1wid-qRRrnU5QAHaE6?r=0&rs=1&pid=ImgDetMain&o=7&rm=3',
            'description': 'Cà phê Robusta phin nguyên chất thơm nồng nặc hòa quyện cùng sữa đặc béo ngọt và đá lạnh sảng khoái.',
            'calories': 130,
            'protein': 3.0,
            'carbs': 18.0,
            'fat': 5.0,
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Trà Sữa Trân Châu Đường Đen',
            'category': 'Nước',
            'price': 25000.0,
            'available': true,
            'avgRating': 4.8,
            'totalReviews': 112,
            'imageUrl': 'https://cdn.tgdd.vn/Files/2022/01/21/1412109/huong-dan-cach-lam-tra-sua-tran-chau-duong-den-202201211522033706.jpg',
            'description': 'Trà sữa Đài Loan đậm vị trà Earl Grey kết hợp sữa tươi thanh trùng và trân châu đường đen nấu dẻo thơm béo.',
            'calories': 280,
            'protein': 4.0,
            'carbs': 52.0,
            'fat': 6.0,
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Nước Cam Ép Nguyên Chất',
            'category': 'Nước',
            'price': 20000.0,
            'available': true,
            'avgRating': 4.7,
            'totalReviews': 53,
            'imageUrl': 'https://tse1.mm.bing.net/th/id/OIP.svee692Ur8ib3Z6176SW0AHaE8?r=0&rs=1&pid=ImgDetMain&o=7&rm=3',
            'description': '100% cam sành tươi mọng nước ép nguyên chất không pha nước, bổ sung Vitamin C tăng sức đề kháng.',
            'calories': 90,
            'protein': 1.5,
            'carbs': 21.0,
            'fat': 0.2,
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Trà Đào Cam Sả Tươi',
            'category': 'Nước',
            'price': 22000.0,
            'available': true,
            'avgRating': 4.6,
            'totalReviews': 76,
            'imageUrl': 'https://img.meta.com.vn/Data/image/2021/05/20/tra-dao-cam-sa-2.jpg',
            'description': 'Trà đen ngâm hương cam sả thơm dịu mát kết hợp miếng đào ngâm giòn ngọt đậm đà.',
            'calories': 110,
            'protein': 0.5,
            'carbs': 28.0,
            'fat': 0.1,
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Nước Mía Vắt Tắc Tươi',
            'category': 'Nước',
            'price': 15000.0,
            'available': true,
            'avgRating': 4.8,
            'totalReviews': 88,
            'imageUrl': 'https://media.phunutoday.vn/files/news/2026/03/29/nuoc-mia-rat-tot-nhung-uong-sai-cach-de-phan-tac-dung-5-dieu-can-nho-de-tranh-hai-co-the-094603.jpg',
            'description': 'Mía ép tươi nguyên cây giải nhiệt mát lạnh kết hợp tắc vắt chua ngọt dịu, thêm đá viên sảng khoái.',
            'calories': 120,
            'protein': 0.3,
            'carbs': 30.0,
            'fat': 0.1,
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Nước Dừa Xiêm Tươi Nguyên Trái',
            'category': 'Nước',
            'price': 25000.0,
            'available': true,
            'avgRating': 4.9,
            'totalReviews': 94,
            'imageUrl': 'https://tse1.mm.bing.net/th/id/OIP.vZeOz4QrzxmrCZn-f4XBcgHaGN?r=0&rs=1&pid=ImgDetMain&o=7&rm=3',
            'description': 'Dừa xiêm xanh Bến Tre nguyên trái chặt tươi ngay tại quán, nước dừa ngọt mát thanh và cùi mỏng giòn.',
            'calories': 60,
            'protein': 0.7,
            'carbs': 14.0,
            'fat': 0.2,
            'createdAt': FieldValue.serverTimestamp(),
          },

          // =====================================================
          // 4. ĂN VẶT (6 món)
          // =====================================================
          {
            'name': 'Bánh Mì Kẹp Thịt Nướng Xiên',
            'category': 'Ăn vặt',
            'price': 18000.0,
            'available': true,
            'avgRating': 4.6,
            'totalReviews': 48,
            'imageUrl': 'https://cdn2.fptshop.com.vn/unsafe/800x0/cach_lam_banh_mi_thit_xien_nuong_8_5f10655a0e.jpg',
            'description': 'Vỏ bánh mì nướng giòn rụm kẹp thịt nướng xiên thơm nức, đồ chua, dưa leo và sốt bơ trứng nhà làm.',
            'calories': 320,
            'protein': 18.0,
            'carbs': 38.0,
            'fat': 10.0,
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Bánh Tráng Trộn Sài Gòn',
            'category': 'Ăn vặt',
            'price': 20000.0,
            'available': true,
            'avgRating': 4.5,
            'totalReviews': 62,
            'imageUrl': 'https://i.pinimg.com/originals/1d/62/25/1d6225c0382eb0adf51533f7e3ffb244.jpg',
            'description': 'Bánh tráng tây ninh thấm vị bò khô, mực xé, trứng cút, xoài bào sợi, rau răm và sốt me tắc đậm đà.',
            'calories': 260,
            'protein': 10.0,
            'carbs': 40.0,
            'fat': 7.0,
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Bánh Xèo Miền Nam Tôm Thịt',
            'category': 'Ăn vặt',
            'price': 30000.0,
            'available': true,
            'avgRating': 4.8,
            'totalReviews': 54,
            'imageUrl': 'https://tse3.mm.bing.net/th/id/OIP.7ObkjCmuem7QQneSFwntiQHaHa?r=0&rs=1&pid=ImgDetMain&o=7&rm=3',
            'description': 'Bánh xèo giòn rụm nhân tôm thịt béo giá đỗ mập, cuốn rau sống chấm nước mắm chua ngọt đặc biệt.',
            'calories': 380,
            'protein': 20.0,
            'carbs': 42.0,
            'fat': 14.0,
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Bò Viên Đặc Biệt Sốt Sa Tế',
            'category': 'Ăn vặt',
            'price': 18000.0,
            'available': true,
            'avgRating': 4.7,
            'totalReviews': 93,
            'imageUrl': 'https://cdn.tgdd.vn/2021/04/content/boviennuong-800x450.jpg',
            'description': 'Bò viên Sài Gòn dai giòn sần sật chấm sa tế tôm khô cay thơm nồng hấp dẫn từng miếng một.',
            'calories': 290,
            'protein': 22.0,
            'carbs': 20.0,
            'fat': 13.0,
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Khoai Tây Chiên Sốt Phô Mai',
            'category': 'Ăn vặt',
            'price': 20000.0,
            'available': true,
            'avgRating': 4.6,
            'totalReviews': 85,
            'imageUrl': 'https://i.vietgiaitri.com/2021/9/6/cach-lam-khoai-tay-chien-sot-pho-mai-bang-noi-chien-khong-dau-don-gian-011-6010987.jpg',
            'description': 'Khoai tây thái que chiên vàng giòn rụm phủ sốt phô mai béo ngậy và phủ bơ tỏi thơm nức.',
            'calories': 340,
            'protein': 5.0,
            'carbs': 42.0,
            'fat': 18.0,
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Xúc Xích Đức Nướng ',
            'category': 'Ăn vặt',
            'price': 15000.0,
            'available': true,
            'avgRating': 4.4,
            'totalReviews': 38,
            'imageUrl': 'https://th.bing.com/th/id/R.695598df037f2d33f281076b4d307e27?rik=JAVnqtrOPLL%2buA&pid=ImgRaw&r=0',
            'description': 'Xúc xích xông khói nướng nóng hổi giòn sần sật châm cùng sốt tương ớt mù tạt vàng.',
            'calories': 250,
            'protein': 12.0,
            'carbs': 8.0,
            'fat': 19.0,
            'createdAt': FieldValue.serverTimestamp(),
          },

          // =====================================================
          // 5. TRÁNG MIỆNG (6 món)
          // =====================================================
          {
            'name': 'Bánh Flan Trứng Sữa Caramen',
            'category': 'Tráng miệng',
            'price': 12000.0,
            'available': true,
            'avgRating': 4.7,
            'totalReviews': 44,
            'imageUrl': 'https://tse1.mm.bing.net/th/id/OIP.3keHIQa-uoHsnkvgpOEHGwHaE6?r=0&rs=1&pid=ImgDetMain&o=7&rm=3',
            'description': 'Bánh flan làm từ trứng gà tươi và sữa đặc mềm mịn tan trong miệng kết hợp lớp đắng nhẹ caramen dừa.',
            'calories': 180,
            'protein': 6.0,
            'carbs': 24.0,
            'fat': 7.0,
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Chè Bưởi An Giang Béo Ngậy',
            'category': 'Tráng miệng',
            'price': 20000.0,
            'available': true,
            'avgRating': 4.8,
            'totalReviews': 57,
            'imageUrl': 'https://th.bing.com/th/id/OIP.cdJ5eEAJ0vUkxIn7WbVoJAHaE8?r=0&o=7rm=3&rs=1&pid=ImgDetMain&o=7&rm=3',
            'description': 'Cùi bưởi chiên giòn dai sần sật không đắng, đỗ xanh đồ kỹ sánh mịn hòa quyện cùng cốt dừa tươi béo ngậy.',
            'calories': 200,
            'protein': 3.0,
            'carbs': 38.0,
            'fat': 5.0,
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Bánh Da Lợn Lá Dứa',
            'category': 'Tráng miệng',
            'price': 15000.0,
            'available': true,
            'avgRating': 4.5,
            'totalReviews': 36,
            'imageUrl': 'https://cdn.tgdd.vn/Files/2019/03/08/1153592/cach-lam-banh-da-lon-deo-ngon-bui-bui-nhu-mua-ngoai-hang-202112031617559658.jpg',
            'description': 'Bánh da lợn miền Nam nhiều lớp xanh trắng trong suốt, dẻo dai thơm lá dứa và vị béo bùi đậu xanh.',
            'calories': 160,
            'protein': 3.0,
            'carbs': 32.0,
            'fat': 3.0,
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Sữa Chua Nếp Cẩm ',
            'category': 'Tráng miệng',
            'price': 18000.0,
            'available': true,
            'avgRating': 4.6,
            'totalReviews': 39,
            'imageUrl': 'https://beptruong.edu.vn/wp-content/uploads/2019/03/sua-chua-nep-cam.jpg',
            'description': 'Sữa chua lên men tự nhiên sánh dẻo mịn mát ăn kèm nếp cẩm ủ men thơm nồng ngọt thanh.',
            'calories': 210,
            'protein': 5.0,
            'carbs': 38.0,
            'fat': 4.0,
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Kem Tươi Dừa Sầu Riêng',
            'category': 'Tráng miệng',
            'price': 22000.0,
            'available': true,
            'avgRating': 4.8,
            'totalReviews': 71,
            'imageUrl': 'https://vuanem.com/blog/wp-content/uploads/2022/11/kem-sau-rieng.jpg',
            'description': 'Kem tươi nguyên kem dừa Bến Tre béo ngậy kết hợp sầu riêng Ri6 nguyên cơm vàng thơm nức.',
            'calories': 290,
            'protein': 4.0,
            'carbs': 30.0,
            'fat': 18.0,
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Chè Ba Màu Đặc Biệt',
            'category': 'Tráng miệng',
            'price': 20000.0,
            'available': true,
            'avgRating': 4.7,
            'totalReviews': 63,
            'imageUrl': 'https://tse2.mm.bing.net/th/id/OIP.oswGfhVPNopjKtQzAr8YmgHaNk?r=0&rs=1&pid=ImgDetMain&o=7&rm=3',
            'description': 'Chè đậu đỏ đậu xanh thạch lá dứa ba tầng màu sắc bắt mắt chan nước cốt dừa tươi béo ngậy.',
            'calories': 220,
            'protein': 4.0,
            'carbs': 42.0,
            'fat': 4.0,
            'createdAt': FieldValue.serverTimestamp(),
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
