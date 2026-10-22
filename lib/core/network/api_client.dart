import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/network/api_region.dart';
import 'package:dpip/core/network/endpoint_health.dart';
import 'package:dpip/core/network/etag_interceptor.dart';
import 'package:dpip/core/network/region_selection.dart';
import 'package:dpip/core/network/tile_hosts.dart';

/// A live byte stream plus the handle that aborts it — the result of
/// [ApiClient.openStream]. [cancel] closes the underlying connection; [stream]
/// ends or errors when the server closes it.
class StreamedResponse {
  const StreamedResponse(this.stream, this.cancel);

  final Stream<Uint8List> stream;
  final void Function() cancel;
}

/// Raw bytes from [ApiClient.getBytes], with the response [etag] when present
/// (from a fresh `200` or a revalidated `304` rewrite).
class BytePayload {
  const BytePayload({required this.bytes, this.etag});

  final Uint8List bytes;
  final String? etag;
}

/// Region-aware HTTP client.
///
/// Resolves concrete, region-pinned hosts from the current [RegionSelection]
/// (never the DNS-balanced bare hosts) and, for multi-active tiers, fails over
/// to the next region when a request fails. The [ApiTier.coreExclusiveApi] tier
/// is issued against `core-tnn1` only, without failover.
///
/// Paths are region-agnostic and begin at the version segment, e.g.
/// `/v2/trem/rts` (the `api`/`static` role is part of the host subdomain).
class ApiClient {
  const ApiClient(this._dio, this._regions, [this._health]);

  final Dio _dio;
  final RegionSelection _regions;

  /// Optional observer of per-host outcomes. When set, every retryable failure
  /// and every success is reported — it is what lights the More tab's
  /// server-status dot when this device stops reaching a region.
  final EndpointHealthMonitor? _health;

  /// GET [path] on [tier] with failover; returns the decoded body.
  ///
  /// [notFoundFailsOver] as in [request].
  Future<dynamic> get(
    ApiTier tier,
    String path, {
    Map<String, dynamic>? query,
    CancelToken? cancelToken,
    bool notFoundFailsOver = false,
  }) async => (await request(
    tier,
    path,
    query: query,
    cancelToken: cancelToken,
    notFoundFailsOver: notFoundFailsOver,
  )).data;

  /// GET [path] as raw bytes (MVT / WebP / …) with ETag revalidation.
  ///
  /// Uses [ResponseType.bytes] so [EtagInterceptor] stores a binary envelope
  /// instead of `jsonEncode`. Returns the body plus the response ETag (for
  /// MapLibre ambient preload at the same URL).
  /// Set [validateJson] for JSON endpoints that need source bytes. Invalid
  /// UTF-8 or JSON participates in failover just like a JSON decode error.
  Future<BytePayload> getBytes(
    ApiTier tier,
    String path, {
    Map<String, dynamic>? query,
    CancelToken? cancelToken,
    bool validateJson = false,
  }) async {
    final response = await request(
      tier,
      path,
      query: query,
      cancelToken: cancelToken,
      options: Options(
        responseType: ResponseType.bytes,
        extra: validateJson
            ? {EtagInterceptor.validateJsonBytesKey: true}
            : null,
      ),
    );
    return _bytePayload(response);
  }

