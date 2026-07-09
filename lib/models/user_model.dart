// ============================================================
// LIB: models/user_model.dart
// Owner: Member 1 — Khánh
// ============================================================

class UserModel {
  final String uid;
  final String displayName;
  final String email;
  final String role; // 'student' | 'admin'
  final String avatarUrl;
  final String fcmToken;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.role,
    this.avatarUrl = '',
    this.fcmToken = '',
    required this.createdAt,
  });

  bool get isAdmin => role == 'admin';
  bool get isStudent => role == 'student';

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      displayName: map['displayName'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'student',
      avatarUrl: map['avatarUrl'] ?? '',
      fcmToken: map['fcmToken'] ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'email': email,
      'role': role,
      'avatarUrl': avatarUrl,
      'fcmToken': fcmToken,
      'createdAt': createdAt,
    };
  }

  UserModel copyWith({
    String? displayName,
    String? avatarUrl,
    String? fcmToken,
  }) {
    return UserModel(
      uid: uid,
      displayName: displayName ?? this.displayName,
      email: email,
      role: role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt,
    );
  }
}
