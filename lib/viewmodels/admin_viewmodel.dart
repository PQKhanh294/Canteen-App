import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../core/constants/app_constants.dart';
import '../core/enums/discount_type.dart';
import '../core/enums/order_status.dart';
import '../models/food_model.dart';
import '../models/order_model.dart';
import '../models/promo_model.dart';
import '../models/user_model.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';

class AdminCategory {
  const AdminCategory({
    required this.id,
    required this.name,
    required this.icon,
  });
  final String id;
  final String name;
  final String icon;
}

class AdminBroadcast {
  const AdminBroadcast({
    required this.id,
    required this.title,
    required this.body,
    required this.sentAt,
    required this.recipientCount,
  });
  final String id;
  final String title;
  final String body;
  final DateTime sentAt;
  final int recipientCount;
}

class CustomerSummary {
  const CustomerSummary({
    required this.user,
    required this.orderCount,
    required this.totalSpent,
  });
  final UserModel user;
  final int orderCount;
  final double totalSpent;
}

class FoodPerformance {
  const FoodPerformance({
    required this.name,
    required this.quantity,
    required this.revenue,
  });
  final String name;
  final int quantity;
  final double revenue;
}

class AdminAnalytics {
  const AdminAnalytics({
    required this.orders,
    required this.revenueByDay,
    required this.ordersByHour,
    required this.topFoods,
  });
  final List<OrderModel> orders;
  final Map<DateTime, double> revenueByDay;
  final Map<int, int> ordersByHour;
  final List<FoodPerformance> topFoods;
  double get revenue => orders.fold(0, (sum, order) => sum + order.totalPrice);
  double get averagePerDay =>
      revenue / (revenueByDay.isEmpty ? 1 : revenueByDay.length);
}

class AdminViewModel extends ChangeNotifier {
  AdminViewModel(
    this._storage,
    this._notifications, {
    FirebaseFirestore? firestore,
  }) : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;
  final StorageService _storage;
  final NotificationService _notifications;
  bool isLoading = false;
  String? errorMessage;

