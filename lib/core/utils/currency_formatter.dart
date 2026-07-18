import 'package:intl/intl.dart';

// ============================================================
// UTILS: CurrencyFormatter
// Owner: ALL (Dùng chung cho toàn bộ app)
// Mô tả: Định dạng tiền tệ VND chuẩn thống nhất
// ============================================================

abstract final class CurrencyFormatter {
  static final NumberFormat _vndFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  );

  static String format(num value) {
    return _vndFormat.format(value);
  }
}
