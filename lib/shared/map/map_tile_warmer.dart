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
/// ([settleDelay]), **generation-guarded**, and serial per consumer. A newer
/// request stops an older one at its next injection chunk, then replaces that
/// working set: URLs outside the new viewport/frame band are evicted from L1
/// before the new priority order fills the reclaimed bytes.
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

  int _cancelEpoch = 0;
  final Map<String, int> _generations = {};
  final Map<String, Set<String>> _workingSets = {};
  Future<void> _serial = Future<void>.value();

  static const String _defaultWorkingSet = 'default';

  // A frame tile always ends in <timestamp>/<z>/<x>/<y>.<ext>. Compressing
  // URLs outside this exact v2 shape could turn a precise basemap/terrain
  // eviction into a much wider one, so those consumers deliberately keep
  // their original URL-per-tile patterns.
  static final RegExp _frameTilePath = RegExp(
    r'^(.*/api/v2/tiles/[^/]+/(?:\d{10}|\d{13})/)\d+/\d+/\d+\.[^/]+$',
  );

  /// Abandons any scheduled or in-flight warm.
  void cancel() {
    _cancelEpoch++;
    MapTileCache.trace('warmer cancel epoch=$_cancelEpoch');
  }

  /// Aborts native tile HTTP for URLs starting with any of [urlPrefixes].
  ///
  /// Scoped, never global: the frames a scrub swept past should stop
  /// downloading, but the basemap and the frame the user landed on must not.
  Future<void> abandon(List<String> urlPrefixes) async {
    if (urlPrefixes.isEmpty) return;
    MapTileCache.trace(
      'warmer abandon frames=${urlPrefixes.length} epoch=$_cancelEpoch',
    );
    await _cache?.cancelFetches(urlContains: urlPrefixes);
  }

  /// Abandons the schedule *and* drops [urlPrefixes]' tiles from MapLibre's
  /// memory. For a layer switch — the bytes stay on disk, so coming back is
  /// still a warm, not a download.
  Future<void> release(List<String> urlPrefixes) async {
    cancel();
    MapTileCache.trace(
      'warmer release sets=${_workingSets.length} '
      'prefixes=${urlPrefixes.length}',
    );
    await _enqueue(() async {
      _workingSets.clear();
      final cache = _cache;
      if (cache == null || urlPrefixes.isEmpty) return;
      await cache.cancelFetches(urlContains: urlPrefixes);
      await cache.evict(urlPrefixes);
    });
  }

  /// Drops one named working set from L1 without touching other consumers.
  ///
  /// Basemap and terrain share a scheduler but own different sets; turning
  /// terrain off should reclaim DEM bytes without flushing the basemap.
  Future<void> discardWorkingSet(String workingSet) async {
    _generations[workingSet] = (_generations[workingSet] ?? 0) + 1;
    await _enqueue(() async {
      final stale = _workingSets.remove(workingSet);
      if (stale == null || stale.isEmpty) return;
      MapTileCache.trace(
        'warmer discard set=$workingSet resident=${stale.length}',
      );
      await _cache?.evict(_evictionPatterns(stale, const <String>{}));
    });
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
    String workingSet = _defaultWorkingSet,
    bool immediate = false,
  }) async {
    final cache = _cache;
    if (cache == null) return;
    final list = <String>{...urls}.toList(growable: false);
    if (list.isEmpty) return;
    final epoch = _cancelEpoch;
    final gen = (_generations[workingSet] ?? 0) + 1;
    _generations[workingSet] = gen;
    final label = logLabel ?? workingSet;
    MapTileCache.trace(
      'warmer schedule label=$label set=$workingSet gen=$gen '
      'wanted=${list.length} fill=${fillUntil.toStringAsFixed(2)} '
      'delay=${immediate ? 0 : settleDelay.inMilliseconds}ms',
    );
    if (!immediate && settleDelay > Duration.zero) {
      await Future<void>.delayed(settleDelay);
    }
    if (!_isCurrent(workingSet, epoch, gen)) {
      MapTileCache.trace(
        'warmer superseded label=$label set=$workingSet gen=$gen before-queue',
      );
      return;
    }

    await _enqueue(() async {
      if (!_isCurrent(workingSet, epoch, gen)) {
        MapTileCache.trace(
          'warmer superseded label=$label set=$workingSet gen=$gen in-queue',
        );
        return;
      }
      final wanted = list.toSet();
      final previous = _workingSets[workingSet] ?? const <String>{};
      final stale = previous.difference(wanted);
      final evictionPatterns = _evictionPatterns(stale, wanted);
      MapTileCache.trace(
        'warmer start label=$label set=$workingSet gen=$gen '
        'previous=${previous.length} evict=${stale.length} '
        'patterns=${evictionPatterns.length}',
      );
      if (evictionPatterns.isNotEmpty) {
        await cache.evict(evictionPatterns);
      }

      final result = await cache.warm(
        list,
        fillUntil: fillUntil,
        shouldContinue: () => _isCurrent(workingSet, epoch, gen),
      );
      // Record what native really retained even when a newer generation arrived
      // mid-injection. Its queued replacement then knows exactly what to evict.
      _workingSets[workingSet] = result.resident;
      MapTileCache.trace(
        'warmer done label=$label set=$workingSet gen=$gen '
        'current=${_isCurrent(workingSet, epoch, gen)} '
        'injected=${result.injected} resident=${result.resident.length}/'
        '${list.length}',
      );
      if (_isCurrent(workingSet, epoch, gen) &&
          logLabel != null &&
          result.injected > 0) {
        Log.debug(
          'MapTileWarmer $logLabel '
          'injected=${result.injected}/${list.length} '
          'resident=${result.resident.length}',
        );
      }
    });
  }

  /// Immediately prepares a small, display-critical URL set.
  ///
  /// Unlike [warmUrls], this does not replace a speculative working set or wait
  /// behind its debounce. It does pre-empt that set's scheduled/in-flight fill:
  /// a thousand-row background SQLite scan must never outrank the handful of
  /// current-viewport tiles that gate a raster timestamp cutover. The partial
  /// resident set is still recorded by [warmUrls], so the next settled fill can
  /// evict or reuse it normally.
  Future<TileWarmResult> prepareUrls(Iterable<String> urls) {
    final list = <String>{...urls}.toList(growable: false);
    final cache = _cache;
    if (cache == null || list.isEmpty) {
      return Future<TileWarmResult>.value((injected: 0, resident: <String>{}));
    }
    _generations[_defaultWorkingSet] =
        (_generations[_defaultWorkingSet] ?? 0) + 1;
    return cache.warm(list);
  }

  /// Probes L1 without touching SQLite or changing a speculative working set.
  Future<Set<String>> residentUrls(Iterable<String> urls) {
    final cache = _cache;
    if (cache == null) return Future<Set<String>>.value(<String>{});
    return cache.residentUrls(urls);
  }

  bool _isCurrent(String workingSet, int epoch, int generation) =>
      epoch == _cancelEpoch && _generations[workingSet] == generation;

  Future<void> _enqueue(Future<void> Function() operation) {
    final next = _serial.then((_) => operation());
    _serial = next.catchError((Object error, StackTrace stackTrace) {
      Log.handle(error, stackTrace, 'MapTileWarmer operation');
    });
    return next;
  }

  /// Collapses fully stale raster frames to one native substring match each.
  ///
  /// Native eviction scans every resident URL against every supplied pattern
  /// while holding its memory-store lock. A timeline hop can retire hundreds
  /// of tiles at once, so sending every complete URL makes one platform call
  /// quadratic enough to block the UI thread. A frame prefix is equivalent
  /// only when the new working set retains no URL from that frame; otherwise
  /// the stale tiles stay precise so current-viewport tiles cannot be removed.
  static List<String> _evictionPatterns(Set<String> stale, Set<String> wanted) {
    if (stale.isEmpty) return const [];
    final wantedFrames = <String>{};
    for (final url in wanted) {
      final prefix = _framePrefix(url);
      if (prefix != null) wantedFrames.add(prefix);
    }

    final patterns = <String>{};
    for (final url in stale) {
      final prefix = _framePrefix(url);
      patterns.add(
        prefix != null && !wantedFrames.contains(prefix) ? prefix : url,
      );
    }
    return patterns.toList(growable: false);
  }

  static String? _framePrefix(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return null;
    final match = _frameTilePath.firstMatch(uri.path);
    final path = match?.group(1);
    if (path == null) return null;
    return '${uri.origin}$path';
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
    String workingSet = _defaultWorkingSet,
    bool immediate = false,
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
      workingSet: workingSet,
      immediate: immediate,
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
    String workingSet = _defaultWorkingSet,
    bool immediate = false,
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
    return warmUrls(
      [for (final tile in tiles) urlFor(tile.z, tile.x, tile.y)],
      logLabel: logLabel ?? 'xyz z=${tiles.first.z}',
      workingSet: workingSet,
      immediate: immediate,
    );
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
