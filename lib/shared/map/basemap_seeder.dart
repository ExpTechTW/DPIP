/// Plants the basemap tiles the app carries into its tile store, so a map with
/// no network has something to draw.
library;

import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/network/etag_cache_store.dart';
import 'package:dpip/shared/map/basemap_seed.g.dart';
import 'package:dpip/shared/map/basemap_seed_format.dart';
import 'package:flutter/services.dart';

/// What one [BasemapSeeder.run] did: rows [planted], asset parts it had to
/// [loaded] out of [parts], and how long it [took].
typedef BasemapSeedReport = ({
  int planted,
  int loaded,
  int parts,
  Duration took,
});

/// Puts the bundled basemap (`tool/gen/basemap_seed.dart`) into the tile
/// store, under rows marked as planted ([EtagCacheStore.seedEtag]).
///
/// ## What a planted row is
/// A fallback. `MapTileCache` asks the network first whenever MapLibre wants
/// one of these tiles and only answers from the planted row when the network
/// cannot; the first download replaces the row for good. So the bundle costs
/// nothing in freshness — it only fills the case where the alternative was an
/// empty map: a first launch, or any launch after the OS emptied the cache
/// directory, with no network.
///
/// ## Run every launch, cheap when there is nothing to do
/// The store lives in the cache directory, which the OS may purge at any time,
/// so "seeded once" cannot be remembered anywhere else and believed. Each run
/// asks the store which of the bundle's URLs it holds — one query, ETags only,
/// no bodies — and loads an asset part only if one of its tiles is missing or
/// was planted from an older bundle. On every launch after the first, that is
/// one query and no asset reads.
///
/// ## Never over a server's answer
/// A URL whose row came from the network, including a cached 404, is left
/// alone, and [EtagCacheStore.seedBytesBatch] repeats the check inside its own
/// write, so a download that lands while this runs still wins.
///
/// ## Memory
/// One part (at most 256 KiB, see the generator) is held at a time, and it is
/// planted as the gzip members it already contains: nothing is inflated or
/// parsed here. Each tile is one copy out of the part, so the database isolate
/// is sent that part's tiles and not the whole buffer once per tile.
class BasemapSeeder {
  // Not initializing formals: Dart has no private *named* parameter, and the
  // fields must stay private.
  BasemapSeeder(
    this._store, {
    AssetBundle? bundle,
    BasemapSeedIndex index = bundledBasemapSeed,
  }) : _bundle = bundle ?? rootBundle,
       // ignore: prefer_initializing_formals
       _index = index;

  final EtagCacheStore _store;
  final AssetBundle _bundle;
  final BasemapSeedIndex _index;

  /// Plants whatever the store is missing. Never throws: a failed part is
  /// logged and skipped, and the next launch tries it again.
  Future<BasemapSeedReport> run() async {
    final elapsed = Stopwatch()..start();
    final etag = EtagCacheStore.seedEtag(_index.version);
    var planted = 0;
    var loaded = 0;
    try {
      final stored = await _store.etagsFor([
        for (final part in _index.parts)
          for (final tile in part.tiles) _url(tile),
      ]);
      for (final part in _index.parts) {
        final wanted = [
          for (final tile in part.tiles)
            if (_wants(stored[_url(tile)], etag)) tile,
        ];
        if (wanted.isEmpty) continue;
        loaded++;
        planted += await _plant(part, wanted, etag);
      }
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'BasemapSeeder');
    }
    final report = (
      planted: planted,
      loaded: loaded,
      parts: _index.parts.length,
      took: elapsed.elapsed,
    );
    Log.info(
      'basemap seed v${_index.version} planted=$planted '
      'parts=$loaded/${report.parts} ${report.took.inMilliseconds}ms',
    );
    return report;
  }

  /// Whether a URL whose row carries [stored] (null: no row) should be planted.
  ///
  /// Only an empty slot or a row from a different bundle. Anything else is a
  /// server's answer or this very bundle already.
  static bool _wants(String? stored, String etag) =>
      stored == null || (EtagCacheStore.isSeedEtag(stored) && stored != etag);

  Future<int> _plant(
    BasemapSeedPart part,
    List<BasemapSeedTile> tiles,
    String etag,
  ) async {
    final ByteData data;
    try {
      data = await _bundle.load(part.asset);
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'BasemapSeeder ${part.asset}');
      return 0;
    }
    // The index is trusted only as far as the bytes agree with it. A part of
    // the wrong length is not this bundle, and slicing it would plant garbage
    // under real tile URLs.
    if (data.lengthInBytes != part.bytes) {
      Log.warning(
        'BasemapSeeder ${part.asset} is ${data.lengthInBytes} bytes, '
        'index says ${part.bytes} — skipped',
      );
      return 0;
    }
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    final rows = <SeedWrite>[];
    for (final tile in tiles) {
      final end = tile.offset + tile.length;
      if (tile.offset < 0 || end > bytes.length) return 0;
      rows.add((url: _url(tile), body: _copy(bytes, tile.offset, end)));
    }
    return _store.seedBytesBatch(rows, etag: etag);
  }

  String _url(BasemapSeedTile tile) =>
      basemapSeedUrl(_index.source, tile.z, tile.x, tile.y);

  static Uint8List _copy(Uint8List bytes, int start, int end) =>
      start == end ? Uint8List(0) : bytes.sublist(start, end);
}
