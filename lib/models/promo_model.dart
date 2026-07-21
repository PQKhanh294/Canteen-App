import '../core/enums/discount_type.dart';
import '../core/utils/model_parsers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PromoModel {
  final String id;
  final String code;
  final String description;
  final DiscountType discountType;
  final double discountValue;
  final double? minimumOrderAmount;
  final double? maximumDiscount;
  final DateTime startAt;
  final DateTime expiresAt;
  final bool isActive;
  final int? usageLimit;
  final int usedCount;

  const PromoModel({
    required this.id,
    required this.code,
    required this.description,
    required this.discountType,
    required this.discountValue,
    this.minimumOrderAmount,
    this.maximumDiscount,
    required this.startAt,
    required this.expiresAt,
    required this.isActive,
    this.usageLimit,
    required this.usedCount,
  });

  bool get hasStarted => !DateTime.now().isBefore(startAt);
  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get hasRemainingUsage => usageLimit == null || usedCount < usageLimit!;

  factory PromoModel.fromMap(Map<String, dynamic> map, String id) {
    // Các fallback type/value/active giữ tương thích với dữ liệu Admin cũ.
    // Mọi lần ghi mới đều dùng schema chuẩn ở toMap().
    final rawType = map['discountType'] ?? map['type'];
    final rawValue = map['discountValue'] ?? map['value'];
    final rawActive = map['isActive'] ?? map['active'];
    final now = DateTime.now();

    return PromoModel(
      id: id,
      code: (map['code'] as String? ?? '').trim().toUpperCase(),
      description: map['description'] as String? ?? '',
      discountType: DiscountType.fromValue(rawType as String?),
      discountValue: parseDouble(rawValue),
      minimumOrderAmount: map['minimumOrderAmount'] != null
          ? parseDouble(map['minimumOrderAmount'])
          : null,
      maximumDiscount: map['maximumDiscount'] != null
          ? parseDouble(map['maximumDiscount'])
          : null,
      startAt:
          parseDateTime(map['startAt']) ??
          now.subtract(const Duration(days: 1)),
      expiresAt: parseDateTime(map['expiresAt']) ?? now,
      isActive: rawActive as bool? ?? false,
      usageLimit: map['usageLimit'] != null
          ? parseInt(map['usageLimit'])
          : null,
      usedCount: parseInt(map['usedCount']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code.trim().toUpperCase(),
      'description': description,
      'discountType': discountType.value,
      'discountValue': discountValue,
      'minimumOrderAmount': minimumOrderAmount,
      'maximumDiscount': maximumDiscount,
      'startAt': Timestamp.fromDate(startAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'isActive': isActive,
      'usageLimit': usageLimit,
      'usedCount': usedCount,
    };
  }
}
