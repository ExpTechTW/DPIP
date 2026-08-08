/// Full earthquake report — `GET /api/v2/eq/report/{id}`, the per-area/town
/// intensity breakdown behind a catalogue row ([PartialEarthquakeReport]).
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'earthquake_report.freezed.dart';
part 'earthquake_report.g.dart';

/// The full earthquake report — epicentre, magnitude, and the per-area/town
/// felt-intensity breakdown. Fetched by id from [ReportRepository.get] when a
/// catalogue row is opened.
@freezed
abstract class EarthquakeReport with _$EarthquakeReport {
  const EarthquakeReport._();

  const factory EarthquakeReport({
    required String id,
    @JsonKey(name: 'lon') required double longitude,
    @JsonKey(name: 'lat') required double latitude,
    @JsonKey(name: 'loc') required String location,
    required double depth,
    @JsonKey(name: 'mag') required double magnitude,
    required Map<String, AreaIntensity> list,

    /// Origin time as Unix **milliseconds**.
    required int time,
    required int trem,
  }) = _EarthquakeReport;

  factory EarthquakeReport.fromJson(Map<String, dynamic> json) =>
      _$EarthquakeReportFromJson(json);

  /// Leading CWA serial segment (e.g. `115032` or `115000`).
  String get serial => id.split('-').first;

  /// `…000` serials are 小區域有感 — no numbered CWA report.
  bool get isLocalFelt => serial.endsWith('000');

  /// Numbered CWA report id, or null when [isLocalFelt].
  String? get number => isLocalFelt ? null : serial;

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

  /// Highest observed intensity across every area/town in [list].
  int get maxIntensity {
    var max = 0;
    for (final area in list.values) {
      for (final town in area.town.values) {
        if (town.intensity > max) max = town.intensity;
      }
    }
    return max;
  }

  /// The official CWA report page for this event.
  Uri get reportUrl {
    final segments = id.split('-')..removeAt(0);
    final magCode = (magnitude * 10).floor();
    final numberSuffix = hasNumber ? number!.substring(3) : '';
    return Uri.parse(
      'https://scweb.cwa.gov.tw/zh-tw/earthquake/details/'
      '${segments.join()}$magCode$numberSuffix',
    );
  }

  /// CWA's rendered report image (地震報告圖). The filename is derived from the
  /// Taipei-local origin time, magnitude, and (when numbered) the report's
  /// serial suffix — CWA doesn't expose this as a field, only as a static path.
  Uri get reportImageUrl {
    final t = originTimeUtc.add(const Duration(hours: 8)); // Asia/Taipei
    final y = t.year.toString();
    final mo = t.month.toString().padLeft(2, '0');
    final d = t.day.toString().padLeft(2, '0');
    final h = t.hour.toString().padLeft(2, '0');
    final mi = t.minute.toString().padLeft(2, '0');
    final s = t.second.toString().padLeft(2, '0');
    final magCode = (magnitude * 10).floor();
    final numberSuffix = hasNumber ? number!.substring(3) : '';
    final name = '$y$mo$d$h$mi$s$magCode${numberSuffix}_H.png';
    final yearMonth = name.substring(0, 6);
    return Uri.parse('https://scweb.cwa.gov.tw/webdata/OLDEQ/$yearMonth/$name');
  }
}

/// One area's (縣市) maximum observed intensity and its station/town breakdown.
@freezed
abstract class AreaIntensity with _$AreaIntensity {
  const factory AreaIntensity({
    @JsonKey(name: 'int') required int intensity,
    required Map<String, StationIntensity> town,
  }) = _AreaIntensity;

  factory AreaIntensity.fromJson(Map<String, dynamic> json) =>
      _$AreaIntensityFromJson(json);
}

/// One station/town's observed intensity and coordinates.
@freezed
abstract class StationIntensity with _$StationIntensity {
  const factory StationIntensity({
    @JsonKey(name: 'lon') required double longitude,
    @JsonKey(name: 'lat') required double latitude,
    @JsonKey(name: 'int') required int intensity,
  }) = _StationIntensity;

  factory StationIntensity.fromJson(Map<String, dynamic> json) =>
      _$StationIntensityFromJson(json);
}
