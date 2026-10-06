/// A camera that has not settled warms nothing. A box that would need more
/// tiles than the cap drops one zoom level instead of warming an empty set.
library;

import 'package:dpip/shared/map/map_tile_warmer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('non-finite cameras produce no tiles', () {
    expect(
      viewportTiles(
        south: double.nan,
        west: 120,
        north: 25,
        east: 122,
        zoom: 6,
        maxZoom: 12,
      ),
      isEmpty,
    );
    expect(
      viewportTiles(
        south: 22,
        west: 120,
        north: 25,
        east: double.infinity,
        zoom: 6,
        maxZoom: 12,
      ),
      isEmpty,
    );
  });

  test('an over-wide box falls back one zoom when the cap is exceeded', () {
    final coarse = viewportTiles(
      south: 22,
      west: 119,
      north: 25,
      east: 139,
      zoom: 6,
      maxZoom: 12,
      pad: 0,
      maxTiles: 3,
    );
    expect(coarse, isNotEmpty);
    expect(coarse.map((tile) => tile.z).toSet(), {5});
  });
}
