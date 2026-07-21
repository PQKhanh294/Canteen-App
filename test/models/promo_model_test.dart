import 'package:flutter_test/flutter_test.dart';
import 'package:canteen_app/models/promo_model.dart';
import 'package:canteen_app/core/enums/discount_type.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  test('fromMap reads legacy Admin promo field names', () {
    final promo = PromoModel.fromMap({
      'code': 'legacy10',
      'description': 'Legacy promo',
      'type': 'percentage',
      'value': 10,
      'active': true,
      'expiresAt': Timestamp.fromDate(DateTime(2030, 1, 1)),
    }, 'legacy-random-id');

    expect(promo.code, 'LEGACY10');
    expect(promo.discountType, DiscountType.percentage);
    expect(promo.discountValue, 10);
    expect(promo.isActive, isTrue);
  });

  group('PromoModel Serialization and Status Tests', () {
    test('fromMap should parse percent discount vouchers correctly', () {
      final map = {
        'code': ' fpt10 ', // Test trim and uppercase conversion
        'description': 'Giảm 10%',
        'discountType': 'percentage',
        'discountValue': 10,
        'minimumOrderAmount': 50000.0,
        'maximumDiscount': 20000,
        'startAt': Timestamp.fromDate(DateTime(2026, 7, 10)),
        'expiresAt': Timestamp.fromDate(DateTime(2026, 7, 20)),
        'isActive': true,
        'usageLimit': 100,
        'usedCount': 20,
      };

      final promo = PromoModel.fromMap(map, 'promo_id_10');

      expect(promo.id, 'promo_id_10');
      expect(promo.code, 'FPT10'); // capitalized and trimmed
      expect(promo.discountType, DiscountType.percentage);
      expect(promo.discountValue, 10.0);
      expect(promo.minimumOrderAmount, 50000.0);
      expect(promo.maximumDiscount, 20000.0);
      expect(promo.isActive, true);
      expect(promo.usageLimit, 100);
      expect(promo.usedCount, 20);
      expect(promo.hasRemainingUsage, true);
    });

    test('isExpired and hasStarted logic tests', () {
      final activePromo = PromoModel(
        id: '1',
        code: 'TEST',
        description: 'Desc',
        discountType: DiscountType.fixed,
        discountValue: 10000.0,
        startAt: DateTime.now().subtract(const Duration(days: 1)),
        expiresAt: DateTime.now().add(const Duration(days: 1)),
        isActive: true,
        usedCount: 0,
      );

      expect(activePromo.hasStarted, true);
      expect(activePromo.isExpired, false);

      final expiredPromo = PromoModel(
        id: '2',
        code: 'EXPIRED',
        description: 'Desc',
        discountType: DiscountType.fixed,
        discountValue: 10000.0,
        startAt: DateTime.now().subtract(const Duration(days: 5)),
        expiresAt: DateTime.now().subtract(const Duration(days: 1)),
        isActive: true,
        usedCount: 0,
      );

      expect(expiredPromo.hasStarted, true);
      expect(expiredPromo.isExpired, true);
    });

    test('toMap and fromMap round-trip checks', () {
      final original = PromoModel(
        id: 'id_promo',
        code: 'SAVE50',
        description: 'Giảm 50k',
        discountType: DiscountType.fixed,
        discountValue: 50000.0,
        minimumOrderAmount: 100000.0,
        startAt: DateTime(2026, 7, 1),
        expiresAt: DateTime(2026, 7, 31),
        isActive: true,
        usageLimit: null,
        usedCount: 15,
      );

      final map = original.toMap();
      final parsed = PromoModel.fromMap(map, 'id_promo');

      expect(parsed.code, original.code);
      expect(parsed.discountValue, original.discountValue);
      expect(parsed.minimumOrderAmount, original.minimumOrderAmount);
      expect(parsed.maximumDiscount, null);
      expect(parsed.usageLimit, null);
      expect(parsed.isActive, original.isActive);
    });
  });
}
