import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================
// VIEWMODEL: FavoritesViewModel
// Owner: Member 2 — Hài
// Mô tả: Quản lý danh sách món ăn yêu thích, lưu trữ cục bộ theo userId
// ============================================================

class FavoritesViewModel extends ChangeNotifier {
  String? _userId;
  List<String> _favoriteIds = [];

  List<String> get favoriteIds => _favoriteIds;

  void syncUser(String? userId) {
    final nextUserId = userId?.trim();
    if (_userId == nextUserId) return;
    _userId = nextUserId;
    _favoriteIds = [];
    if (nextUserId != null && nextUserId.isNotEmpty) {
      _loadFavorites();
    } else {
      notifyListeners();
    }
  }

  String _storageKey(String userId) => 'favorites_$userId';

  Future<void> _loadFavorites() async {
    if (_userId == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _favoriteIds = prefs.getStringList(_storageKey(_userId!)) ?? [];
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    }
  }

  bool isFavorite(String foodId) {
    return _favoriteIds.contains(foodId);
  }

  Future<void> toggleFavorite(String foodId) async {
    if (_userId == null) return;
    if (_favoriteIds.contains(foodId)) {
      _favoriteIds.remove(foodId);
    } else {
      _favoriteIds.add(foodId);
    }
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_storageKey(_userId!), _favoriteIds);
    } catch (e) {
      debugPrint('Error saving favorites: $e');
    }
  }
}
