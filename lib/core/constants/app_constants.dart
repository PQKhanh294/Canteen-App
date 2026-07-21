// ============================================================
// LIB: core/constants/app_constants.dart
// Owner: ALL (đọc, không sửa tự ý)
// ============================================================

class AppConstants {
  // Firestore collection names
  static const String usersCollection = 'users';
  static const String foodsCollection = 'foods';
  static const String ordersCollection = 'orders';
  static const String reviewsCollection = 'reviews';
  static const String promosCollection = 'promos';
  static const String categoriesCollection = 'categories';

  // Order status
  static const String statusPending = 'pending';
  static const String statusPreparing = 'preparing';
  static const String statusReady = 'ready';
  static const String statusCompleted = 'completed';
  static const String statusCancelled = 'cancelled';

  // User roles
  static const String roleStudent = 'student';
  static const String roleAdmin = 'admin';

  // Food categories
  static const List<String> foodCategories = [
    'Cơm',
    'Bún/Phở',
    'Nước',
    'Tráng miệng',
    'Ăn vặt',
  ];

  // Pickup time slots
  static const List<String> pickupTimeSlots = [
    '11:00',
    '11:30',
    '12:00',
    '12:30',
    '17:00',
    '17:30',
  ];

  // Payment methods
  static const String paymentCash = 'cash';
  static const String paymentEwallet = 'ewallet';
}
