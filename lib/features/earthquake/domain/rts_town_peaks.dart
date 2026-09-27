/// The 震度排行: each township's strongest level over the last minute, so a
/// township that shook stays on the list after its stations have calmed down.
///
/// Why a window at all: a frame's alerting stations flicker — a station clears
/// its alert once it reads under 0.5, and the S-wave moves on — so a ranking
/// built from the latest frame alone would reorder and empty itself every
/// second while the shaking is still the news. Holding each township's peak
/// for 60 seconds is TREM-Lite's ranking, ported: the same window, the same
/// integer levels, the same fold to counties when the list gets long.
library;

import 'package:dpip/core/geo/town.dart';

/// How long a township keeps its peak after its last alerting frame.
const Duration rtsTownPeakWindow = Duration(seconds: 60);

/// Past this many townships the ranking lists counties instead — a big event
/// lights dozens, and a list that long is no longer a glance.
const int rtsRankingTownLimit = 6;

/// One row of the ranking: a township, or a whole county once the list is
/// folded ([town] null), its display [name] (`臺北市中正區` / `臺北市`), and the
/// strongest [level] 0–9 in it.
typedef RtsRankingRow = ({Town? town, String name, int level});

/// Each township's peak level inside [rtsTownPeakWindow].
///
/// Fed one frame at a time with that frame's server instant, not the device
/// clock: a replay plays hours-old frames, and a device clock that jumped would
/// otherwise expire everything at once. Keyed by the township code, which is
/// unique per township in the bundled directory.
class RtsTownPeaks {
  final Map<String, List<(int, int)>> _samples = {};

  /// Adds [towns] (code → level) seen at [timeMs] and returns every
  /// township's peak in the window ending there. A sample stamped after
  /// [timeMs] is dropped too — what a jump back in time (a replay restarted
  /// earlier) left behind is not "within the last minute".
  Map<String, int> update(Map<String, int> towns, int timeMs) {
    for (final entry in towns.entries) {
      (_samples[entry.key] ??= []).add((timeMs, entry.value));
    }
    final windowMs = rtsTownPeakWindow.inMilliseconds;
    final peaks = <String, int>{};
    _samples.removeWhere((code, samples) {
      samples.removeWhere(
        (sample) => sample.$1 > timeMs || timeMs - sample.$1 >= windowMs,
      );
      if (samples.isEmpty) return true;
      var peak = samples.first.$2;
      for (final sample in samples) {
        if (sample.$2 > peak) peak = sample.$2;
      }
      peaks[code] = peak;
      return false;
    });
    return peaks;
  }

  void clear() => _samples.clear();
}

/// The ranking rows for [peaks], strongest first.
///
/// Up to [rtsRankingTownLimit] townships are listed one by one; past that they
/// fold into their counties, each at its strongest township's level, and only
/// the top [rtsRankingTownLimit] counties are kept. A code the directory does
/// not know is dropped rather than shown as a bare number. Equal levels keep a
/// stable order (by code) so the list does not reshuffle every second.
List<RtsRankingRow> rtsRanking(
  Map<String, int> peaks,
  Town? Function(String code) townOf,
) {
  final rows = <RtsRankingRow>[
    for (final entry in peaks.entries)
      if (townOf(entry.key) case final town?)
        (
          town: town,
          name: '${town.cityName}${town.townName}',
          level: entry.value,
        ),
  ]..sort(_byLevel);
  if (rows.length <= rtsRankingTownLimit) return rows;
  final counties = <String, RtsRankingRow>{};
  for (final row in rows) {
    final county = row.town!.cityName;
    final current = counties[county];
    if (current == null || row.level > current.level) {
      counties[county] = (town: null, name: county, level: row.level);
    }
  }
  return (counties.values.toList()..sort(_byLevel))
      .take(rtsRankingTownLimit)
      .toList();
}

int _byLevel(RtsRankingRow a, RtsRankingRow b) {
  final byLevel = b.level.compareTo(a.level);
  if (byLevel != 0) return byLevel;
  return (a.town?.code ?? a.name).compareTo(b.town?.code ?? b.name);
}
