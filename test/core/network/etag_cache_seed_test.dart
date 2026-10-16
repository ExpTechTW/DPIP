/// Rows the app plants from its bundled basemap are a fallback, never an
/// answer: they fill only what nothing else has filled, a server's row always
/// replaces them and they never replace a server's row, and the HTTP path does
/// not treat one as a hit.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dpip/core/network/dio_client.dart';
import 'package:dpip/core/network/etag_cache_store.dart';
import 'package:dpip/core/network/etag_interceptor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite_async/sqlite_async.dart';

import '../storage/memory_db.dart';

const _url = 'https://static.lb.exptech.dev/api/v1/map/tiles/7/107/55.pbf';
final _v1 = EtagCacheStore.seedEtag('v1');
final _v2 = EtagCacheStore.seedEtag('v2');

Uint8List _member(List<int> body) =>
    Uint8List.fromList(GZipCodec(level: 9).encode(body));

/// Answers every request with [bytes], or fails as if the radio were off.
class _Origin implements HttpClientAdapter {
  _Origin({this.bytes, this.offline = false});

  final Uint8List? bytes;
  final bool offline;
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    if (offline) throw const SocketException('Network is unreachable');
    return ResponseBody.fromBytes(
      bytes!,
      200,
      headers: {
        Headers.contentTypeHeader: ['application/octet-stream'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
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

  Future<void> network(List<int> bytes) => store.writeBytes(
    _url,
    etag: EtagInterceptor.etagFromUrl(Uri.parse(_url)),
    bytes: Uint8List.fromList(bytes),
    contentType: 'application/octet-stream',
  );

  group('seed ETag', () {
    test('marks planted rows and nothing a server sends', () {
      expect(EtagCacheStore.isSeedEtag(_v1), isTrue);
      expect(
        EtagCacheStore.isSeedEtag(EtagInterceptor.etagFromUrl(Uri.parse(_url))),
        isFalse,
      );
      expect(
        EtagCacheStore.isSeedEtag(EtagInterceptor.negativeTileEtag),
        isFalse,
      );
      expect(EtagCacheStore.isSeedEtag('"seed-v1"'), isFalse);
    });
  });

  group('seedBytesBatch', () {
    test('plants a gzip member that reads back decoded', () async {
      final written = await store.seedBytesBatch([
        (url: _url, body: _member([1, 2, 3])),
      ], etag: _v1);

      expect(written, 1);
      final row = await store.readBytes(_url);
      expect(row?.bytes, [1, 2, 3]);
      expect(row?.etag, _v1);
      expect(row?.size, 0, reason: 'nothing was downloaded, nothing is saved');
    });

    test('plants an empty body as an empty tile', () async {
      await store.seedBytesBatch([(url: _url, body: Uint8List(0))], etag: _v1);

      expect((await store.readBytes(_url))?.bytes, isEmpty);
    });

    test('is idempotent for the same bundle', () async {
      final rows = [
        (url: _url, body: _member([1])),
      ];
      expect(await store.seedBytesBatch(rows, etag: _v1), 1);
      expect(await store.seedBytesBatch(rows, etag: _v1), 0);
    });

    test('replaces a row planted from an older bundle', () async {
      await store.seedBytesBatch([
        (url: _url, body: _member([1])),
      ], etag: _v1);

      final written = await store.seedBytesBatch([
        (url: _url, body: _member([2])),
      ], etag: _v2);

      expect(written, 1);
      final row = await store.readBytes(_url);
      expect(row?.bytes, [2]);
      expect(row?.etag, _v2);
    });

    test('never replaces a downloaded row', () async {
      await network([9, 9]);

      final written = await store.seedBytesBatch([
        (url: _url, body: _member([1])),
      ], etag: _v1);

      expect(written, 0);
      expect((await store.readBytes(_url))?.bytes, [9, 9]);
    });

    test('never replaces a cached 404', () async {
      await store.writeBytes(
        _url,
        etag: EtagInterceptor.negativeTileEtag,
        bytes: Uint8List(0),
      );

      expect(
        await store.seedBytesBatch([
          (url: _url, body: _member([1])),
        ], etag: _v1),
        0,
      );
      expect(
        (await store.readBytes(_url))?.etag,
        EtagInterceptor.negativeTileEtag,
      );
    });

    test('a download replaces a planted row', () async {
      await store.seedBytesBatch([
        (url: _url, body: _member([1])),
      ], etag: _v1);

      await network([9]);

      final row = await store.readBytes(_url);
      expect(row?.bytes, [9]);
      expect(EtagCacheStore.isSeedEtag(row!.etag), isFalse);
    });

    test('plants only the slots that are free, in one batch', () async {
      const other =
          'https://static.lb.exptech.dev/api/v1/map/tiles/7/106/55.pbf';
      await network([9]);

      final written = await store.seedBytesBatch([
        (url: _url, body: _member([1])),
        (url: other, body: _member([2])),
      ], etag: _v1);

      expect(written, 1);
      expect((await store.readBytes(_url))?.bytes, [9]);
      expect((await store.readBytes(other))?.bytes, [2]);
    });
  });

  group('reads', () {
    test('etagsFor reports rows without reading or touching them', () async {
      await store.seedBytesBatch([
        (url: _url, body: _member([1])),
      ], etag: _v1);
      final before = (await db.get('SELECT time FROM http_cache'))['time'];

      final etags = await store.etagsFor([_url, '$_url?missing']);

      expect(etags, {_url: _v1});
      await Future<void>.delayed(const Duration(milliseconds: 600));
      expect((await db.get('SELECT time FROM http_cache'))['time'], before);
    });

    test('accept turns a planted row into a miss', () async {
      await store.seedBytesBatch([
        (url: _url, body: _member([1])),
      ], etag: _v1);
      bool notPlanted(String _, String etag) =>
          !EtagCacheStore.isSeedEtag(etag);

      expect(await store.readBytes(_url, accept: notPlanted), isNull);
      expect(await store.readBytesBatch([_url], accept: notPlanted), isEmpty);
      expect(await store.readBytesBatch([_url]), contains(_url));
    });
  });

  group('the HTTP path', () {
    Future<Response<List<int>>> get(Dio dio) => dio.get<List<int>>(
      _url,
      options: Options(responseType: ResponseType.bytes),
    );

    test('a planted row is not a local hit — the request goes out', () async {
      await store.seedBytesBatch([
        (url: _url, body: _member([1])),
      ], etag: _v1);
      final origin = _Origin(bytes: Uint8List.fromList([7, 7]));
      final dio = createDio(etagCache: store)..httpClientAdapter = origin;

      final response = await get(dio);

      expect(origin.calls, 1);
      expect(response.data, [7, 7]);
    });

    test('the download replaces the planted row', () async {
      await store.seedBytesBatch([
        (url: _url, body: _member([1])),
      ], etag: _v1);
      final dio = createDio(etagCache: store)
        ..httpClientAdapter = _Origin(bytes: Uint8List.fromList([7]));

      await get(dio);

      CachedBytes? row;
      for (var i = 0; i < 50; i++) {
        row = await store.readBytes(_url);
        if (row != null && !EtagCacheStore.isSeedEtag(row.etag)) break;
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      expect(row?.bytes, [7]);
      expect(row?.etag, EtagInterceptor.etagFromUrl(Uri.parse(_url)));
    });

    test('offline, the planted row is not passed off as a response', () async {
      await store.seedBytesBatch([
        (url: _url, body: _member([1])),
      ], etag: _v1);
      final dio = createDio(etagCache: store)
        ..httpClientAdapter = _Origin(offline: true);

      await expectLater(get(dio), throwsA(isA<DioException>()));
      expect(
        (await store.readBytes(_url))?.etag,
        _v1,
        reason: 'the fallback stays for the map to use',
      );
    });
  });
}
