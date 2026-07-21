/// Quy tắc giờ nhận món dùng chung cho Checkout UI và tầng Firestore.
///
/// Căn tin nhận đơn trong hai ca, chia mỗi 15 phút. Đơn phải được đặt trước
/// ít nhất 30 phút và có thể đặt trước tối đa 7 ngày (tính cả hôm nay).
abstract final class PickupSchedule {
  static const int slotIntervalMinutes = 15;
  static const int leadTimeMinutes = 30;
  static const int advanceBookingDays = 7;
  static const int maxOrdersPerSlot = 20;

  /// Khoảng thời gian được biểu diễn bằng số phút tính từ 00:00.
  /// Điểm kết thúc là exclusive, ví dụ 11:00-13:00 có slot cuối là 12:45.
  static const List<({int start, int end})> windows = [
    (start: 11 * 60, end: 13 * 60),
    (start: 17 * 60, end: 18 * 60),
  ];

  static DateTime dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static bool isSameDate(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;

  static List<DateTime> availableDates({DateTime? currentTime}) {
    final now = currentTime ?? DateTime.now();
    final today = dateOnly(now);

    return List<DateTime>.generate(
      advanceBookingDays,
      (index) => today.add(Duration(days: index)),
    ).where((date) => slotsForDate(date, currentTime: now).isNotEmpty).toList();
  }

  static List<DateTime> slotsForDate(DateTime date, {DateTime? currentTime}) {
    final now = currentTime ?? DateTime.now();
    final normalizedDate = dateOnly(date);
    final today = dateOnly(now);
    final lastDate = today.add(const Duration(days: advanceBookingDays - 1));

    if (normalizedDate.isBefore(today) || normalizedDate.isAfter(lastDate)) {
      return const [];
    }

    final earliestPickup = now.add(const Duration(minutes: leadTimeMinutes));
    final slots = <DateTime>[];

    for (final window in windows) {
      for (
        var minute = window.start;
        minute < window.end;
        minute += slotIntervalMinutes
      ) {
        final slot = DateTime(
          normalizedDate.year,
          normalizedDate.month,
          normalizedDate.day,
          minute ~/ 60,
          minute % 60,
        );
        if (!slot.isBefore(earliestPickup)) {
          slots.add(slot);
        }
      }
    }

    return slots;
  }

  static bool isValidPickupAt(DateTime pickupAt, {DateTime? currentTime}) {
    final now = currentTime ?? DateTime.now();
    return slotsForDate(
      pickupAt,
      currentTime: now,
    ).any((slot) => slot.isAtSameMomentAs(pickupAt));
  }

  static String slotId(DateTime pickupAt) {
    String twoDigits(int value) => value.toString().padLeft(2, '0');

    return '${pickupAt.year}'
        '${twoDigits(pickupAt.month)}'
        '${twoDigits(pickupAt.day)}_'
        '${twoDigits(pickupAt.hour)}'
        '${twoDigits(pickupAt.minute)}';
  }
}
