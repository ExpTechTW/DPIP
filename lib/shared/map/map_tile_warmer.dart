/// Turns a viewport into tile URLs and warms them into native memory.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/api_region.dart';
import 'package:dpip/shared/map/map_tile_cache.dart';
import 'package:dpip/shared/map/xyz_tiles.dart';

/// Shared warm-up spine for radar / satellite / DPM / basemap.
///
/// Given a camera box it derives the XYZ tiles MapLibre will ask for, then hands
/// those URLs to [MapTileCache.warm] so their bytes are sitting in native memory
/// *before* the layer is revealed. Nothing here touches the network: the bytes
/// either exist in the app's store or they don't, and a miss simply means
/// MapLibre downloads that tile the ordinary way.
///
/// That is the whole reason this replaced the old Dio-based prefetcher, which
/// was permanently disabled because it raced MapLibre for the same URLs and
/// doubled the traffic. Reading what we already have costs nothing and races
/// nobody.
///
/// Scrubs and pans schedule work constantly, so a warm is **debounced**
/// ([settleDelay]) and **generation-guarded**: a superseded request is dropped
/// before it reads anything, and [cancel] abandons whatever is in flight.
class MapTileWarmer {
  MapTileWarmer(
    this._cache, {
    this.maxTiles = 48,
    this.settleDelay = const Duration(milliseconds: 120),
  });

  /// Null when the cache database couldn't be opened — every warm is then a
  /// no-op and MapLibre simply downloads tiles the ordinary way.
  final MapTileCache? _cache;

  /// Ceiling on tiles per warm — a wide camera drops to a coarser zoom instead.
  final int maxTiles;

  /// How long a schedule waits for the camera / finger to settle.
  final Duration settleDelay;

  int _generation = 0;

  /// Abandons any scheduled or in-flight warm.
  void cancel() => _generation++;

  /// Aborts native tile HTTP for URLs starting with any of [urlPrefixes].
  ///
  /// Scoped, never global: the frames a scrub swept past should stop
  /// downloading, but the basemap and the frame the user landed on must not.
  Future<void> abandon(List<String> urlPrefixes) async {
    if (urlPrefixes.isEmpty) return;
    await _cache?.cancelFetches(urlContains: urlPrefixes);
  }

  /// Abandons the schedule *and* drops [urlPrefixes]' tiles from MapLibre's
  /// memory. For a layer switch — the bytes stay on disk, so coming back is
  /// still a warm, not a download.
  Future<void> release(List<String> urlPrefixes) async {
    cancel();
    final cache = _cache;
    if (cache == null || urlPrefixes.isEmpty) return;
    await cache.cancelFetches(urlContains: urlPrefixes);
    await cache.evict(urlPrefixes);
  }

  /// Warms absolute tile [urls] (already resolved, e.g. from a layer's
  /// `tileUrl` template).
  ///
  /// [fillUntil] (0 = off) puts the cache in fill mode: [urls] must be ordered
  /// most-wanted first, and injection stops once the native mirror is near its
  /// cap — the caller tops it up outward from the current frame.
  Future<void> warmUrls(
    Iterable<String> urls, {
    String? logLabel,
    double fillUntil = 0,
  }) async {
    final cache = _cache;
    if (cache == null) return;
    final list = urls.toList(growable: false);
    if (list.isEmpty) return;
    final gen = ++_generation;
    await Future<void>.delayed(settleDelay);
    if (gen != _generation) return;
    final injected = await cache.warm(list, fillUntil: fillUntil);
    if (gen == _generation && logLabel != null && injected > 0) {
      Log.debug('MapTileWarmer $logLabel injected=$injected/${list.length}');
    }
  }

  /// Warms the viewport for a region-pinned path template.
  ///
  /// [pathFor] returns `/api/…/{z}/{x}/{y}.ext`; the origin is resolved the same
  /// way [ApiClient] would, so the URL matches what MapLibre requests byte for
  /// byte — a mismatch here would silently warm keys nothing ever asks for.
  Future<void> warmViewport({
    required ApiClient client,
    required ApiTier tier,
    required String Function(int z, int x, int y) pathFor,
    required double south,
    required double west,
    required double north,
    required double east,
    required double zoom,
    int maxZoom = 16,
    int pad = 1,
    String? logLabel,
  }) {
    final hosts = client.hostsFor(tier);
    if (hosts.isEmpty) return Future<void>.value();
    final origin = hosts.first;
    return warmViewportAbsolute(
      urlFor: (z, x, y) => '$origin${pathFor(z, x, y)}',
      south: south,
      west: west,
      north: north,
      east: east,
      zoom: zoom,
      maxZoom: maxZoom,
      pad: pad,
      logLabel: logLabel,
    );
  }

  /// Warms the viewport for an absolute URL template (basemap and friends).
  Future<void> warmViewportAbsolute({
    required String Function(int z, int x, int y) urlFor,
    required double south,
    required double west,
    required double north,
    required double east,
    required double zoom,
    int maxZoom = 12,
    int pad = 1,
    String? logLabel,
  }) {
    final tiles = viewportTiles(
      south: south,
      west: west,
      north: north,
      east: east,
      zoom: zoom,
      maxZoom: maxZoom,
      pad: pad,
      maxTiles: maxTiles,
    );
    if (tiles.isEmpty) return Future<void>.value();
    return warmUrls([
      for (final tile in tiles) urlFor(tile.z, tile.x, tile.y),
    ], logLabel: logLabel ?? 'xyz z=${tiles.first.z}');
  }
}

/// The XYZ tiles covering a camera box, dropping one zoom level when the box
/// would need more than [maxTiles].
///
/// Shared by every warm path so the coarser-zoom fallback can't drift between
/// them (a layer that skipped it just warmed nothing on a wide camera).
List<XyzTile> viewportTiles({
  required double south,
  required double west,
  required double north,
  required double east,
  required double zoom,
  required int maxZoom,
  int pad = 1,
  int maxTiles = 48,
}) {
  // A camera that hasn't settled can report NaN/∞ for zoom and bounds —
  // MapLibre returns these mid-init or during a transition. Nothing to warm
  // until it's finite; bailing here (instead of letting `zoom.floor()` throw)
  // makes every warm path a no-op instead of a crash.
  if (!south.isFinite ||
      !west.isFinite ||
      !north.isFinite ||
      !east.isFinite ||
      !zoom.isFinite) {
    return const [];
  }
  final z = math.min(zoom.floor(), maxZoom);
  final tiles = tilesCovering(
    south: south,
    west: west,
    north: north,
    east: east,
    z: z,
    pad: pad,
    maxTiles: maxTiles,
  );
  if (tiles.isNotEmpty || z <= 0) return tiles;
  return tilesCovering(
    south: south,
    west: west,
    north: north,
    east: east,
    z: z - 1,
    pad: pad,
    maxTiles: maxTiles,
  );
}
