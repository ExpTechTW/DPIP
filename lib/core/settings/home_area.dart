/// One switchable area on the Home region bar.
///
/// Everything is keyed by township **code** — names are derived from the town
/// directory on demand, never stored (so a renamed town or locale change is
/// always correct). The ordered set is: [Nationwide], [CurrentArea] (GPS), then
/// the saved [SavedArea]s.
sealed class HomeArea {
  const HomeArea();

  /// The township code this area stands for — null for 全國, and null for
  /// 所在地 until GPS reports one.
  ///
  /// Declared here rather than switched at each reader: a screen that needs a
  /// code needs *this* derivation, and nine hand-written copies of it is nine
  /// chances for a future area kind to be quietly filed under 全國.
  String? get code;
}

/// 全國 — the whole-country view.
class NationwideArea extends HomeArea {
  const NationwideArea();

  @override
  String? get code => null;
}

/// 所在地 — the current GPS township. [code] is null when GPS is unavailable, so
/// the bar shows the "can't get current location" state but the slot stays.
class CurrentArea extends HomeArea {
  const CurrentArea(this.code);

  @override
  final String? code;
}

/// A saved township, identified only by its [code].
class SavedArea extends HomeArea {
  const SavedArea(this.code);

  @override
  final String code;
}
