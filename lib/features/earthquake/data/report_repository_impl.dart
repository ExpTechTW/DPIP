/// [ReportRepository] backed by [EarthquakeApi].
library;

import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/network/api_exception.dart';
import 'package:dpip/features/earthquake/data/earthquake_api.dart';
import 'package:dpip/features/earthquake/domain/partial_earthquake_report.dart';
import 'package:dpip/features/earthquake/domain/report_list_query.dart';
import 'package:dpip/features/earthquake/domain/report_repository.dart';

/// Maps transport/decode errors via [guardResult]; owns JSON → model.
class ReportRepositoryImpl implements ReportRepository {
  const ReportRepositoryImpl(this._api);

  final EarthquakeApi _api;

  @override
  Future<Result<List<PartialEarthquakeReport>>> list({
    int limit = 30,
    int page = 1,
    ReportListQuery query = ReportListQuery.empty,
  }) => guardResult(() async {
    final raw = await _api.getReportList(
      limit: limit,
      page: page,
      minIntensity: query.minIntensity,
      maxIntensity: query.maxIntensity,
      minMagnitude: query.minMagnitude,
      maxMagnitude: query.maxMagnitude,
      minDepth: query.minDepth,
      maxDepth: query.maxDepth,
      loc: query.loc,
      city: query.city,
      cityMinInt: query.cityMinInt,
      cityMaxInt: query.cityMaxInt,
    );
    return parseReportList(raw);
  });

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
