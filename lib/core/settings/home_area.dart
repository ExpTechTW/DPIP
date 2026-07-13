/// One switchable area on the Home region bar.
///
/// Everything is keyed by township **code** — names are derived from the town
/// directory on demand, never stored (so a renamed town or locale change is
/// always correct). The ordered set is: [Nationwide], [CurrentArea] (GPS), then
/// the saved [SavedArea]s.
sealed class HomeArea {
  const HomeArea();
}

/// 全國 — the whole-country view.
class NationwideArea extends HomeArea {
  const NationwideArea();
}

/// 所在地 — the current GPS township. [code] is null when GPS is unavailable, so
/// the bar shows the "can't get current location" state but the slot stays.
class CurrentArea extends HomeArea {
  const CurrentArea(this.code);

  final String? code;
}

/// A saved township, identified only by its [code].
class SavedArea extends HomeArea {
  const SavedArea(this.code);

  final String code;
}
