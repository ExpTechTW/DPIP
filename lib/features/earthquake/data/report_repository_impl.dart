/// [ReportRepository] backed by [EarthquakeApi].
library;

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/api_exception.dart';
import 'package:dpip/features/earthquake/data/earthquake_api.dart';
import 'package:dpip/features/earthquake/domain/earthquake_report.dart';
import 'package:dpip/features/earthquake/domain/earthquake_report_snapshot.dart';
import 'package:dpip/features/earthquake/domain/partial_earthquake_report.dart';
import 'package:dpip/features/earthquake/domain/report_list_query.dart';
import 'package:dpip/features/earthquake/domain/report_repository.dart';

/// Maps transport/decode errors via [guardResult]; owns JSON → model.
class ReportRepositoryImpl implements ReportRepository, EarthquakeShareSource {
  const ReportRepositoryImpl(this._api);

  final EarthquakeApi _api;

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
    return _decodeDetail(raw, id);
  });

  /// Strict source acquisition for v3, including reports with fields that
  /// the ordinary display model cannot represent. The v3 adapter applies the
  /// modern profile and validates measurement and observation semantics.
  Future<Result<CoreEarthquakeReportSnapshot>> getSourceSnapshot(String id) =>
      guardResult(() async {
        try {
          return _sourceSnapshot(await _api.getReport(id), id);
        } on DioException catch (error) {
          // The region client retries a malformed wire response like a
          // transport fault. If no region succeeded, preserve the decode cause.
          if (error.error case final FormatException cause) throw cause;
          rethrow;
        }
      });

  /// Acquire the display model and its source evidence from one HTTP response.
  /// A strict source failure can coexist with a displayable detail response.
  @override
  Future<Result<SourcedEarthquakeReport>> getDetailWithSource(String id) =>
      guardResult(() async {
        final raw = await _api.getReport(id);
        final source = await guardResult(
          () async => _sourceSnapshot(raw, id),
          shouldLog: (_) => false,
        );
        return (
          report: source.valueOrNull?.report ?? _decodeDetail(raw, id),
          source: source,
        );
      });

  static EarthquakeReport _decodeDetail(BytePayload raw, String id) {
    final json = jsonDecode(utf8.decode(raw.bytes)) as Map<String, dynamic>;
    if (json['id'] != id) {
      throw const EarthquakeReportSourceException(
        EarthquakeReportSourceError.identityMismatch,
        '/id',
        'Detail response does not match the requested report.',
      );
    }
    return EarthquakeReport.fromJson(json);
  }

  static CoreEarthquakeReportSnapshot _sourceSnapshot(
    BytePayload raw,
    String id,
  ) => CoreEarthquakeReportSnapshot.decode(
    raw.bytes,
    requestedReportId: id,
    endpoint: raw.endpoint,
    confirmedAt: raw.confirmedAt,
    etag: raw.etag,
    revalidated: raw.revalidated,
  );

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
