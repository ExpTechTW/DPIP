/// Earthquake-report catalogue (ExpTech report-server, Core API).
library;

import 'package:dpip/core/error/result.dart';
import 'package:dpip/features/earthquake/domain/partial_earthquake_report.dart';

/// Fetches paginated report summaries. Implementations live in `data/`.
abstract interface class ReportRepository {
  /// Page of lightweight reports (newest first). Defaults match the server.
  Future<Result<List<PartialEarthquakeReport>>> list({
    int limit = 50,
    int page = 1,
  });
}
