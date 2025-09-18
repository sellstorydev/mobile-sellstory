enum LaneDisplayMode {
  totalBeforeDiscount('before_discount', 'Total (before discount)'),
  totalAfterDiscount('after_discount', 'Total (after discount)'),
  grandTotal('grand_total', 'Grand Total (after VAT)'),
  netTotal('net_total', 'Net Total (after VAT & WHT)'),
  none('none', 'None');

  const LaneDisplayMode(this.key, this.label);

  final String key;
  final String label;

  static LaneDisplayMode fromKey(String key) {
    return LaneDisplayMode.values.firstWhere(
      (mode) => mode.key == key,
      orElse: () => LaneDisplayMode.totalBeforeDiscount,
    );
  }
}
