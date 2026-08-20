/// Dart's side of the MapLibre tile cache — the authority for tile bytes.
library;

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/network/etag_cache_store.dart';
import 'package:dpip/core/network/etag_interceptor.dart';
import 'package:dpip/core/network/network_usage_store.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:maplibre_gl/maplibre_gl.dart';

/// What one L1 warm actually accomplished.
///
/// [resident] is probed after injection rather than inferred from the request:
/// the SQLite store may miss, another consumer may have displaced an entry, or
/// native may have trimmed at its byte cap.
typedef TileWarmResult = ({int injected, Set<String> resident});

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
  /// Temporary, code-owned switch for the tile timing trace.
  ///
  /// Keep this off in normal development: cache tracing deliberately adds
  /// probes and log writes to the hottest map path. Turn it on only while
  /// reproducing a raster flicker, then search the app log for `TILE TRACE`.
  /// [kDebugMode] below is a second hard gate, so changing this cannot make a
  /// release build persist tile URLs or pay the diagnostic overhead.
  static bool traceEnabled = false;

  static int _traceSequence = 0;

  /// Emits one line in a stable format shared by cache, warmer and timeline.
  static void trace(String message) {
    if (!kDebugMode || !traceEnabled) return;
    Log.debug('TILE TRACE $message');
  }

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
  /// 48 MB holds hundreds of frame viewports plus the basemap. [warm]'s fill
  /// mode tops it up outward from the current frame until it is near this cap,
  /// then stops — the mirror trims LRU beyond it, dropping the frames a scrub
  /// swept past.
  static const int defaultMemoryBytes = 48 * 1024 * 1024;

  /// Tiles per `injectTiles` message — roughly one frame's viewport.
  static const int _injectChunk = 24;

  /// L2 URLs read at once while filling L1 — 16 typical frame viewports.
  ///
  /// The candidate window is deliberately much wider than memory. Reading its
  /// every body before injection briefly doubled tens of MiB in Dart, even
  /// though fill mode stopped once native reached its cap. This stays aligned
  /// to both [_injectChunk] and SQLite's 400-variable query chunk.
  static const int _fillReadChunk = _injectChunk * 16;

  /// URLs per native L1-presence probe.
  ///
  /// A settled radar fill can name 12k+ tiles. Sending that as one platform
  /// message makes iOS decode a huge string array and perform every lookup on
  /// the platform thread before it can draw again. Bounded probes preserve the
  /// same answer while giving the event loop regular scheduling points.
  static const int _probeChunk = _fillReadChunk;

  /// Large fills are intentionally exhaustive, but not urgent. Briefly yield
  /// after this many native messages so pointer/lifecycle/render work can run
  /// while L1 is filled in the background.
  static const int _messagesPerSlice = 4;
  static const Duration _cooperativePause = Duration(milliseconds: 2);

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
    trace('config install limit=${_bytes(memoryBytes)}');
  }

  /// Re-applies settings that can be sent before MapLibre's channel exists.
  ///
  /// Bootstrap binds the Dart handlers before the first platform map is
  /// created. Native pulls the URL patterns when it attaches, but the memory
  /// cap is a Dart-to-native setting and that early message can be lost. The
  /// scaffold calls this once it owns a live controller so L1 is really the
  /// configured 48 MB instead of native's 2 MB bootstrap default.
  Future<void> syncNativeConfiguration() async {
    await setMapLibreTileMemoryLimit(_memoryLimit);
    trace('config live-sync limit=${_bytes(_memoryLimit)}');
  }

  /// Native asked for tile bodies — answer the ones we hold; a store miss
  /// keeps the native-download path.
  Future<List<MapLibreTile>> _onGetBatch(List<String> urls) async {
    final elapsed = Stopwatch()..start();
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
    trace(
      'demand l1-miss=${wanted.length} '
      'l2-hit=${served.length} l2-miss=${wanted.length - served.length} '
      'bytes=${_bytes(_tileBytes(served.values))} '
      'dt=${elapsed.elapsedMilliseconds}ms '
      'sample=${_urls(wanted)}',
    );
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
    trace(
      'network-fill count=${writes.length} bytes=${_bytes(downloaded)} '
      'sample=${_urls([for (final write in writes) write.url])}',
    );
    unawaited(_usage?.record(down: downloaded, hit: false, saved: 0));
  }

  /// Pushes the cached bodies for [urls] into native memory, skipping whatever
  /// native already holds.
  ///
  /// Returns the injected count and the requested URLs still resident after
  /// the operation. Safe to call often — the resident probes are strings-only
  /// round-trips, so a repeat warm of the same frame costs almost nothing.
  ///
  /// When [fillUntil] is non-zero, injection runs in [fillUntil]'s **fill
  /// mode**: [urls] must be ordered most-wanted first, and the loop stops once
  /// the native mirror is estimated to be at `fillUntil × limit` — so a
  /// timeline can top the mirror up outward from the current frame until it is
  /// nearly full and then stop, instead of over-filling into a native LRU trim
  /// (which would evict the very frames just injected).
  Future<TileWarmResult> warm(
    List<String> urls, {
    double fillUntil = 0,
    bool Function()? shouldContinue,
  }) async {
    // A set preserves insertion order: priority survives while duplicate URLs
    // do not waste a native probe or a tile-body transfer.
    final wanted = <String>{
      for (final url in urls)
        if (_isTile(url)) url,
    }.toList(growable: false);
    if (wanted.isEmpty) return (injected: 0, resident: <String>{});
    final traceId = ++_traceSequence;
    final elapsed = Stopwatch()..start();
    trace(
      'warm#$traceId start wanted=${wanted.length} '
      'fill=${fillUntil > 0 ? fillUntil.toStringAsFixed(2) : 'all'} '
      'sample=${_urls(wanted)}',
    );
    try {
      final missing = await _missingFromL1(
        wanted,
        shouldContinue: shouldContinue,
      );
      trace(
        'warm#$traceId probe l1-hit=${wanted.length - missing.length} '
        'l1-miss=${missing.length} dt=${elapsed.elapsedMilliseconds}ms',
      );
      if (missing.isEmpty) {
        trace(
          'warm#$traceId done injected=0 resident=${wanted.length}/'
          '${wanted.length} dt=${elapsed.elapsedMilliseconds}ms',
        );
        return (injected: 0, resident: wanted.toSet());
      }
      if (shouldContinue?.call() == false) {
        final absent = missing.toSet();
        trace('warm#$traceId cancelled before-l2');
        return (
          injected: 0,
          resident: {
            for (final url in wanted)
              if (!absent.contains(url)) url,
          },
        );
      }
      if (fillUntil > 0) {
        final fill = await _injectFillFromStore(
          missing,
          fillUntil,
          shouldContinue: shouldContinue,
          traceId: traceId,
        );
        trace(
          'warm#$traceId l2-hit=${fill.hits} '
          'l2-miss=${fill.scanned - fill.hits} '
          'bytes=${_bytes(fill.bytes)} '
          'scanned=${fill.scanned}/${missing.length} '
          'dt=${elapsed.elapsedMilliseconds}ms',
        );
        final resident = await _residentSubset(wanted);
        trace(
          'warm#$traceId done injected=${fill.injected} '
          'resident=${resident.length}/${wanted.length} '
          'dt=${elapsed.elapsedMilliseconds}ms',
        );
        return (injected: fill.injected, resident: resident);
      }
      // Don't bump last-used for a speculative warm: a frame the user scrubbed
      // past must not outrank one they actually looked at.
      final hits = await _store.readBytesBatch(missing, touch: false);
      trace(
        'warm#$traceId l2-hit=${hits.length} '
        'l2-miss=${missing.length - hits.length} '
        'bytes=${_bytes(_binaryBytes(hits.values))} '
        'dt=${elapsed.elapsedMilliseconds}ms',
      );
      if (shouldContinue?.call() == false || hits.isEmpty) {
        final resident = await _residentSubset(wanted);
        trace(
          'warm#$traceId ${hits.isEmpty ? 'cold' : 'cancelled'} '
          'resident=${resident.length}/${wanted.length} '
          'dt=${elapsed.elapsedMilliseconds}ms',
        );
        return (injected: 0, resident: resident);
      }
      // SQLite's IN query has no row-order guarantee. Rebuild from [missing],
      // otherwise fill mode can inject a far frame first and stop before the
      // centre frame even though the caller supplied the correct priority.
      final tiles = [
        for (final url in missing)
          if (hits[url] case final entry?)
            MapLibreTile(
              url: url,
              data: entry.bytes,
              contentType: entry.contentType,
              etag: entry.etag,
            ),
      ];
      final injected = await _injectAll(
        tiles,
        shouldContinue: shouldContinue,
        traceId: traceId,
      );
      final resident = await _residentSubset(wanted);
      trace(
        'warm#$traceId done injected=$injected '
        'resident=${resident.length}/${wanted.length} '
        'dt=${elapsed.elapsedMilliseconds}ms',
      );
      return (injected: injected, resident: resident);
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'MapTileCache.warm');
      final resident = await _residentSubset(wanted);
      trace(
        'warm#$traceId error=${error.runtimeType} '
        'resident=${resident.length}/${wanted.length} '
        'dt=${elapsed.elapsedMilliseconds}ms',
      );
      return (injected: 0, resident: resident);
    }
  }

  Future<Set<String>> _residentSubset(List<String> wanted) async {
    final missing = (await _missingFromL1(wanted)).toSet();
    return {
      for (final url in wanted)
        if (!missing.contains(url)) url,
    };
  }

  /// Probes a potentially huge candidate set without monopolising the native
  /// platform thread. Ordering is retained because fill mode uses it as its
  /// centre-out priority.
  Future<List<String>> _missingFromL1(
    List<String> wanted, {
    bool Function()? shouldContinue,
  }) async {
    final missing = <String>[];
    var messages = 0;
    for (var i = 0; i < wanted.length; i += _probeChunk) {
      final end = math.min(i + _probeChunk, wanted.length);
      missing.addAll(await mapLibreTilesMissing(wanted.sublist(i, end)));
      if (shouldContinue?.call() == false) {
        // Unprobed URLs are conservatively unknown/missing. That keeps the
        // returned resident set truthful while letting a hidden surface stop
        // before another multi-thousand-URL platform pass.
        missing.addAll(wanted.sublist(end));
        break;
      }
      messages++;
      if (end < wanted.length && messages % _messagesPerSlice == 0) {
        await Future<void>.delayed(_cooperativePause);
      }
    }
    return missing;
  }

  /// The requested URLs native currently holds in its in-process mirror.
  ///
  /// This is intentionally a strings-only probe. Raster timelines use it to
  /// keep the previous timestamp visible until every tile needed by the next
  /// frame has arrived, without shipping image bodies over the channel again.
  Future<Set<String>> residentUrls(Iterable<String> urls) {
    final wanted = <String>{
      for (final url in urls)
        if (_isTile(url)) url,
    }.toList(growable: false);
    if (wanted.isEmpty) return Future<Set<String>>.value(<String>{});
    return _residentSubset(wanted);
  }

  /// Injects every [tiles] in fixed chunks.
  ///
  /// Chunked because warming a wide band of frames is megabytes of image data,
  /// and one giant message would occupy the platform channel long enough to be
  /// felt by whatever gesture is in progress.
  Future<int> _injectAll(
    List<MapLibreTile> tiles, {
    bool Function()? shouldContinue,
    required int traceId,
  }) async {
    var injected = 0;
    var messages = 0;
    for (var i = 0; i < tiles.length; i += _injectChunk) {
      if (shouldContinue?.call() == false) break;
      final end = math.min(i + _injectChunk, tiles.length);
      final chunk = tiles.sublist(i, end);
      final usage = await injectMapLibreTiles(chunk);
      injected += end - i;
      trace(
        'warm#$traceId inject count=${chunk.length} '
        'bytes=${_bytes(_tileBytes(chunk))} '
        '${_formatUsage(usage)}',
      );
      messages++;
      if (end < tiles.length && messages % _messagesPerSlice == 0) {
        await Future<void>.delayed(_cooperativePause);
      }
    }
    return injected;
  }

  /// Reads L2 and injects it in priority order until the mirror is estimated to
  /// hold `fillUntil × cap` bytes, then stops without reading the cold tail.
  ///
  /// The estimate is the last `injectTiles` echo plus the bytes this side is
  /// about to send. Overshooting native's cap invokes its LRU while the fill is
  /// still running, which can evict an earlier, higher-priority frame to make
  /// room for a later one. When a chunk straddles the goal it is split and only
  /// the fitting prefix is sent.
  Future<({int injected, int hits, int scanned, int bytes})>
  _injectFillFromStore(
    List<String> missing,
    double fillUntil, {
    bool Function()? shouldContinue,
    required int traceId,
  }) async {
    var cap = (_memoryLimit * fillUntil).floor();
    if (cap <= 0) return (injected: 0, hits: 0, scanned: 0, bytes: 0);
    var used = 0; // No pre-inject usage query — start at the optimistic 0.
    var injected = 0;
    var l2Hits = 0;
    var scanned = 0;
    var l2Bytes = 0;
    var messages = 0;

    outer:
    for (var readAt = 0; readAt < missing.length; readAt += _fillReadChunk) {
      if (shouldContinue?.call() == false || used >= cap) break;
      final readEnd = math.min(readAt + _fillReadChunk, missing.length);
      final urls = missing.sublist(readAt, readEnd);
      final hits = await _store.readBytesBatch(urls, touch: false);
      scanned += urls.length;
      l2Hits += hits.length;
      l2Bytes += _binaryBytes(hits.values);
      if (shouldContinue?.call() == false) break;

      // SQLite does not preserve IN-query order. Rebuild this bounded batch
      // from [urls], keeping centre-out frame priority intact.
      final tiles = [
        for (final url in urls)
          if (hits[url] case final entry?)
            MapLibreTile(
              url: url,
              data: entry.bytes,
              contentType: entry.contentType,
              etag: entry.etag,
            ),
      ];
      for (var tileAt = 0; tileAt < tiles.length; tileAt += _injectChunk) {
        if (shouldContinue?.call() == false || used >= cap) break outer;
        final tileEnd = math.min(tileAt + _injectChunk, tiles.length);
        var chunk = tiles.sublist(tileAt, tileEnd);
        var chunkBytes = _tileBytes(chunk);
        var reachedTarget = false;
        if (used + chunkBytes > cap) {
          final fits = <MapLibreTile>[];
          var size = 0;
          for (final tile in chunk) {
            if (used + size + tile.data.length > cap) break;
            fits.add(tile);
            size += tile.data.length;
          }
          if (fits.isEmpty) break outer;
          chunk = fits;
          chunkBytes = size;
          reachedTarget = true;
        }
        final usage = await injectMapLibreTiles(chunk);
        used = usage?.used ?? used + chunkBytes;
        if (usage != null && usage.limit > 0) {
          cap = (usage.limit * fillUntil).floor();
        }
        injected += chunk.length;
        trace(
          'warm#$traceId inject count=${chunk.length} '
          'bytes=${_bytes(chunkBytes)} ${_formatUsage(usage)} '
          'target=${_bytes(cap)}',
        );
        messages++;
        if (messages % _messagesPerSlice == 0) {
          await Future<void>.delayed(_cooperativePause);
        }
        if (reachedTarget) break outer;
      }
    }
    return (injected: injected, hits: l2Hits, scanned: scanned, bytes: l2Bytes);
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
  Future<void> cancelFetches({List<String> urlContains = const []}) async {
    trace(
      'cancel-fetch patterns=${urlContains.length} '
      'sample=${_urls(urlContains)}',
    );
    await cancelMapLibreTileFetches(urlContains: urlContains);
  }

  /// Drops tiles matching [urlContains] from native's mirror (bytes stay in
  /// SQLite — this only reclaims memory).
  Future<void> evict(List<String> urlContains) async {
    trace(
      'evict patterns=${urlContains.length} '
      'scope=${urlContains.isEmpty ? 'all' : _urls(urlContains)}',
    );
    await evictMapLibreTiles(urlContains);
  }

  static int _tileBytes(Iterable<MapLibreTile> tiles) =>
      tiles.fold(0, (sum, tile) => sum + tile.data.length);

  static int _binaryBytes(Iterable<CachedBytes> entries) =>
      entries.fold(0, (sum, entry) => sum + entry.bytes.length);

  static String _bytes(int value) => value < 1024
      ? '${value}B'
      : value < 1024 * 1024
      ? '${(value / 1024).toStringAsFixed(1)}KiB'
      : '${(value / (1024 * 1024)).toStringAsFixed(1)}MiB';

  static String _formatUsage(TileMemoryUsage? usage) => usage == null
      ? 'l1-usage=unavailable'
      : 'l1-usage=${_bytes(usage.used)}/${_bytes(usage.limit)}';

  static String _urls(Iterable<String> urls) {
    final sample = <String>[];
    for (final url in urls) {
      final uri = Uri.tryParse(url);
      sample.add(uri == null ? url : uri.path);
      if (sample.length == 3) break;
    }
    return sample.isEmpty ? '-' : sample.join(',');
  }

  static bool _isTile(String url) {
    final uri = Uri.tryParse(url);
    return uri != null && EtagInterceptor.isImmutableTile(uri);
  }
}
