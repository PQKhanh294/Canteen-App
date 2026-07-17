import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/food_model.dart';
import '../core/constants/app_colors.dart';
import 'canteen_card.dart';
import 'shimmer_loading.dart';

// ============================================================
// WIDGET: FoodCard
// Owner: Member 2 — Hài
// ============================================================

class FoodCard extends StatelessWidget {
  final FoodModel food;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;
  final VoidCallback? onToggleFavorite;
  final bool isFavorite;

  const FoodCard({
    super.key,
    required this.food,
    this.onTap,
    this.onAddToCart,
    this.onToggleFavorite,
    this.isFavorite = false,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final isNew = DateTime.now().difference(food.createdAt).inDays <= 7;
    final isBestSeller = food.totalReviews > 20;

    return CanteenCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Phần 1: Ảnh đại diện & các Badges (Mới, Hết hàng...)
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: CachedNetworkImage(
                  imageUrl: food.imageUrl.isNotEmpty
                      ? food.imageUrl
                      : 'https://via.placeholder.com/150',
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const ShimmerLoading(
                    width: double.infinity,
                    height: 120,
                    borderRadius: 0,
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 120,
                    color: AppColors.surfaceVariant,
                    child: const Icon(Icons.fastfood, color: Colors.grey, size: 40),
                  ),
                ),
              ),
              
              // Cụm Badges bên trái
              Positioned(
                top: 8,
                left: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!food.available)
                      _buildBadge('Hết hàng', AppColors.error),
                    if (food.available && isNew)
                      _buildBadge('Mới', AppColors.primary),
                    if (food.available && isBestSeller && !isNew)
                      _buildBadge('Bán chạy', AppColors.pending),
                  ],
                ),
              ),

              // Nút yêu thích bên phải
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: onToggleFavorite,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      size: 18,
                      color: isFavorite ? AppColors.error : AppColors.textHint,
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          // Phần 2: Nội dung chi tiết (Tên, Giá, Đánh giá)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    food.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      height: 1.2,
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: AppColors.star),
                      const SizedBox(width: 4),
                      Text(
                        food.avgRating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        ' (${food.totalReviews})',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          currencyFormatter.format(food.price),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: food.available ? onAddToCart : null,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: food.available 
                                ? AppColors.primary 
                                : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.add,
                            size: 18,
                            color: food.available ? Colors.white : AppColors.textHint,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
