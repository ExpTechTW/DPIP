/// [ApiClientStaleIfError.getOrSaved] end to end: a real region client, the
/// real ETag interceptor over an in-memory cache, and a fake network per host.
///
/// What is pinned is the order of things. The region client must still fail
/// over to a host that is up — a saved copy is the answer only once every
/// host has failed — and the copy that comes back must carry its marker, so
/// nothing above can show it as current.
library;

import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/api_region.dart';
import 'package:dpip/core/network/dio_client.dart';
import 'package:dpip/core/network/etag_cache_store.dart';
import 'package:dpip/core/network/region_selection.dart';
import 'package:dpip/core/network/stale_if_error.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite_async/sqlite_async.dart';

import '../storage/memory_db.dart';

/// Answers per host: a body, a status, or a dropped connection.
class _Hosts implements HttpClientAdapter {
  final Map<String, Object> byHost = {};
  final List<String> asked = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    asked.add(options.uri.host);
    final answer = byHost[options.uri.host];
    if (answer is String) {
      return ResponseBody.fromString(
        answer,
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
          'etag': ['"${answer.hashCode}"'],
        },
      );
    }
    if (answer is int) {
      return ResponseBody.fromBytes(Uint8List(0), answer, headers: {});
    }
    throw DioException.connectionError(
      requestOptions: options,
      reason: 'unreachable',
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  const path = '/api/v2/eq/report';
  const first = 'api.core-tnn1.exptech.dev';
  const second = 'api.core-tyo1.exptech.dev';
  late SqliteDatabase db;
  late _Hosts hosts;
  late ApiClient client;

  setUp(() async {
    db = openMemoryDb();
    await EtagCacheStore.createSchema(db);
    hosts = _Hosts();
    final dio = createDio(etagCache: EtagCacheStore(db))
      ..httpClientAdapter = hosts;
    client = ApiClient(dio, RegionSelection(SettingsStore.inMemory({})));
  });

  tearDown(() async => db.close());

  Future<void> saveFromFirstHost() async {
    hosts.byHost[first] = '[{"id":"saved"}]';
    final fresh = await client.getOrSaved(ApiTier.coreApi, path);
    expect(fresh.stale, isNull);
    // The interceptor's write is fire-and-forget.
    await Future<void>.delayed(const Duration(milliseconds: 150));
  }

  test('every host down: the saved copy, marked as such', () async {
    await saveFromFirstHost();
    hosts.byHost.clear();

    final result = await client.getOrSaved(ApiTier.coreApi, path);

    expect(result.data, [
      {'id': 'saved'},
    ]);
    expect(result.stale, isNotNull);
    expect(result.stale!.failure, isA<NetworkFailure>());
    expect(result.stale!.since, isNotNull);
    expect(hosts.asked, [
      first,
      first,
      second,
    ], reason: 'the save, then both hosts tried before the copy is used');
  });

  test('a host that is up still wins over the saved copy', () async {
    await saveFromFirstHost();
    hosts.byHost
      ..clear()
      ..[second] = '[{"id":"fresh"}]';

    final result = await client.getOrSaved(ApiTier.coreApi, path);

    expect(result.data, [
      {'id': 'fresh'},
    ]);
    expect(result.stale, isNull);
  });

  test('nothing saved: the failure comes back as before', () async {
    await expectLater(
      client.getOrSaved(ApiTier.coreApi, path),
      throwsA(isA<DioException>()),
    );
  });

  test('a 404 is never covered by a saved copy', () async {
    await saveFromFirstHost();
    hosts.byHost
      ..clear()
      ..[first] = 404;

    await expectLater(
      client.getOrSaved(ApiTier.coreApi, path),
      throwsA(isA<DioException>()),
    );
  });
}
