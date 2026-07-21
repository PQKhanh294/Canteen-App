enum OrderStatus {
  pending('pending'),
  confirmed('confirmed'),
  preparing('preparing'),
  ready('ready'),
  completed('completed'),
  cancelled('cancelled'),
  unknown('unknown');

  const OrderStatus(this.value);

  final String value;

  static const List<OrderStatus> adminFilterStatuses = [
    pending,
    confirmed,
    preparing,
    ready,
    completed,
    cancelled,
  ];

  static OrderStatus fromValue(Object? value) {
    if (value is OrderStatus) return value;

    var normalized = value?.toString().trim().toLowerCase() ?? '';
    if (normalized.startsWith('orderstatus.')) {
      normalized = normalized.substring('orderstatus.'.length);
    }
    normalized = normalized.replaceAll('-', '_').replaceAll(' ', '_');

    const aliases = {
      'canceled': cancelled,
      'processing': preparing,
      'in_progress': preparing,
    };
    final alias = aliases[normalized];
    if (alias != null) return alias;

    return OrderStatus.values.firstWhere(
      (status) =>
          status != OrderStatus.unknown &&
          (status.value == normalized || status.name == normalized),
      orElse: () => OrderStatus.unknown,
    );
  }

  String get label => switch (this) {
    OrderStatus.pending => 'Chờ xác nhận',
    OrderStatus.confirmed => 'Đã xác nhận',
    OrderStatus.preparing => 'Đang chuẩn bị',
    OrderStatus.ready => 'Sẵn sàng lấy',
    OrderStatus.completed => 'Hoàn thành',
    OrderStatus.cancelled => 'Đã hủy',
    OrderStatus.unknown => 'Không xác định',
  };

  OrderStatus? get nextAdminStatus => switch (this) {
    OrderStatus.pending => OrderStatus.confirmed,
    OrderStatus.confirmed => OrderStatus.preparing,
    OrderStatus.preparing => OrderStatus.ready,
    OrderStatus.ready => OrderStatus.completed,
    OrderStatus.completed ||
    OrderStatus.cancelled ||
    OrderStatus.unknown => null,
  };

  String? get adminActionLabel => switch (this) {
    OrderStatus.confirmed => 'Xác nhận đơn hàng',
    OrderStatus.preparing => 'Bắt đầu chuẩn bị',
    OrderStatus.ready => 'Đánh dấu sẵn sàng',
    OrderStatus.completed => 'Hoàn thành',
    OrderStatus.pending || OrderStatus.cancelled || OrderStatus.unknown => null,
  };

  bool canTransitionTo(OrderStatus next) => nextAdminStatus == next;
}
