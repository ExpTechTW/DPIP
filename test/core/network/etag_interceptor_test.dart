import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dpip/core/network/dio_client.dart';
import 'package:dpip/core/network/etag_cache_store.dart';
import 'package:dpip/core/network/etag_interceptor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite_async/sqlite_async.dart';

import '../storage/memory_db.dart';

/// A Dio adapter that answers `304` when the request carries the matching
/// `If-None-Match`, else `200` with [body] and (optionally) an ETag — enough to
/// exercise the full revalidation path without a network.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter({required this.body, this.etag});

  final String body;
  final String? etag;
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    if (etag != null && options.headers['if-none-match'] == etag) {
      return ResponseBody.fromString('', 304, headers: {});
    }
    return ResponseBody.fromString(
      body,
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
        if (etag != null) 'etag': [etag!],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// A store that claims to hold an etag (so `If-None-Match` is sent) but whose
/// body is gone by response time — models an entry evicted mid-request.
class _EvictedStore extends EtagCacheStore {
  _EvictedStore(super.db);

  @override
  Future<String?> readEtag(String url) async => 'v1';

  @override
  Future<CachedResponse?> read(String url) async => null;
}

void main() {
  late SqliteDatabase db;
  late EtagCacheStore store;

  setUp(() async {
    db = openMemoryDb();
    await EtagCacheStore.createSchema(db);
    store = EtagCacheStore(db);
  });

  tearDown(() async => db.close());

  Dio dioWith(HttpClientAdapter adapter) =>
      createDio(etagCache: store)..httpClientAdapter = adapter;

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 150));

  test('a 304 is served from cache as a 200 with the cached body', () async {
    final adapter = _FakeAdapter(body: '{"n":1}', etag: 'v1');
    final dio = dioWith(adapter);

    final first = await dio.get<dynamic>('https://x.test/data');
    expect(first.statusCode, 200);
    expect(first.data, {'n': 1});
    expect(adapter.calls, 1);

    final second = await dio.get<dynamic>('https://x.test/data');
    expect(adapter.calls, 2, reason: 'revalidated over the network');
    expect(second.statusCode, 200, reason: '304 rewritten to 200');
    expect(second.data, {'n': 1}, reason: 'body came from cache');
  });

  test(
    'a 304 whose cache entry was evicted fails, never null success',
    () async {
      final dio = createDio(etagCache: _EvictedStore(db))
        ..httpClientAdapter = _FakeAdapter(body: '{"n":1}', etag: 'v1');

      // If-None-Match 'v1' is sent (readEtag), the server 304s, but read() is
      // empty — the interceptor must reject rather than hand up a bodyless 200.
      await expectLater(
        dio.get<dynamic>('https://x.test/evicted'),
        throwsA(isA<DioException>()),
      );
    },
  );

  test('a 200 without an ETag is not cached', () async {
    final adapter = _FakeAdapter(body: '{"n":2}'); // no etag
    final dio = dioWith(adapter);

    await dio.get<dynamic>('https://x.test/nocache');
    expect(await store.read('https://x.test/nocache'), isNull);
  });

  test(
    'streaming responses are skipped (no If-None-Match, no caching)',
    () async {
      final adapter = _FakeAdapter(body: 'stream-body', etag: 'v1');
      final dio = dioWith(adapter);

      await dio.get<dynamic>(
        'https://x.test/stream',
        options: Options(responseType: ResponseType.stream),
      );
      expect(await store.read('https://x.test/stream'), isNull);
    },
  );

  test('live / personal paths are never cached', () async {
    final adapter = _FakeAdapter(body: '[]', etag: 'v1');
    final dio = dioWith(adapter);
    const urls = [
      'https://api.lb-tpe1.exptech.dev/api/v2/eq/eew',
      'https://api.lb-tpe1.exptech.dev/api/v2/trem/rts',
      'https://api.core-tnn1.exptech.dev/api/v2/location/1/tok/1.0/25,121',
      'https://api.core-tnn1.exptech.dev/api/v2/notify/tok',
      'https://api.core-tnn1.exptech.dev/api/v2/notify/tok/eew/1',
    ];
    for (final url in urls) {
      await dio.get<dynamic>(url);
      expect(await store.read(url), isNull, reason: url);
      expect(EtagInterceptor.isUncacheablePath(Uri.parse(url).path), isTrue);
    }
  });

  test('basemap PBF 404 is cached as empty and served locally', () async {
    const url = 'https://static.lb.exptech.dev/api/v1/map/tiles/7/114/56.pbf';
    final adapter = _StatusAdapter(404);
    final dio = dioWith(adapter);

    await expectLater(
      dio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      ),
      throwsA(isA<DioException>()),
    );
    final cached = await store.readBytes(url);
    expect(cached, isNotNull);
    expect(cached!.bytes, isEmpty);
    expect(cached.etag, EtagInterceptor.negativeTileEtag);

    // Second get is a local hit (200 empty) — no second network call.
    final again = await dio.get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
    expect(again.statusCode, 200);
    expect(again.data, isEmpty);
    expect(adapter.calls, 1);
  });

  test('a status-dashboard POST is cached under the URL hash', () async {
    const url = 'https://status.exptech.dev/api/ds/query';
    final adapter = _FakeAdapter(body: '{"results":{}}', etag: 'no-etag');
    final dio = dioWith(adapter);

    final first = await dio.post<dynamic>(url, data: {'queries': []});
    expect(first.statusCode, 200);
    expect(first.data, {'results': {}});
    // Immutable POST: stored under a synthetic URL-hash ETag, ignoring the
    // server's (here absent) ETag.
    await settle();
    final cached = await store.readJson(url);
    expect(cached, isNotNull);
    expect(cached!.etag, EtagInterceptor.etagFromUrl(Uri.parse(url)));
    expect(cached.data, {'results': {}});

    // A follow-up POST still goes to the network — online must always refresh —
    // and again overwrites the entry (same URL hash, `replace`).
    await dio.post<dynamic>(url, data: {'queries': []});
    expect(adapter.calls, 2);
    // Writes are fire-and-forget inside the interceptor (unawaited), so give
    // the gzip+insert hop a beat before the read.
    await settle();
    expect(await store.readJson(url), isNotNull);
  });

  test('a status-dashboard POST serves the cached snapshot when offline', () async {
    const url = 'https://status.exptech.dev/api/ds/query';
    // Prime the store with a good snapshot, then make every network call fail.
    final okAdapter = _FakeAdapter(body: '{"results":{"status":0}}');
    final onlineDio = dioWith(okAdapter);
    await onlineDio.post<dynamic>(url, data: {'queries': []});
    await settle(); // let the fire-and-forget write land

    final offline = _NetworkDownAdapter();
    final dio = dioWith(offline);
    final response = await dio.post<dynamic>(url, data: {'queries': []});
    expect(response.statusCode, 200);
    expect(response.data, {
      'results': {'status': 0},
    });
    expect(
      offline.calls,
      1,
      reason: 'network was attempted before falling back',
    );
  });

  test(
    'a failing POST on a non-dashboard host is not served from cache',
    () async {
      const url = 'https://status.other.test/api/ds/query';
      final okAdapter = _FakeAdapter(body: '{"n":1}');
      final onlineDio = dioWith(okAdapter);
      await onlineDio.post<dynamic>(url, data: {'queries': []});
      // Only status.exptech.dev is content-addressed for POST; a different host
      // with a status-like URL must not grow an offline fallback policy by
      // accident.
      final dio = dioWith(_NetworkDownAdapter());
      await expectLater(
        dio.post<dynamic>(url, data: {'queries': []}),
        throwsA(isA<DioException>()),
      );
    },
  );
}

/// Adapter that always fails with a connection error — models being offline.
class _NetworkDownAdapter implements HttpClientAdapter {
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    throw DioException.connectionError(
      requestOptions: options,
      reason: 'no network',
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Adapter that always returns [status] with an empty body.
class _StatusAdapter implements HttpClientAdapter {
  _StatusAdapter(this.status);

  final int status;
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    return ResponseBody.fromBytes(Uint8List(0), status, headers: {});
  }

  @override
  void close({bool force = false}) {}
}
