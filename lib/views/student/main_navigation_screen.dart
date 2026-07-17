import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/cart_viewmodel.dart';
import '../../core/constants/app_colors.dart';

// Import Screens cho từng Tab
import 'home_screen.dart';
import 'profile_screen.dart';
import 'menu_screen.dart';
import 'cart_screen.dart';
import 'order_history_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const HomeScreen(),
      const MenuScreen(),
      CartScreen(
        onExploreMenu: () {
          setState(() {
            _selectedIndex = 1; // MenuScreen
          });
        },
        onGoHome: () {
          setState(() {
            _selectedIndex = 0; // HomeScreen
          });
        },
        onShowOrders: () {
          setState(() {
            _selectedIndex = 3; // OrderHistoryScreen
          });
        },
      ),
      OrderHistoryScreen(
        onExploreMenu: () {
          setState(() {
            _selectedIndex = 1; // MenuScreen
          });
        },
      ),
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final cartItemCount = context.select<CartViewModel, int>(
      (cart) => cart.totalQuantity,
    );

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu_outlined),
            activeIcon: Icon(Icons.restaurant_menu),
            label: 'Thực đơn',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.shopping_cart_outlined),
                if (cartItemCount > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$cartItemCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            activeIcon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.shopping_cart),
                if (cartItemCount > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$cartItemCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Giỏ hàng',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment),
            label: 'Đơn hàng',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Tôi',
          ),
        ],
      ),
    );
  }
}
