import 'package:flutter/material.dart';
import '../models/food_model.dart';
import '../services/firestore_service.dart';

// ============================================================
// LIB: viewmodels/menu_viewmodel.dart
// Owner: Member 2 — Hài
// ============================================================

class MenuViewModel extends ChangeNotifier {
  final FirestoreService _firestoreService;

  MenuViewModel(this._firestoreService);

  String _selectedCategory = '';
  String _searchQuery = '';
  
  String _selectedSort = 'Mới nhất';
  String _selectedPriceRange = 'Tất cả';
  bool _availableOnly = false;

  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  
  String get selectedSort => _selectedSort;
  String get selectedPriceRange => _selectedPriceRange;
  bool get availableOnly => _availableOnly;

  Stream<List<FoodModel>> get foodsStream =>
      _firestoreService.getFoodsStream(category: _selectedCategory.isEmpty ? null : _selectedCategory);

  void setCategory(String category) {
    _selectedCategory = category == _selectedCategory ? '' : category;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void applyFilters({
    required String sort,
    required String priceRange,
    required bool availableOnly,
  }) {
    _selectedSort = sort;
    _selectedPriceRange = priceRange;
    _availableOnly = availableOnly;
    notifyListeners();
  }

  void resetFilters() {
    _selectedSort = 'Mới nhất';
    _selectedPriceRange = 'Tất cả';
    _availableOnly = false;
    notifyListeners();
  }

  List<FoodModel> filterBySearch(List<FoodModel> foods) {
    if (_searchQuery.isEmpty) return foods;
    return foods
        .where((f) => f.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  List<FoodModel> applySortingAndFiltering(List<FoodModel> foods) {
    var result = List<FoodModel>.from(foods);

    // 1. Lọc theo tình trạng còn hàng
    if (_availableOnly) {
      result = result.where((f) => f.available).toList();
    }

    // 2. Lọc theo khoảng giá
    if (_selectedPriceRange != 'Tất cả') {
      if (_selectedPriceRange == 'Dưới 20k') {
        result = result.where((f) => f.price < 20000).toList();
      } else if (_selectedPriceRange == '20k - 50k') {
        result = result.where((f) => f.price >= 20000 && f.price <= 50000).toList();
      } else if (_selectedPriceRange == 'Trên 50k') {
        result = result.where((f) => f.price > 50000).toList();
      }
    }

    // 3. Sắp xếp
    if (_selectedSort == 'Mới nhất') {
      result.sort((first, second) => second.createdAt.compareTo(first.createdAt));
    } else if (_selectedSort == 'Giá tăng dần') {
      result.sort((first, second) => first.price.compareTo(second.price));
    } else if (_selectedSort == 'Giá giảm dần') {
      result.sort((first, second) => second.price.compareTo(first.price));
    } else if (_selectedSort == 'Đánh giá cao') {
      result.sort((first, second) => second.avgRating.compareTo(first.avgRating));
    }

    return result;
  }
}
