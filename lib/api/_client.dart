part of 'exptech.dart';

/// Thrown when RTS data is unavailable for the requested time.
class Rtsnodata implements Exception {
  /// Creates a [Rtsnodata] exception.
  const Rtsnodata();
}

/// Wraps [IOHttpClientAdapter] to add zstd decompression support and proxy config.
class _ZstdAdapter implements HttpClientAdapter {
  final Zstandard _zstd = Zstandard();
  final IOHttpClientAdapter _inner;

  _ZstdAdapter(this._inner);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    options.headers['Accept-Encoding'] = 'gzip, deflate, zstd';
    final response = await _inner.fetch(options, requestStream, cancelFuture);

    final contentEncoding = response.headers['content-encoding']?.firstOrNull
        ?.toLowerCase();
    if (contentEncoding == 'zstd') {
      final builder = BytesBuilder(copy: false);
      await for (final chunk in response.stream) {
        builder.add(chunk);
      }
      final decompressed = await _zstd.decompress(builder.takeBytes());
      if (decompressed != null) {
        final headers = Map<String, List<String>>.from(response.headers)
          ..remove('content-encoding');
        return ResponseBody.fromBytes(
          decompressed,
          response.statusCode,
          headers: headers,
          statusMessage: response.statusMessage,
          isRedirect: response.isRedirect,
        );
      }
    }

    return response;
  }

  @override
  void close({bool force = false}) => _inner.close(force: force);
}

IOHttpClientAdapter _createInnerAdapter() => IOHttpClientAdapter(
  createHttpClient: () {
    final client = HttpClient();
    final proxyEnabled = Preference.proxyEnabled ?? false;
    final proxyHost = Preference.proxyHost;
    final proxyPort = Preference.proxyPort;
    if (proxyEnabled && proxyHost != null && proxyPort != null) {
      client.findProxy = (_) => 'PROXY $proxyHost:$proxyPort';
      client.badCertificateCallback = (_, __, ___) => false;
    }
    return client;
  },
);

Dio _createDio() =>
    Dio()..httpClientAdapter = _ZstdAdapter(_createInnerAdapter());

final _cacheOptions = CacheOptions(
  store: MemCacheStore(),
  policy: .request,
  hitCacheOnErrorExcept: [401, 403],
);

final Dio _dio = _createDio();
final Dio _cachedDio = _createDio()
  ..interceptors.add(DioCacheInterceptor(options: _cacheOptions));
