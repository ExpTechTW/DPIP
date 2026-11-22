/// The catalogue must forward every filter the sheet set, and one malformed
/// row must not blank the list. Dropping a query field here looks like the
/// filter did nothing.
library;

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/features/earthquake/data/earthquake_api.dart';
import 'package:dpip/features/earthquake/data/report_repository_impl.dart';
import 'package:dpip/features/earthquake/domain/report_list_query.dart';
import 'package:flutter_test/flutter_test.dart';

class _Api implements EarthquakeApi {
  _Api(this.listBody, this.reportBody);

  final List<dynamic> listBody;
  final Map<String, Object?>? reportBody;
  ReportListQuery? seen;
  Object? error;
  Staleness? stale;

  @override
  Future<Fetched<List<dynamic>>> getReportList({
    int limit = 50,
    int page = 1,
    int? minIntensity,
    int? maxIntensity,
    double? minMagnitude,
    double? maxMagnitude,
    double? minDepth,
    double? maxDepth,
    String? startTime,
    String? endTime,
    String? sort,
    String? order,
    String? city,
    int? cityMinInt,
    int? cityMaxInt,
  }) async {
    if (error != null) throw error!;
    seen = ReportListQuery(
      minIntensity: minIntensity,
      maxIntensity: maxIntensity,
      minMagnitude: minMagnitude,
      maxMagnitude: maxMagnitude,
      minDepth: minDepth,
      maxDepth: maxDepth,
      startTime: startTime,
      endTime: endTime,
      sort: sort,
      order: order,
      city: city,
      cityMinInt: cityMinInt,
      cityMaxInt: cityMaxInt,
    );
    return (data: listBody, stale: stale);
  }

  @override
  Future<BytePayload> getReport(String reportId) async {
    if (error != null) throw error!;
    return BytePayload(bytes: utf8.encode(jsonEncode(reportBody)));
  }

  @override
  Future<List<dynamic>> getEewRealtime() => throw UnimplementedError();

  @override
  Future<List<dynamic>> getEewAt(int seconds) => throw UnimplementedError();

  @override
  Future<bool> hasReplayAt(int seconds) async {
    await getRtsAt(seconds);
    return true;
  }

  @override
  Future<Map<String, dynamic>> getRtsAt(int seconds) =>
      throw UnimplementedError();
}

Map<String, dynamic> _row(String id) => {
  'id': id,
  'lon': 121.5,
  'lat': 24.0,
  'loc': '花蓮縣',
  'depth': 10.0,
  'mag': 5.0,
  'int': 4,
  'time': 1700000000000,
  'trem': 1,
  'md5': 'abc',
};

void main() {
  test(
    'list forwards every filter and skips a row that will not parse',
    () async {
      final api = _Api([
        _row('115032'),
        'not-a-row',
        {'id': 'broken'},
      ], null);
      final repo = ReportRepositoryImpl(api);
      const query = ReportListQuery(
        minIntensity: 3,
        maxIntensity: 7,
        minMagnitude: 4,
        maxMagnitude: 7,
        minDepth: 1,
        maxDepth: 30,
        startTime: '2026-10-01',
        endTime: '2026-10-04',
        sort: 'mag',
        order: 'asc',
        city: '花蓮縣',
        cityMinInt: 4,
        cityMaxInt: 5,
      );

      final result = await repo.list(limit: 10, page: 2, query: query);

      expect(result.valueOrNull!.map((r) => r.id), ['115032']);
      expect(api.seen, query);
    },
  );

  test(
    'get decodes the full report, and a transport error stays typed',
    () async {
      final api = _Api(const [], {
        'id': '115032',
        'lon': 121.5,
        'lat': 24.0,
        'loc': '花蓮縣',
        'depth': 10,
        'mag': 5.2,
        'time': 1700000000000,
        'trem': 1,
        'list': {
          '花蓮縣': {
            'int': 4,
            'town': {
              '花蓮市': {'lon': 121.6, 'lat': 23.9, 'int': 4},
            },
          },
        },
      });
      final repo = ReportRepositoryImpl(api);
      expect((await repo.get('115032')).valueOrNull!.magnitude, 5.2);

      api.error = DioException(
        requestOptions: RequestOptions(path: '/api/v2/eq/report'),
        type: DioExceptionType.connectionTimeout,
      );
      expect((await repo.get('115032')).failureOrNull, isA<TimeoutFailure>());
    },
  );

  test(
    'get displays a report the share-grade evidence decoder would reject',
    () async {
      final api = _Api(const [], {
        'id': '115032',
        'lon': 121.5,
        'lat': 24.0,
        'loc': '花蓮縣',
        'depth': 10,
        'mag': 5.2,
        'time': 1700000000000,
        'trem': 1,
        // The model coerces these spellings; the v2 evidence scan is stricter
        // and only the share path needs it.
        'list': {
          '花蓮縣': {
            'int': 4.0,
            'town': {
              '花蓮市': {'lon': 121.6, 'lat': 23.9, 'int': 4.0},
            },
          },
        },
      });
      final repo = ReportRepositoryImpl(api);

      expect((await repo.get('115032')).valueOrNull!.maxIntensity, 4);
      expect(
        (await repo.getSnapshot('115032')).failureOrNull,
        isA<DecodeFailure>(),
      );
    },
  );

  test('a saved page keeps its marker on the way up', () async {
    final since = DateTime.utc(2026, 10, 16, 1);
    final api = _Api([_row('115032')], null)
      ..stale = Staleness(failure: const NetworkFailure('down'), since: since);

    final result = await ReportRepositoryImpl(api).list();

    expect(result.valueOrNull!.single.id, '115032');
    expect((result as Ok).stale?.since, since);
  });
}
