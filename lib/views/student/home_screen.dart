import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/canteen_card.dart';
import '../../widgets/canteen_button.dart';
import '../../viewmodels/order_viewmodel.dart';
import '../../viewmodels/cart_viewmodel.dart';
import '../../models/order_model.dart';
import '../../core/enums/order_status.dart';
import 'order_detail_screen.dart';
import '../../viewmodels/menu_viewmodel.dart';
import '../../viewmodels/favorites_viewmodel.dart';
import '../../models/food_model.dart';
import '../../widgets/food_card.dart';
import '../../widgets/shimmer_loading.dart';

// ============================================================
// VIEW: views/student/home_screen.dart
// Owner: Member 1 — Khánh
// ============================================================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onShowCart});

  final VoidCallback? onShowCart;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _bannerController = PageController();
  int _activeBanner = 0;

  // Banner khuyến mãi ảo
  final List<String> _banners = [
    'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&q=80&w=800',
    'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?auto=format&fit=crop&q=80&w=800',
    'https://images.unsplash.com/photo-1484723091739-30a097e8f929?auto=format&fit=crop&q=80&w=800',
  ];

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final orderVM = context.watch<OrderViewModel>();
    final menuVM = context.watch<MenuViewModel>();
    final favoritesVM = context.watch<FavoritesViewModel>();
    final user = authVM.currentUser;
    final userName = user?.displayName ?? 'Sinh viên';

    OrderModel? latestCompletedOrder;
    for (final order in orderVM.orders) {
      if (order.status == OrderStatus.completed) {
        latestCompletedOrder = order;
        break;
      }
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Chào hỏi
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Xin chào, $userName 👋',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Hôm nay bạn muốn ăn gì nào?',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/profile');
                      },
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.primaryLight.withOpacity(
                          0.3,
                        ),
                        backgroundImage: user?.avatarUrl.isNotEmpty == true
                            ? NetworkImage(user!.avatarUrl)
                            : null,
                        child: user?.avatarUrl.isEmpty == true || user == null
                            ? const Icon(Icons.person, color: AppColors.primary)
                            : null,
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Banner quảng cáo tự chạy
              SizedBox(
                height: 160,
                child: PageView.builder(
                  controller: _bannerController,
                  onPageChanged: (index) {
                    setState(() {
                      _activeBanner = index;
                    });
                  },
                  itemCount: _banners.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        image: DecorationImage(
                          image: NetworkImage(_banners[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              // Dots indicators cho Banner
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _banners.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _activeBanner == index ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _activeBanner == index
                          ? AppColors.primary
                          : AppColors.divider,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 3. Section Danh mục món ăn
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  'Danh Mục Món Ăn',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 90,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: AppConstants.foodCategories.length,
                  itemBuilder: (context, index) {
                    final category = AppConstants.foodCategories[index];
                    return GestureDetector(
                      onTap: () {
                        // Sẽ trigger filter danh mục bên tab Menu khi Member 2 ráp
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 80,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.fastfood_outlined,
                                color: AppColors.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              category,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // 4. Món Hôm Nay (Featured)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Món Đặc Biệt Hôm Nay 🔥',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/daily-special');
                      },
                      child: const Text(
                        'Xem tất cả',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Grid hiển thị món đặc biệt hôm nay lấy từ Firestore
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: StreamBuilder<List<FoodModel>>(
                  stream: menuVM.foodsStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return ShimmerLoading.foodListSkeleton();
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Lỗi: ${snapshot.error}'));
                    }

                    final allFoods = snapshot.data ?? [];
                    var specialFoods = allFoods.where((f) => f.avgRating >= 4.5).toList();
                    if (specialFoods.isEmpty) {
                      // Fallback: hiển thị các món có sẵn đầu tiên nếu chưa có rating
                      specialFoods = allFoods.take(4).toList();
                    }

                    if (specialFoods.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24.0),
                          child: Text(
                            'Hôm nay chưa có món đặc biệt nào.',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                          ),
                        ),
                      );
                    }

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.7,
                      ),
                      itemCount: specialFoods.length.clamp(0, 4), // Hiển thị tối đa 4 món
                      itemBuilder: (context, index) {
                        final food = specialFoods[index];
                        return FoodCard(
                          food: food,
                          isFavorite: favoritesVM.isFavorite(food.id),
                          onTap: () {
                            Navigator.pushNamed(context, '/food-detail', arguments: food);
                          },
                          onAddToCart: () async {
                            final result = await context.read<CartViewModel>().addItem(food);
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
              ),
              const SizedBox(height: 24),

              // 5. Đặt lại nhanh (Quick Reorder)
              if (latestCompletedOrder != null) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    'Đặt Lại Nhanh',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: CanteenCard(
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: NetworkImage(
                                latestCompletedOrder
                                        .items
                                        .first
                                        .imageUrl
                                        .isNotEmpty
                                    ? latestCompletedOrder.items.first.imageUrl
                                    : 'https://images.unsplash.com/photo-1484723091739-30a097e8f929?auto=format&fit=crop&q=80&w=200',
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                latestCompletedOrder.items.first.foodName +
                                    (latestCompletedOrder.items.length > 1
                                        ? ' và ${latestCompletedOrder.items.length - 1} món khác'
                                        : ''),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Đặt ngày: ${latestCompletedOrder.createdAt != null ? DateFormat('dd/MM/yyyy').format(latestCompletedOrder.createdAt!) : 'Gần đây'}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        orderVM.isReorderingOrder(latestCompletedOrder.id)
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              )
                            : IconButton(
                                icon: const Icon(
                                  Icons.replay,
                                  color: AppColors.primary,
                                ),
                                onPressed: () => _handleQuickReorder(
                                  context,
                                  latestCompletedOrder!,
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleQuickReorder(
    BuildContext context,
    OrderModel order,
  ) async {
    final cartVM = context.read<CartViewModel>();
    final orderVM = context.read<OrderViewModel>();

    final result = await orderVM.reorder(order: order, cartViewModel: cartVM);

    if (!context.mounted) return;

    if (!result.hasAddedItems) {
      await _showReorderResultSheet(context, result, hasAddedItems: false);
      return;
    }

    if (result.hasSkippedItems) {
      await _showReorderResultSheet(context, result, hasAddedItems: true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã đặt lại đơn hàng thành công.'),
          backgroundColor: AppColors.success,
        ),
      );
      widget.onShowCart?.call();
    }
  }

  Future<void> _showReorderResultSheet(
    BuildContext context,
    ReorderResult result, {
    required bool hasAddedItems,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      hasAddedItems
                          ? Icons.check_circle_outline
                          : Icons.error_outline,
                      color: hasAddedItems
                          ? AppColors.success
                          : AppColors.error,
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        hasAddedItems
                            ? 'Đặt lại đơn hàng một phần'
                            : 'Không thể đặt lại đơn hàng',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (hasAddedItems)
                  Text(
                    'Đã thêm ${result.addedQuantity} món vào giỏ hàng thành công. Các món dưới đây bị bỏ qua:',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  )
                else
                  const Text(
                    'Các món trong đơn hiện không còn được bán hoặc đang hết hàng.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                const SizedBox(height: 16),
                if (result.deletedFoods.isNotEmpty) ...[
                  const Text(
                    'Món ăn đã ngừng kinh doanh:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  ...result.deletedFoods.map(
                    (name) => Padding(
                      padding: const EdgeInsets.only(left: 12.0, top: 4.0),
                      child: Text(
                        '• $name',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (result.unavailableFoods.isNotEmpty) ...[
                  const Text(
                    'Món ăn hiện đã hết hàng:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  ...result.unavailableFoods.map(
                    (name) => Padding(
                      padding: const EdgeInsets.only(left: 12.0, top: 4.0),
                      child: Text(
                        '• $name',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (result.failedFoods.isNotEmpty) ...[
                  const Text(
                    'Món ăn không thể thêm (Vượt giới hạn 99 món):',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  ...result.failedFoods.map(
                    (name) => Padding(
                      padding: const EdgeInsets.only(left: 12.0, top: 4.0),
                      child: Text(
                        '• $name',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.divider),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'Đóng',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    if (hasAddedItems) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: CanteenButton(
                          text: 'Xem giỏ hàng',
                          onPressed: () {
                            Navigator.pop(context); // Close result sheet
                            widget.onShowCart?.call(); // Switch tab
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
