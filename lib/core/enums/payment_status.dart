enum PaymentStatus {
  unpaid('unpaid'),
  mockPaid('mock_paid');

  const PaymentStatus(this.value);

  final String value;

  static PaymentStatus fromValue(String? value) {
    return PaymentStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => PaymentStatus.unpaid,
    );
  }
}
