/// Dart's side of the MapLibre tile cache — the authority for tile bytes.
library;

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/network/etag_cache_store.dart';
import 'package:dpip/core/network/etag_interceptor.dart';
import 'package:dpip/core/network/network_usage_store.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// Owns tile bytes for MapLibre: SQLite persistence, traffic metering, and the
/// warm path that pushes bytes into native memory before they are needed.
///
/// ## Why the app caches tiles at all
/// MapLibre keeps its own ambient database, but it only fills on a *live*
/// download. The app already has these bytes in [EtagCacheStore] (shared with
/// every other HTTP fetch, metered, and swept on the app's own policy), so the
/// native side is bound to ask here first.
///
/// ## Why this is fast now
/// The bridge is **batched in both directions and blocking in neither**. Native
/// coalesces the tiles a viewport asks for into one [getBatch], answered by one
/// `IN` query; downloaded bodies come back as one [putBatch], written in one
/// transaction. The previous design asked per tile and parked the requesting
/// thread on a 100 ms timeout — under a timeline scrub that timeout fired
/// constantly, and every timeout read as a cache *miss*, so the app
/// re-downloaded tiles it already had on disk.
///
/// ## The warm path
/// [warm] is the reason a scrub can be smooth: the caller names the tile URLs a
/// frame is about to need, and this reads them out of SQLite and injects them
/// into native's in-process mirror. When the frame is then revealed, MapLibre
/// resolves every tile from memory — no IPC, no SQLite, no network.
class MapTileCache {
  /// [usage] meters tiles native downloaded. Cache *hits* are metered inside
  /// [EtagCacheStore], so they must never be counted again here.
  //
  // Not an initializing formal: Dart has no private *named* parameter, and the
  // field must stay private.
  // ignore: prefer_initializing_formals
  MapTileCache(this._store, {NetworkUsageStore? usage}) : _usage = usage;

  final EtagCacheStore _store;
  final NetworkUsageStore? _usage;

  /// Native's in-process mirror budget.
  ///
  /// This tier is a staging buffer for the warm path, not a second copy of the
  /// store: the store stays the source of truth for every byte, and anything
  /// the mirror does not hold is read back from it. Sizing it is a trade-off —
  /// too small and a warm band ([RasterTimelineLayer.warmRadius]) evicts its
  /// own earlier tiles mid-injection and re-reads them on every settle; too
  /// large and the mirror quietly becomes the real cache, leaving
  /// [EtagCacheStore] doing nothing but the cold start.
  ///
  /// 24 MB holds a full ±12-frame scrub band of webp tiles *plus* the basemap
  /// viewport, so a fast timeline drag stays on memory hits even while the map
  /// itself downloads. [warm]'s fill mode ([warm]) tops it up outward from the
  /// current frame until it is near this cap, then stops — the mirror trims
  /// LRU beyond it, dropping the frames a scrub swept past.
  static const int defaultMemoryBytes = 24 * 1024 * 1024;

  /// Tiles per `injectTiles` message — roughly one frame's viewport.
  static const int _injectChunk = 24;

  /// Binds this store as the tile authority and sizes the native mirror.
  ///
  /// The patterns come from [EtagInterceptor.immutableAssetMarkers] — the same
  /// list [_isTile] gates on — so native can never end up asking about a URL
  /// this store would refuse to keep.
  Future<void> install({int memoryBytes = defaultMemoryBytes}) async {
    await bindMapLibreTileCache(
      cacheablePatterns: EtagInterceptor.immutableAssetMarkers,
      getBatch: _onGetBatch,
      putBatch: _onPutBatch,
    );
    await setMapLibreTileMemoryLimit(memoryBytes);
  }

  /// Native asked for tile bodies — answer the ones we hold.
  Future<List<MapLibreTile>> _onGetBatch(List<String> urls) async {
    final wanted = urls.where(_isTile).toList(growable: false);
    if (wanted.isEmpty) return const [];
    // Hit metering lives inside [EtagCacheStore.readBytesBatch] — never
    // double-count these serves here.
    final hits = await _store.readBytesBatch(wanted);
    return [
      for (final entry in hits.entries)
        MapLibreTile(
          url: entry.key,
          data: entry.value.bytes,
          contentType: entry.value.contentType,
          etag: entry.value.etag,
        ),
    ];
  }

