/// The static RTS detection "box" grid: coarse cells covering Taiwan, each
/// keyed by an integer id. A box lights up when an alerting station stands in
/// it (see `rts_alert_areas.dart`), and the grid turns the lit ids into map
/// polygons. Pure domain data — the grid itself is loaded by the data layer
/// and injected here.
class RtsBoxGrid {
  const RtsBoxGrid(this.rings);

  /// Each box's closed polygon ring (`[lon, lat]` pairs), keyed by its id.
  final Map<int, List<List<double>>> rings;

  /// The box the point stands in, or null outside every box.
  ///
  /// An even–odd ray cast on each ring — the test the server ran when it still
  /// sent `box` itself, and the one TREM-Lite runs now. The cells tile without
  /// overlapping, so the first hit is the only one.
  int? boxAt(double latitude, double longitude) {
    for (final entry in rings.entries) {
      if (_contains(entry.value, latitude, longitude)) return entry.key;
    }
    return null;
  }

  static bool _contains(
    List<List<double>> ring,
    double latitude,
    double longitude,
  ) {
    var inside = false;
    for (var i = 0, j = ring.length - 1; i < ring.length; j = i++) {
      final xi = ring[i][0], yi = ring[i][1];
      final xj = ring[j][0], yj = ring[j][1];
      if ((yi > latitude) != (yj > latitude) &&
          longitude < (xj - xi) * (latitude - yi) / (yj - yi) + xi) {
        inside = !inside;
      }
    }
    return inside;
  }
}
