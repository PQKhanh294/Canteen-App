import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';

// Import Screens thuộc Module 1 của Khánh
import 'views/splash_screen.dart';
import 'views/onboarding/onboarding_screen.dart';
import 'views/auth/login_screen.dart';
import 'views/auth/register_screen.dart';
import 'views/auth/forgot_password_screen.dart';
import 'views/auth/change_password_screen.dart';
import 'views/student/main_navigation_screen.dart';
import 'views/student/home_screen.dart';
import 'views/student/profile_screen.dart';
import 'views/student/edit_profile_screen.dart';
import 'views/student/favorites_screen.dart';
import 'views/student/notification_settings_screen.dart';
import 'models/order_model.dart';
import 'views/admin/admin_broadcast_screen.dart';
import 'views/admin/admin_category_screen.dart';
import 'views/admin/admin_food_form_screen.dart';
import 'views/admin/admin_main_navigation.dart';
import 'views/admin/admin_order_detail_screen.dart';
import 'views/admin/admin_orders_screen.dart';

// Import Screens thuộc Module 2 của Hài
import 'views/student/search_screen.dart';
import 'views/student/food_detail_screen.dart';
import 'views/student/image_viewer_screen.dart';
import 'views/student/write_review_screen.dart';
import 'views/student/all_reviews_screen.dart';
import 'views/student/daily_special_screen.dart';
import 'models/food_model.dart';

// ============================================================
// LIB: app.dart
// Owner: ALL (Quản lý Route chính của ứng dụng)
// ============================================================

class CanteenApp extends StatelessWidget {
  const CanteenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Canteen App',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      // Màn hình khởi chạy đầu tiên là Splash
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/change-password': (context) => const ChangePasswordScreen(),
        '/main-nav': (context) => const MainNavigationScreen(),
        '/home': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/edit-profile': (context) => const EditProfileScreen(),
        '/favorites': (context) => const FavoritesScreen(),
        '/notification-settings': (context) => const NotificationSettingsScreen(),
        
        // === Routes thuộc Module 2 của Hài (Sinh viên) ===
        '/search': (context) => const SearchScreen(),
        '/food-detail': (context) => FoodDetailScreen(food: ModalRoute.of(context)!.settings.arguments as FoodModel),
        '/image-viewer': (context) => ImageViewerScreen(imageUrl: ModalRoute.of(context)!.settings.arguments as String),
        '/write-review': (context) => const WriteReviewScreen(),
        '/all-reviews': (context) => const AllReviewsScreen(),
        '/daily-special': (context) => const DailySpecialScreen(),
        
        // === Routes thuộc Module 4 của Quý (Admin) ===
        '/admin': (context) => const AdminMainNavigation(),
        '/admin/orders': (context) => const Scaffold(body: SafeArea(child: AdminOrdersScreen())),
        '/admin/categories': (context) => const AdminCategoryScreen(),
        '/admin/broadcast': (context) => const AdminBroadcastScreen(),
        '/admin/order-detail': (context) => AdminOrderDetailScreen(
          order: ModalRoute.of(context)!.settings.arguments as OrderModel,
        ),
        '/admin/food-form': (context) => AdminFoodFormScreen(
          food: ModalRoute.of(context)!.settings.arguments as FoodModel?,
        ),
      },
    );
  }
}
