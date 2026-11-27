/// Earthquake-report catalogue (ExpTech report-server, Core API).
library;

import 'package:dpip/core/error/result.dart';
import 'package:dpip/features/earthquake/domain/earthquake_report.dart';
import 'package:dpip/features/earthquake/domain/earthquake_report_snapshot.dart';
import 'package:dpip/features/earthquake/domain/partial_earthquake_report.dart';
import 'package:dpip/features/earthquake/domain/report_list_query.dart';

typedef SourcedEarthquakeReport = ({
  EarthquakeReport report,
  Result<CoreEarthquakeReportSnapshot> source,
});

/// Loads a display report and its sharing evidence from the same response.
abstract interface class EarthquakeShareSource {
  Future<Result<SourcedEarthquakeReport>> getDetailWithSource(String id);
}

/// Fetches paginated report summaries. Implementations live in `data/`.
abstract interface class ReportRepository {
  /// Page of lightweight reports (newest first). Defaults match the server.
  Future<Result<List<PartialEarthquakeReport>>> list({
    int limit = 30,
    int page = 1,
    ReportListQuery query = ReportListQuery.empty,
  });

  /// The full report — including the per-area/town intensity breakdown — by
  /// [id], for the detail page behind a catalogue row.
  Future<Result<EarthquakeReport>> get(String id);

  /// Whether the replay archive still holds [timestamp] (Unix ms).
  ///
  /// The retained window moves, so the detail page asks on every visit rather
  /// than comparing against a fixed date. A 404 is `Ok(false)`; other
  /// failures stay `Err` so a transient probe failure does not read as "never
  /// replayable".
  Future<Result<bool>> hasReplayAt(int timestamp);
}
