import 'package:canteen_app/core/utils/pickup_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PickupSchedule', () {
    test('generates 15-minute slots with a 30-minute lead time', () {
      final now = DateTime(2026, 7, 21, 10, 20);
      final slots = PickupSchedule.slotsForDate(now, currentTime: now);

      expect(slots.first, DateTime(2026, 7, 21, 11));
      expect(slots[1], DateTime(2026, 7, 21, 11, 15));
      expect(slots.last, DateTime(2026, 7, 21, 17, 45));
    });

    test('keeps afternoon slots after the lunch window has passed', () {
      final now = DateTime(2026, 7, 21, 12, 40);
      final slots = PickupSchedule.slotsForDate(now, currentTime: now);

      expect(slots.first, DateTime(2026, 7, 21, 17));
      expect(slots.every((slot) => slot.hour >= 17), isTrue);
    });

    test('offers tomorrow after all slots for today have passed', () {
      final now = DateTime(2026, 7, 21, 17, 40);
      final dates = PickupSchedule.availableDates(currentTime: now);

      expect(
        PickupSchedule.isSameDate(dates.first, DateTime(2026, 7, 22)),
        isTrue,
      );
      expect(
        PickupSchedule.slotsForDate(dates.first, currentTime: now).first,
        DateTime(2026, 7, 22, 11),
      );
    });

    test('rejects past, off-grid, and too-far pickup values', () {
      final now = DateTime(2026, 7, 21, 10);

      expect(
        PickupSchedule.isValidPickupAt(
          DateTime(2026, 7, 21, 11),
          currentTime: now,
        ),
        isTrue,
      );
      expect(
        PickupSchedule.isValidPickupAt(
          DateTime(2026, 7, 21, 11, 7),
          currentTime: now,
        ),
        isFalse,
      );
      expect(
        PickupSchedule.isValidPickupAt(
          DateTime(2026, 7, 28, 11),
          currentTime: now,
        ),
        isFalse,
      );
    });

    test('creates stable Firestore slot document IDs', () {
      expect(
        PickupSchedule.slotId(DateTime(2026, 7, 2, 9, 5)),
        '20260702_0905',
      );
    });
  });
}
