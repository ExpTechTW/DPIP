/// CWA tsunami bulletins, their coastal entries, and the wave-height scale the
/// map and the sheet both colour by.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'tsunami_report.freezed.dart';
part 'tsunami_report.g.dart';

/// Earthquake a tsunami bulletin was issued for.
@freezed
abstract class TsunamiEarthquake with _$TsunamiEarthquake {
  const factory TsunamiEarthquake({
    /// Origin time (Unix milliseconds).
    @JsonKey(name: 't') required int time,
    @JsonKey(name: 'lon') required double longitude,
    @JsonKey(name: 'lat') required double latitude,
    @JsonKey(name: 'loc') required String location,

    /// Focal depth (km).
    @JsonKey(name: 'dep') required double depth,

    /// CWA magnitude.
    @JsonKey(name: 'mag') required double magnitude,
  }) = _TsunamiEarthquake;

  factory TsunamiEarthquake.fromJson(Map<String, dynamic> json) =>
      _$TsunamiEarthquakeFromJson(json);
}

/// One predicted coastal impact area (a `data.type == 'predict'` row).
///
/// [height] is CWA's own text (`<1`, and on other bulletins a bare number), and
/// it stays text on purpose: unlike an observation it is not a measurement, so
/// there is no centimetre value to bucket — see [TsunamiWaveBand].
@freezed
abstract class TsunamiPrediction with _$TsunamiPrediction {
  const factory TsunamiPrediction({
    required String area,
    required String coast,
    required String height,

    /// Predicted arrival time (Unix milliseconds).
    required int arrivalTime,

    /// CWA's own warning colour for the area (`黃色`), the fifth field of the
    /// tuple. Null when the tuple is shorter or the field is empty: the map
    /// then leaves the area unpainted rather than reading a band out of
    /// [height].
    String? color,
  }) = _TsunamiPrediction;
}

/// One observed reading from a tide-gauge station (a `data.type == 'observe'`
/// row).
///
/// [longitude] / [latitude] are **nullable** — several stations in the
/// 2024-04-03 花蓮 bulletin ship `null` for both, so an absent position is a
/// real shape rather than a reason to reject the bulletin.
@freezed
abstract class TsunamiObservation with _$TsunamiObservation {
  const factory TsunamiObservation({
    required String name,

    /// CWA's observed height text (`27公分`).
    required String height,

    /// Observation time (Unix milliseconds).
    required int time,
    double? longitude,
    double? latitude,
  }) = _TsunamiObservation;
}

/// One report of one event, as the index lists it (`GET /api/v1/cwa/tsunami`).
///
/// The index rows carry the summary only — no text, no `data.area` — which is
/// exactly what the sheet's report picker needs: enough to label a pill (第3報)
/// and fetch the full bulletin behind it.
@freezed
abstract class TsunamiBulletin with _$TsunamiBulletin {
  const factory TsunamiBulletin({
    required String id,

    /// CWA event number, shared by every report of the same earthquake
    /// (`113003`) — the key that makes "this event's reports" a list.
    @JsonKey(name: 'no') required int number,

    /// Report within the event, CWA's own wording (`第3報`).
    @JsonKey(name: 'rep') required String report,

    /// `海嘯警報` / `海嘯警報解除`.
    required String type,

    /// Send time (Unix milliseconds).
    required int sent,
  }) = _TsunamiBulletin;

  factory TsunamiBulletin.fromJson(Map<String, dynamic> json) =>
      _$TsunamiBulletinFromJson(json);

  /// The **newest event's** reports from the raw index rows, newest first.
  ///
  /// An event, not the whole index: the index mixes past years in (the only
  /// rows CWA serves outside an event are old ones), so "the current event" is
  /// the newest row's `no` and its reports are the rows sharing it. Filtering
  /// by `no` rather than by an id prefix is deliberate — the id carries the
  /// event *and* the report (`…11300303-2024-0403-111000`), so a prefix match
  /// would re-derive a serial CWA already gives us. An index with nothing in it
  /// is an empty list, which is the calm case rather than a failure.
  static List<TsunamiBulletin> newestEvent(List<dynamic> rows) {
    if (rows.isEmpty) return const [];
    final event = (rows.first as Map<String, dynamic>)['no'];
    return [
      for (final row in rows)
        if ((row as Map<String, dynamic>)['no'] == event)
          TsunamiBulletin.fromJson(row),
    ];
  }
}

