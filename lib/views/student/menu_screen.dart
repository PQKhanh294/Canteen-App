import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/menu_viewmodel.dart';
import '../../viewmodels/cart_viewmodel.dart';
import '../../core/enums/cart_action_result.dart';
import '../../widgets/food_card.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/filter_bottom_sheet.dart';
import '../../core/constants/app_colors.dart';

// ============================================================
// VIEW: views/student/menu_screen.dart
// Owner: Member 2 — Hài
// ============================================================

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final List<String> _categories = [
    'Cơm',
    'Bún/Phở',
    'Nước',
    'Tráng miệng',
    'Ăn vặt',
  ];

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

  @override
  Widget build(BuildContext context) {
    final menuVM = context.watch<MenuViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Thực Đơn'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const FilterBottomSheet(),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Thanh tìm kiếm (Click chuyển sang SearchScreen)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/search');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.search, color: AppColors.textHint),
                      SizedBox(width: 8),
                      Text(
                        'Tìm kiếm món ăn...',
                        style: TextStyle(color: AppColors.textHint, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Danh sách Category Chips
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                itemCount: _categories.length + 1,
                itemBuilder: (context, index) {
                  final isAll = index == 0;
                  final category = isAll ? '' : _categories[index - 1];
                  final isSelected = menuVM.selectedCategory == category;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ChoiceChip(
                      label: Text(isAll ? 'Tất cả' : category),
                      selected: isSelected,
                      onSelected: (selected) {
                        menuVM.setCategory(category);
                      },
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      backgroundColor: AppColors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? AppColors.primary : AppColors.divider,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // Danh sách món ăn
            Expanded(
              child: StreamBuilder(
                stream: menuVM.foodsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return ShimmerLoading.foodListSkeleton();
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Lỗi: ${snapshot.error}'));
                  }

                  final allFoods = snapshot.data ?? [];
                  // Lọc theo keyword nếu MenuVM đang giữ state search
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
                        onTap: () {
                          Navigator.pushNamed(context, '/food-detail', arguments: food);
                        },
                        onAddToCart: () async {
                          final result = await context.read<CartViewModel>().addItem(food);
                          if (!context.mounted) return;
                          _showCartResult(context, result, food.name);
                        },
                        onToggleFavorite: () {
                          // TODO: Connect to Favorites logic
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