  Stream<List<OrderModel>> get ordersStream => _db
      .collection(AppConstants.ordersCollection)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (s) => s.docs.map((d) => OrderModel.fromMap(d.data(), d.id)).toList(),
      );
  Stream<List<FoodModel>> get foodsStream => _db
      .collection(AppConstants.foodsCollection)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (s) => s.docs.map((d) => FoodModel.fromMap(d.data(), d.id)).toList(),
      );
  Stream<List<AdminCategory>> get categoriesStream => _db
      .collection('categories')
      .orderBy('name')
      .snapshots()
      .map(
        (s) => s.docs
            .map(
              (d) => AdminCategory(
                id: d.id,
                name: d.data()['name'] ?? '',
                icon: d.data()['icon'] ?? 'restaurant',
              ),
            )
            .toList(),
      );
  Stream<List<PromoModel>> get promosStream =>
      _db.collection('promos').snapshots().map((snapshot) {
        final promos = snapshot.docs
            .map((document) => PromoModel.fromMap(document.data(), document.id))
            .toList();
        promos.sort(
          (first, second) => second.expiresAt.compareTo(first.expiresAt),
        );
        return promos;
      });
  Stream<List<AdminBroadcast>> get broadcastsStream => _db
      .collection('broadcasts')
      .orderBy('sentAt', descending: true)
      .snapshots()
      .map(
        (s) => s.docs.map((d) {
          final m = d.data();
          return AdminBroadcast(
            id: d.id,
            title: m['title'] ?? '',
            body: m['body'] ?? '',
            sentAt: _date(m['sentAt']),
            recipientCount: (m['recipientCount'] as num?)?.toInt() ?? 0,
          );
        }).toList(),
      );

  Future<void> updateOrderStatus(
    OrderModel order,
    OrderStatus nextStatus, {
    String? counterNumber,
  }) async {
    final normalizedCounter = counterNumber?.trim();
    if (nextStatus == OrderStatus.ready &&
        (normalizedCounter == null || normalizedCounter.isEmpty)) {
      throw StateError('Vui lòng nhập số quầy trước khi đánh dấu sẵn sàng.');
    }

    await _run(() async {
      final orderReference = _db
          .collection(AppConstants.ordersCollection)
          .doc(order.id);
      await _db.runTransaction((transaction) async {
        final snapshot = await transaction.get(orderReference);
        if (!snapshot.exists || snapshot.data() == null) {
          throw StateError('Không tìm thấy đơn hàng.');
        }

        final currentStatus = OrderStatus.fromValue(
          snapshot.data()!['status'] as String?,
        );
        if (!currentStatus.canTransitionTo(nextStatus)) {
          throw StateError(
            'Trạng thái đơn đã thay đổi. Vui lòng tải lại danh sách.',
          );
        }

        transaction.update(orderReference, {
          'status': nextStatus.value,
          'updatedAt': FieldValue.serverTimestamp(),
          'statusTimestamps.${nextStatus.value}': FieldValue.serverTimestamp(),
          if (nextStatus == OrderStatus.ready)
            'counterNumber': normalizedCounter,
        });
      });

      if (nextStatus == OrderStatus.ready) {
        try {
          await _notifications.queueOrderReadyNotification(
            order.userId,
            order.id,
          );
        } catch (error, stackTrace) {
          debugPrint(
            'Order ready but notification could not be queued: '
            '$error\n$stackTrace',
          );
        }
      }
    });
  }

  Future<String> saveFood({
    String? id,
    required String name,
    required String description,
    required double price,
    required String category,
    required bool available,
    required bool isFeatured,
    File? image,
  }) async {
    var result = id ?? '';
    await _run(() async {
      final ref = id == null
          ? _db.collection(AppConstants.foodsCollection).doc()
          : _db.collection(AppConstants.foodsCollection).doc(id);
      var imageUrl = id == null
          ? ''
          : ((await ref.get()).data()?['imageUrl'] ?? '');
      if (image != null) {
        imageUrl = await _storage.uploadFoodImage(image, ref.id);
      }
      await ref.set({
        'name': name,
        'description': description,
        'price': price,
        'category': category,
        'imageUrl': imageUrl,
        'available': available,
        'isFeatured': isFeatured,
        'createdAt': id == null
            ? FieldValue.serverTimestamp()
            : (await ref.get()).data()?['createdAt'] ??
                  FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      result = ref.id;
    });
    return result;
  }

  Future<void> toggleFood(FoodModel food, bool value) => _run(
    () => _db.collection(AppConstants.foodsCollection).doc(food.id).update({
      'available': value,
    }),
  );
  Future<bool> isFoodFeatured(String id) async =>
      (await _db.collection(AppConstants.foodsCollection).doc(id).get())
          .data()?['isFeatured'] ??
      false;
  Future<void> deleteFood(FoodModel food) => _run(() async {
    await _db.collection(AppConstants.foodsCollection).doc(food.id).delete();
    if (food.imageUrl.isNotEmpty) await _storage.deleteImage(food.imageUrl);
  });

  Future<void> saveCategory({
    String? id,
    required String name,
    required String icon,
  }) => _run(
    () =>
        (id == null
                ? _db.collection('categories').doc()
                : _db.collection('categories').doc(id))
            .set({
              'name': name.trim(),
              'icon': icon.trim(),
            }, SetOptions(merge: true)),
  );
  Future<void> deleteCategory(AdminCategory category) => _run(() async {
    final used = await _db
        .collection(AppConstants.foodsCollection)
        .where('category', isEqualTo: category.name)
        .limit(1)
        .get();
    if (used.docs.isNotEmpty) throw Exception('Danh mục vẫn còn món ăn');
    await _db.collection('categories').doc(category.id).delete();
  });
  Future<void> savePromo({
    String? id,
    required String code,
    required String description,
    required DiscountType discountType,
    required double discountValue,
    double? minimumOrderAmount,
    double? maximumDiscount,
    required DateTime startAt,
    required DateTime expiresAt,
    int? usageLimit,
    int usedCount = 0,
    bool isActive = true,
  }) => _run(() async {
    final normalizedCode = code.trim().toUpperCase();
    if (normalizedCode.isEmpty) throw ArgumentError('Mã không được để trống');
    if (discountValue <= 0) throw ArgumentError('Giá trị giảm phải lớn hơn 0');
    if (discountType == DiscountType.percentage && discountValue > 100) {
      throw ArgumentError('Phần trăm giảm không được vượt quá 100');
    }
    if (minimumOrderAmount != null && minimumOrderAmount < 0) {
      throw ArgumentError('Giá trị đơn tối thiểu không được âm');
    }
    if (maximumDiscount != null && maximumDiscount <= 0) {
      throw ArgumentError('Mức giảm tối đa phải lớn hơn 0');
    }
    if (usageLimit != null && usageLimit <= 0) {
      throw ArgumentError('Giới hạn lượt dùng phải lớn hơn 0');
    }
    if (usedCount < 0) {
      throw ArgumentError('Số lượt đã dùng không được âm');
    }
    if (!expiresAt.isAfter(startAt)) {
      throw ArgumentError('Ngày hết hạn phải sau ngày bắt đầu');
    }

    // Voucher mới dùng code làm document ID. Voucher cũ giữ ID hiện tại để
    // các order đã lưu promoId vẫn có thể hoàn lượt khi bị hủy.
    final reference = _db
        .collection(AppConstants.promosCollection)
        .doc(id ?? normalizedCode);
    final existing = await reference.get();
    final persistedUsedCount = existing.exists
        ? (existing.data()?['usedCount'] as num?)?.toInt() ?? usedCount
        : usedCount;
    await reference.set({
      'code': normalizedCode,
      'description': description.trim(),
      'discountType': discountType.value,
      'discountValue': discountValue,
      'minimumOrderAmount': minimumOrderAmount,
      'maximumDiscount': maximumDiscount,
      'startAt': Timestamp.fromDate(startAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'isActive': isActive,
      'usageLimit': usageLimit,
      'usedCount': persistedUsedCount,
      'updatedAt': FieldValue.serverTimestamp(),
      if (!existing.exists) 'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  });
  Future<void> togglePromo(PromoModel promo, bool isActive) => _run(
    () => _db.collection('promos').doc(promo.id).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    }),
  );

  Future<List<CustomerSummary>> loadCustomers() async {
    final results = await Future.wait([
      _db
          .collection(AppConstants.usersCollection)
          .where('role', isEqualTo: AppConstants.roleStudent)
          .get(),
      _db.collection(AppConstants.ordersCollection).get(),
    ]);
    final users = results[0].docs.map((d) => UserModel.fromMap(d.data(), d.id));
    final orders = results[1].docs
        .map((d) => OrderModel.fromMap(d.data(), d.id))
        .toList();
    return users.map((u) {
      final own = orders.where((o) => o.userId == u.uid).toList();
      return CustomerSummary(
        user: u,
        orderCount: own.length,
        totalSpent: own
            .where((o) => o.status == OrderStatus.completed)
            .fold(0, (s, o) => s + o.totalPrice),
      );
    }).toList();
  }

  Future<List<OrderModel>> loadCustomerOrders(String uid) async {
    final s = await _db
        .collection(AppConstants.ordersCollection)
        .where('userId', isEqualTo: uid)
        .get();
    final list = s.docs.map((d) => OrderModel.fromMap(d.data(), d.id)).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<AdminAnalytics> loadAnalytics(DateTime from, DateTime to) async {
    final s = await _db
        .collection(AppConstants.ordersCollection)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(to))
        .get();
    final orders = s.docs
        .map((d) => OrderModel.fromMap(d.data(), d.id))
        .where((o) => o.status == OrderStatus.completed)
        .toList();
    final revenue = <DateTime, double>{};
    final hours = <int, int>{};
    final foods = <String, FoodPerformance>{};
    for (final o in orders) {
      final day = DateTime(
        o.createdAt.year,
        o.createdAt.month,
        o.createdAt.day,
      );
      revenue[day] = (revenue[day] ?? 0) + o.totalPrice;
      hours[o.createdAt.hour] = (hours[o.createdAt.hour] ?? 0) + 1;
      for (final i in o.items) {
        final old = foods[i.foodId];
        foods[i.foodId] = FoodPerformance(
          name: i.foodName,
          quantity: (old?.quantity ?? 0) + i.quantity,
          revenue: (old?.revenue ?? 0) + i.subtotal,
        );
      }
    }
    final top = foods.values.toList()
      ..sort((a, b) => b.quantity.compareTo(a.quantity));
    return AdminAnalytics(
      orders: orders,
      revenueByDay: revenue,
      ordersByHour: hours,
      topFoods: top.take(5).toList(),
    );
  }

  Future<void> sendBroadcast(String title, String body) async {
    await _run(() async {
      final users = await _db
          .collection(AppConstants.usersCollection)
          .where('role', isEqualTo: AppConstants.roleStudent)
          .get();
      final ref = await _db.collection('broadcasts').add({
        'title': title.trim(),
        'body': body.trim(),
        'sentAt': FieldValue.serverTimestamp(),
        'recipientCount': users.size,
      });
      await _notifications.queueBroadcastNotification(
        ref.id,
        title.trim(),
        body.trim(),
      );
    });
  }

  Future<String> exportRevenueCsv(AdminAnalytics data) async {
    final buffer = StringBuffer('Ngày,Doanh thu\n');
    final rows = data.revenueByDay.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    for (final row in rows) {
      buffer.writeln(
        '${DateFormat('yyyy-MM-dd').format(row.key)},${row.value.toStringAsFixed(0)}',
      );
    }
    final directory = await getApplicationDocumentsDirectory();
    final file = File(
      '${directory.path}${Platform.pathSeparator}doanh_thu_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv',
    );
    await file.writeAsString('\uFEFF$buffer');
    return file.path;
  }

  Future<void> _run(Future<void> Function() action) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await action();
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  static DateTime _date(dynamic value) =>
      value is Timestamp ? value.toDate() : DateTime.now();
}
