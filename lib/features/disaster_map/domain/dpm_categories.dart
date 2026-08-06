/// Filterable category values carried by the DPM MVT tiles.
///
/// These are wire values from `/api/v2/tiles/dpm/…` — restroom venues are
/// `type2` ints 1–10 and restroom types are `type` ints 1–6 (labels map
/// through `AppLocalizations.restroomCategory*` / `restroomType*`), shelter
/// disaster types are the raw CJK strings inside each feature's `category`
/// JSON-array string. Labels for the latter live in
/// `AppLocalizations.dpmDisaster*`.
library;

abstract final class DpmCategories {
  /// Restroom `type2` venue codes, in [RestroomDetail] mapping order.
  static const List<int> restroom = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];

  /// Restroom `type` codes (toilet kind), in [RestroomDetail] mapping order —
  /// `0=未知` / `7=未設定` are left out of the picker.
  static const List<int> restroomType = [1, 2, 3, 4, 5, 6];

  /// Shelter disaster types, as embedded in the tile `category` string.
  static const List<String> shelter = ['水災', '震災', '土石流', '海嘯', '坡地災害', '核子事故'];
}
