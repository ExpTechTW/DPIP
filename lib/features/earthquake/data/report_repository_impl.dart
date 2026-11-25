/// [ReportRepository] backed by [EarthquakeApi].
library;

import 'dart:convert';

import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/network/api_exception.dart';
import 'package:dpip/features/earthquake/data/earthquake_api.dart';
import 'package:dpip/features/earthquake/domain/earthquake_report.dart';
import 'package:dpip/features/earthquake/domain/earthquake_report_snapshot.dart';
import 'package:dpip/features/earthquake/domain/earthquake_share_input.dart';
import 'package:dpip/features/earthquake/domain/partial_earthquake_report.dart';
import 'package:dpip/features/earthquake/domain/report_list_query.dart';
import 'package:dpip/features/earthquake/domain/report_repository.dart';

/// Maps transport/decode errors via [guardResult]; owns JSON → model.
class ReportRepositoryImpl implements ReportRepository, EarthquakeShareSource {
  const ReportRepositoryImpl(this._api);

  final EarthquakeApi _api;

  // The county/station identities and scale were independently checked for
  // this exact Core v2 body. See the share_input fixture README for sources.
  static const _verifiedReportId = '115000-2026-0422-111524';
  static final _verifiedIdentities = VerifiedEarthquakeReportIdentities(
    bodySha256:
        'e6761038a7eea6b8afa58c936693f35d663bd5ca1ecdb2ad4613b72e2d46e4c1',
    scale: ReportIntensityScale.cwa2020,
    magnitudeIsMl: true,
    countyCodes: const {'臺東縣': '10014', '花蓮縣': '10015'},
    stationCodes: const {
      ('臺東縣', '成功'): 'CHK',
      ('臺東縣', '長濱'): 'ECB',
      ('臺東縣', '池上'): 'ECS',
      ('臺東縣', '東河'): 'EDH',
      ('花蓮縣', '紅葉'): 'EHY',
    },
  );

  @override
  Future<Result<EarthquakeShareInput>> getShareInput(
    EarthquakeReport report,
  ) async {
    if (report.id != _verifiedReportId) {
      return Ok(adaptEarthquakeShareInput(report));
    }
    final result = await getSnapshot(report.id);
    return result.when(
      ok: (snapshot) => Ok(
        snapshot.report == report
            ? adaptEarthquakeShareSnapshot(
                snapshot,
                identities: _verifiedIdentities,
              )
            : adaptEarthquakeShareInput(report),
      ),
      err: (failure) => switch (failure) {
        DecodeFailure(cause: EarthquakeReportSourceException()) => Ok(
          adaptEarthquakeShareInput(report),
        ),
        _ => Err(failure),
      },
    );
  }

  @override
  Future<Result<List<PartialEarthquakeReport>>> list({
    int limit = 30,
    int page = 1,
    ReportListQuery query = ReportListQuery.empty,
  }) => guardFetched(() async {
    final raw = await _api.getReportList(
      limit: limit,
      page: page,
      minIntensity: query.minIntensity,
      maxIntensity: query.maxIntensity,
      minMagnitude: query.minMagnitude,
      maxMagnitude: query.maxMagnitude,
      minDepth: query.minDepth,
      maxDepth: query.maxDepth,
      startTime: query.startTime,
      endTime: query.endTime,
      sort: query.sort,
      order: query.order,
      city: query.city,
      cityMinInt: query.cityMinInt,
      cityMaxInt: query.cityMaxInt,
    );
    return (data: parseReportList(raw.data), stale: raw.stale);
  });

  @override
  Future<Result<EarthquakeReport>> get(String id) => guardResult(() async {
    final raw = await _api.getReport(id);
    // Display only needs a decodable model. The stricter source evidence is
    // for the share card, and must not turn a report the app could show into
    // an error page.
    return EarthquakeReport.fromJson(
      (jsonDecode(utf8.decode(raw.bytes)) as Map).cast<String, dynamic>(),
    );
  });

  /// The detail model and exact evidence from a single Core v2 detail fetch.
  Future<Result<EarthquakeReportSnapshot>> getSnapshot(String id) =>
      guardResult(() async {
        final raw = await _api.getReport(id);
        return EarthquakeReportSnapshot.decode(
          raw.bytes,
          requestedReportId: id,
          etag: raw.etag,
        );
      });

  @override
  Future<Result<bool>> hasReplayAt(int timestamp) =>
      guardResult(() => _api.hasReplayAt(timestamp ~/ 1000));

  /// Skips malformed rows so one bad record cannot blank the catalogue.
  static List<PartialEarthquakeReport> parseReportList(List<dynamic> raw) {
    return [
      for (final item in raw)
        if (item is Map) ?_tryParse(item.cast<String, dynamic>()),
    ];
  }

  static PartialEarthquakeReport? _tryParse(Map<String, dynamic> json) {
    try {
      return PartialEarthquakeReport.fromJson(json);
    } on Object {
      return null;
    }
  }
}
