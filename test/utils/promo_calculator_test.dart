import 'package:flutter_test/flutter_test.dart';
import 'package:canteen_app/models/promo_model.dart';
import 'package:canteen_app/core/enums/discount_type.dart';
import 'package:canteen_app/core/utils/promo_calculator.dart';
import 'package:canteen_app/core/utils/currency_formatter.dart';

void main() {
  test('releaseUsage restores one voucher use without becoming negative', () {
    expect(PromoCalculator.releaseUsage(10), 9);
    expect(PromoCalculator.releaseUsage(1), 0);
    expect(PromoCalculator.releaseUsage(0), 0);
    expect(PromoCalculator.releaseUsage(-1), 0);
  });

  group('PromoCalculator Validation Tests', () {
    final now = DateTime(2026, 7, 15, 12, 0);

    test('valid active voucher should pass validation', () {
      final promo = PromoModel(
        id: 'FPT10',
        code: 'FPT10',
        description: 'Giảm 10%',
        discountType: DiscountType.percentage,
        discountValue: 10,
        minimumOrderAmount: 50000,
        startAt: DateTime(2026, 7, 1),
        expiresAt: DateTime(2026, 7, 31),
        isActive: true,
        usageLimit: 100,
        usedCount: 0,
      );

      final result = PromoCalculator.validate(
        promo: promo,
        subtotal: 60000,
        currentTime: now,
      );

      expect(result.isValid, true);
      expect(result.status, PromoValidationStatus.valid);
    });

    test('inactive voucher should fail', () {
      final promo = PromoModel(
        id: 'DISABLED',
        code: 'DISABLED',
        description: 'Tắt',
        discountType: DiscountType.fixed,
        discountValue: 10000,
        startAt: DateTime(2026, 7, 1),
        expiresAt: DateTime(2026, 7, 31),
        isActive: false,
        usedCount: 0,
      );

      final result = PromoCalculator.validate(
        promo: promo,
        subtotal: 50000,
        currentTime: now,
      );

      expect(result.isValid, false);
      expect(result.status, PromoValidationStatus.inactive);
      expect(result.message, 'Mã giảm giá hiện đang tạm ngừng.');
    });

    test('not started voucher should fail', () {
      final promo = PromoModel(
        id: 'FUTURE',
        code: 'FUTURE',
        description: 'Chưa chạy',
        discountType: DiscountType.fixed,
        discountValue: 10000,
        startAt: DateTime(2026, 7, 20),
        expiresAt: DateTime(2026, 7, 31),
        isActive: true,
        usedCount: 0,
      );

      final result = PromoCalculator.validate(
        promo: promo,
        subtotal: 50000,
        currentTime: now,
      );

      expect(result.isValid, false);
      expect(result.status, PromoValidationStatus.notStarted);
      expect(result.message, 'Mã giảm giá chưa đến thời gian sử dụng.');
    });

    test('expired voucher should fail', () {
      final promo = PromoModel(
        id: 'EXPIRED',
        code: 'EXPIRED',
        description: 'Hết hạn',
        discountType: DiscountType.fixed,
        discountValue: 10000,
        startAt: DateTime(2026, 7, 1),
        expiresAt: DateTime(2026, 7, 10),
        isActive: true,
        usedCount: 0,
      );

      final result = PromoCalculator.validate(
        promo: promo,
        subtotal: 50000,
        currentTime: now,
      );

      expect(result.isValid, false);
      expect(result.status, PromoValidationStatus.expired);
      expect(result.message, 'Mã giảm giá đã hết hạn.');
    });

    test(
      'minimum order not met should fail and show remaining amount needed',
      () {
        final promo = PromoModel(
          id: 'FPT10',
          code: 'FPT10',
          description: 'Giảm 10% đơn từ 50k',
          discountType: DiscountType.percentage,
          discountValue: 10,
          minimumOrderAmount: 50000,
          startAt: DateTime(2026, 7, 1),
          expiresAt: DateTime(2026, 7, 31),
          isActive: true,
          usedCount: 0,
        );

        final result = PromoCalculator.validate(
          promo: promo,
          subtotal: 40000,
          currentTime: now,
        );

        expect(result.isValid, false);
        expect(result.status, PromoValidationStatus.minimumOrderNotMet);
        expect(
          result.message,
          'Cần thêm ${CurrencyFormatter.format(10000)} để sử dụng mã này.',
        );
      },
    );

    test('usage limit reached should fail', () {
      final promo = PromoModel(
        id: 'FULL',
        code: 'FULL',
        description: 'Hết lượt',
        discountType: DiscountType.fixed,
        discountValue: 10000,
        startAt: DateTime(2026, 7, 1),
        expiresAt: DateTime(2026, 7, 31),
        isActive: true,
        usageLimit: 10,
        usedCount: 10,
      );

      final result = PromoCalculator.validate(
        promo: promo,
        subtotal: 50000,
        currentTime: now,
      );

      expect(result.isValid, false);
      expect(result.status, PromoValidationStatus.usageLimitReached);
      expect(result.message, 'Mã giảm giá đã hết lượt sử dụng.');
    });

    test('invalid configurations should fail gracefully', () {
      final zeroValuePromo = PromoModel(
        id: 'BAD',
        code: 'BAD',
        description: 'Sai',
        discountType: DiscountType.fixed,
        discountValue: 0,
        startAt: DateTime(2026, 7, 1),
        expiresAt: DateTime(2026, 7, 31),
        isActive: true,
        usedCount: 0,
      );

      expect(
        PromoCalculator.validate(
          promo: zeroValuePromo,
          subtotal: 50000,
          currentTime: now,
        ).status,
        PromoValidationStatus.invalidConfiguration,
      );

      final overPercentPromo = PromoModel(
        id: 'BAD_PERCENT',
        code: 'BAD_PERCENT',
        description: '150%',
        discountType: DiscountType.percentage,
        discountValue: 150,
        startAt: DateTime(2026, 7, 1),
        expiresAt: DateTime(2026, 7, 31),
        isActive: true,
        usedCount: 0,
      );

      expect(
        PromoCalculator.validate(
          promo: overPercentPromo,
          subtotal: 50000,
          currentTime: now,
        ).status,
        PromoValidationStatus.invalidConfiguration,
      );

      final badTimelinePromo = PromoModel(
        id: 'BAD_TIMELINE',
        code: 'BAD_TIMELINE',
        description: 'Expires before start',
        discountType: DiscountType.fixed,
        discountValue: 10000,
        startAt: DateTime(2026, 7, 31),
        expiresAt: DateTime(2026, 7, 1),
        isActive: true,
        usedCount: 0,
      );

      expect(
        PromoCalculator.validate(
          promo: badTimelinePromo,
          subtotal: 50000,
          currentTime: now,
        ).status,
        PromoValidationStatus.invalidConfiguration,
      );
    });
  });

  group('PromoCalculator Discount Amount Calculations', () {
    test('calculate percentage discount under limit', () {
      final promo = PromoModel(
        id: 'FPT10',
        code: 'FPT10',
        description: '10%',
        discountType: DiscountType.percentage,
        discountValue: 10,
        maximumDiscount: 20000,
        startAt: DateTime(2026, 7, 1),
        expiresAt: DateTime(2026, 7, 31),
        isActive: true,
        usedCount: 0,
      );

      final discount = PromoCalculator.calculateDiscount(
        promo: promo,
        subtotal: 120000,
      );

      expect(discount, 12000);
    });

    test('keeps decimal precision for percentage vouchers', () {
      final promo = PromoModel(
        id: 'DECIMAL',
        code: 'DECIMAL',
        description: '10.5%',
        discountType: DiscountType.percentage,
        discountValue: 10.5,
        startAt: DateTime(2026, 7, 1),
        expiresAt: DateTime(2026, 7, 31),
        isActive: true,
        usedCount: 0,
      );

      expect(
        PromoCalculator.calculateDiscount(promo: promo, subtotal: 100000),
        10500,
      );
    });

    test('calculate percentage discount capped at maximumDiscount', () {
      final promo = PromoModel(
        id: 'FPT10',
        code: 'FPT10',
        description: '10%',
        discountType: DiscountType.percentage,
        discountValue: 10,
        maximumDiscount: 20000,
        startAt: DateTime(2026, 7, 1),
        expiresAt: DateTime(2026, 7, 31),
        isActive: true,
        usedCount: 0,
      );

      final discount = PromoCalculator.calculateDiscount(
        promo: promo,
        subtotal: 300000,
      );

      expect(discount, 20000);
    });

    test('calculate fixed discount within subtotal', () {
      final promo = PromoModel(
        id: 'SAVE20',
        code: 'SAVE20',
        description: '20k',
        discountType: DiscountType.fixed,
        discountValue: 20000,
        startAt: DateTime(2026, 7, 1),
        expiresAt: DateTime(2026, 7, 31),
        isActive: true,
        usedCount: 0,
      );

      final discount = PromoCalculator.calculateDiscount(
        promo: promo,
        subtotal: 120000,
      );

      expect(discount, 20000);
    });

    test(
      'fixed discount larger than subtotal should be clamped to subtotal (final total = 0)',
      () {
        final promo = PromoModel(
          id: 'SAVE20',
          code: 'SAVE20',
          description: '20k',
          discountType: DiscountType.fixed,
          discountValue: 20000,
          startAt: DateTime(2026, 7, 1),
          expiresAt: DateTime(2026, 7, 31),
          isActive: true,
          usedCount: 0,
        );

        final discount = PromoCalculator.calculateDiscount(
          promo: promo,
          subtotal: 15000,
        );

        expect(discount, 15000);
      },
    );
  });
}