/// One complete CWA tsunami bulletin.
@freezed
abstract class TsunamiReport with _$TsunamiReport {
  const factory TsunamiReport({
    required String id,

    /// Send time (Unix milliseconds — the tsunami feed, unlike the meteor
    /// families, is not in seconds).
    required int sent,

    /// CAP message type: `Issue` / `Update` / `Cancel`. `Cancel` means the
    /// threat was lifted, which the sheet states rather than hiding.
    required String msgType,

    /// Report within the event, CWA's own wording (`第3報`).
    required String report,

    /// `海嘯警報` / `海嘯警報解除`.
    required String type,
    required String content,
    required TsunamiEarthquake earthquake,
    required List<TsunamiPrediction> predictions,
    required List<TsunamiObservation> observations,
  }) = _TsunamiReport;

  /// Decodes the payload, whose `data.area` is a positional tuple — five
  /// fields when `data.type` is `predict`, six when it is `observe`.
  factory TsunamiReport.decode(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    final areas = (data?['area'] as List?) ?? const [];
    final predicted = data?['type'] == 'predict';
    return TsunamiReport(
      id: json['id'] as String,
      sent: (json['sent'] as num).toInt(),
      msgType: json['msgType'] as String,
      report: json['rep'] as String,
      type: json['type'] as String,
      content: json['content'] as String,
      earthquake: TsunamiEarthquake.fromJson(
        json['eq'] as Map<String, dynamic>,
      ),
      predictions: predicted
          ? [
              for (final raw in areas)
                TsunamiPrediction(
                  area: (raw as List)[0] as String,
                  coast: raw[1] as String,
                  height: raw[2] as String,
                  arrivalTime: (raw[3] as num).toInt(),
                  color: raw.length > 4 ? raw[4] as String? : null,
                ),
            ]
          : const [],
      observations: predicted
          ? const []
          : [
              for (final raw in areas)
                TsunamiObservation(
                  name: (raw as List)[1] as String,
                  height: raw[2] as String,
                  time: (raw[3] as num).toInt(),
                  longitude: (raw[4] as num?)?.toDouble(),
                  latitude: (raw[5] as num?)?.toDouble(),
                ),
            ],
    );
  }
}

/// How tall a wave was, in the four steps CWA and the legacy app both used.
///
/// The boundaries are CWA's own (0.3 m / 1 m / 3 m) and the labels read in
/// metres even though an **observed** height arrives in centimetres, because
/// the step a reader cares about is "was it over a metre", not the exact number.
enum TsunamiWaveBand {
  /// Under 0.3 m.
  under30cm,

  /// 0.3–1 m.
  from30cm,

  /// 1–3 m.
  from1m,

  /// Over 3 m.
  over3m;

  /// The band CWA's warning colour for a predicted area stands for, or null for
  /// a colour this map has no step for.
  ///
  /// Yellow is CWA's "under 1 m" and is the legacy app's 0.3–1 m step; red and
  /// purple are 1–3 m and over 3 m. There is no predicted colour for the quiet
  /// blue step, so an unknown colour is left unpainted rather than defaulted.
  static TsunamiWaveBand? ofWarningColor(String? color) => switch (color) {
    '黃色' => from30cm,
    '紅色' => from1m,
    '紫色' => over3m,
    _ => null,
  };

  /// The band a [centimeters] reading falls in.
  static TsunamiWaveBand of(int centimeters) => switch (centimeters) {
    >= 300 => over3m,
    >= 100 => from1m,
    >= 30 => from30cm,
    _ => under30cm,
  };
}

/// The centimetre reading inside CWA's observed-height text (`27公分`, `1.5 公尺`),
/// or null when the text holds no number at all.
///
/// Returns null rather than 0 for text it cannot read: "no height I understand"
/// and "a zero-centimetre wave" must not paint the same colour, and the map's
/// quietest band is a claim about the sea.
int? parseObservedCentimeters(String text) {
  final match = RegExp(r'\d+(?:\.\d+)?').firstMatch(text);
  if (match == null) return null;
  final value = double.tryParse(match.group(0)!);
  if (value == null) return null;
  // A reading CWA wrote in metres (`1.5 公尺`) is not 1.5 cm.
  return text.contains('公尺') ? (value * 100).round() : value.round();
}
