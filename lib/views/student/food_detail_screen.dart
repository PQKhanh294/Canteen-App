import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/food_model.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/canteen_button.dart';
import '../../viewmodels/cart_viewmodel.dart';
import '../../core/enums/cart_action_result.dart';

// ============================================================
// VIEW: views/student/food_detail_screen.dart
// Owner: Member 2 — Hài
// ============================================================

class FoodDetailScreen extends StatefulWidget {
  final FoodModel food;

  const FoodDetailScreen({super.key, required this.food});

  @override
  State<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends State<FoodDetailScreen> {
  int _quantity = 1;
  bool _isFavorite = false;
  bool _isAddingToCart = false;

  void _showCartResult(BuildContext context, CartActionResult result) {
    final String message;
    final bool isSuccess;

    switch (result) {
      case CartActionResult.success:
        message = 'Đã thêm ${widget.food.name} vào giỏ hàng.';
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

  Future<void> _handleAddToCart() async {
    if (_isAddingToCart) return;

    setState(() {
      _isAddingToCart = true;
    });

    final result = await context.read<CartViewModel>().addItem(
          widget.food,
          quantity: _quantity,
        );

    if (!mounted) return;

    setState(() {
      _isAddingToCart = false;
    });

    _showCartResult(context, result);
    if (result == CartActionResult.success) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final totalPrice = widget.food.price * _quantity;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Ảnh tràn viền
          SliverAppBar(
            expandedHeight: 250.0,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorite ? AppColors.error : Colors.white,
                ),
                onPressed: () {
                  setState(() => _isFavorite = !_isFavorite);
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/image-viewer', arguments: widget.food.imageUrl);
                },
                child: Hero(
                  tag: widget.food.id,
                  child: CachedNetworkImage(
                    imageUrl: widget.food.imageUrl.isNotEmpty
                        ? widget.food.imageUrl
                        : 'https://via.placeholder.com/400',
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Nội dung chi tiết
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(20.0),
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              transform: Matrix4.translationValues(0.0, -20.0, 0.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.food.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        currencyFormatter.format(widget.food.price),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Đánh giá nhanh
                  Row(
                    children: [
                      const Icon(Icons.star, color: AppColors.star, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        widget.food.avgRating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${widget.food.totalReviews} đánh giá)',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/all-reviews',
                          arguments: {
                            'foodId': widget.food.id,
                            'foodName': widget.food.name,
                          },
                        ),
                        child: const Text(
                          'Xem tất cả',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  const Text(
                    'Mô tả món ăn',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.food.description.isNotEmpty 
                        ? widget.food.description 
                        : 'Chưa có mô tả cho món ăn này.',
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Nutritional Info Card
                  if (widget.food.calories > 0) _buildNutritionCard(),
                  const SizedBox(height: 24),
                  
                  // Khối Rating Breakdown
                  _buildRatingBreakdown(),
                  
                  const SizedBox(height: 100), // Khoảng trống cho nút bottom
                ],
              ),
            ),
          ),
        ],
      ),
      
      // Bottom Bar (Sticky)
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Nút tăng giảm số lượng
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, color: AppColors.textPrimary),
                      onPressed: () {
                        if (_quantity > 1) setState(() => _quantity--);
                      },
                    ),
                    Text(
                      '$_quantity',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, color: AppColors.textPrimary),
                      onPressed: () {
                        setState(() => _quantity++);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Nút thêm vào giỏ
              Expanded(
                child: CanteenButton(
                  text: widget.food.available
                      ? 'Thêm • ${currencyFormatter.format(totalPrice)}'
                      : 'MÓN ĐÃ HẾT',
                  isLoading: _isAddingToCart,
                  onPressed: widget.food.available && !_isAddingToCart
                      ? _handleAddToCart
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingBreakdown() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Đánh giá chi tiết',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              GestureDetector(
                onTap: () => Navigator.pushNamed(
                  context,
                  '/write-review',
                  arguments: {
                    'foodId': widget.food.id,
                    'foodName': widget.food.name,
                  },
                ),
                child: const Text(
                  'Viết đánh giá',
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRatingBar(5, 0.7),
          _buildRatingBar(4, 0.2),
          _buildRatingBar(3, 0.05),
          _buildRatingBar(2, 0.03),
          _buildRatingBar(1, 0.02),
        ],
      ),
    );
  }

  Widget _buildRatingBar(int star, double percent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text('$star', style: const TextStyle(fontWeight: FontWeight.bold)),
          const Icon(Icons.star, size: 14, color: AppColors.star),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percent,
                backgroundColor: Colors.white,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_fire_department, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Thông tin dinh dưỡng',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${widget.food.calories} kcal',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildNutrientItem('Đạm', '${widget.food.protein.toStringAsFixed(1)}g', const Color(0xFF1E88E5)),
              _buildNutrientItem('Tinh bột', '${widget.food.carbs.toStringAsFixed(1)}g', const Color(0xFFFF8F00)),
              _buildNutrientItem('Chất béo', '${widget.food.fat.toStringAsFixed(1)}g', const Color(0xFFE53935)),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bars
          _buildNutrientBar('Đạm (Protein)', widget.food.protein, 60, const Color(0xFF1E88E5)),
          const SizedBox(height: 6),
          _buildNutrientBar('Tinh bột (Carbs)', widget.food.carbs, 100, const Color(0xFFFF8F00)),
          const SizedBox(height: 6),
          _buildNutrientBar('Chất béo (Fat)', widget.food.fat, 70, const Color(0xFFE53935)),
        ],
      ),
    );
  }

  Widget _buildNutrientItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                value,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientBar(String label, double value, double max, Color color) {
    final percent = (value / max).clamp(0.0, 1.0);
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ),
      ],
    );
  }
}