  /// Native downloaded tiles — persist and meter them.
  Future<void> _onPutBatch(List<MapLibreTile> tiles) async {
    final writes = <BinaryWrite>[];
    var downloaded = 0;
    for (final tile in tiles) {
      final uri = Uri.tryParse(tile.url);
      if (uri == null || !EtagInterceptor.isImmutableTile(uri)) continue;
      // A 404 arrives as an empty body. For the basemap that is a deliberate
      // hole worth keeping (ocean / uncovered z-x-y is stable). For anything
      // else — a glyph range that momentarily failed, say — persisting
      // emptiness would serve a blank asset for the next seven days.
      if (tile.data.isEmpty && !EtagInterceptor.isBasemapPbf(uri)) continue;
      writes.add((
        url: tile.url,
        // The URL is content-addressed, so the synthetic tag is the right key —
        // a new frame is a new URL, never a revalidation of this one.
        etag: EtagInterceptor.etagFromUrl(uri),
        bytes: tile.data,
        contentType: tile.contentType,
        size: tile.data.length,
      ));
      downloaded += tile.data.length;
    }
    if (writes.isEmpty) return;
    await _store.writeBytesBatch(writes);
    unawaited(_usage?.record(down: downloaded, hit: false, saved: 0));
  }

  /// Pushes the cached bodies for [urls] into native memory, skipping whatever
  /// native already holds.
  ///
  /// Returns how many tiles were injected. Safe to call often — the
  /// already-resident check is a strings-only round-trip, so a repeat warm of
  /// the same frame costs almost nothing.
  ///
  /// When [fillUntil] is non-zero, injection runs in [fillUntil]'s **fill
  /// mode**: [urls] must be ordered most-wanted first, and the loop stops once
  /// the native mirror is at `fillUntil × limit` — so a timeline can top the
  /// mirror up outward from the current frame until it is nearly full and then
  /// stop, instead of over-filling and churning LRU (or re-reading on settle).
  Future<int> warm(List<String> urls, {double fillUntil = 0}) async {
    final wanted = urls.where(_isTile).toList(growable: false);
    if (wanted.isEmpty) return 0;
    try {
      final missing = await mapLibreTilesMissing(wanted);
      if (missing.isEmpty) return 0;
      // Don't bump last-used for a speculative warm: a frame the user scrubbed
      // past must not outrank one they actually looked at.
      final hits = await _store.readBytesBatch(missing, touch: false);
      if (hits.isEmpty) return 0;
      final tiles = [
        for (final entry in hits.entries)
          MapLibreTile(
            url: entry.key,
            data: entry.value.bytes,
            contentType: entry.value.contentType,
            etag: entry.value.etag,
          ),
      ];
      // Chunked: warming a wide band of frames is megabytes of image data, and
      // one giant message would occupy the platform channel long enough to be
      // felt by whatever gesture is in progress. Each inject echoes the
      // mirror's post-injection usage, so a fill warm can bail as it nears the
      // cap — the remaining (more distant) urls simply stay cold.
      for (var i = 0; i < tiles.length; i += _injectChunk) {
        final end = math.min(i + _injectChunk, tiles.length);
        final usage = await injectMapLibreTiles(tiles.sublist(i, end));
        if (fillUntil > 0 &&
            usage != null &&
            usage.limit > 0 &&
            usage.used >= usage.limit * fillUntil) {
          break;
        }
      }
      return hits.length;
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'MapTileCache.warm');
      return 0;
    }
  }

  /// Stores [bytes] for [url] directly (a body the app fetched itself).
  Future<void> put(String url, Uint8List bytes, {String? contentType}) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !EtagInterceptor.isImmutableTile(uri)) return;
    await _store.writeBytesBatch([
      (
        url: url,
        etag: EtagInterceptor.etagFromUrl(uri),
        bytes: bytes,
        contentType: contentType,
        size: bytes.length,
      ),
    ]);
  }

  /// Aborts in-flight native tile HTTP whose URL contains one of [urlContains].
  ///
  /// **Always scope this.** An unscoped cancel takes the basemap and the frame
  /// the user is actually looking at down with the abandoned ones, which reads
  /// as a stall rather than a speed-up.
  Future<void> cancelFetches({List<String> urlContains = const []}) =>
      cancelMapLibreTileFetches(urlContains: urlContains);

  /// Drops tiles matching [urlContains] from native's mirror (bytes stay in
  /// SQLite — this only reclaims memory).
  Future<void> evict(List<String> urlContains) =>
      evictMapLibreTiles(urlContains);

  static bool _isTile(String url) {
    final uri = Uri.tryParse(url);
    return uri != null && EtagInterceptor.isImmutableTile(uri);
  }
}
