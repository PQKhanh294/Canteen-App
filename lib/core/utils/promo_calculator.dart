import '../../models/promo_model.dart';
import '../../core/enums/discount_type.dart';
import 'currency_formatter.dart';

// ============================================================
// UTILS: PromoCalculator
// Owner: Member 3 — An
// Mô tả: Kiểm tra tính hợp lệ và tính toán giá trị giảm của Voucher
// ============================================================

enum PromoValidationStatus {
  valid,
  inactive,
  notStarted,
  expired,
  minimumOrderNotMet,
  usageLimitReached,
  invalidConfiguration,
}

class PromoValidationResult {
  const PromoValidationResult({required this.status, required this.message});

  final PromoValidationStatus status;
  final String message;

  bool get isValid => status == PromoValidationStatus.valid;
}

abstract final class PromoCalculator {
  static PromoValidationResult validate({
    required PromoModel promo,
    required int subtotal,
    DateTime? currentTime,
  }) {
    final now = currentTime ?? DateTime.now();

    // Kiểm tra cấu hình sai trước
    if (promo.discountValue <= 0) {
      return const PromoValidationResult(
        status: PromoValidationStatus.invalidConfiguration,
        message: 'Mã giảm giá có cấu hình không hợp lệ.',
      );
    }

    if (promo.discountType == DiscountType.percentage &&
        promo.discountValue > 100) {
      return const PromoValidationResult(
        status: PromoValidationStatus.invalidConfiguration,
        message: 'Phần trăm giảm giá không hợp lệ.',
      );
    }

    if (promo.expiresAt.isBefore(promo.startAt)) {
      return const PromoValidationResult(
        status: PromoValidationStatus.invalidConfiguration,
        message: 'Mã giảm giá có cấu hình không hợp lệ.',
      );
    }

    if (!promo.isActive) {
      return const PromoValidationResult(
        status: PromoValidationStatus.inactive,
        message: 'Mã giảm giá hiện đang tạm ngừng.',
      );
    }

    if (now.isBefore(promo.startAt)) {
      return const PromoValidationResult(
        status: PromoValidationStatus.notStarted,
        message: 'Mã giảm giá chưa đến thời gian sử dụng.',
      );
    }

    if (now.isAfter(promo.expiresAt)) {
      return const PromoValidationResult(
        status: PromoValidationStatus.expired,
        message: 'Mã giảm giá đã hết hạn.',
      );
    }

    final minimumOrder = promo.minimumOrderAmount?.toInt() ?? 0;

    if (subtotal < minimumOrder) {
      final missingAmount = minimumOrder - subtotal;

      return PromoValidationResult(
        status: PromoValidationStatus.minimumOrderNotMet,
        message:
            'Cần thêm ${CurrencyFormatter.format(missingAmount)} '
            'để sử dụng mã này.',
      );
    }

    final usageLimit = promo.usageLimit;

    if (usageLimit != null && promo.usedCount >= usageLimit) {
      return const PromoValidationResult(
        status: PromoValidationStatus.usageLimitReached,
        message: 'Mã giảm giá đã hết lượt sử dụng.',
      );
    }

    return const PromoValidationResult(
      status: PromoValidationStatus.valid,
      message: 'Có thể áp dụng mã giảm giá.',
    );
  }

  static int calculateDiscount({
    required PromoModel promo,
    required int subtotal,
  }) {
    if (subtotal <= 0) {
      return 0;
    }

    int discount;

    switch (promo.discountType) {
      case DiscountType.percentage:
        discount = subtotal * promo.discountValue.toInt() ~/ 100;

        final maximumDiscount = promo.maximumDiscount?.toInt();

        if (maximumDiscount != null && discount > maximumDiscount) {
          discount = maximumDiscount;
        }
        break;

      case DiscountType.fixed:
        discount = promo.discountValue.toInt();
        break;
    }

    return discount.clamp(0, subtotal);
  }
}
