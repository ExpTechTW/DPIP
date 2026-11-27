import 'package:dpip/features/events/domain/event_addition.dart';
import 'package:dpip/features/events/domain/event_card.dart';
import 'package:dpip/features/events/domain/event_facts.dart';
import 'package:dpip/features/events/presentation/detail/event_detail_blocks.dart';
import 'package:dpip/features/events/presentation/detail/event_type_detail.dart';
import 'package:dpip/features/events/presentation/widgets/event_fact_chip.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// The detail of the meteor observation types: heavy_rain.short,
/// heavy_rain.short_extreme, wind.strong, wind.damaging,
/// thunderstorm.lightning, river_rise.watch, river_rise.warning and
/// fog.visibility.
///
/// A meteor card is one round of observations, one `addition.stations`
/// element per station (a cluster, for lightning). The summary lists them
/// from the latest report, most severe first; each report keeps the default
/// headline facts.
final class MeteorDetail extends EventTypeDetail {
  const MeteorDetail();

  @override
  Widget? summary(BuildContext context, EventCardDetail detail) {
    final l10n = AppLocalizations.of(context);
    final latest = detail.latest;
    final rows = _rows(latest.type, latest.addition, l10n);
    if (rows.isEmpty) return null;
    return EventDetailSection(
      title: l10n.eventDetailStations,
      child: EventDetailRows(rows: rows),
    );
  }
}

/// The station rows of a card of [type] whose `addition` is [addition], most
/// severe first. Empty for a null or malformed [addition] and for a type that
/// is not a meteor type.
List<EventDetailRow> _rows(
  String type,
  Map<String, dynamic>? addition,
  AppLocalizations l10n,
) {
  if (addition == null) return const [];
  final stations = additionMaps(addition['stations']);
  return switch (type) {
    'heavy_rain.short' || 'heavy_rain.short_extreme' => _rain(stations),
    'wind.strong' || 'wind.damaging' => _wind(stations, l10n),
    'thunderstorm.lightning' => _lightning(stations),
    'river_rise.watch' || 'river_rise.warning' => _river(stations),
    'fog.visibility' => _fog(stations),
    _ => const [],
  };
}

/// One-hour rainfall `rain.1h` per station, highest first: `85 mm`.
List<EventDetailRow> _rain(List<Map<Object?, Object?>> stations) => _ranked([
  for (final station in stations)
    if ((
          _stationLabel(station),
          additionAmount(additionMap(station['rain'])?['1h']),
        )
        case (final label?, final mm?))
      (
        key: -mm,
        row: EventDetailRow(label: label, value: '${eventDecimal(mm, 1)} mm'),
      ),
]);

/// Per station the higher of its gust `gust.speed` and mean wind
/// `wind.speed`, highest first, named by which one it is: `Gust 33 m/s`.
/// The two are named because one list mixes them.
List<EventDetailRow> _wind(
  List<Map<Object?, Object?>> stations,
  AppLocalizations l10n,
) => _ranked([
  for (final station in stations)
    if ((
          _stationLabel(station),
          _strongest(
            gust: additionAmount(additionMap(station['gust'])?['speed']),
            wind: additionAmount(additionMap(station['wind'])?['speed']),
          ),
        )
        case (final label?, (final kind, final speed)?))
      (
        key: -speed,
        row: EventDetailRow(
          label: label,
          value:
              '${eventFactKindLabel(kind, l10n)} ${eventDecimal(speed, 1)} m/s',
        ),
      ),
]);

/// Strikes `count` per lightning cluster, most first, labelled by the
/// cluster's `center` coordinates (the cluster has no place name): `160`.
List<EventDetailRow> _lightning(List<Map<Object?, Object?>> clusters) =>
    _ranked([
      for (final cluster in clusters)
        if ((
              _coordinates(additionMap(cluster['center'])),
              additionInt(cluster['count']),
            )
            case (final label?, final count?) when count >= 0)
          (
            key: -count.toDouble(),
            row: EventDetailRow(label: label, value: '$count'),
          ),
    ]);

