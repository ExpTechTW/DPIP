import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/api_region.dart';
import 'package:dpip/core/network/region_selection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dpip/core/settings/prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    SharedPreferences.setMockInitialValues({});
    regions = RegionSelection(Prefs(await SharedPreferences.getInstance()));
  });

  ApiClient clientWith(_FakeAdapter adapter) =>
      ApiClient(Dio()..httpClientAdapter = adapter, regions);

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
}