  /// Absolute-URL GET as bytes with ETag (no region failover).
  ///
  /// For hosts that are not an [ApiTier] — the glyphs CDN a MapLibre style
  /// names, third-party images. A tile on a region host goes through
  /// [getTileBytes], and any other region-pinned ExpTech path through
  /// [getBytes].
  Future<BytePayload> getBytesAbsolute(
    String url, {
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.request<dynamic>(
      url,
      cancelToken: cancelToken,
      options: Options(method: 'GET', responseType: ResponseType.bytes),
    );
    return _bytePayload(response);
  }

  /// GET a map tile by the absolute URL a MapLibre style names.
  ///
  /// A tile whose family every region carries ([tileRoute]) fails over as a
  /// frame list does: the same [_isRetryable] split, each host at most once,
  /// in [hostsFor] order — except that a host which failed a tile request in
  /// the last [_tileHostRetryAfter] is asked last (see [_tileHostOrder]). A 404
  /// moves on only where the family sets `notFoundFailsOver` (the core frame
  /// tiles); a basemap 404 is the answer on every host. A 404 is never charged
  /// to the host. Anything else is one [getBytesAbsolute] to the URL as given.
  ///
  /// Whichever host answers, [EtagInterceptor] stores the body under
  /// [tileCacheKey], which is also where MapLibre's own URL is looked up.
  Future<BytePayload> getTileBytes(
    String url, {
    CancelToken? cancelToken,
  }) async {
    final route = tileRoute(url);
    if (route == null) return getBytesAbsolute(url, cancelToken: cancelToken);
    final response = await _requestAlong(
      _tileHostOrder(route),
      route.tier,
      route.path,
      cancelToken: cancelToken,
      options: Options(responseType: ResponseType.bytes),
      notFoundFailsOver: route.notFoundFailsOver,
    );
    return _bytePayload(response);
  }

  /// How long a host that failed a tile request is asked last. Past it, the
  /// host goes back to the front, so one request finds out whether it has
  /// recovered.
  static const Duration _tileHostRetryAfter = Duration(seconds: 30);

  /// [hostsFor] for [route]'s tier, with every host that failed a tile request
  /// in the last [_tileHostRetryAfter] moved to the end — still each host once.
  ///
  /// A takeover in `MapTileCache` happens because the selected host failed.
  /// Asking it first again spends its connect timeout (8 s) against native's
  /// 1.8 s budget, so the tile misses that budget and the cache reads the
  /// network as down. Only for a while, though: a host kept last for good is
  /// never asked while the other region answers, so its failing verdict —
  /// which is what keeps the takeover going — would never clear.
  List<String> _tileHostOrder(TileRoute route) {
    final hosts = hostsFor(route.tier);
    final health = _health;
    if (health == null) return hosts;
    final service = EndpointService.ofPath(route.path);
    // wall-clock: aged against the monitor's own `lastFailure`, which is this
    // device's clock as well; never compared with anything a server stamped.
    final now = DateTime.now();
    bool failedLately(String host) {
      final seen = health.of(service, route.tier, host);
      final at = seen?.lastFailure;
      return seen != null &&
          (seen.state == EndpointState.degraded ||
              seen.state == EndpointState.down) &&
          at != null &&
          now.difference(at) < _tileHostRetryAfter;
    }

    final failing = hosts.where(failedLately).toList(growable: false);
    if (failing.isEmpty || failing.length == hosts.length) return hosts;
    return [
      for (final host in hosts)
        if (!failing.contains(host)) host,
      ...failing,
    ];
  }

  /// Whether the region host [url] names is failing its tile requests: the
  /// health monitor saw its last one fail ([EndpointState.degraded] or
  /// [EndpointState.down]).
  ///
  /// Only [getTileBytes] reports a tile host's outcomes, so this is what Dart
  /// itself observed — MapLibre's own downloads report nothing. False without
  /// a monitor, and for a tile with nowhere to fail over to.
  bool tileHostFailing(String url) {
    final health = _health;
    final route = tileRoute(url);
    if (health == null || route == null) return false;
    final origin = url.substring(0, url.length - route.path.length);
    final state = health
        .of(EndpointService.ofPath(route.path), route.tier, origin)
        ?.state;
    return state == EndpointState.degraded || state == EndpointState.down;
  }

  /// Absolute-URL GET with JSON decode + ETag (no region failover).
  ///
  /// For third-party hosts (e.g. GitHub releases) that still go through Dio so
  /// [EtagInterceptor] can revalidate. Prefer [get] for region-pinned ExpTech.
  Future<dynamic> getAbsolute(
    String url, {
    Map<String, dynamic>? query,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.request<dynamic>(
      url,
      queryParameters: query,
      cancelToken: cancelToken,
      options: Options(method: 'GET', headers: headers),
    );
    return response.data;
  }

  /// Absolute-URL POST with JSON decode + ETag (no region failover).
  ///
  /// For third-party hosts (e.g. the Grafana status dashboard) whose query body
  /// is a compile-time constant — the ETag interceptor treats the URL as the
  /// content key and caches unconditionally, exactly like an immutable tile.
  Future<dynamic> postAbsolute(
    String url, {
    Object? data,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.request<dynamic>(
      url,
      data: data,
      cancelToken: cancelToken,
      options: Options(method: 'POST', headers: headers),
    );
    return response.data;
  }

  /// Absolute-URL request with a streamed body (no region failover) — a
  /// third-party host that writes its answer as it goes, e.g. the AI service
  /// the user set up for the AI chat.
  ///
  /// Never cached: [EtagInterceptor] skips stream responses, which is the
  /// point for an answer that depends on the caller's own key. Every status
  /// is returned rather than thrown, so the caller can read the service's own
  /// error body (an AI service explains a 400 or a 429 there). [idleTimeout]
  /// replaces the client-wide 10 s receive timeout: Dio applies it between
  /// body chunks, and a model on a busy GPU can think for longer than that
  /// before its first word. `Accept-Encoding: identity`, as for SSE: a
  /// compressed body arrives in the compressor's blocks, not as written.
  Future<Response<ResponseBody>> streamAbsolute(
    String url, {
    String method = 'POST',
    Object? data,
    Map<String, dynamic>? headers,
    Duration idleTimeout = Duration.zero,
    CancelToken? cancelToken,
  }) => _dio.request<ResponseBody>(
    url,
    data: data,
    cancelToken: cancelToken,
    options: Options(
      method: method,
      responseType: ResponseType.stream,
      receiveTimeout: idleTimeout,
      headers: {'Accept-Encoding': 'identity', ...?headers},
      validateStatus: (_) => true,
    ),
  );

  static BytePayload _bytePayload(Response<dynamic> response) {
    final data = response.data;
    final Uint8List bytes = switch (data) {
      final Uint8List b => b,
      final List<int> list => Uint8List.fromList(list),
      _ => throw StateError('Expected bytes, got ${data.runtimeType}'),
    };
    return BytePayload(bytes: bytes, etag: response.headers.value('etag'));
  }

  /// POST [data] to [path] on [tier] with failover; returns the decoded body.
  Future<dynamic> post(
    ApiTier tier,
    String path, {
    Object? data,
    Map<String, dynamic>? query,
    CancelToken? cancelToken,
  }) async => (await request(
    tier,
    path,
    method: 'POST',
    data: data,
    query: query,
    cancelToken: cancelToken,
  )).data;

  /// Low-level request against [tier], trying each region host in failover
  /// order. Exposes the full [Response] for callers that need headers (e.g. NTP).
  ///
  /// Failover is **only** for transient/server faults (connection drops,
  /// timeouts, 5xx): a 4xx is a client error that would repeat on every region,
  /// and a cancellation is deliberate, so both throw immediately without trying
  /// the next host. Every failover is logged so a silent region switch is
  /// visible, and reported to [_health] so the server-status dot can show it.
  /// Pass a [cancelToken] to abort a superseded request.
  ///
  /// [notFoundFailsOver] makes a 404 move on to the next region too, for an
  /// immutable resource one region may simply not hold: each core region
  /// keeps its own history, and an outage leaves a gap in one of them. The
  /// 404 is still not charged to the host — the region lacks the item, it is
  /// not sick — and a 404 from the last region is the answer.
  Future<Response<dynamic>> request(
    ApiTier tier,
    String path, {
    String method = 'GET',
    Object? data,
    Map<String, dynamic>? query,
    Options? options,
    CancelToken? cancelToken,
    bool notFoundFailsOver = false,
  }) => _requestAlong(
    hostsFor(tier),
    tier,
    path,
    method: method,
    data: data,
    query: query,
    options: options,
    cancelToken: cancelToken,
    notFoundFailsOver: notFoundFailsOver,
  );

  /// [request] along [hosts], which are [tier]'s in the order to try them.
  Future<Response<dynamic>> _requestAlong(
    List<String> hosts,
    ApiTier tier,
    String path, {
    String method = 'GET',
    Object? data,
    Map<String, dynamic>? query,
    Options? options,
    CancelToken? cancelToken,
    bool notFoundFailsOver = false,
  }) async {
    for (var i = 0; i < hosts.length; i++) {
      try {
        final response = await _dio.request(
          '${hosts[i]}$path',
          data: data,
          queryParameters: query,
          cancelToken: cancelToken,
          options: (options ?? Options()).copyWith(method: method),
        );
        _health?.success(tier, hosts[i], path);
        return response;
      } on DioException catch (e) {
        final retryable = _isRetryable(e);
        // Only what the *host* is answerable for, which is what [_isRetryable]
        // already separates. A 404 says the route or the resource is wrong, not
        // that the region is sick: replaying an event older than the RTS
        // retention 404s once a second, and charging those to the host parked
        // `api-1` at `down` for the rest of the session.
        if (retryable) _health?.failure(tier, hosts[i], path);
        final missing = notFoundFailsOver && e.response?.statusCode == 404;
        final isLastHost = i == hosts.length - 1;
        if (isLastHost || !(retryable || missing)) rethrow;
        Log.warning(
          'ApiClient: ${tier.name} ${hosts[i]} failed (${_describe(e)}); '
          'failing over to ${hosts[i + 1]}',
        );
      }
    }
    // Every tier yields at least one host, so this is unreachable in practice.
    throw StateError('No hosts configured for $tier');
  }

  /// Opens a streaming GET against [tier] as a raw byte stream, trying each
  /// region host in failover order (same policy as [request]).
  ///
  /// Built for long-lived responses (Server-Sent Events). The client-wide 10 s
  /// receive timeout does not apply — a feed may be legitimately silent for
  /// minutes (the EEW stream sends nothing between earthquakes) — and is
  /// replaced by [idleTimeout]: the longest the response may go without a
  /// single byte before the stream errors with a receive timeout. Pass the
  /// longest silence the server can produce on a healthy connection (its ping
  /// cadence, with margin); zero disables it. The connect timeout still bounds
  /// the initial handshake so a dead host fails over. The returned
  /// [StreamedResponse.stream] ends or errors when the server closes the
  /// connection, or when [idleTimeout] passes — the caller treats both as
  /// "reconnect me". [cancel] aborts an in-progress connection (e.g. on
  /// dispose).
  Future<StreamedResponse> openStream(
    ApiTier tier,
    String path, {
    Map<String, dynamic>? query,
    Map<String, dynamic>? headers,
    Duration idleTimeout = Duration.zero,
  }) async {
    final hosts = hostsFor(tier);
    for (var i = 0; i < hosts.length; i++) {
      final cancelToken = CancelToken();
      try {
        final response = await _dio.request<ResponseBody>(
          '${hosts[i]}$path',
          queryParameters: query,
          cancelToken: cancelToken,
          options: Options(
            method: 'GET',
            responseType: ResponseType.stream,
            // Not merged from BaseOptions' 10s: a quiet SSE feed must not be
            // torn down for ten seconds of nothing. Dio applies this between
            // body chunks, so it bounds silence, not the stream's length — a
            // half-open socket (no FIN after a handover) errors out instead of
            // waiting forever.
            receiveTimeout: idleTimeout,
            headers: headers,
          ),
        );
        // A connected SSE is a host that answered — the stream itself may
        // later end or error (the caller reconnects), but the host is up.
        _health?.success(tier, hosts[i], path);
        return StreamedResponse(response.data!.stream, cancelToken.cancel);
      } on DioException catch (e) {
        // Same split as [request]: a host is only charged for what it is
        // answerable for.
        final retryable = _isRetryable(e);
        if (retryable) _health?.failure(tier, hosts[i], path);
        final isLastHost = i == hosts.length - 1;
        if (isLastHost || !retryable) rethrow;
        Log.warning(
          'ApiClient: ${tier.name} stream ${hosts[i]} failed (${_describe(e)}); '
          'failing over to ${hosts[i + 1]}',
        );
      }
    }
    // Every tier yields at least one host, so this is unreachable in practice.
    throw StateError('No hosts configured for $tier');
  }

  /// Whether [e] is worth retrying against the next region. Transient transport
  /// faults and server (5xx) errors are; client (4xx) errors, cancellations, and
  /// certificate failures are not — they would recur identically.
  static bool _isRetryable(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        return true;
      case DioExceptionType.badResponse:
        return (e.response?.statusCode ?? 0) >= 500;
      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
        return false;
    }
  }

  static String _describe(DioException e) =>
      e.type == DioExceptionType.badResponse
      ? 'HTTP ${e.response?.statusCode}'
      : e.type.name;

  /// The ordered base hosts for [tier], honouring the current region selection
  /// and failover order.
  List<String> hostsFor(ApiTier tier) {
    switch (tier) {
      case ApiTier.lbApi:
        return [
          for (final r in _regions.lbOrder)
            'https://api.lb-${r.code}.exptech.dev',
        ];
      case ApiTier.lbStatic:
        return [
          for (final r in _regions.lbOrder)
            'https://static.lb-${r.code}.exptech.dev',
        ];
      case ApiTier.coreApi:
        return [
          for (final r in _regions.coreOrder)
            'https://api.core-${r.code}.exptech.dev',
        ];
      case ApiTier.coreStatic:
        return [
          for (final r in _regions.coreOrder)
            'https://static.core-${r.code}.exptech.dev',
        ];
      case ApiTier.coreExclusiveApi:
        return const ['https://api.core-tnn1.exptech.dev'];
      case ApiTier.coreStaticExclusive:
        return const ['https://static.core-tnn1.exptech.dev'];
      case ApiTier.legacyApi:
        return const ['https://api-1.exptech.dev'];
    }
  }
}
