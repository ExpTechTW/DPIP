import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dpip/core/network/dio_client.dart';
import 'package:dpip/core/network/etag_cache_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

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
  late Database db;
  late EtagCacheStore store;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await EtagCacheStore.createSchema(db);
    store = EtagCacheStore(db);
  });

  tearDown(() async => db.close());

  Dio dioWith(_FakeAdapter adapter) =>
      createDio(etagCache: store)..httpClientAdapter = adapter;

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
}
