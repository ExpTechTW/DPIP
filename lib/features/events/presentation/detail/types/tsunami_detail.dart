import 'package:dpip/features/events/domain/event_addition.dart';
import 'package:dpip/features/events/domain/event_card.dart';
import 'package:dpip/features/events/presentation/detail/event_detail_blocks.dart';
import 'package:dpip/features/events/presentation/detail/event_type_detail.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// The detail of tsunami.warning and tsunami.info.
///
/// A tsunami.warning card's summary is the `info` of its latest report, one
/// row per place, earliest arrival first:
///
/// - `info.type` `estimate`: the estimated wave height and arrival time of
///   each coastal area, until the warning is lifted (`status` 2), after which
///   the estimates are no longer shown.
/// - `info.type` `actual`: the wave height and arrival time each tide station
///   observed, shown whether or not the warning has been lifted.
///
/// Any other `info.type` gives no summary. A tsunami.info card has no
/// summary either: its `addition` names no area, and the earthquake it
/// carries is already in each report's facts. Reports keep the default body.
final class TsunamiDetail extends EventTypeDetail {
  const TsunamiDetail();

  @override
  Widget? summary(BuildContext context, EventCardDetail detail) {
    final latest = detail.latest;
    if (latest.type != 'tsunami.warning') return null;
    final listing = _readWarning(latest.addition);
    if (listing == null) return null;
    final l10n = AppLocalizations.of(context);
    return EventDetailSection(
      title: switch (listing.kind) {
        _InfoKind.estimate => l10n.eventDetailTsunamiByArea,
        _InfoKind.actual => l10n.eventDetailTsunamiObserved,
      },
      child: EventDetailRows(rows: listing.rows),
    );
  }
}

/// What a tsunami.warning `info` lists, by its `type`.
enum _InfoKind {
  /// Estimates per coastal area, `{area, arrival_time, wave_height}`.
  estimate('area', 1),

  /// Tide-station readings, `{name, id, lat, lon, wave_height,
  /// arrival_time}`. Two decimals in metres keep every centimetre of a
  /// reading, which is often under 10 cm.
  actual('name', 2);

  const _InfoKind(this.nameKey, this.metreDigits);

  /// The key of the place name in each `data` item.
  final String nameKey;

  /// Decimals of the wave height, in metres.
  final int metreDigits;
}

/// The rows of a tsunami.warning [addition]'s `info`; null when it lists
/// nothing to show.
({_InfoKind kind, List<EventDetailRow> rows})? _readWarning(
  Map<String, dynamic>? addition,
) {
  if (addition == null) return null;
  final info = addition['info'];
  if (info is! Map<Object?, Object?>) return null;
  final kind = switch (info['type']) {
    'estimate' when !_isLifted(addition['status']) => _InfoKind.estimate,
    'actual' => _InfoKind.actual,
    _ => null,
  };
  final data = info['data'];
  if (kind == null || data is! List<Object?>) return null;
  final rows = _rows(data, kind);
  return rows.isEmpty ? null : (kind: kind, rows: rows);
}

/// Whether the warning is lifted: `status` 2, which upstream may also write
/// as `2.0` or `"2"`.
bool _isLifted(Object? status) => switch (status) {
  final num value => value == 2,
  final String text => text.trim() == '2',
  _ => false,
};

/// One row per [data] item that has a place name and a wave height or an
/// arrival time: `1.0 m · 20:56`. Earliest arrival first; items without one
/// follow in the order sent.
List<EventDetailRow> _rows(List<Object?> data, _InfoKind kind) {
  final lines = <({int index, int? arrivalMs, EventDetailRow row})>[];
  for (final (index, item) in data.indexed) {
    if (item is! Map<Object?, Object?>) continue;
    final name = additionText(item[kind.nameKey]);
    if (name == null) continue;
    final heightCm = additionAmount(item['wave_height']);
    final arrivalMs = additionEpochMs(item['arrival_time']);
    final parts = [
      if (heightCm != null)
        '${(heightCm / 100).toStringAsFixed(kind.metreDigits)} m',
      if (arrivalMs != null) eventClock(arrivalMs),
    ];
    if (parts.isEmpty) continue;
    lines.add((
      index: index,
      arrivalMs: arrivalMs,
      row: EventDetailRow(label: name, value: parts.join(' · ')),
    ));
  }
  lines.sort((a, b) {
    final aMs = a.arrivalMs;
    final bMs = b.arrivalMs;
    final byArrival = switch ((aMs, bMs)) {
      (final int x, final int y) => x.compareTo(y),
      (int(), null) => -1,
      (null, int()) => 1,
      (null, null) => 0,
    };
    return byArrival != 0 ? byArrival : a.index.compareTo(b.index);
  });
  return [for (final line in lines) line.row];
}
