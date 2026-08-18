import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dpip/core/network/api_client.dart';
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
}
