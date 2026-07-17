import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item_model.dart';

// ============================================================
// SERVICE: CartStorageService
// Owner: Member 3 — An
// Mô tả: Quản lý lưu trữ giỏ hàng cục bộ bằng SharedPreferences
// ============================================================

class CartStorageService {
  static const String _cartKeyPrefix = 'cart_';

  String _buildCartKey(String userId) {
    final normalizedUserId = userId.trim();

    if (normalizedUserId.isEmpty) {
      throw ArgumentError.value(
        userId,
        'userId',
        'User ID must not be empty.',
      );
    }

    return '$_cartKeyPrefix$normalizedUserId';
  }

  Future<List<CartItemModel>> loadCart(String userId) async {
    final preferences = await SharedPreferences.getInstance();
    final key = _buildCartKey(userId);
    final rawJson = preferences.getString(key);

    if (rawJson == null || rawJson.trim().isEmpty) {
      return <CartItemModel>[];
    }

    try {
      final decoded = jsonDecode(rawJson);

      if (decoded is! List<dynamic>) {
        throw const FormatException(
          'Cart data must be a JSON list.',
        );
      }

      return decoded
          .whereType<Map>()
          .map(
            (item) => CartItemModel.fromMap(
              Map<String, dynamic>.from(item),
            ),
          )
          .where(
            (item) =>
                item.foodId.trim().isNotEmpty &&
                item.unitPrice >= 0 &&
                item.quantity >= 1,
          )
          .toList();
    } catch (error, stackTrace) {
      debugPrint(
        'Could not decode cart for user $userId: '
        '$error\n$stackTrace',
      );

      // Dữ liệu local lỗi không được làm ứng dụng crash.
      await preferences.remove(key);
      return <CartItemModel>[];
    }
  }

  Future<void> saveCart(
    String userId,
    List<CartItemModel> items,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    final key = _buildCartKey(userId);

    if (items.isEmpty) {
      await preferences.remove(key);
      return;
    }

    final rawJson = jsonEncode(
      items.map((item) => item.toMap()).toList(),
    );

    final saved = await preferences.setString(key, rawJson);

    if (!saved) {
      throw StateError('Could not save cart data.');
    }
  }

  Future<void> clearCart(String userId) async {
    final preferences = await SharedPreferences.getInstance();
    final key = _buildCartKey(userId);

    await preferences.remove(key);
  }
}
