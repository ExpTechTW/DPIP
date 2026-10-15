/// The shape of the bundled basemap tiles, shared by the tool that packs them
/// (`tool/gen/basemap_seed.dart`), the app that plants them
/// (`basemap_seeder.dart`) and the test that holds the two together.
///
/// Pure Dart on purpose: the generator runs under the plain Dart VM, where
/// anything that reaches `dart:ui` cannot even be imported.
///
/// ## The format
/// Each part is an asset of gzip members laid back to back, one per tile, with
/// no header of its own. Where a tile starts and how long it is lives in the
/// generated index (`basemap_seed.g.dart`), so a part can be planted by slicing
/// views out of the one buffer it arrives in — nothing is parsed, inflated or
/// copied on the UI isolate. A tile the origin answers with no content
/// (204/404, open sea) is an entry of length zero.
///
/// The gzip member is exactly what the tile store keeps for a compressible
/// body (`EtagCacheStore.kindBinaryGzip`), which is why a part can go straight
/// into it.
library;

import 'dart:math' as math;

/// One bundled tile: its address, and where its gzip member sits in the part.
typedef BasemapSeedTile = ({int z, int x, int y, int offset, int length});

/// One bundled asset and the tiles it holds. [bytes] is the asset's length,
/// checked before anything in it is trusted.
typedef BasemapSeedPart = ({
  String asset,
  int bytes,
  List<BasemapSeedTile> tiles,
});

/// A lon/lat box, in degrees.
typedef BasemapSeedBounds = ({
  double west,
  double south,
  double east,
  double north,
});

/// Everything the generator wrote down about one run.
///
/// [version] names the tiles' *content*, so it changes exactly when a
/// regenerated bundle would draw something different — see
/// [basemapSeedVersion]. [source] is the URL template the tiles were fetched
/// from, which is also the key they are stored under. [bounds], [minZoom],
/// [maxZoom] and [worldMaxZoom] are the coverage the run was asked for (see
/// [basemapSeedCoverage]), recorded so a test can check the index against them.
typedef BasemapSeedIndex = ({
  String version,
  String source,
  BasemapSeedBounds bounds,
  int minZoom,
  int maxZoom,
  int worldMaxZoom,
  List<BasemapSeedPart> parts,
});

/// Every XYZ tile the bundle has to hold, sorted by zoom, then x, then y.
///
/// [bounds] at every zoom from [minZoom] to [maxZoom], plus the whole world at
/// every zoom up to [worldMaxZoom] — so a map zoomed out past Taiwan still has
/// the coastlines around it.
List<(int, int, int)> basemapSeedCoverage(
  BasemapSeedBounds bounds, {
  required int minZoom,
  required int maxZoom,
  required int worldMaxZoom,
}) {
  final tiles = <(int, int, int)>{};
  for (var z = minZoom; z <= maxZoom; z++) {
    final (x0, y0) = _tileOf(bounds.west, bounds.north, z);
    final (x1, y1) = _tileOf(bounds.east, bounds.south, z);
    for (var x = x0; x <= x1; x++) {
      for (var y = y0; y <= y1; y++) {
        tiles.add((z, x, y));
      }
    }
  }
  for (var z = 0; z <= worldMaxZoom; z++) {
    final n = 1 << z;
    for (var x = 0; x < n; x++) {
      for (var y = 0; y < n; y++) {
        tiles.add((z, x, y));
      }
    }
  }
  return tiles.toList()..sort((a, b) {
    if (a.$1 != b.$1) return a.$1.compareTo(b.$1);
    if (a.$2 != b.$2) return a.$2.compareTo(b.$2);
    return a.$3.compareTo(b.$3);
  });
}

/// The slippy-map tile holding [lon], [lat] at [z], clamped to the grid.
(int, int) _tileOf(double lon, double lat, int z) {
  final n = 1 << z;
  final x = ((lon + 180) / 360 * n).floor();
  final t = math.tan(lat * math.pi / 180);
  // asinh(t), which `dart:math` does not have: ln(t + sqrt(t² + 1)).
  final mercator = math.log(t + math.sqrt(t * t + 1));
  final y = ((1 - mercator / math.pi) / 2 * n).floor();
  return (x.clamp(0, n - 1), y.clamp(0, n - 1));
}

/// Names a set of tiles by content: FNV-1a (64-bit) over each tile's address,
/// length and *decoded* bytes, in the order given.
///
/// Decoded, not the gzip members: the compressor stamps its host platform into
/// the header, and the same tiles packed on two machines must not look like a
/// new bundle and reseed every installed copy.
String basemapSeedVersion(
  Iterable<({int z, int x, int y, List<int> bytes})> tiles,
) {
  var hash = _fnvOffset;
  void add(int byte) {
    hash ^= byte & 0xff;
    hash *= _fnvPrime;
  }

  void addInt(int value) {
    for (var shift = 0; shift < 32; shift += 8) {
      add(value >> shift);
    }
  }

  for (final tile in tiles) {
    addInt(tile.z);
    addInt(tile.x);
    addInt(tile.y);
    addInt(tile.bytes.length);
    tile.bytes.forEach(add);
  }
  // Two unsigned halves: a 64-bit Dart int is signed, and its own hex would
  // print a minus sign for half of all versions.
  final high = (hash >> 32) & 0xffffffff;
  final low = hash & 0xffffffff;
  return '${high.toRadixString(16).padLeft(8, '0')}'
      '${low.toRadixString(16).padLeft(8, '0')}';
}

const int _fnvOffset = 0xcbf29ce484222325;
const int _fnvPrime = 0x100000001b3;

/// [template] with its `{z}`, `{x}`, `{y}` filled in.
String basemapSeedUrl(String template, int z, int x, int y) => template
    .replaceFirst('{z}', '$z')
    .replaceFirst('{x}', '$x')
    .replaceFirst('{y}', '$y');
