/// Number-to-text helpers shared across display sites.
library;

/// Formats [value] to [digits] decimals, dropping a trailing `.0` — e.g. a
/// latitude `25.0` reads as `25`, matching what the chart / fact rows did by
/// hand in the typhoon panel and the station trend axis.
String trimTrailingZero(double value, {int digits = 1}) {
  final s = value.toStringAsFixed(digits);
  return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
}
