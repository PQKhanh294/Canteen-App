import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../viewmodels/menu_viewmodel.dart';
import '../../viewmodels/cart_viewmodel.dart';
import '../../core/enums/cart_action_result.dart';
import '../../widgets/food_card.dart';
import '../../core/constants/app_colors.dart';
import '../../viewmodels/favorites_viewmodel.dart';

// ============================================================
// VIEW: views/student/search_screen.dart
// Owner: Member 2 — Hài
// ============================================================

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<String> _recentSearches = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    // Clear search query in VM when leaving
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<MenuViewModel>().setSearchQuery('');
      }
    });
    super.dispose();
  }

  void _showCartResult(BuildContext context, CartActionResult result, String foodName) {
    final String message;
    final bool isSuccess;

    switch (result) {
      case CartActionResult.success:
        message = 'Đã thêm $foodName vào giỏ hàng.';
        isSuccess = true;
        break;
      case CartActionResult.unavailable:
        message = 'Món ăn hiện đang hết hàng.';
        isSuccess = false;
        break;
      case CartActionResult.maximumQuantityReached:
        message = 'Số lượng tối đa cho mỗi món là 99.';
        isSuccess = false;
        break;
      case CartActionResult.notInitialized:
        message = 'Giỏ hàng đang được khởi tạo. Vui lòng thử lại.';
        isSuccess = false;
        break;
      case CartActionResult.persistenceFailed:
        message = 'Không thể lưu giỏ hàng. Vui lòng thử lại.';
        isSuccess = false;
        break;
      default:
        message = 'Không thể thêm món vào giỏ hàng.';
        isSuccess = false;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: isSuccess ? AppColors.primary : AppColors.error,
        ),
      );
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches = prefs.getStringList('recent_searches') ?? [];
    });
  }

  Future<void> _saveRecentSearch(String query) async {
    if (query.trim().isEmpty) return;
    
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList('recent_searches') ?? [];
    
    // Remove if exists to put it at the top
    history.remove(query);
    history.insert(0, query);
    
    // Keep only last 10 searches
    if (history.length > 10) {
      history = history.sublist(0, 10);
    }
    
    await prefs.setStringList('recent_searches', history);
    setState(() {
      _recentSearches = history;
    });
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('recent_searches');
    setState(() {
      _recentSearches = [];
    });
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    setState(() {
      _isSearching = _searchController.text.trim().isNotEmpty;
    });

    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        context.read<MenuViewModel>().setSearchQuery(_searchController.text.trim());
      }
    });
  }

  void _submitSearch(String query) {
    _searchController.text = query;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: query.length),
    );
    _saveRecentSearch(query.trim());
  }

  @override
  Widget build(BuildContext context) {
    final menuVM = context.watch<MenuViewModel>();
    final favoritesVM = context.watch<FavoritesViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        titleSpacing: 0,
        title: TextField(
          controller: _searchController,
          autofocus: true,
          onSubmitted: _submitSearch,
          decoration: InputDecoration(
            hintText: 'Tìm kiếm món ăn...',
            hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 16),
            border: InputBorder.none,
            suffixIcon: _isSearching
                ? IconButton(
                    icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                    onPressed: () {
                      _searchController.clear();
                    },
                  )
                : null,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Divider(height: 1),
            // Hiển thị Lịch sử tìm kiếm hoặc Kết quả tìm kiếm
            Expanded(
              child: !_isSearching && _recentSearches.isNotEmpty
                  ? _buildRecentSearches()
                  : _buildSearchResults(menuVM, favoritesVM),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSearches() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Tìm kiếm gần đây',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: _clearHistory,
              child: const Text('Xóa', style: TextStyle(color: AppColors.textHint)),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _recentSearches.map((query) {
            return ActionChip(
              label: Text(query),
              backgroundColor: AppColors.surface,
              side: const BorderSide(color: AppColors.divider),
              labelStyle: const TextStyle(color: AppColors.textSecondary),
              onPressed: () => _submitSearch(query),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSearchResults(MenuViewModel menuVM, FavoritesViewModel favoritesVM) {
    if (!_isSearching) {
      return const Center(
        child: Text(
          'Nhập tên món ăn để tìm kiếm',
          style: TextStyle(color: AppColors.textHint, fontSize: 16),
        ),
      );
    }

    return StreamBuilder(
      stream: menuVM.foodsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        }

        final allFoods = snapshot.data ?? [];
        final foods = menuVM.filterBySearch(allFoods);

        if (foods.isEmpty) {
          return const Center(
            child: Text(
              'Không tìm thấy món ăn nào 😢',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.7,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: foods.length,
          itemBuilder: (context, index) {
            final food = foods[index];
            return FoodCard(
              food: food,
              isFavorite: favoritesVM.isFavorite(food.id),
              onTap: () {
                _saveRecentSearch(_searchController.text.trim());
                Navigator.pushNamed(context, '/food-detail', arguments: food);
              },
              onAddToCart: () async {
                final result = await context.read<CartViewModel>().addItem(food);
                if (!context.mounted) return;
                _showCartResult(context, result, food.name);
              },
              onToggleFavorite: () {
                favoritesVM.toggleFavorite(food.id);
              },
            );
          },
        );
      },
    );
  }
}
