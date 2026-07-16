enum DiscountType {
  percentage('percentage'),
  fixed('fixed');

  const DiscountType(this.value);

  final String value;

  static DiscountType fromValue(String? value) {
    return DiscountType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => DiscountType.fixed,
    );
  }
}
