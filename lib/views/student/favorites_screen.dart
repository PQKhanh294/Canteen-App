import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/food_model.dart';
import '../../widgets/food_card.dart';
import '../../viewmodels/favorites_viewmodel.dart';
import '../../viewmodels/menu_viewmodel.dart';
import '../../viewmodels/cart_viewmodel.dart';

// ============================================================
// VIEW: views/student/favorites_screen.dart
// Owner: Member 1 — Khánh
// ============================================================

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  Widget build(BuildContext context) {
    final favoritesVM = context.watch<FavoritesViewModel>();
    final menuVM = context.watch<MenuViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Món Ăn Yêu Thích'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        titleTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<List<FoodModel>>(
        stream: menuVM.foodsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          final allFoods = snapshot.data ?? [];
          final favoriteFoods =
              allFoods.where((f) => favoritesVM.isFavorite(f.id)).toList();

          if (favoriteFoods.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.favorite_border,
                    size: 80,
                    color: AppColors.textHint,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Chưa có món ăn yêu thích nào',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.7,
            ),
            itemCount: favoriteFoods.length,
            itemBuilder: (context, index) {
              final food = favoriteFoods[index];
              return FoodCard(
                food: food,
                isFavorite: true,
                onTap: () {
                  Navigator.pushNamed(context, '/food-detail', arguments: food);
                },
                onAddToCart: () async {
                  final result =
                      await context.read<CartViewModel>().addItem(food);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(
                        content: Text('Đã thêm ${food.name} vào giỏ hàng.'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                },
                onToggleFavorite: () {
                  favoritesVM.toggleFavorite(food.id);
                },
              );
            },
          );
        },
      ),
    );
  }
}
