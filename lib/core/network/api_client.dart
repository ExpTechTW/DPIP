import 'package:dio/dio.dart';
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
  }) async => (await request(tier, path, query: query)).data;

  /// POST [data] to [path] on [tier] with failover; returns the decoded body.
  Future<dynamic> post(
    ApiTier tier,
    String path, {
    Object? data,
    Map<String, dynamic>? query,
  }) async => (await request(
    tier,
    path,
    method: 'POST',
    data: data,
    query: query,
  )).data;

  /// Low-level request against [tier], trying each region host in failover
  /// order until one succeeds. Exposes the full [Response] for callers that
  /// need headers (e.g. NTP).
  Future<Response<dynamic>> request(
    ApiTier tier,
    String path, {
    String method = 'GET',
    Object? data,
    Map<String, dynamic>? query,
    Options? options,
  }) async {
    Object error = StateError('No hosts for $tier');
    StackTrace stack = StackTrace.current;
    for (final host in hostsFor(tier)) {
      try {
        return await _dio.request(
          '$host$path',
          data: data,
          queryParameters: query,
          options: (options ?? Options()).copyWith(method: method),
        );
      } catch (e, s) {
        error = e;
        stack = s;
        // Multi-active tiers retry the next region; the exclusive tier yields a
        // single host, so this is naturally a no-failover request.
      }
    }
    Error.throwWithStackTrace(error, stack);
  }

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
      case ApiTier.globalApi:
        return [
          for (final r in _regions.lbOrder)
            'https://api.lb-${r.code}.exptech.dev',
          for (final r in _regions.coreOrder)
            'https://api.core-${r.code}.exptech.dev',
        ];
      case ApiTier.coreExclusiveApi:
        return const ['https://api.core-tnn1.exptech.dev'];
    }
  }
}
