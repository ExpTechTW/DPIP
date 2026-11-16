/// EarthquakeApi is a thin, unguarded wrapper over [ApiClient]: every method
/// must hit the right tier/path/query — [getReportList] must build the
/// canonical query (omitting default page/sort/order so the URL — and its
/// ETag — matches the server's own form). None of it guards errors, so whatever `ApiClient` throws must come
/// straight back out, unchanged, for the repository layer to convert.
library;

import 'package:dio/dio.dart';
import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/api_paths.dart';
import 'package:dpip/core/network/api_region.dart';
import 'package:dpip/features/earthquake/data/earthquake_api.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingApiClient implements ApiClient {
  final List<(ApiTier, String, Map<String, dynamic>?)> getCalls = [];

  dynamic nextGetResult;
  Object? getError;

  @override
  Future<dynamic> get(
    ApiTier tier,
    String path, {
    Map<String, dynamic>? query,
    CancelToken? cancelToken,
  }) async {
    getCalls.add((tier, path, query));
    if (getError != null) throw getError!;
    return nextGetResult;
  }

  @override
  Future<StreamedResponse> openStream(
    ApiTier tier,
    String path, {
    Map<String, dynamic>? query,
    Map<String, dynamic>? headers,
    Duration idleTimeout = Duration.zero,
  }) => throw UnimplementedError();

  @override
  Future<BytePayload> getBytes(
    ApiTier tier,
    String path, {
    Map<String, dynamic>? query,
    CancelToken? cancelToken,
  }) => throw UnimplementedError();

  @override
  Future<BytePayload> getBytesAbsolute(
    String url, {
    CancelToken? cancelToken,
  }) => throw UnimplementedError();

  @override
  Future<dynamic> getAbsolute(
    String url, {
    Map<String, dynamic>? query,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
  }) => throw UnimplementedError();

  @override
  Future<dynamic> postAbsolute(
    String url, {
    Object? data,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
  }) => throw UnimplementedError();

  @override
  Future<dynamic> post(
    ApiTier tier,
    String path, {
    Object? data,
    Map<String, dynamic>? query,
    CancelToken? cancelToken,
  }) => throw UnimplementedError();

  @override
  Future<Response<dynamic>> request(
    ApiTier tier,
    String path, {
    String method = 'GET',
    Object? data,
    Map<String, dynamic>? query,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    getCalls.add((tier, path, query));
    if (getError != null) throw getError!;
    return Response<dynamic>(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: nextGetResult,
    );
  }

  @override
  List<String> hostsFor(ApiTier tier) => throw UnimplementedError();
}

void main() {
  late _RecordingApiClient client;
  late EarthquakeApi api;

  setUp(() {
    client = _RecordingApiClient();
    api = EarthquakeApi(client);
  });

  group('one-shot GETs hit the right tier and path', () {
    test('getEewRealtime', () async {
      client.nextGetResult = <dynamic>[];
      final result = await api.getEewRealtime();
      expect(client.getCalls.single.$1, ApiTier.lbApi);
      expect(client.getCalls.single.$2, ApiPaths.eew);
      expect(result, isEmpty);
    });

    test('getReport', () async {
      client.nextGetResult = {'id': '115032'};
      await api.getReport('115032');
      expect(client.getCalls.single.$1, ApiTier.coreApi);
      expect(client.getCalls.single.$2, '/api/v2/eq/report/115032');
    });
  });

  group('getRtsAt', () {
    test(
      'hits the v3 archive on the core tier at the requested second',
      () async {
        client.nextGetResult = {'ts': 1700000000000};
        final result = await api.getRtsAt(1700000000);
        expect(client.getCalls.single.$1, ApiTier.coreApi);
        expect(client.getCalls.single.$2, '${ApiPaths.rtsArchive}/1700000000');
        expect(result, {'ts': 1700000000000});
      },
    );
  });

  group('getEewAt', () {
    test('hits the core tier at the requested second', () async {
      client.nextGetResult = <dynamic>[];
      await api.getEewAt(1700000000);
      expect(client.getCalls.single.$1, ApiTier.coreApi);
      expect(client.getCalls.single.$2, '${ApiPaths.eew}/1700000000');
    });
  });

  group('getReportList query building', () {
    test(
      'omits defaults so the URL matches the server canonical form',
      () async {
        client.nextGetResult = <dynamic>[];
        await api.getReportList(limit: 50);
        final query = client.getCalls.single.$3!;
        expect(query, {'limit': 50});
      },
    );

    test('includes every optional filter only when provided', () async {
      client.nextGetResult = <dynamic>[];
      await api.getReportList(
        limit: 10,
        page: 2,
        minIntensity: 1,
        maxIntensity: 7,
        minMagnitude: 3.0,
        maxMagnitude: 8.0,
        minDepth: 0.0,
        maxDepth: 100.0,
        startTime: '2026-01-01',
        endTime: '2026-01-31',
        sort: 'magnitude',
        order: 'asc',
        city: '花蓮縣',
        cityMinInt: 2,
        cityMaxInt: 6,
      );
      final query = client.getCalls.single.$3!;
      expect(query, {
        'limit': 10,
        'page': 2,
        'minIntensity': 1,
        'maxIntensity': 7,
        'minMagnitude': 3.0,
        'maxMagnitude': 8.0,
        'minDepth': 0.0,
        'maxDepth': 100.0,
        'startTime': '2026-01-01',
        'endTime': '2026-01-31',
        'sort': 'magnitude',
        'order': 'asc',
        'city': '花蓮縣',
        'cityMinInt': 2,
        'cityMaxInt': 6,
      });
    });

    test(
      'page=1/sort=time/order=desc stay omitted even when passed explicitly',
      () async {
        client.nextGetResult = <dynamic>[];
        await api.getReportList(page: 1, sort: 'time', order: 'desc');
        final query = client.getCalls.single.$3!;
        expect(query, {'limit': 50});
      },
    );
  });

  group('errors are never swallowed', () {
    test('a client failure propagates unchanged, not wrapped', () async {
      client.getError = StateError('boom');
      await expectLater(api.getRtsAt(1), throwsA(isA<StateError>()));
    });
  });
}
