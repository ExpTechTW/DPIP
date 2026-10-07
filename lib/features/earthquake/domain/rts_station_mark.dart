/// How the 強震監視器 marks one station in a frame — TREM-Lite's rules, so
/// the two monitors show the same stations the same way.
///
/// What a station shows depends on two things beyond its own reading: whether
/// the frame lights any detection box (an event is being picked up), and
/// whether an EEW is out.
///
/// | station                          | no EEW            | EEW out           |
/// |----------------------------------|-------------------|-------------------|
/// | alerting, box lit, level > 0     | intensity badge   | intensity badge   |
/// | alerting, box lit, 0.2 ≤ i < 0.5 | dot at level 0    | grey dot          |
/// | alerting, box lit, i < 0.2       | dot at level 0    | dot at level 0     |
/// | anything else                    | dot at its `i`    | not drawn         |
///
/// Without an EEW nothing is hidden: the whole network stays on the map, so a
/// calm station is still visibly a working one. Once an EEW is out, the map
/// is about that earthquake — the wavefront and the stations picking it up —
/// and the rest of the island's background noise would only bury them.
library;

import 'package:dpip/features/earthquake/domain/rts.dart';
import 'package:dpip/shared/seismic/intensity.dart';

enum RtsStationMarkKind {
  /// A dot coloured by [RtsStationMark.colorValue].
  dot,

  /// The discrete-intensity badge for [RtsStationMark.level].
  badge,

  /// A grey dot: an alerting station in a lit event with an active EEW and
  /// intensity at least 0.2 but below discrete level 1.
  grey,
}

/// One station's mark: its [kind], its discrete [level] (0–9), and the value
/// its dot is coloured by — the continuous reading, or the discrete level for
/// a station counted into a lit event.
typedef RtsStationMark = ({
  RtsStationMarkKind kind,
  int level,
  double colorValue,
});

/// The mark for [reading], or null when it is not drawn at all.
///
/// [eventLit] is whether the frame lights any detection box; [eewActive]
/// whether an EEW is currently out (and its feed live).
RtsStationMark? rtsStationMark(
  RtsStation reading, {
  required bool eventLit,
  required bool eewActive,
}) {
  final level = Intensity.toScale(reading.intensity);
  if (eventLit && reading.alert) {
    if (level > 0) {
      return (
        kind: RtsStationMarkKind.badge,
        level: level,
        colorValue: level.toDouble(),
      );
    }
    return (
      kind: eewActive && reading.intensity >= 0.2
          ? RtsStationMarkKind.grey
          : RtsStationMarkKind.dot,
      level: 0,
      colorValue: 0,
    );
  }
  if (eewActive) return null;
  return (
    kind: RtsStationMarkKind.dot,
    level: level,
    colorValue: reading.intensity,
  );
}
