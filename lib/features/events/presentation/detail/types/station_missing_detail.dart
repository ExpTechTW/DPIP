import 'package:dpip/features/events/domain/event_addition.dart';
import 'package:dpip/features/events/domain/event_card.dart';
import 'package:dpip/features/events/presentation/detail/event_detail_blocks.dart';
import 'package:dpip/features/events/presentation/detail/event_type_detail.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// The detail of earthquake.station_missing.
///
/// The summary lists the stations of the latest report's `addition.stations`
/// in the server's order — the order they were pushed in — each by its name
/// and the county and township it stands in. A station's `intensity` is left
/// out: the server does not say what that value is the intensity of. Every
/// report keeps the default headline facts.
final class StationMissingDetail extends EventTypeDetail {
  const StationMissingDetail();

  @override
  Widget? summary(BuildContext context, EventCardDetail detail) {
    final rows = _stationRows(detail.latest.addition);
    if (rows.isEmpty) return null;
    return EventDetailSection(
      title: AppLocalizations.of(context).eventDetailMissingStations,
      child: EventDetailRows(rows: rows),
    );
  }
}

/// One row per station of `addition.stations`; empty when there is none.
List<EventDetailRow> _stationRows(Map<String, dynamic>? addition) => [
  for (final station in additionMaps(addition?['stations']))
    ?_stationRow(station),
];

/// [station] labelled by its name and valued by its county and township, as
/// `臺東縣 蘭嶼鄉`.
///
/// Without a name the station code is the label; without a county or
/// township the code is the value. Null when the station has neither a name
/// nor a code.
EventDetailRow? _stationRow(Map<Object?, Object?> station) {
  final name = additionText(station['name']);
  final code = additionText(station['code']);
  final label = name ?? code;
  if (label == null) return null;
  final place = [
    ?additionText(station['county']),
    ?additionText(station['town']),
  ].join(' ');
  final value = place.isNotEmpty ? place : (name == null ? null : code);
  return EventDetailRow(label: label, value: value ?? '');
}
