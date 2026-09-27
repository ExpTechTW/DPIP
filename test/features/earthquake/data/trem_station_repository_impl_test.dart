/// The station directory's fetch-and-keep contract: what the monitor draws
/// with, on the connection an earthquake leaves behind.
///
/// Each rule here guards a way the monitor goes blank without saying why:
/// - An unchanged list is revalidated with the saved ETag and answered `304`,
///   and that answer must yield the saved copy, not an empty body.
/// - A failed or empty answer must never replace the copy in hand — the
///   saved directory is the only thing that places the dots.
/// - A validator is only sent for a copy that still parses; a `304` for an
///   unreadable copy would pin the monitor to nothing.
library;

import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/region_selection.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/core/storage/trem_station_store.dart';
import 'package:dpip/features/earthquake/data/trem_station_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../core/storage/memory_db.dart';

const _csv = '''loc_code,id,lat,lon,floor,code,net,time,work
1,125313C,23.3188,121.4564,2,962,3,2026-02-16,1
''';

const _changedCsv = '''loc_code,id,lat,lon,floor,code,net,time,work
1,125313C,23.3188,121.4564,2,962,3,2026-02-16,1
1,11DFDBC,24.1,121.6,1,970,3,2026-09-01,1
''';

/// Answers each request from [responder] and records the headers it was sent.
class _Adapter implements HttpClientAdapter {
  _Adapter(this.responder);

  final ResponseBody Function(RequestOptions options) responder;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return responder(options);
  }

  @override
  void close({bool force = false}) {}
}

/// Served the way nginx serves it: CSV, labelled JSON, with a weak ETag.
ResponseBody _ok(String body, {String etag = 'W/"a"'}) =>
    ResponseBody.fromString(
      body,
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        'etag': [etag],
      },
    );

ResponseBody _notModified() => ResponseBody.fromString('', 304);

ResponseBody _failure(int status) => ResponseBody.fromString('', status);

void main() {
  late _Adapter adapter;
  late TremStationStore store;

  TremStationRepositoryImpl repository() => TremStationRepositoryImpl(
    ApiClient(
      Dio(
        BaseOptions(
          validateStatus: (s) =>
              s != null && ((s >= 200 && s < 300) || s == 304),
        ),
      )..httpClientAdapter = adapter,
      RegionSelection(SettingsStore.inMemory({})),
    ),
    store,
    now: () => DateTime.utc(2026, 9, 28),
  );

  setUp(() async {
    final db = openMemoryDb();
    await TremStationStore.createSchema(db);
    store = TremStationStore(db);
  });

  test('a first fetch is unconditional, and is kept with its ETag', () async {
    adapter = _Adapter((_) => _ok(_csv));
    final repo = repository();

    expect(await repo.saved(), isNull);
    final result = await repo.refresh();

    expect(result.valueOrNull?.keys, ['125313C']);
    expect(adapter.requests.single.headers['If-None-Match'], isNull);
    expect(adapter.requests.single.uri.path, '/resource/station');
    final stored = await store.read();
    expect(stored?.csv, _csv);
    expect(stored?.etag, 'W/"a"');
  });

  test('an unchanged list costs a 304 and yields the saved copy', () async {
    await store.write(csv: _csv, etag: 'W/"a"', fetchedAt: DateTime.utc(2026));
    adapter = _Adapter((_) => _notModified());

    final result = await repository().refresh();

    expect(adapter.requests.single.headers['If-None-Match'], 'W/"a"');
    expect(result.valueOrNull?.keys, ['125313C']);
  });

  test('a changed list replaces the saved one, validator and all', () async {
    await store.write(csv: _csv, etag: 'W/"a"', fetchedAt: DateTime.utc(2026));
    adapter = _Adapter((_) => _ok(_changedCsv, etag: 'W/"b"'));
    final repo = repository();

    final result = await repo.refresh();

    expect(result.valueOrNull, hasLength(2));
    expect((await store.read())?.etag, 'W/"b"');
    expect(await repo.saved(), hasLength(2));
  });

  test('a failed fetch is an Err and leaves the saved copy alone', () async {
    await store.write(csv: _csv, etag: 'W/"a"', fetchedAt: DateTime.utc(2026));
    adapter = _Adapter((_) => _failure(404));
    final repo = repository();

    final result = await repo.refresh();

    expect(result.failureOrNull, isA<NotFoundFailure>());
    expect((await repo.saved())?.keys, ['125313C']);
    expect((await store.read())?.csv, _csv);
  });

  test(
    'an empty list is a DecodeFailure, never saved over a good one',
    () async {
      await store.write(
        csv: _csv,
        etag: 'W/"a"',
        fetchedAt: DateTime.utc(2026),
      );
      adapter = _Adapter(
        (_) => _ok('loc_code,id,lat,lon,floor,code,net,time,work\n'),
      );

      final result = await repository().refresh();

      expect(result.failureOrNull, isA<DecodeFailure>());
      expect((await store.read())?.csv, _csv);
    },
  );

  test(
    'an unreadable saved copy is fetched afresh, without a validator',
    () async {
      await store.write(
        csv: 'garbage',
        etag: 'W/"a"',
        fetchedAt: DateTime.utc(2026),
      );
      adapter = _Adapter((_) => _ok(_csv));
      final repo = repository();

      expect(await repo.saved(), isNull);
      final result = await repo.refresh();

      expect(adapter.requests.single.headers['If-None-Match'], isNull);
      expect(result.valueOrNull?.keys, ['125313C']);
    },
  );
}
