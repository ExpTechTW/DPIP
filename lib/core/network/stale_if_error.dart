/// HTTP stale-if-error for the GETs that may opt into it: when the network
/// fails, answer with the body the ETag cache saved last time, marked as a
/// saved copy — never as current.
library;

import 'package:dio/dio.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/api_exception.dart';
import 'package:dpip/core/network/api_region.dart';

/// One saved body the ETag cache could fall back to.
typedef SavedBody = ({Object? data, DateTime? fetchedAt});

/// The opt-in, carried on a request's `extra`, and the slot the
/// `EtagInterceptor` fills when that request fails.
///
/// Why a slot on the request rather than a cached response in its place: the
/// region client fails over between hosts, and an interceptor answering the
/// first host's failure with the saved copy would stop it trying a second
/// host that is up. So the interceptor only *offers* the copy here and lets
/// the failure run its course; only once every host has failed does
/// [ApiClientStaleIfError.getOrSaved] take what was offered.
///
/// Each host has its own URL and so its own cache entry; the offer from the
/// host that served most recently wins.
final class StaleIfError {
  /// The `RequestOptions.extra` key the opt-in travels under.
  static const String extraKey = 'dpip.staleIfError';

  SavedBody? _saved;

  /// The best saved copy offered so far, or null.
  SavedBody? get saved => _saved;

  /// Request options carrying this opt-in.
  Options get options => Options(extra: {extraKey: this});

  /// The opt-in on [options], or null for a request that did not ask.
  static StaleIfError? of(RequestOptions options) =>
      switch (options.extra[extraKey]) {
        final StaleIfError opt => opt,
        _ => null,
      };

  /// Whether a request that failed with [error] may be answered from the
  /// cache: the server could not be reached, or failed on its side (5xx).
  ///
  /// Not a 4xx — the resource is gone or the request is wrong, and a saved copy
  /// would hide that — and not a cancellation or a certificate failure.
  static bool covers(DioException error) => switch (error.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.transformTimeout ||
    DioExceptionType.connectionError ||
    DioExceptionType.unknown => true,
    DioExceptionType.badResponse => (error.response?.statusCode ?? 0) >= 500,
    DioExceptionType.cancel || DioExceptionType.badCertificate => false,
  };

  /// Records [body] as a fallback, keeping the most recently confirmed one.
  void offer(SavedBody body) {
    final current = _saved;
    final at = body.fetchedAt;
    if (current == null ||
        (at != null && (current.fetchedAt?.isBefore(at) ?? true))) {
      _saved = body;
    }
  }
}

/// GETs that fall back to the saved copy.
extension ApiClientStaleIfError on ApiClient {
  /// GET [path] on [tier] like [ApiClient.get], except that when every host
  /// fails in a way [StaleIfError.covers], the body the cache saved from the
  /// last success is returned instead of the error — with [Fetched.stale] set,
  /// so it can never pass for current. With nothing saved, the error is
  /// rethrown as before.
  ///
  /// Only for data that is still worth seeing when old and that a reader can
  /// judge by its age — a list of past reports, not an alert feed.
  Future<Fetched<Object?>> getOrSaved(
    ApiTier tier,
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final fallback = StaleIfError();
    try {
      final response = await request(
        tier,
        path,
        query: query,
        options: fallback.options,
      );
      return (data: response.data, stale: null);
    } on DioException catch (error) {
      final saved = fallback.saved;
      if (saved == null || !StaleIfError.covers(error)) rethrow;
      Log.warning(
        'ApiClient: $path unreachable (${error.type.name}); serving the copy '
        'saved at ${saved.fetchedAt?.toIso8601String() ?? 'an unknown time'}',
      );
      return (
        data: saved.data,
        stale: Staleness(failure: mapException(error), since: saved.fetchedAt),
      );
    }
  }
}
