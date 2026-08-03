/// Query parameters for `GET /api/v2/eq/report` list filters.
library;

/// Immutable filter bag for the report catalogue. `null` fields are omitted
/// from the wire query (server defaults apply).
final class ReportListQuery {
  const ReportListQuery({
    this.minIntensity,
    this.maxIntensity,
    this.minMagnitude,
    this.maxMagnitude,
    this.minDepth,
    this.maxDepth,
    this.loc,
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

  /// Fuzzy match on the report `location` string.
  final String? loc;
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
      (loc == null || loc!.trim().isEmpty) &&
      (city == null || city!.trim().isEmpty) &&
      cityMinInt == null &&
      cityMaxInt == null;

  ReportListQuery copyWith({
    int? minIntensity,
    int? maxIntensity,
    double? minMagnitude,
    double? maxMagnitude,
    double? minDepth,
    double? maxDepth,
    String? loc,
    String? city,
    int? cityMinInt,
    int? cityMaxInt,
    bool clearMinIntensity = false,
    bool clearMaxIntensity = false,
    bool clearMinMagnitude = false,
    bool clearMaxMagnitude = false,
    bool clearMinDepth = false,
    bool clearMaxDepth = false,
    bool clearLoc = false,
    bool clearCity = false,
    bool clearCityMinInt = false,
    bool clearCityMaxInt = false,
  }) {
    return ReportListQuery(
      minIntensity: clearMinIntensity
          ? null
          : (minIntensity ?? this.minIntensity),
      maxIntensity: clearMaxIntensity
          ? null
          : (maxIntensity ?? this.maxIntensity),
      minMagnitude: clearMinMagnitude
          ? null
          : (minMagnitude ?? this.minMagnitude),
      maxMagnitude: clearMaxMagnitude
          ? null
          : (maxMagnitude ?? this.maxMagnitude),
      minDepth: clearMinDepth ? null : (minDepth ?? this.minDepth),
      maxDepth: clearMaxDepth ? null : (maxDepth ?? this.maxDepth),
      loc: clearLoc ? null : (loc ?? this.loc),
      city: clearCity ? null : (city ?? this.city),
      cityMinInt: clearCityMinInt ? null : (cityMinInt ?? this.cityMinInt),
      cityMaxInt: clearCityMaxInt ? null : (cityMaxInt ?? this.cityMaxInt),
    );
  }

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
          loc == other.loc &&
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
    loc,
    city,
    cityMinInt,
    cityMaxInt,
  );
}
