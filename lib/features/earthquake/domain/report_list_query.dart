/// Query parameters for `GET /api/v2/eq/report` list filters.
library;

/// Immutable filter bag for the report catalogue. `null` fields are omitted
/// from the wire query (server defaults apply).
///
/// Dates are calendar days in **Asia/Taipei** as `YYYY-MM-DD` (see report-server
/// `startTime` / `endTime`). `loc` / lat-lon filters were removed server-side.
final class ReportListQuery {
  const ReportListQuery({
    this.minIntensity,
    this.maxIntensity,
    this.minMagnitude,
    this.maxMagnitude,
    this.minDepth,
    this.maxDepth,
    this.startTime,
    this.endTime,
    this.sort,
    this.order,
    this.city,
    this.cityMinInt,
    this.cityMaxInt,
  });

  static const ReportListQuery empty = ReportListQuery();

  final int? minIntensity;
  final int? maxIntensity;
  final double? minMagnitude;
  final double? maxMagnitude;
  final double? minDepth;
  final double? maxDepth;

  /// Inclusive start day (`YYYY-MM-DD`, Taipei).
  final String? startTime;

  /// Inclusive end day (`YYYY-MM-DD`, Taipei).
  final String? endTime;

  /// `time` / `intensity` / `magnitude` / `depth` — omit for server default
  /// (`time`).
  final String? sort;

  /// `asc` / `desc` — omit for server default (`desc`).
  final String? order;

  final String? city;
  final int? cityMinInt;
  final int? cityMaxInt;

  bool get isEmpty =>
      minIntensity == null &&
      maxIntensity == null &&
      minMagnitude == null &&
      maxMagnitude == null &&
      minDepth == null &&
      maxDepth == null &&
      startTime == null &&
      endTime == null &&
      sort == null &&
      order == null &&
      (city == null || city!.trim().isEmpty) &&
      cityMinInt == null &&
      cityMaxInt == null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReportListQuery &&
          minIntensity == other.minIntensity &&
          maxIntensity == other.maxIntensity &&
          minMagnitude == other.minMagnitude &&
          maxMagnitude == other.maxMagnitude &&
          minDepth == other.minDepth &&
          maxDepth == other.maxDepth &&
          startTime == other.startTime &&
          endTime == other.endTime &&
          sort == other.sort &&
          order == other.order &&
          city == other.city &&
          cityMinInt == other.cityMinInt &&
          cityMaxInt == other.cityMaxInt;

  @override
  int get hashCode => Object.hash(
    minIntensity,
    maxIntensity,
    minMagnitude,
    maxMagnitude,
    minDepth,
    maxDepth,
    startTime,
    endTime,
    sort,
    order,
    city,
    cityMinInt,
    cityMaxInt,
  );
}
