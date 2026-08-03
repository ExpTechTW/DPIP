/// Fetches HTTPS resources via [ApiClient] (binary ETag / SQLite) and pins them
/// into MapLibre ambient under the **same URL** MapLibre will request.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/api_region.dart';
import 'package:dpip/shared/map/map_cache.dart';
import 'package:dpip/shared/map/xyz_tiles.dart';

/// Shared spine for radar / satellite / DPM / basemap warm-up.
///
/// Timeline scrub / camera pan schedule work often — [cancel] aborts in-flight
/// Dio immediately, and a short [settleDelay] drops superseded schedules before
/// they hit the network.
class AmbientPrefetcher {
  AmbientPrefetcher(
    this._client, {
    this._cache = const MapCache(),
    this.maxTiles = 48,
    this.concurrency = 4,
    this.settleDelay = const Duration(milliseconds: 350),
  });

  final ApiClient _client;
  final MapCache _cache;
  final int maxTiles;
  final int concurrency;
  final Duration settleDelay;

  int _scheduleId = 0;
  int _generation = 0;
  CancelToken? _token;

  /// Abort in-flight Dio immediately (layer clear / scrub / superseded camera).
  void cancel() {
    _scheduleId++;
    _generation++;
    final token = _token;
    _token = null;
    token?.cancel('ambient-prefetch-cancel');
  }

  /// Prefetch region-pinned [paths] (each starts at `/api/…`).
  Future<void> prefetchPaths(
    ApiTier tier,
    Iterable<String> paths, {
    String? logLabel,
  }) async {
    final list = paths.toList(growable: false);
    if (list.isEmpty) return;
    final schedule = ++_scheduleId;
    // Cancel the previous generation *now* — don't wait for settle.
    _token?.cancel('ambient-prefetch-superseded');
    _token = null;
    await Future<void>.delayed(settleDelay);
    if (schedule != _scheduleId) return;

    final gen = ++_generation;
    final token = CancelToken();
    _token = token;
    final hosts = _client.hostsFor(tier);
    final originBase = hosts.isEmpty ? '' : hosts.first;
    await _run(
      gen: gen,
      token: token,
      jobs: [
        for (final path in list)
          (url: '$originBase$path', pathOrUrl: path, tier: tier),
      ],
    );
    if (gen == _generation && logLabel != null) {
      Log.debug('AmbientPrefetch $logLabel paths=${list.length}');
    }
  }

  /// Prefetch absolute HTTPS [urls] (basemap — no failover).
  Future<void> prefetchAbsolute(
    Iterable<String> urls, {
    String? logLabel,
  }) async {
    final list = urls.toList(growable: false);
    if (list.isEmpty) return;
    final schedule = ++_scheduleId;
    _token?.cancel('ambient-prefetch-superseded');
    _token = null;
    await Future<void>.delayed(settleDelay);
    if (schedule != _scheduleId) return;

    final gen = ++_generation;
    final token = CancelToken();
    _token = token;
    await _run(
      gen: gen,
      token: token,
      jobs: [for (final url in list) (url: url, pathOrUrl: url, tier: null)],
    );
    if (gen == _generation && logLabel != null) {
      Log.debug('AmbientPrefetch $logLabel urls=${list.length}');
    }
  }

  /// Viewport XYZ tiles: [pathFor] returns `/api/…/{z}/{x}/{y}.ext`.
  Future<void> prefetchViewport({
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
  }) async {
    final z = math.min(zoom.floor(), maxZoom);
    var tiles = tilesCovering(
      south: south,
      west: west,
      north: north,
      east: east,
      z: z,
      pad: pad,
      maxTiles: maxTiles,
    );
    if (tiles.isEmpty && z > 0) {
      tiles = tilesCovering(
        south: south,
        west: west,
        north: north,
        east: east,
        z: z - 1,
        pad: pad,
        maxTiles: maxTiles,
      );
    }
    if (tiles.isEmpty) return;
    await prefetchPaths(tier, [
      for (final t in tiles) pathFor(t.z, t.x, t.y),
    ], logLabel: logLabel ?? 'xyz z=$z');
  }

  /// Absolute-URL XYZ (e.g. basemap on `lb.exptech.dev`).
  Future<void> prefetchViewportAbsolute({
    required String Function(int z, int x, int y) urlFor,
    required double south,
    required double west,
    required double north,
    required double east,
    required double zoom,
    int maxZoom = 12,
    int pad = 1,
    String? logLabel,
  }) async {
    final z = math.min(zoom.floor(), maxZoom);
    var tiles = tilesCovering(
      south: south,
      west: west,
      north: north,
      east: east,
      z: z,
      pad: pad,
      maxTiles: maxTiles,
    );
    if (tiles.isEmpty && z > 0) {
      tiles = tilesCovering(
        south: south,
        west: west,
        north: north,
        east: east,
        z: z - 1,
        pad: pad,
        maxTiles: maxTiles,
      );
    }
    if (tiles.isEmpty) return;
    await prefetchAbsolute([
      for (final t in tiles) urlFor(t.z, t.x, t.y),
    ], logLabel: logLabel ?? 'abs-xyz z=$z');
  }

  Future<void> _run({
    required int gen,
    required CancelToken token,
    required List<({String url, String pathOrUrl, ApiTier? tier})> jobs,
  }) async {
    final pending = List.of(jobs);
    Future<void> worker() async {
      while (true) {
        if (gen != _generation || token.isCancelled) return;
        if (pending.isEmpty) return;
        final job = pending.removeLast();
        try {
          final payload = job.tier != null
              ? await _client.getBytes(
                  job.tier!,
                  job.pathOrUrl,
                  cancelToken: token,
                )
              : await _client.getBytesAbsolute(
                  job.pathOrUrl,
                  cancelToken: token,
                );
          if (gen != _generation || token.isCancelled) return;
          await _cache.preload(
            url: job.url,
            data: payload.bytes,
            etag: payload.etag,
            mustRevalidate: true,
          );
        } on DioException catch (e) {
          if (e.type == DioExceptionType.cancel) return;
          Log.debug(
            'AmbientPrefetch miss ${job.pathOrUrl}: '
            '${e.response?.statusCode ?? e.type.name}',
          );
        } catch (error, stackTrace) {
          Log.handle(error, stackTrace, 'AmbientPrefetcher');
        }
      }
    }

    await Future.wait([for (var i = 0; i < concurrency; i++) worker()]);
  }
}
