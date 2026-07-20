import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';

// Import Services
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';
import 'services/cart_storage_service.dart';

// Import ViewModels
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/menu_viewmodel.dart';
import 'viewmodels/cart_viewmodel.dart';
import 'viewmodels/order_viewmodel.dart';
import 'viewmodels/review_viewmodel.dart';
import 'viewmodels/admin_viewmodel.dart';
import 'viewmodels/promo_viewmodel.dart';
import 'viewmodels/favorites_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // NOTE: Nhóm trưởng Khánh cần cấu hình Firebase trước khi bỏ comment dòng này
  await Firebase.initializeApp();
  // Initialize Firebase with error handling
  try {
    await Firebase.initializeApp();
    debugPrint('Firebase initialized successfully');
    
    // Tự động seeding dữ liệu nếu các collections trống
    final firestore = FirestoreService();
    await firestore.seedDataIfNeeded();
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
    // Continue without Firebase for now
  }

  runApp(
    MultiProvider(
      providers: [
        // Services
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        Provider<StorageService>(create: (_) => StorageService()),
        Provider<NotificationService>(create: (_) => NotificationService()),
        Provider<CartStorageService>(create: (_) => CartStorageService()),

        // ViewModels phụ thuộc vào Services
        ChangeNotifierProxyProvider2<
          AuthService,
          NotificationService,
          AuthViewModel
        >(
          create: (context) => AuthViewModel(
            context.read<AuthService>(),
            context.read<NotificationService>(),
          ),
          update: (context, authService, notificationService, previous) =>
              previous ?? AuthViewModel(authService, notificationService),
        ),
        ChangeNotifierProxyProvider<FirestoreService, MenuViewModel>(
          create: (context) => MenuViewModel(context.read<FirestoreService>()),
          update: (context, firestoreService, previous) =>
              previous ?? MenuViewModel(firestoreService),
        ),
        ChangeNotifierProxyProvider<AuthViewModel, CartViewModel>(
          create: (context) => CartViewModel(
            storageService: context.read<CartStorageService>(),
            firestoreService: context.read<FirestoreService>(),
          ),
          update: (context, authViewModel, previousCartViewModel) {
            final cartViewModel =
                previousCartViewModel ??
                CartViewModel(
                  storageService: context.read<CartStorageService>(),
                  firestoreService: context.read<FirestoreService>(),
                );
            cartViewModel.syncUser(authViewModel.currentUser?.uid);
            return cartViewModel;
          },
        ),
        ChangeNotifierProxyProvider2<FirestoreService, AuthViewModel, OrderViewModel>(
          create: (context) => OrderViewModel(
            firestoreService: context.read<FirestoreService>(),
          ),
          update: (context, firestoreService, authViewModel, previous) {
            final orderVM = previous ??
                OrderViewModel(
                  firestoreService: firestoreService,
                );
            orderVM.syncUser(authViewModel.currentUser?.uid);
            return orderVM;
          },
        ),
        ChangeNotifierProxyProvider<FirestoreService, ReviewViewModel>(
          create: (context) =>
              ReviewViewModel(context.read<FirestoreService>()),
          update: (context, firestoreService, previous) =>
              previous ?? ReviewViewModel(firestoreService),
        ),
        ChangeNotifierProxyProvider2<
          StorageService,
          NotificationService,
          AdminViewModel
        >(
          create: (context) => AdminViewModel(
            context.read<StorageService>(),
            context.read<NotificationService>(),
          ),
          update: (context, storage, notifications, previous) =>
              previous ?? AdminViewModel(storage, notifications),
        ChangeNotifierProxyProvider<FirestoreService, PromoViewModel>(
          create: (context) =>
              PromoViewModel(firestoreService: context.read<FirestoreService>())
                ..listenPromos(),
          update: (context, firestoreService, previous) =>
              previous ??
              (PromoViewModel(firestoreService: firestoreService)
                ..listenPromos()),
        ),
        ChangeNotifierProxyProvider<AuthViewModel, FavoritesViewModel>(
          create: (context) => FavoritesViewModel(),
          update: (context, authViewModel, previous) {
            final favoritesVM = previous ?? FavoritesViewModel();
            favoritesVM.syncUser(authViewModel.currentUser?.uid);
            return favoritesVM;
          },
        ),
      ],
      child: const CanteenApp(),
    ),
  );
}
