import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

// ============================================================
// LIB: services/storage_service.dart
// Cloudinary unsigned upload service.
// ============================================================

class StorageService {
  StorageService({
    String? cloudName,
    String? uploadPreset,
    http.Client? client,
  }) : _cloudName = cloudName ?? _configuredCloudName,
       _uploadPreset = uploadPreset ?? _configuredUploadPreset,
       _client = client ?? http.Client();

  static const _configuredCloudName = String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
    defaultValue: 'dptpvn56u',
  );
  static const _configuredUploadPreset = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
    defaultValue: 'canteen_preset',
  );

  final String _cloudName;
  final String _uploadPreset;
  final http.Client _client;

  Future<String> uploadFoodImage(File imageFile, String foodId) {
    return _uploadImage(
      imageFile: imageFile,
      folder: 'canteen/foods',
      publicIdPrefix: foodId,
      label: 'ảnh món ăn',
    );
  }

  Future<String> uploadAvatar(File imageFile, String userId) {
    return _uploadImage(
      imageFile: imageFile,
      folder: 'canteen/avatars',
      publicIdPrefix: userId,
      label: 'ảnh đại diện',
    );
  }

  Future<String> _uploadImage({
    required File imageFile,
    required String folder,
    required String publicIdPrefix,
    required String label,
  }) async {
    _validateConfiguration();

    if (!await imageFile.exists()) {
      throw Exception('Tệp ảnh đã chọn không còn tồn tại. Vui lòng chọn lại ảnh.');
    }

    final endpoint = Uri.https(
      'api.cloudinary.com',
      '/v1_1/$_cloudName/image/upload',
    );
    final request = http.MultipartRequest('POST', endpoint)
      ..fields['upload_preset'] = _uploadPreset
      ..fields['folder'] = folder
      ..fields['public_id'] =
          '${publicIdPrefix}_${DateTime.now().millisecondsSinceEpoch}'
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    try {
      final streamedResponse = await _client.send(request);
      final response = await http.Response.fromStream(streamedResponse);
      final payload = _decodeResponse(response.body);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final cloudinaryMessage = _readCloudinaryError(payload);
        throw Exception(
          'Cloudinary không thể tải $label lên '
          '(${response.statusCode}): $cloudinaryMessage',
        );
      }

      final secureUrl = payload['secure_url'];
      if (secureUrl is! String || secureUrl.isEmpty) {
        throw Exception('Cloudinary không trả về đường dẫn HTTPS của $label.');
      }
      return secureUrl;
    } on SocketException {
      throw Exception('Không có kết nối mạng để tải $label lên Cloudinary.');
    } on HttpException catch (error) {
      throw Exception('Không thể kết nối Cloudinary: ${error.message}');
    }
  }

  Map<String, dynamic> _decodeResponse(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } on FormatException {
      return <String, dynamic>{};
    }
  }

  String _readCloudinaryError(Map<String, dynamic> payload) {
    final error = payload['error'];
    if (error is Map<String, dynamic>) {
      final message = error['message'];
      if (message is String && message.isNotEmpty) return message;
    }
    return 'Phản hồi không hợp lệ từ máy chủ.';
  }

  void _validateConfiguration() {
    if (_cloudName.isEmpty || _uploadPreset.isEmpty) {
      throw StateError(
        'Chưa cấu hình Cloudinary. Hãy truyền CLOUDINARY_CLOUD_NAME và '
        'CLOUDINARY_UPLOAD_PRESET bằng --dart-define.',
      );
    }
  }

  /// Unsigned upload không được phép xóa asset. Việc xóa cần thực hiện qua
  /// backend có giữ Cloudinary API Secret, tuyệt đối không đặt secret trong app.
  Future<void> deleteImage(String imageUrl) async {}
}
