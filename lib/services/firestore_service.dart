import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/food_model.dart';
import '../models/order_model.dart';
import '../models/review_model.dart';
import '../models/promo_model.dart';
import '../core/constants/app_constants.dart';

// ============================================================
// LIB: services/firestore_service.dart
// Owner: SHARED — báo nhóm trước khi sửa file này!
// ============================================================

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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

  /// Tạo đơn hàng mới
  Future<String> createOrder(OrderModel order) async {
    final doc = await _db
        .collection(AppConstants.ordersCollection)
        .add(order.toMap());
    return doc.id;
  }

  /// Stream đơn hàng của 1 user (realtime)
  Stream<List<OrderModel>> getOrdersByUserStream(String userId) {
    return _db
        .collection(AppConstants.ordersCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
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

  /// Cập nhật trạng thái đơn hàng (Admin)
  Future<void> updateOrderStatus(String orderId, String status) async {
    await _db.collection(AppConstants.ordersCollection).doc(orderId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
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
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => ReviewModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  /// Kiểm tra user đã review món này chưa
  Future<bool> hasReviewed(String userId, String foodId) async {
    final snap = await _db
        .collection(AppConstants.reviewsCollection)
        .where('userId', isEqualTo: userId)
        .where('foodId', isEqualTo: foodId)
        .limit(1)
        .get();
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
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final promos = snapshot.docs.map((document) {
            return PromoModel.fromMap(document.data(), document.id);
          }).toList();

          promos.sort(
            (first, second) => first.expiresAt.compareTo(second.expiresAt),
          );

          return promos;
        });
  }

  /// Lấy voucher theo mã code (document ID)
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

      if (!document.exists || document.data() == null) {
        return null;
      }

      return PromoModel.fromMap(document.data()!, document.id);
    } on FirebaseException catch (error, stackTrace) {
      // Ghi nhận lỗi và rethrow (Không nuốt lỗi)
      print('Could not find promo $normalizedCode: $error\n$stackTrace');
      rethrow;
    }
  }
}
