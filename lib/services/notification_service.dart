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
    await _messaging.requestPermission(alert: true, badge: true, sound: true);
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
    await _db.collection(AppConstants.usersCollection).doc(userId).update({
      'fcmToken': token,
    });
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

  /// Tạo job để Cloud Function/backend gửi push an toàn bằng Admin SDK.
  Future<void> queueOrderReadyNotification(
    String userId,
    String orderId,
  ) async {
    await _db.collection('notification_jobs').add({
      'type': 'order_ready',
      'userId': userId,
      'orderId': orderId,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'pending',
    });
  }

  /// Topic `students` được backend xử lý; client không giữ server key.
  Future<void> queueBroadcastNotification(
    String broadcastId,
    String title,
    String body,
  ) async {
    await _db.collection('notification_jobs').add({
      'type': 'broadcast',
      'topic': 'students',
      'broadcastId': broadcastId,
      'title': title,
      'body': body,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'pending',
    });
  }

  // NOTE: Gửi push notification thực tế cần Firebase Cloud Functions
  // hoặc server-side code. Trong scope project, admin sẽ trigger
  // status update và user tự refresh / listen realtime stream.
}
