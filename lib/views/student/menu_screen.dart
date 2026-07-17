import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/menu_viewmodel.dart';
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
                        onAddToCart: () {
                          // TODO: Connect to CartVM
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Đã thêm ${food.name} vào giỏ hàng'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
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
