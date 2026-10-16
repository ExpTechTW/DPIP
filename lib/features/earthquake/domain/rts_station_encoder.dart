/// Where the 強震監視器 has its station layer built when the UI isolate does
/// not have to build it.
library;

import 'package:dpip/features/earthquake/domain/rts.dart';
import 'package:dpip/features/earthquake/domain/seismic_station.dart';

/// Builds the station layer — `encodeRtsStationGeoJson`'s output — for frames
/// it already holds, so the monitor neither walks the stations nor encodes
/// them on the UI isolate.
///
/// Only a frame the encoder decoded itself can be asked for; any other frame,
/// or one it has let go of, answers null, and the caller builds the layer
/// itself with `rtsStationGeoJson`. So an encoder is only ever a faster way to
/// the same output, never the only way to it.
abstract interface class RtsStationEncoder {
  /// The station directory every later [encode] places frames against — the
  /// one the monitor itself is drawing with.
  void placeStations(Map<String, SeismicStation> stations);

  /// [frame]'s station layer, encoded; or null when this encoder does not
  /// hold [frame]. The flags and icons are the monitor's at the moment it
  /// asks (see `rtsStationGeoJson`).
  Future<String?> encode(
    Rts frame, {
    required bool eventLit,
    required bool eewActive,
    required List<String> badgeIcons,
  });
}
