/// What one RTS frame's alerting stations light up: the detection boxes and
/// the townships — the `box` and `int` the old v2 feed computed on the server
/// and `rts.v1` leaves to the client.
///
/// Only an **alerting** station counts. A calm station reading 2 is ordinary
/// noise across a network of a hundred sensors; the network flags `alert` when
/// it has tied a station to an event, and lighting a box on anything less
/// would put the whole island on the map every windy afternoon. Each area
/// takes the strongest discrete level among its alerting stations, and a frame
/// with no alerting station lights nothing — which is also what tells the
/// monitor that a large event is (or is no longer) under way.
library;

import 'package:dpip/features/earthquake/domain/rts.dart';
import 'package:dpip/features/earthquake/domain/rts_box_grid.dart';
import 'package:dpip/features/earthquake/domain/seismic_station.dart';
import 'package:dpip/shared/seismic/intensity.dart';

/// Where one station stands, as far as lighting areas goes: the detection
/// [box] it falls in, and its [town] code — either null when unknown.
typedef StationArea = ({int? box, String? town});

/// Every station's [StationArea], worked out once per directory rather than
/// once per frame: the ray cast is the only costly step, and a station does not
/// move between frames.
Map<String, StationArea> stationAreas(
  Map<String, SeismicStation> stations,
  RtsBoxGrid grid,
) => {
  for (final station in stations.values)
    station.id: (
      box: grid.boxAt(station.latitude, station.longitude),
      town: station.townCode,
    ),
};

/// The areas one frame lights: box id → level and town code → level.
class RtsAlertAreas {
  const RtsAlertAreas({this.boxes = const {}, this.towns = const {}});

  /// Lit detection boxes and the strongest level (0–9) in each.
  final Map<int, int> boxes;

  /// Townships with an alerting station, and the strongest level in each.
  final Map<String, int> towns;

  static const RtsAlertAreas none = RtsAlertAreas();
}

/// Lights [frame]'s areas from its alerting stations. A station missing from
/// [areas] (not in the directory yet) lights nothing — there is nowhere to put
/// it.
RtsAlertAreas rtsAlertAreas(
  Map<String, RtsStation> frame,
  Map<String, StationArea> areas,
) {
  Map<int, int>? boxes;
  Map<String, int>? towns;
  for (final entry in frame.entries) {
    final reading = entry.value;
    if (!reading.alert) continue;
    final area = areas[entry.key];
    if (area == null) continue;
    final level = Intensity.toScale(reading.intensity);
    final box = area.box;
    if (box != null) {
      final lit = boxes ??= {};
      if (level > (lit[box] ?? -1)) lit[box] = level;
    }
    final town = area.town;
    if (town != null) {
      final lit = towns ??= {};
      if (level > (lit[town] ?? -1)) lit[town] = level;
    }
  }
  if (boxes == null && towns == null) return RtsAlertAreas.none;
  return RtsAlertAreas(boxes: boxes ?? const {}, towns: towns ?? const {});
}
