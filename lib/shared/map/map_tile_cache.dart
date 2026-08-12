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
  MapTileCache(
    this._store, {
    NetworkUsageStore? usage,
    // ignore: prefer_initializing_formals
  }) : _usage = usage;

  final EtagCacheStore _store;
  // Not initializing formals: Dart has no private *named* parameter, and these
  // fields must stay private.
  // ignore: prefer_initializing_formals
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
  /// 48 MB holds a full ±64-frame scrub band of webp tiles *plus* the basemap
  /// viewport, so a fast timeline drag stays on memory hits even while the map
  /// itself downloads. [warm]'s fill mode ([warm]) tops it up outward from the
  /// current frame until it is near this cap, then stops — the mirror trims
  /// LRU beyond it, dropping the frames a scrub swept past.
  static const int defaultMemoryBytes = 48 * 1024 * 1024;

  /// Tiles per `injectTiles` message — roughly one frame's viewport.
  static const int _injectChunk = 24;

  /// The cap [install] sized the mirror with — remembered so a fill warm can
  /// estimate how much it may inject without overshooting into a trim.
  int _memoryLimit = defaultMemoryBytes;

  /// Binds this store as the tile authority and sizes the native mirror.
  ///
  /// The patterns come from [EtagInterceptor.immutableAssetMarkers] — the same
  /// list [_isTile] gates on — so native can never end up asking about a URL
  /// this store would refuse to keep.
  Future<void> install({int memoryBytes = defaultMemoryBytes}) async {
    _memoryLimit = memoryBytes;
    await bindMapLibreTileCache(
      cacheablePatterns: EtagInterceptor.immutableAssetMarkers,
      getBatch: _onGetBatch,
      putBatch: _onPutBatch,
    );
    await setMapLibreTileMemoryLimit(memoryBytes);
  }

  /// Native asked for tile bodies — answer the ones we hold; a store miss
  /// keeps the native-download path.
  Future<List<MapLibreTile>> _onGetBatch(List<String> urls) async {
    final wanted = urls.where(_isTile).toList(growable: false);
    if (wanted.isEmpty) return const [];
    // Hit metering lives inside [EtagCacheStore.readBytesBatch] — never
    // double-count these serves here.
    final hits = await _store.readBytesBatch(wanted);
    final served = <String, MapLibreTile>{};
    for (final entry in hits.entries) {
      served[entry.key] = MapLibreTile(
        url: entry.key,
        data: entry.value.bytes,
        contentType: entry.value.contentType,
        etag: entry.value.etag,
      );
    }
    return served.values.toList();
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
      final bytes = tile.data;
      writes.add((
        url: tile.url,
        // The URL is content-addressed, so the synthetic tag is the right key —
        // a new frame is a new URL, never a revalidation of this one.
        etag: EtagInterceptor.etagFromUrl(uri),
        bytes: bytes,
        contentType: tile.contentType,
        size: bytes.length,
      ));
      downloaded += bytes.length;
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
  /// the native mirror is estimated to be at `fillUntil × limit` — so a
  /// timeline can top the mirror up outward from the current frame until it is
  /// nearly full and then stop, instead of over-filling into a native LRU trim
  /// (which would evict the very frames just injected).
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
      if (fillUntil > 0) return _injectFill(tiles, fillUntil);
      return _injectAll(tiles);
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'MapTileCache.warm');
      return 0;
    }
  }

  /// Injects every [tiles] in fixed chunks.
  ///
  /// Chunked because warming a wide band of frames is megabytes of image data,
  /// and one giant message would occupy the platform channel long enough to be
  /// felt by whatever gesture is in progress.
  Future<int> _injectAll(List<MapLibreTile> tiles) async {
    for (var i = 0; i < tiles.length; i += _injectChunk) {
      final end = math.min(i + _injectChunk, tiles.length);
      await injectMapLibreTiles(tiles.sublist(i, end));
    }
    return tiles.length;
  }

  /// Injects [tiles] (ordered most-wanted first) until the mirror is estimated
  /// to hold `fillUntil × cap` bytes, then stops.
  ///
  /// The estimate is the last `injectTiles` echo plus the bytes this side is
  /// about to send — native trims LRU beyond the cap and *down to 85% of it*,
  /// so overshooting once (a chunk's worth of tiles past the goal) would evict
  /// exactly the frames that were just injected, which is worse than stopping
  /// a little short. When a chunk straddles the goal it is split and only the
  /// fitting prefix is sent.
  Future<int> _injectFill(List<MapLibreTile> tiles, double fillUntil) async {
    final cap = (_memoryLimit * fillUntil).floor();
    if (cap <= 0) return 0;
    var used = 0; // No pre-inject usage query — start at the optimistic 0.
    var injected = 0;
    for (var i = 0; i < tiles.length; i += _injectChunk) {
      final end = math.min(i + _injectChunk, tiles.length);
      var chunkBytes = 0;
      for (var j = i; j < end; j++) {
        chunkBytes += tiles[j].data.length;
      }
      if (used + chunkBytes > cap) {
        // Split the chunk at the goal — send only the tiles that fit.
        final fits = <MapLibreTile>[];
        var size = 0;
        for (var j = i; j < end; j++) {
          if (used + size + tiles[j].data.length > cap) break;
          fits.add(tiles[j]);
          size += tiles[j].data.length;
        }
        if (fits.isEmpty) break;
        final usage = await injectMapLibreTiles(fits);
        used = usage?.used ?? used + size;
        injected += fits.length;
        break;
      }
      final usage = await injectMapLibreTiles(tiles.sublist(i, end));
      used = usage?.used ?? used + chunkBytes;
      injected += end - i;
    }
    return injected;
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
