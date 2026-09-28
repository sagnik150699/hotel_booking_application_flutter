/// Formats whole-rupee amounts using the Indian digit grouping system.
///
/// Examples:
/// * `formatInr(950)` → `₹950`
/// * `formatInr(6400)` → `₹6,400`
/// * `formatInr(123456)` → `₹1,23,456`
/// * `formatInr(-1200)` → `-₹1,200`
///
/// The app intentionally avoids a dependency on `intl` for this; the grouping
/// rule is small, deterministic, and easy to unit test.
String formatInr(int amount, {String symbol = '₹'}) {
  final isNegative = amount < 0;
  final digits = amount.abs().toString();
  final grouped = groupIndianDigits(digits);
  return '${isNegative ? '-' : ''}$symbol$grouped';
}

/// Applies Indian digit grouping (last three digits, then pairs) to a string of
/// ASCII digits. Non-digit input is returned unchanged.
String groupIndianDigits(String digits) {
  if (digits.length <= 3 || !RegExp(r'^\d+$').hasMatch(digits)) {
    return digits;
  }

  final lastThree = digits.substring(digits.length - 3);
  var rest = digits.substring(0, digits.length - 3);
  final parts = <String>[];

  while (rest.length > 2) {
    parts.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) {
    parts.insert(0, rest);
  }

  return '${parts.join(',')},$lastThree';
}
