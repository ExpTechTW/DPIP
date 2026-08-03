import 'package:dpip/shared/map/xyz_tiles.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Taipei ~ near z=10 is a single tile neighbourhood', () {
    // ~25.03°N 121.56°E
    final tiles = tilesCovering(
      south: 25.0,
      west: 121.5,
      north: 25.1,
      east: 121.6,
      z: 10,
      pad: 0,
    );
    expect(tiles, isNotEmpty);
    expect(tiles.every((t) => t.z == 10), isTrue);
    expect(tiles.length, lessThanOrEqualTo(4));
  });

  test('pad expands coverage by one ring', () {
    final tight = tilesCovering(
      south: 25.03,
      west: 121.56,
      north: 25.04,
      east: 121.57,
      z: 12,
      pad: 0,
    );
    final padded = tilesCovering(
      south: 25.03,
      west: 121.56,
      north: 25.04,
      east: 121.57,
      z: 12,
      pad: 1,
    );
    expect(padded.length, greaterThan(tight.length));
  });

  test('oversized coverage returns empty (caller drops zoom)', () {
    final tiles = tilesCovering(
      south: -85,
      west: -180,
      north: 85,
      east: 180,
      z: 8,
      pad: 0,
      maxTiles: 48,
    );
    expect(tiles, isEmpty);
  });

  test('lng/lat → tile known anchors', () {
    // Equator / prime meridian at z=0 → tile (0,0)
    expect(lngToTileX(0, 0), 0);
    expect(latToTileY(0, 0), 0);
    // z=1: eastern hemisphere
    expect(lngToTileX(90, 1), 1);
  });
}
