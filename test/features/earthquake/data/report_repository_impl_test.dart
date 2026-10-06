/// The catalogue must forward every filter the sheet set, and one malformed
/// row must not blank the list. Dropping a query field here looks like the
/// filter did nothing.
library;

import 'package:dio/dio.dart';
import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/network/sse_event.dart';
import 'package:dpip/features/earthquake/data/earthquake_api.dart';
import 'package:dpip/features/earthquake/data/report_repository_impl.dart';
import 'package:dpip/features/earthquake/domain/report_list_query.dart';
import 'package:flutter_test/flutter_test.dart';

class _Api implements EarthquakeApi {
  _Api(this.listBody, this.reportBody);

  final List<dynamic> listBody;
  final dynamic reportBody;
  ReportListQuery? seen;
  Object? error;

  @override
  Future<List<dynamic>> getReportList({
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
    return listBody;
  }

  @override
  Future<dynamic> getReport(String reportId) async {
    if (error != null) throw error!;
    return reportBody;
  }

  @override
  Future<List<dynamic>> getEewRealtime() => throw UnimplementedError();

  @override
  Stream<SseEvent> openEewSse() => throw UnimplementedError();

  @override
  Future<List<dynamic>> getEewAt(int seconds) => throw UnimplementedError();

  @override
  Stream<SseEvent> openTremSse({required bool live}) =>
      throw UnimplementedError();

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
}
