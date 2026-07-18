import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import 'admin_customer_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_food_list_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_stats_screen.dart';

class AdminMainNavigation extends StatefulWidget {
  const AdminMainNavigation({super.key});
  @override
  State<AdminMainNavigation> createState() => _AdminMainNavigationState();
}

class _AdminMainNavigationState extends State<AdminMainNavigation> {
  int index = 0;
  static const screens = [
    AdminDashboardScreen(),
    AdminOrdersScreen(),
    AdminFoodListScreen(),
    AdminCustomerScreen(),
    AdminStatsScreen(),
  ];
  static const labels = [
    'Tổng quan',
    'Đơn hàng',
    'Thực đơn',
    'Khách hàng',
    'Thống kê',
  ];
  static const icons = [
    Icons.dashboard_outlined,
    Icons.receipt_long_outlined,
    Icons.restaurant_menu,
    Icons.people_outline,
    Icons.bar_chart,
  ];
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(labels[index]),
      actions: [
        IconButton(
          tooltip: 'Thông báo hàng loạt',
          onPressed: () => Navigator.pushNamed(context, '/admin/broadcast'),
          icon: const Icon(Icons.campaign_outlined),
        ),
        IconButton(
          tooltip: 'Danh mục & ưu đãi',
          onPressed: () => Navigator.pushNamed(context, '/admin/categories'),
          icon: const Icon(Icons.settings_outlined),
        ),
      ],
    ),
    body: IndexedStack(index: index, children: screens),
    bottomNavigationBar: NavigationBar(
      selectedIndex: index,
      indicatorColor: AppColors.primaryLight.withValues(alpha: .2),
      onDestinationSelected: (value) => setState(() => index = value),
      destinations: List.generate(
        labels.length,
        (i) => NavigationDestination(icon: Icon(icons[i]), label: labels[i]),
      ),
    ),
  );
}
