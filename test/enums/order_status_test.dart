import 'package:canteen_app/core/enums/order_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('admin order status follows the canonical workflow', () {
    expect(OrderStatus.pending.nextAdminStatus, OrderStatus.confirmed);
    expect(OrderStatus.confirmed.nextAdminStatus, OrderStatus.preparing);
    expect(OrderStatus.preparing.nextAdminStatus, OrderStatus.ready);
    expect(OrderStatus.ready.nextAdminStatus, OrderStatus.completed);
    expect(OrderStatus.completed.nextAdminStatus, isNull);
    expect(OrderStatus.cancelled.nextAdminStatus, isNull);
    expect(OrderStatus.unknown.nextAdminStatus, isNull);
  });

  test('does not allow skipping order status steps', () {
    expect(OrderStatus.pending.canTransitionTo(OrderStatus.preparing), isFalse);
    expect(OrderStatus.pending.canTransitionTo(OrderStatus.confirmed), isTrue);
    expect(OrderStatus.ready.canTransitionTo(OrderStatus.completed), isTrue);
  });

  group('OrderStatus.fromValue', () {
    test('normalizes database values, enum names, case and whitespace', () {
      expect(OrderStatus.fromValue(' pending '), OrderStatus.pending);
      expect(OrderStatus.fromValue('READY'), OrderStatus.ready);
      expect(
        OrderStatus.fromValue('OrderStatus.completed'),
        OrderStatus.completed,
      );
      expect(
        OrderStatus.fromValue(OrderStatus.cancelled),
        OrderStatus.cancelled,
      );
      expect(OrderStatus.fromValue('in progress'), OrderStatus.preparing);
    });

    test('maps null and unsupported values to unknown', () {
      expect(OrderStatus.fromValue(null), OrderStatus.unknown);
      expect(OrderStatus.fromValue('not-a-status'), OrderStatus.unknown);
      expect(OrderStatus.fromValue('   '), OrderStatus.unknown);
    });

    test('admin filters contain cancelled but never unknown', () {
      expect(OrderStatus.adminFilterStatuses, contains(OrderStatus.cancelled));
      expect(
        OrderStatus.adminFilterStatuses,
        isNot(contains(OrderStatus.unknown)),
      );
    });
  });
}
