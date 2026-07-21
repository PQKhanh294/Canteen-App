enum OrderStatus {
  pending('pending'),
  confirmed('confirmed'),
  preparing('preparing'),
  ready('ready'),
  completed('completed'),
  cancelled('cancelled');

  const OrderStatus(this.value);

  final String value;

  static OrderStatus fromValue(String? value) {
    return OrderStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => OrderStatus.pending,
    );
  }

  OrderStatus? get nextAdminStatus => switch (this) {
    OrderStatus.pending => OrderStatus.confirmed,
    OrderStatus.confirmed => OrderStatus.preparing,
    OrderStatus.preparing => OrderStatus.ready,
    OrderStatus.ready => OrderStatus.completed,
    OrderStatus.completed || OrderStatus.cancelled => null,
  };

  bool canTransitionTo(OrderStatus next) => nextAdminStatus == next;
}
