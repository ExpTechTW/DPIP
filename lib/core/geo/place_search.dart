/// Search over the township directory the way people actually type place
/// names: `台北` for `臺北市`, a township without its city, a full-width digit
/// from a CJK keyboard.
library;

import 'package:dpip/core/geo/town.dart';
import 'package:dpip/core/geo/town_directory.dart';

/// Folds [input] to the form both sides of a place-name match are compared in.
///
/// - **臺 → 台.** The directory spells every city `臺北市` / `臺中市` / `臺東縣`,
///   while almost everyone types the everyday `台`. Without the fold `台北`
///   matched nothing at all.
/// - **Whitespace removed**, not just trimmed — `臺北市 中正區` is how
///   [Town.fullName] reads, and `台北 中正` / `台北中正` are both what someone
///   means.
/// - **Full-width ASCII → ASCII** (U+FF01–U+FF5E, plus the ideographic space):
///   the part of Unicode NFKC that a CJK keyboard actually produces. Dart has
///   no normaliser built in, and the full table would fold nothing a place
///   name here contains.
/// - **Lower case**, for the Latin-script names a translated directory or a
///   code search would carry.
///
/// Pure and total: any string in, a string out, never throws.
String foldPlaceName(String input) {
  final out = StringBuffer();
  for (final rune in input.runes) {
    final folded = switch (rune) {
      _taiTraditional => _taiCommon,
      _ideographicSpace => null,
      >= _fullWidthFirst && <= _fullWidthLast => rune - _fullWidthOffset,
      _ => rune,
    };
    if (folded == null || _isWhitespace(folded)) continue;
    out.writeCharCode(folded);
  }
  return out.toString().toLowerCase();
}

const int _taiTraditional = 0x81FA; // 臺
const int _taiCommon = 0x53F0; // 台
const int _ideographicSpace = 0x3000;
const int _fullWidthFirst = 0xFF01;
const int _fullWidthLast = 0xFF5E;
const int _fullWidthOffset = 0xFEE0;

bool _isWhitespace(int rune) =>
    rune == 0x20 ||
    (rune >= 0x09 && rune <= 0x0D) ||
    rune == 0x85 ||
    rune == 0xA0 ||
    rune == 0x1680 ||
    (rune >= 0x2000 && rune <= 0x200A) ||
    rune == 0x2028 ||
    rune == 0x2029 ||
    rune == 0x202F ||
    rune == 0x205F ||
    rune == 0xFEFF;

/// One query's matches: the cities to drill into, and the townships that can
/// be picked straight away.
typedef PlaceSearchResult = ({List<String> cities, List<Town> towns});

/// The township directory pre-folded for [search].
///
/// Built once per picker page, not per keystroke: folding every name is the
/// whole cost of a search, and the directory never changes while the app runs.
class PlaceSearchIndex {
  PlaceSearchIndex(TownDirectory directory)
    : this._(directory.cities, directory.all);

  PlaceSearchIndex._(List<String> cities, Iterable<Town> towns)
    : _cities = [for (final city in cities) (city, foldPlaceName(city))],
      _towns = [
        for (final town in towns)
          (
            town: town,
            name: foldPlaceName(town.townName),
            city: foldPlaceName(town.cityName),
            // `台北市中正區` and `台北中正` both name this township.
            withCity: [
              foldPlaceName('${town.cityName}${town.townName}'),
              foldPlaceName('${town.city}${town.town}'),
            ],
          ),
      ];

  final List<(String, String)> _cities;
  final List<({Town town, String name, String city, List<String> withCity})>
  _towns;

  /// Cities whose name contains [query], and townships it names.
  ///
  /// A township matches on its own name (`板橋` → 新北市 板橋區, `中正` → every
  /// 中正區), or on its name with the city in front (`台北中正`). It does **not**
  /// match on the city part alone: `台北` is a question about the city, which
  /// is already in [PlaceSearchResult.cities], and listing all twelve of its
  /// districts underneath would bury every other answer.
  ///
  /// An empty (or all-whitespace) query matches every city and no township —
  /// the picker's resting state.
  PlaceSearchResult search(String query) {
    final needle = foldPlaceName(query);
    if (needle.isEmpty) {
      return (cities: [for (final (city, _) in _cities) city], towns: const []);
    }
    return (
      cities: [
        for (final (city, folded) in _cities)
          if (folded.contains(needle)) city,
      ],
      towns: [
        for (final entry in _towns)
          if (entry.name.contains(needle) ||
              (!entry.city.contains(needle) &&
                  entry.withCity.any((name) => name.contains(needle))))
            entry.town,
      ],
    );
  }
}
