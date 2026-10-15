import 'package:dpip/core/models/lat_lng.dart';
import 'package:dpip/core/models/serialization.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'eew.freezed.dart';
part 'eew.g.dart';

/// An Earthquake Early Warning for an in-progress earthquake.
///
/// The template for the app's API models: a `@freezed` immutable value type with
/// generated `fromJson`/`toJson`, `@JsonKey` mapping the wire names, and
/// `boolishInt` coercing the API's `0`/`1` booleans. New payloads copy this
/// shape.
@freezed
abstract class Eew with _$Eew {
  const factory Eew({
    @JsonKey(name: 'author') required String agency,
    required String id,
    required int serial,
    required int status,
    @JsonKey(name: 'final', fromJson: boolishInt, toJson: intFromBool)
    required bool isFinal,
    @JsonKey(name: 'eq') required EewInfo info,
  }) = _Eew;

  factory Eew.fromJson(Map<String, dynamic> json) => _$EewFromJson(json);
}

/// Whether [Eew.agency] is 中央氣象署 (CWA) — case-insensitive, since the wire
/// value is lowercase (`'cwa'`) but nothing guarantees that stays true for
/// every publishing agency the upstream feed ever adds.
extension EewAgencyX on Eew {
  bool get isCwa => agency.toLowerCase() == 'cwa';

  /// Whether [Eew.agency] is 気象庁 (JMA) — unconditionally filtered out by
  /// every EEW data source, regardless of `EewCwaOnlySettings`. Not a
  /// selectable source: "所有來源" means every agency *except* this one.
  bool get isJma => agency.toLowerCase() == 'jma';
}

/// Which earthquake a report belongs to.
extension EewIdentityX on Eew {
  /// One event across all its reports: the publishing agency plus its own
  /// event id — the same pair the server keys its list on, since two agencies
  /// number their events independently. The agency is lower-cased because
  /// nothing guarantees one feed spells it the same way every time.
  String get eventKey => '${agency.toLowerCase()}:$id';
}

/// What a report is, read from [Eew.status].
enum EewReportKind {
  /// 預警 — an ordinary report (`0`, and any code this app does not know).
  forecast,

  /// 警報 — the agency's public warning (`1`).
  warning,

  /// 取消 — the agency withdrew the event: it was not an earthquake, or not
  /// the one the earlier reports described (`2` or `3`).
  cancelled,
}

/// The meaning of the wire `status` integer.
///
/// The public JSON (`/api/v2/eq/eew`, GET and `?sse=1`) carries the
/// publishing agency's own code through untouched — the edge decodes it as a
/// single byte of the binary NATS message and copies it into the JSON — so
/// the cancel code depends on who encoded it:
///
/// | code | meaning | where it comes from |
/// |---|---|---|
/// | `0` | 預警 | every agency |
/// | `1` | 警報 | CWA's public warning |
/// | `2` | 取消 | the event server's own model (`0 normal, 1 alert, 2 cancel`), which is how the `nied` feed's cancel arrives |
/// | `3` | 取消 | the CWA feed, and what every ExpTech client keys its cancel styling on |
///
/// No feed uses `2` or `3` for anything else, so both read as a cancel.
/// [Eew.isFinal] (`final`) is separate: `1` marks the agency's last report
/// for the event, which says nothing about whether it was cancelled.
///
/// An unknown code reads as [EewReportKind.forecast], never as a cancel: a
/// misread code must leave an alert on screen, not hide one.
extension EewStatusX on Eew {
  EewReportKind get kind => switch (status) {
    1 => EewReportKind.warning,
    2 || 3 => EewReportKind.cancelled,
    _ => EewReportKind.forecast,
  };

  /// Whether the agency withdrew this event. A cancelled report must never
  /// drive an alert: no countdown, no local estimate, no wave rings, no
  /// speech — only a "cancelled" notice until it leaves the list.
  bool get isCancelled => kind == EewReportKind.cancelled;

  /// Whether this is the agency's public 警報 rather than a 預警.
  bool get isWarning => kind == EewReportKind.warning;
}

/// The cancel filter every consumer of an alert list needs.
extension EewListX on List<Eew> {
  /// The alerts that still describe an earthquake in progress — everything
  /// but the cancelled ones, in their original order.
  List<Eew> get uncancelled => [
    for (final alert in this)
      if (!alert.isCancelled) alert,
  ];

  /// Whether any alert still describes an earthquake in progress.
  bool get hasUncancelled => any((alert) => !alert.isCancelled);
}

/// The earthquake parameters carried by an [Eew].
@freezed
abstract class EewInfo with _$EewInfo {
  const EewInfo._();

  const factory EewInfo({
    required int time,
    @JsonKey(name: 'lon') required double longitude,
    @JsonKey(name: 'lat') required double latitude,
    required double depth,
    @JsonKey(name: 'mag') required double magnitude,
    @JsonKey(name: 'loc') required String location,
    required int max,
  }) = _EewInfo;

  factory EewInfo.fromJson(Map<String, dynamic> json) =>
      _$EewInfoFromJson(json);

  /// The epicentre as a dependency-free coordinate for the EEW math.
  LatLng get latlng => LatLng(latitude, longitude);
}
