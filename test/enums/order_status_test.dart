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
  });

  test('does not allow skipping order status steps', () {
    expect(OrderStatus.pending.canTransitionTo(OrderStatus.preparing), isFalse);
    expect(OrderStatus.pending.canTransitionTo(OrderStatus.confirmed), isTrue);
    expect(OrderStatus.ready.canTransitionTo(OrderStatus.completed), isTrue);
  });
}
