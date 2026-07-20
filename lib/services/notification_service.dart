import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';

// ============================================================
// LIB: services/notification_service.dart
// Owner: Member 4 — Quý
// ============================================================

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Xin quyền thông báo và lưu FCM token
  Future<void> initialize(String userId) async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    final token = await _messaging.getToken();
    if (token != null) {
      await _saveFcmToken(userId, token);
    }
    // Lắng nghe token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      _saveFcmToken(userId, newToken);
    });
  }

  /// Lưu FCM token vào Firestore
  Future<void> _saveFcmToken(String userId, String token) async {
    await _db
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .update({'fcmToken': token});
  }

  /// Lấy FCM token của user để gửi notification
  Future<String?> getFcmToken(String userId) async {
    final doc = await _db
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .get();
    return doc.data()?['fcmToken'] as String?;
  }

  /// Lắng nghe tin nhắn khi app đang mở
  void listenForegroundMessages(Function(RemoteMessage) onMessage) {
    FirebaseMessaging.onMessage.listen(onMessage);
  }

  // NOTE: Gửi push notification thực tế cần Firebase Cloud Functions
  // hoặc server-side code. Trong scope project, admin sẽ trigger
  // status update và user tự refresh / listen realtime stream.
}
