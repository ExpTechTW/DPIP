import 'package:dio/dio.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/network/api_region.dart';
import 'package:dpip/core/network/region_selection.dart';

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
  const ApiClient(this._dio, this._regions);

  final Dio _dio;
  final RegionSelection _regions;

  /// GET [path] on [tier] with failover; returns the decoded body.
  Future<dynamic> get(
    ApiTier tier,
    String path, {
    Map<String, dynamic>? query,
    CancelToken? cancelToken,
  }) async =>
      (await request(tier, path, query: query, cancelToken: cancelToken)).data;

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
  /// visible. Pass a [cancelToken] to abort a superseded request.
  Future<Response<dynamic>> request(
    ApiTier tier,
    String path, {
    String method = 'GET',
    Object? data,
    Map<String, dynamic>? query,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    final hosts = hostsFor(tier);
    for (var i = 0; i < hosts.length; i++) {
      try {
        return await _dio.request(
          '${hosts[i]}$path',
          data: data,
          queryParameters: query,
          cancelToken: cancelToken,
          options: (options ?? Options()).copyWith(method: method),
        );
      } on DioException catch (e) {
        final isLastHost = i == hosts.length - 1;
        if (isLastHost || !_isRetryable(e)) rethrow;
        Log.warning(
          'ApiClient: ${tier.name} ${hosts[i]} failed (${_describe(e)}); '
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
      case ApiTier.legacyApi:
        return const ['https://api-1.exptech.dev'];
    }
  }
}
