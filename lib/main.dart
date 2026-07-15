import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';

// Import Services
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';

// Import ViewModels
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/menu_viewmodel.dart';
import 'viewmodels/cart_viewmodel.dart';
import 'viewmodels/order_viewmodel.dart';
import 'viewmodels/review_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // NOTE: Nhóm trưởng Khánh cần cấu hình Firebase trước khi bỏ comment dòng này
  await Firebase.initializeApp();

  runApp(
    MultiProvider(
      providers: [
        // Services
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        Provider<StorageService>(create: (_) => StorageService()),
        Provider<NotificationService>(create: (_) => NotificationService()),

        // ViewModels phụ thuộc vào Services
        ChangeNotifierProxyProvider2<AuthService, NotificationService, AuthViewModel>(
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
        ChangeNotifierProxyProvider<FirestoreService, CartViewModel>(
          create: (context) => CartViewModel(context.read<FirestoreService>()),
          update: (context, firestoreService, previous) =>
              previous ?? CartViewModel(firestoreService),
        ),
        ChangeNotifierProxyProvider<FirestoreService, OrderViewModel>(
          create: (context) => OrderViewModel(context.read<FirestoreService>()),
          update: (context, firestoreService, previous) =>
              previous ?? OrderViewModel(firestoreService),
        ),
        ChangeNotifierProxyProvider<FirestoreService, ReviewViewModel>(
          create: (context) => ReviewViewModel(context.read<FirestoreService>()),
          update: (context, firestoreService, previous) =>
              previous ?? ReviewViewModel(firestoreService),
        ),
      ],
      child: const CanteenApp(),
    ),
  );
}
