/// Lightweight earthquake-report row from `GET /api/v2/eq/report` (no area
/// `list` — that lives on the detail endpoint).
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'partial_earthquake_report.freezed.dart';
part 'partial_earthquake_report.g.dart';

/// One entry in the paginated report list — epicentre, magnitude, max intensity,
/// and the CWA/ExpTech id used to fetch the full report.
@freezed
abstract class PartialEarthquakeReport with _$PartialEarthquakeReport {
  const PartialEarthquakeReport._();

  const factory PartialEarthquakeReport({
    required String id,
    @JsonKey(name: 'lon') required double longitude,
    @JsonKey(name: 'lat') required double latitude,
    @JsonKey(name: 'loc') required String location,
    required double depth,
    @JsonKey(name: 'mag') required double magnitude,
    @JsonKey(name: 'int') required int intensity,

    /// Origin time as Unix **milliseconds**.
    required int time,
    required int trem,
    required String md5,
  }) = _PartialEarthquakeReport;

  factory PartialEarthquakeReport.fromJson(Map<String, dynamic> json) =>
      _$PartialEarthquakeReportFromJson(json);

  /// CWA serial when the id is not a `…000-` placeholder (e.g. `115053`).
  String? get number {
    final n = id.split('-').first;
    if (n.endsWith('000')) return null;
    return n;
  }

  bool get hasNumber => number != null;

  /// Origin time in UTC.
  DateTime get originTimeUtc =>
      DateTime.fromMillisecondsSinceEpoch(time, isUtc: true);

  /// Short place string — prefer the parenthetical CWA locality when present.
  String get shortLocation {
    final open = location.indexOf('(');
    final close = location.indexOf(')');
    if (open >= 0 && close > open) {
      var inner = location.substring(open + 1, close);
      if (inner.startsWith('位於')) inner = inner.substring(2);
      return inner.trim();
    }
    final fang = location.indexOf('方');
    if (fang >= 0) return location.substring(0, fang + 1).trim();
    return location.trim();
  }
}
