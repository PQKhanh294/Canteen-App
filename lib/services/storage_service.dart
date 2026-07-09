import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

// ============================================================
// LIB: services/storage_service.dart
// Owner: Member 4 — Quý
// ============================================================

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload ảnh món ăn, trả về download URL
  Future<String> uploadFoodImage(File imageFile, String foodId) async {
    try {
      final ref = _storage.ref().child('foods/$foodId.jpg');
      final uploadTask = await ref.putFile(imageFile);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Không thể upload ảnh: $e');
    }
  }

  /// Upload ảnh avatar user
  Future<String> uploadAvatar(File imageFile, String userId) async {
    try {
      final ref = _storage.ref().child('avatars/$userId.jpg');
      final uploadTask = await ref.putFile(imageFile);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Không thể upload avatar: $e');
    }
  }

  /// Xóa ảnh theo path
  Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (_) {
      // Bỏ qua lỗi nếu file không tồn tại
    }
  }
}
