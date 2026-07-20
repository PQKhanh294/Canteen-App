enum PaymentMethod {
  cash('cash'),
  eWalletMock('e_wallet_mock');

  const PaymentMethod(this.value);

  final String value;

  static PaymentMethod fromValue(String? value) {
    return PaymentMethod.values.firstWhere(
      (method) => method.value == value,
      orElse: () => PaymentMethod.cash,
    );
  }
}
