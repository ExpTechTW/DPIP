import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:dpip/features/location/domain/town.dart';
import 'package:flutter/services.dart' show rootBundle;

/// The Taiwan township directory, loaded from the bundled
/// `assets/location.json.gz`, with lookup by code and by GPS coordinate.
///
/// GPS→township is **nearest centroid** for now (dependency-light and exact
/// enough away from borders); a point-in-polygon upgrade using
/// `assets/map/town.json.zst` can replace [nearest] later without touching
/// callers. Pure and injectable — [fromJson] builds it from decoded data so the
/// lookup is unit-testable without the asset.
class TownDirectory {
  const TownDirectory(this._byCode);

  final Map<String, Town> _byCode;

  /// Builds the directory from the raw `code → {city,…}` JSON map, injecting the
  /// map key as each town's [Town.code].
  factory TownDirectory.fromJson(Map<String, dynamic> json) => TownDirectory({
    for (final entry in json.entries)
      entry.key: Town.fromJson({
        ...entry.value as Map<String, dynamic>,
        'code': entry.key,
      }),
  });

  /// Loads and decodes the bundled directory (`gzip` → JSON).
  static Future<TownDirectory> load() async {
    final bytes = await rootBundle.load('assets/location.json.gz');
    final json =
        jsonDecode(utf8.decode(gzip.decode(bytes.buffer.asUint8List())))
            as Map<String, dynamic>;
    return TownDirectory.fromJson(json);
  }

  /// Every township.
  Iterable<Town> get all => _byCode.values;

  /// The township with [code], or null.
  Town? byCode(String? code) => code == null ? null : _byCode[code];

  /// The township whose centroid is nearest to ([lat], [lng]), or null if the
  /// directory is empty. Distance is cos-weighted planar (fine at Taiwan's
  /// extent) so no per-town trig is needed.
  Town? nearest(double lat, double lng) {
    final cosLat = math.cos(lat * math.pi / 180);
    Town? best;
    var bestSq = double.infinity;
    for (final town in _byCode.values) {
      final dLat = lat - town.lat;
      final dLng = (lng - town.lng) * cosLat;
      final sq = dLat * dLat + dLng * dLng;
      if (sq < bestSq) {
        bestSq = sq;
        best = town;
      }
    }
    return best;
  }
}