/// Water level `waterLevel` per station and the alert line its `stage` has
/// crossed: `warningLevel1` for `l1`/`l1up`, `warningLevel2` for `l2`/`l2up`,
/// as the headline facts read it: `4.5 m / 4 m`. Stages of different rivers
/// are not comparable, so the order is by alert stage (level 1 first), then
/// the server's.
List<EventDetailRow> _river(List<Map<Object?, Object?>> stations) => _ranked([
  for (final station in stations)
    if ((_stationLabel(station), additionStage(station['waterLevel'])) case (
      final label?,
      final level?,
    ))
      _riverRow(station, label, level),
]);

({double key, EventDetailRow row}) _riverRow(
  Map<Object?, Object?> station,
  String label,
  double level,
) {
  final (rank, line) = switch (station['stage']) {
    'l1' || 'l1up' => (0.0, additionStage(station['warningLevel1'])),
    'l2' || 'l2up' => (1.0, additionStage(station['warningLevel2'])),
    _ => (2.0, null),
  };
  final reading = '${eventDecimal(level, 2)} m';
  return (
    key: rank,
    row: EventDetailRow(
      label: label,
      value: line == null ? reading : '$reading / ${eventDecimal(line, 2)} m',
    ),
  );
}

/// Visibility `visibility` per station in km, lowest first. The source's
/// `visibilityText` wins over the number when it has one, because a bound
/// such as `<1` is stored as half of it (`0.5`): `< 1 km`.
List<EventDetailRow> _fog(List<Map<Object?, Object?>> stations) => _ranked([
  for (final station in stations)
    if ((_stationLabel(station), additionAmount(station['visibility'])) case (
      final label?,
      final km?,
    ))
      (
        key: km,
        row: EventDetailRow(
          label: label,
          value:
              '${additionVisibilityText(station['visibilityText']) ?? eventDecimal(km, 1)}'
              ' km',
        ),
      ),
]);

// ── Ordering ────────────────────────────────────────────────────────────────

/// The rows of [entries] by ascending `key`; equal keys keep their order.
List<EventDetailRow> _ranked(List<({double key, EventDetailRow row})> entries) {
  final indexed = entries.indexed.toList()
    ..sort((a, b) {
      final byKey = a.$2.key.compareTo(b.$2.key);
      return byKey != 0 ? byKey : a.$1.compareTo(b.$1);
    });
  return [for (final (_, entry) in indexed) entry.row];
}

/// The higher of [gust] and [wind] and which one it is; the gust when they
/// are equal, null when neither has a reading.
(EventFactKind, double)? _strongest({double? gust, double? wind}) {
  if (gust != null && (wind == null || gust >= wind)) {
    return (EventFactKind.gust, gust);
  }
  return wind == null ? null : (EventFactKind.windSpeed, wind);
}

// ── Labels ──────────────────────────────────────────────────────────────────

/// A station as the card's subtitle names it, `{county}{town} {stationName}`,
/// leaving out the parts it lacks; its `stationId` stands in for a missing
/// name. Null when it has none of them.
String? _stationLabel(Map<Object?, Object?> station) {
  final place =
      '${additionText(station['county']) ?? ''}${additionText(station['town']) ?? ''}';
  final name =
      additionText(station['stationName']) ??
      additionText(station['stationId']);
  final parts = [if (place.isNotEmpty) place, ?name];
  return parts.isEmpty ? null : parts.join(' ');
}

/// `{lat, lng}` as `25.030, 121.500`, the three decimals the source rounds
/// to; null unless both are valid coordinates.
String? _coordinates(Map<Object?, Object?>? center) {
  final lat = center?['lat'];
  final lng = center?['lng'];
  if (lat is! num || lng is! num) return null;
  if (!lat.isFinite || !lng.isFinite) return null;
  if (lat.abs() > 90 || lng.abs() > 180) return null;
  return '${lat.toStringAsFixed(3)}, ${lng.toStringAsFixed(3)}';
}
