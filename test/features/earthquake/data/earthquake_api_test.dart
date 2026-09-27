/// EarthquakeApi is a thin, unguarded wrapper over [ApiClient]: every method
/// must hit the right tier/path/query — the TREM stream must ask for its topic
/// and only ask for every frame (`mode=live`) when told to, since the sleeping
/// stream is what saves the phone's data — and [getReportList] must build the
/// canonical query (omitting default
/// page/sort/order so the URL — and its ETag — matches the server's own
/// form). None of it guards errors, so whatever `ApiClient` throws must come
/// straight back out, unchanged, for the repository layer to convert.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/api_paths.dart';
import 'package:dpip/core/network/api_region.dart';
import 'package:dpip/features/earthquake/data/earthquake_api.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingApiClient implements ApiClient {
  final List<(ApiTier, String, Map<String, dynamic>?)> getCalls = [];
  final List<(ApiTier, String, Map<String, dynamic>?)> streamCalls = [];

  dynamic nextGetResult;
  Object? getError;
  Stream<List<int>>? nextStream;

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
  }) async {
    streamCalls.add((tier, path, query));
    return StreamedResponse(
      (nextStream ?? const Stream<List<int>>.empty()).cast<Uint8List>(),
      () {},
    );
  }

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
  }) => throw UnimplementedError();

  @override
  List<String> hostsFor(ApiTier tier) => throw UnimplementedError();
}

Stream<List<int>> _sseBody(String data) =>
    Stream.value(utf8.encode('data: $data\n\n'));

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

  group('SSE streams', () {
    test(
      'openTremSse asks for the RTS topic, and every frame only when live',
      () async {
        client.nextStream = _sseBody('x');
        final events = await api.openTremSse(live: true).toList();
        expect(client.streamCalls.single.$1, ApiTier.lbApi);
        expect(client.streamCalls.single.$2, ApiPaths.tremSse);
        expect(client.streamCalls.single.$3, {
          'topics': 'trem.rts.v1',
          'mode': 'live',
        });
        expect(events.single.data, 'x');

        client.nextStream = _sseBody('x');
        await api.openTremSse(live: false).toList();
        expect(client.streamCalls.last.$3, {'topics': 'trem.rts.v1'});
      },
    );

    test(
      'openEewSse opens the lb tier with sse+compress and parses frames',
      () async {
        client.nextStream = _sseBody('[]');
        final events = await api.openEewSse().toList();
        expect(client.streamCalls.single.$1, ApiTier.lbApi);
        expect(client.streamCalls.single.$2, ApiPaths.eew);
        expect(client.streamCalls.single.$3, {'sse': 1, 'compress': 1});
        expect(events, hasLength(1));
        expect(events.single.data, '[]');
      },
    );
  });
}
