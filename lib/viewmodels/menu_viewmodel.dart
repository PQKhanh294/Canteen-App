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

  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;

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

  List<FoodModel> filterBySearch(List<FoodModel> foods) {
    if (_searchQuery.isEmpty) return foods;
    return foods
        .where((f) => f.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }
}
