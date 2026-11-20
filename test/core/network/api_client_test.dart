import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/api_paths.dart';
import 'package:dpip/core/network/api_region.dart';
import 'package:dpip/core/network/endpoint_health.dart';
import 'package:dpip/core/network/region_selection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dpip/core/settings/settings_store.dart';

/// A dio adapter that records the hosts it is asked to fetch and returns a
/// scripted response per call, so failover behaviour is observable without a
/// network.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.responder);

  final ResponseBody Function(int call, RequestOptions options) responder;
  final List<String> hits = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    hits.add(options.uri.host);
    return responder(hits.length, options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(String body, int status) => ResponseBody.fromString(
  body,
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RegionSelection regions;

  setUp(() async {
    regions = RegionSelection(SettingsStore.inMemory({}));
  });

  ApiClient clientWith(_FakeAdapter adapter) =>
      ApiClient(Dio()..httpClientAdapter = adapter, regions);

  ApiClient monitoredClient(
    _FakeAdapter adapter,
    EndpointHealthMonitor health,
  ) => ApiClient(Dio()..httpClientAdapter = adapter, regions, health);

  test('first host succeeds → no failover', () async {
    final adapter = _FakeAdapter((_, _) => _json('{"ok":true}', 200));
    final res = await clientWith(adapter).request(ApiTier.lbApi, '/x');
    expect(res.statusCode, 200);
    expect(adapter.hits, hasLength(1)); // only the primary region
  });

  test('a 5xx fails over to the next region', () async {
    final adapter = _FakeAdapter(
      (call, _) => call == 1 ? _json('{}', 503) : _json('{"ok":true}', 200),
    );
    final res = await clientWith(adapter).request(ApiTier.lbApi, '/x');
    expect(res.statusCode, 200);
    expect(adapter.hits, hasLength(2)); // primary then secondary
  });

  test('a connection error fails over to the next region', () async {
    final adapter = _FakeAdapter((call, options) {
      if (call == 1) {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        );
      }
      return _json('{"ok":true}', 200);
    });
    final res = await clientWith(adapter).request(ApiTier.lbApi, '/x');
    expect(res.statusCode, 200);
    expect(adapter.hits, hasLength(2));
  });

  test('a 4xx throws immediately without failover', () async {
    final adapter = _FakeAdapter((_, _) => _json('{"err":"bad"}', 404));
    final client = clientWith(adapter);
    await expectLater(
      () => client.request(ApiTier.lbApi, '/x'),
      throwsA(isA<DioException>()),
    );
    expect(adapter.hits, hasLength(1)); // the other region was NOT tried
  });

  test('all regions failing throws after trying each', () async {
    final adapter = _FakeAdapter((_, _) => _json('{}', 503));
    final client = clientWith(adapter);
    await expectLater(
      () => client.request(ApiTier.lbApi, '/x'),
      throwsA(isA<DioException>()),
    );
    expect(adapter.hits, hasLength(2)); // every region attempted
  });

  test('a cancelled request is not retried against another region', () async {
    final adapter = _FakeAdapter((_, _) => _json('{"ok":true}', 200));
    final client = clientWith(adapter);
    final token = CancelToken()..cancel();
    await expectLater(
      () => client.request(ApiTier.lbApi, '/x', cancelToken: token),
      throwsA(isA<DioException>()),
    );
    expect(adapter.hits.length, lessThan(2)); // cancellation is not failed over
  });

  test('the exclusive tier does not fail over (single host)', () async {
    final adapter = _FakeAdapter((_, _) => _json('{}', 503));
    final client = clientWith(adapter);
    await expectLater(
      () => client.request(ApiTier.coreExclusiveApi, '/x'),
      throwsA(isA<DioException>()),
    );
    expect(adapter.hits, hasLength(1));
  });

  test('a successful request marks the host healthy', () async {
    final health = EndpointHealthMonitor();
    final adapter = _FakeAdapter((_, _) => _json('{"ok":true}', 200));
    await monitoredClient(adapter, health).request(ApiTier.lbApi, '/x');

    expect(
      health.of(
        EndpointService.other,
        ApiTier.lbApi,
        'api.lb-tpe1.exptech.dev',
      ),
      isNotNull,
    );
    expect(health.summary, EndpointState.healthy);
    expect(
      health
          .of(EndpointService.other, ApiTier.lbApi, 'api.lb-tpe1.exptech.dev')!
          .lastSuccess,
      isNotNull,
    );
  });

  test('failed-over request marks the dead host and the healthy one', () async {
    final health = EndpointHealthMonitor();
    final adapter = _FakeAdapter(
      (call, _) => call == 1 ? _json('{}', 503) : _json('{"ok":true}', 200),
    );
    await monitoredClient(adapter, health).request(ApiTier.lbApi, '/x');

    // First host (tpe1) got a 503 → degraded after one failure.
    final tpe1 = health.of(
      EndpointService.other,
      ApiTier.lbApi,
      'api.lb-tpe1.exptech.dev',
    )!;
    expect(tpe1.consecutiveFailures, 1);
    expect(tpe1.state, EndpointState.degraded);
    // Second host (khh1) served the 200 → healthy.
    final khh1 = health.of(
      EndpointService.other,
      ApiTier.lbApi,
      'api.lb-khh1.exptech.dev',
    )!;
    expect(khh1.state, EndpointState.healthy);
    expect(health.summary, EndpointState.degraded);
  });

  test('a 404 fails over only when the caller asks, uncharged', () async {
    // An immutable snapshot one region lacks may be held by the other: the
    // regions keep their own history. The missing one is not a sick host.
    final health = EndpointHealthMonitor();
    final adapter = _FakeAdapter(
      (call, _) => call == 1 ? _json('{}', 404) : _json('{"ok":true}', 200),
    );
    final res = await monitoredClient(
      adapter,
      health,
    ).request(ApiTier.coreStatic, '/x', notFoundFailsOver: true);

    expect(res.statusCode, 200);
    expect(adapter.hits, [
      'static.core-tnn1.exptech.dev',
      'static.core-tyo1.exptech.dev',
    ]);
    expect(
      health.of(
        EndpointService.other,
        ApiTier.coreStatic,
        'static.core-tnn1.exptech.dev',
      ),
      isNull,
    );
  });

  test('a 404 from every region is the answer', () async {
    final adapter = _FakeAdapter((_, _) => _json('{}', 404));
    await expectLater(
      () =>
          clientWith(adapter)
              .get(ApiTier.coreStatic, '/x', notFoundFailsOver: true),
      throwsA(
        isA<DioException>().having(
          (e) => e.response?.statusCode,
          'status',
          404,
        ),
      ),
    );
    expect(adapter.hits, hasLength(2));
  });

  test('a 4xx is not charged to the host', () async {
    // A 404 says the route or the resource is wrong, not that the region is
    // sick. Replaying an event older than the RTS retention 404s once a second,
    // and counting those parked the host at `down` for the rest of the session.
    final health = EndpointHealthMonitor();
    final adapter = _FakeAdapter((_, _) => _json('{"err":"bad"}', 404));
    await expectLater(
      () => monitoredClient(adapter, health).request(ApiTier.lbApi, '/x'),
      throwsA(isA<DioException>()),
    );

    expect(
      health.of(
        EndpointService.other,
        ApiTier.lbApi,
        'api.lb-tpe1.exptech.dev',
      ),
      isNull, // untouched, not merely still healthy
    );
    expect(health.summary, EndpointState.unknown);
  });

  test('exclusive and core tiers track the same host separately', () async {
    final health = EndpointHealthMonitor();
    final adapter = _FakeAdapter((_, _) => _json('{"ok":true}', 200));
    final client = monitoredClient(adapter, health);
    await client.request(ApiTier.coreApi, '/x');
    await client.request(ApiTier.coreExclusiveApi, '/x');

    // Both hit api.core-tnn1, but they are different services: two entries.
    expect(health.entries, hasLength(2));
    expect(
      health
          .of(
            EndpointService.other,
            ApiTier.coreApi,
            'api.core-tnn1.exptech.dev',
          )!
          .state,
      EndpointState.healthy,
    );
    expect(
      health
          .of(
            EndpointService.other,
            ApiTier.coreExclusiveApi,
            'api.core-tnn1.exptech.dev',
          )!
          .state,
      EndpointState.healthy,
    );
  });

  test('two consecutive failures mark the host down', () async {
    final health = EndpointHealthMonitor();
    // Every request 503s; tpe1 is the first host attempted in each run, so
    // two runs accumulate a two-failure streak on it.
    final adapter = _FakeAdapter((_, _) => _json('{}', 503));
    final client = monitoredClient(adapter, health);
    await expectLater(
      () => client.request(ApiTier.lbApi, '/x'),
      throwsA(isA<DioException>()),
    );
    await expectLater(
      () => client.request(ApiTier.lbApi, '/x'),
      throwsA(isA<DioException>()),
    );

    final tpe1 = health.of(
      EndpointService.other,
      ApiTier.lbApi,
      'api.lb-tpe1.exptech.dev',
    )!;
    expect(tpe1.state, EndpointState.down);
    expect(health.summary, EndpointState.down);
  });

  test('hostsFor names every tier from the current region order', () {
    final client = clientWith(_FakeAdapter((_, _) => _json('{}', 200)));
    expect(
      client.hostsFor(ApiTier.lbStatic).first,
      'https://static.lb-tpe1.exptech.dev',
    );
    expect(
      client.hostsFor(ApiTier.coreStatic).first,
      startsWith('https://static.core-'),
    );
    expect(client.hostsFor(ApiTier.coreStaticExclusive), [
      'https://static.core-tnn1.exptech.dev',
    ]);
    expect(client.hostsFor(ApiTier.legacyApi), ['https://api-1.exptech.dev']);
  });

  test('post and absolute helpers return the decoded body', () async {
    final adapter = _FakeAdapter((_, options) {
      expect(options.method, 'POST');
      return _json('{"posted":true}', 200);
    });
    final client = clientWith(adapter);
    expect(await client.post(ApiTier.lbApi, '/x', data: {'a': 1}), {
      'posted': true,
    });
    expect(
      await client.postAbsolute('https://status.example/q', data: const {}),
      {'posted': true},
    );
  });

  test('getBytes keeps the body and the etag', () async {
    final adapter = _FakeAdapter(
      (_, _) => ResponseBody.fromBytes(
        [9, 8, 7],
        200,
        headers: {
          Headers.contentTypeHeader: ['application/octet-stream'],
          'etag': ['"tile"'],
        },
      ),
    );
    final payload = await clientWith(adapter).getBytes(ApiTier.lbApi, '/t');
    expect(payload.bytes, [9, 8, 7]);
    expect(payload.etag, '"tile"');
  });

  test('a certificate failure is not failed over', () async {
    final adapter = _FakeAdapter((call, options) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.badCertificate,
      );
    });
    await expectLater(
      () => clientWith(adapter).request(ApiTier.lbApi, '/x'),
      throwsA(isA<DioException>()),
    );
    expect(adapter.hits, hasLength(1));
  });

  test('openStream returns the byte stream and can be cancelled', () async {
    final adapter = _FakeAdapter(
      (_, _) => ResponseBody(Stream.value(Uint8List.fromList([1, 2])), 200),
    );
    final opened = await clientWith(adapter).openStream(ApiTier.lbApi, '/sse');
    expect(await opened.stream.fold<int>(0, (n, chunk) => n + chunk.length), 2);
    opened.cancel();
    expect(adapter.hits, hasLength(1));
  });

  test(
    'openStream errors a stream that falls silent past idleTimeout',
    () async {
      // A half-open socket after a network handover sends nothing and never
      // closes. Without a bound the stream waits on it forever.
      final silent = StreamController<Uint8List>();
      addTearDown(silent.close);
      final adapter = _FakeAdapter((_, _) => ResponseBody(silent.stream, 200));
      final opened = await clientWith(adapter).openStream(
        ApiTier.lbApi,
        '/sse',
        idleTimeout: const Duration(milliseconds: 50),
      );
      silent.add(Uint8List.fromList([1]));
      await expectLater(
        opened.stream,
        emitsInOrder([
          isA<Uint8List>(),
          emitsError(
            isA<DioException>().having(
              (e) => e.type,
              'type',
              DioExceptionType.receiveTimeout,
            ),
          ),
        ]),
      );
    },
  );

  test('a stream 5xx fails over and a 4xx does not', () async {
    final health = EndpointHealthMonitor();
    final failing = _FakeAdapter(
      (call, _) =>
          ResponseBody(Stream.value(Uint8List(0)), call == 1 ? 503 : 200),
    );
    final opened = await monitoredClient(
      failing,
      health,
    ).openStream(ApiTier.lbApi, '/sse');
    expect(failing.hits, hasLength(2));
    opened.cancel();
    expect(
      health
          .of(EndpointService.other, ApiTier.lbApi, 'api.lb-tpe1.exptech.dev')!
          .consecutiveFailures,
      1,
    );

    final clientError = _FakeAdapter(
      (_, _) => ResponseBody(Stream.value(Uint8List(0)), 404),
    );
    await expectLater(
      () => clientWith(clientError).openStream(ApiTier.lbApi, '/sse'),
      throwsA(isA<DioException>()),
    );
    expect(clientError.hits, hasLength(1));
  });

  test(
    'the shared realtime stream reports to both the EEW and RTS rows',
    () async {
      // `SseMux` opens one connection on `ApiPaths.sse` for every live feed.
      // Charged to `other`, an SSE outage would never reach the server-status
      // dot as the EEW or RTS feed it actually is.
      final health = EndpointHealthMonitor();
      final adapter = _FakeAdapter(
        (call, _) =>
            ResponseBody(Stream.value(Uint8List(0)), call == 1 ? 503 : 200),
      );
      final opened = await monitoredClient(adapter, health).openStream(
        ApiTier.lbApi,
        ApiPaths.sse,
        query: {'topics': 'eq.eew.v1,trem.rts.v1'},
      );
      opened.cancel();
      for (final service in [EndpointService.eew, EndpointService.rts]) {
        expect(
          health
              .of(service, ApiTier.lbApi, 'api.lb-tpe1.exptech.dev')!
              .consecutiveFailures,
          1,
          reason: '$service: the failed region',
        );
        expect(
          health.of(service, ApiTier.lbApi, 'api.lb-khh1.exptech.dev')!.state,
          EndpointState.healthy,
          reason: '$service: the region that answered',
        );
      }
      expect(
        health.of(
          EndpointService.other,
          ApiTier.lbApi,
          'api.lb-tpe1.exptech.dev',
        ),
        isNull,
      );
      expect(health.needsAttention, isTrue);
    },
  );

  group('getTileBytes', () {
    const path = '/api/v2/tiles/radar/1783360200/7/107/55.webp';
    const tnn1 = 'https://static.core-tnn1.exptech.dev';
    const tyo1 = 'https://static.core-tyo1.exptech.dev';

    ResponseBody tile(int status) => ResponseBody.fromBytes(
      status == 200 ? [0x52, 0x49, 0x46, 0x46] : const [],
      status,
    );

    test('a retryable failure fails over to the same path on the next '
        'region', () async {
      final adapter = _FakeAdapter((call, options) {
        if (call == 1) {
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.connectionTimeout,
          );
        }
        return tile(200);
      });
      final payload = await clientWith(adapter).getTileBytes('$tnn1$path');
      expect(payload.bytes, [0x52, 0x49, 0x46, 0x46]);
      expect(adapter.hits, [
        'static.core-tnn1.exptech.dev',
        'static.core-tyo1.exptech.dev',
      ]);
    });

    test('a 5xx fails over too', () async {
      final adapter = _FakeAdapter((call, _) => tile(call == 1 ? 502 : 200));
      await clientWith(adapter).getTileBytes('$tnn1$path');
      expect(adapter.hits, hasLength(2));
    });

    test('a frame one region lacks is asked of the other, uncharged', () async {
      // Each core region keeps its own history, so a 404 is a gap in this
      // region, not the answer — and not a sick host either.
      final health = EndpointHealthMonitor();
      final adapter = _FakeAdapter((call, _) => tile(call == 1 ? 404 : 200));
      final payload = await monitoredClient(
        adapter,
        health,
      ).getTileBytes('$tnn1$path');
      expect(payload.bytes, [0x52, 0x49, 0x46, 0x46]);
      expect(adapter.hits, [
        'static.core-tnn1.exptech.dev',
        'static.core-tyo1.exptech.dev',
      ]);
      expect(
        health
            .of(EndpointService.radar, ApiTier.coreStatic, tnn1)
            ?.consecutiveFailures,
        anyOf(isNull, 0),
      );
    });

    test('a 404 from every region is the answer', () async {
      final adapter = _FakeAdapter((_, _) => tile(404));
      await expectLater(
        () => clientWith(adapter).getTileBytes('$tnn1$path'),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'status',
            404,
          ),
        ),
      );
      expect(adapter.hits, hasLength(2), reason: 'each region once');
    });

    test('asks each host at most once, in the selected order', () async {
      regions.core = CoreRegion.tyo1;
      final adapter = _FakeAdapter((_, _) => tile(503));
      await expectLater(
        () => clientWith(adapter).getTileBytes('$tnn1$path'),
        throwsA(isA<DioException>()),
      );
      expect(adapter.hits, [
        'static.core-tyo1.exptech.dev',
        'static.core-tnn1.exptech.dev',
      ]);
    });

    test('a basemap 404 is final: every LB host has the same tiles', () async {
      final adapter = _FakeAdapter((_, _) => tile(404));
      await expectLater(
        () => clientWith(adapter).getTileBytes(
          'https://static.lb-tpe1.exptech.dev/api/v1/map/tiles/9/400/200.pbf',
        ),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'status',
            404,
          ),
        ),
      );
      expect(adapter.hits, ['static.lb-tpe1.exptech.dev']);
    });

    test('a basemap tile fails over on a retryable error', () async {
      final adapter = _FakeAdapter((call, _) => tile(call == 1 ? 503 : 200));
      await clientWith(adapter).getTileBytes(
        'https://static.lb-tpe1.exptech.dev/api/v1/map/tiles/9/400/200.pbf',
      );
      expect(adapter.hits, [
        'static.lb-tpe1.exptech.dev',
        'static.lb-khh1.exptech.dev',
      ]);
    });

    test('a family only tnn1 carries is one request', () async {
      final adapter = _FakeAdapter((_, _) => tile(503));
      await expectLater(
        () => clientWith(adapter).getTileBytes(
          '$tnn1/api/v2/tiles/satellite/13/normal/1783360200/5/26/14.webp',
        ),
        throwsA(isA<DioException>()),
      );
      expect(adapter.hits, ['static.core-tnn1.exptech.dev']);
    });

    test('a host that just failed a tile is asked last', () async {
      // A takeover happens because the selected host failed; asking it first
      // again would spend its timeout against the cache's 1.8 s budget.
      final health = EndpointHealthMonitor()
        ..failure(ApiTier.coreStatic, tnn1, path);
      final adapter = _FakeAdapter((_, _) => tile(200));
      await monitoredClient(adapter, health).getTileBytes('$tnn1$path');
      expect(adapter.hits, ['static.core-tyo1.exptech.dev']);
    });

    test('a host asked last is still asked, once', () async {
      final health = EndpointHealthMonitor()
        ..failure(ApiTier.coreStatic, tnn1, path);
      final adapter = _FakeAdapter((call, _) => tile(call == 1 ? 503 : 200));
      await monitoredClient(adapter, health).getTileBytes('$tnn1$path');
      expect(adapter.hits, [
        'static.core-tyo1.exptech.dev',
        'static.core-tnn1.exptech.dev',
      ]);
    });

    test('with every host failing, the selected order stands', () async {
      final health = EndpointHealthMonitor()
        ..failure(ApiTier.coreStatic, tnn1, path)
        ..failure(ApiTier.coreStatic, tyo1, path);
      final adapter = _FakeAdapter((_, _) => tile(503));
      await expectLater(
        () => monitoredClient(adapter, health).getTileBytes('$tnn1$path'),
        throwsA(isA<DioException>()),
      );
      expect(adapter.hits, [
        'static.core-tnn1.exptech.dev',
        'static.core-tyo1.exptech.dev',
      ]);
    });

    test('tileHostFailing reports what the tile requests saw', () async {
      final health = EndpointHealthMonitor();
      final adapter = _FakeAdapter((call, _) => tile(call == 1 ? 503 : 200));
      final client = monitoredClient(adapter, health);
      expect(client.tileHostFailing('$tnn1$path'), isFalse);

      await client.getTileBytes('$tnn1$path');

      expect(client.tileHostFailing('$tnn1$path'), isTrue);
      expect(client.tileHostFailing('$tyo1$path'), isFalse);
      expect(
        clientWith(adapter).tileHostFailing('$tnn1$path'),
        isFalse,
        reason: 'no monitor, no verdict',
      );
    });
  });
}
