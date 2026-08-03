import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dpip/core/network/dio_client.dart';
import 'package:dpip/core/network/etag_cache_store.dart';
import 'package:dpip/core/network/etag_interceptor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Answers `304` when `If-None-Match` matches, else `200` with raw [bytes].
class _BinaryAdapter implements HttpClientAdapter {
  _BinaryAdapter({required this.bytes, this.etag});

  final Uint8List bytes;
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
      return ResponseBody.fromBytes(const [], 304, headers: {});
    }
    return ResponseBody.fromBytes(
      bytes,
      200,
      headers: {
        Headers.contentTypeHeader: ['application/vnd.mapbox-vector-tile'],
        if (etag != null) 'etag': [etag!],
      },
    );
  }

  @override
  void close({bool force = false}) {}
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

  test('binary write/read round-trips bytes and etag', () async {
    final bytes = Uint8List.fromList([0x1a, 0x2b, 0x3c, 0x4d]);
    await store.writeBytes(
      'https://x/t.mvt',
      etag: 'W/"mvt1"',
      bytes: bytes,
      contentType: 'application/vnd.mapbox-vector-tile',
      size: 99,
    );
    expect(await store.read('https://x/t.mvt'), isNull, reason: 'JSON path');
    final entry = await store.readBytes('https://x/t.mvt');
    expect(entry, isNotNull);
    expect(entry!.etag, 'W/"mvt1"');
    expect(entry.bytes, bytes);
    expect(entry.size, 99);
  });

  test('JSON and binary entries do not cross-decode', () async {
    await store.write('https://x/j', etag: '1', body: '{"a":1}');
    await store.writeBytes(
      'https://x/b',
      etag: '2',
      bytes: Uint8List.fromList([9, 8, 7]),
    );
    expect(await store.readBytes('https://x/j'), isNull);
    expect(await store.read('https://x/b'), isNull);
    expect((await store.read('https://x/j'))!.body, '{"a":1}');
    expect((await store.readBytes('https://x/b'))!.bytes, [9, 8, 7]);
  });

  test('bytes 304 is served from binary cache', () async {
    final payload = Uint8List.fromList(utf8.encode('mvt-bytes'));
    final adapter = _BinaryAdapter(bytes: payload, etag: 'v1');
    final dio = createDio(etagCache: store)..httpClientAdapter = adapter;

    final first = await dio.get<List<int>>(
      'https://x.test/tile.mvt',
      options: Options(responseType: ResponseType.bytes),
    );
    expect(first.statusCode, 200);
    expect(first.data, payload);
    expect(adapter.calls, 1);

    final second = await dio.get<List<int>>(
      'https://x.test/tile.mvt',
      options: Options(responseType: ResponseType.bytes),
    );
    expect(adapter.calls, 2);
    expect(second.statusCode, 200);
    expect(second.data, payload);
    expect(second.headers.value('etag'), 'v1');
  });

  test('bytes 200 without ETag is not cached (non-basemap)', () async {
    final payload = Uint8List.fromList([0x52, 0x49, 0x46, 0x46]);
    final adapter = _BinaryAdapter(bytes: payload); // no etag
    final dio = createDio(etagCache: store)..httpClientAdapter = adapter;
    const url =
        'https://static.core-tnn1.exptech.dev/api/v2/tiles/radar/1/7/1/1.webp';

    await dio.get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(await store.readBytes(url), isNull);
  });

  test('basemap PBF uses URL-hash ETag and hits locally on repeat', () async {
    final payload = Uint8List.fromList([0x1a, 0x2b, 0x3c]);
    final adapter = _BinaryAdapter(bytes: payload); // no server etag
    final dio = createDio(etagCache: store)..httpClientAdapter = adapter;
    const url = 'https://lb.exptech.dev/api/v1/map/tiles/7/109/55.pbf';
    final expectedEtag = EtagInterceptor.etagFromUrl(Uri.parse(url));

    final first = await dio.get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
    expect(first.data, payload);
    expect(first.headers.value('etag'), expectedEtag);
    expect(adapter.calls, 1);

    CachedBytes? entry;
    for (var i = 0; i < 50 && entry == null; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      entry = await store.readBytes(url);
    }
    expect(entry?.etag, expectedEtag);

    final second = await dio.get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
    expect(adapter.calls, 1, reason: 'URL-hash local hit, no LB round trip');
    expect(second.data, payload);
    expect(second.headers.value('etag'), expectedEtag);
  });
}
