/// Which townships to show in the 震度排行榜, derived from an RTS feed state.
///
/// Lives in `domain` because two different features render this ranking — the
/// map's monitor layer and the earthquake feature's replay page — and neither
/// may import the other's presentation. Keeping the selection (including the
/// freshness gate) here is also the only way both surfaces are guaranteed to
/// apply the same rule: a ranking read off a stale feed would be a claim about
/// how the ground is shaking *now*, made from data that no longer says so.
library;

import 'package:dpip/core/realtime/realtime_state.dart';
import 'package:dpip/features/earthquake/domain/rts.dart';

/// One row of the ranking: a township [code] (as [TownDirectory] keys it) and
/// the felt intensity observed there.
typedef RankedArea = ({String code, int intensity});

/// How many townships the ranking shows — the legacy monitor's
/// `if (count == 3) break;`, kept: three rows never reach far enough down the
/// map to cover the island, and the ranking is a glance, not a table.
const int kRtsAreaRankingLimit = 3;

/// The shaking townships in [state], strongest first and capped at [limit] —
/// or **null** when no ranking may be shown at all: the feed is not
/// [RealtimeStatus.live], or no snapshot has arrived (which includes a replay
/// far enough back that the server kept no RTS for it — see `RtsReplaySource`).
///
/// An empty list is the distinct third case: the feed is live and reports
/// nothing shaking. Callers show the ranking's empty state for that, and
/// nothing at all for null.
///
/// The wire list arrives roughly strongest-first but promises nothing, so this
/// sorts. `List.sort` is not stable, so the feed's own index breaks ties —
/// otherwise the rows of a whole county reading 1 could reshuffle every second
/// while the ranking sat open.
List<RankedArea>? rtsAreaRanking(
  RealtimeState<Rts> state, {
  int limit = kRtsAreaRankingLimit,
}) {
  final snapshot = state.data;
  if (state.status != RealtimeStatus.live || snapshot == null) return null;
  final areas =
      [for (final (index, area) in snapshot.intensities.indexed) (index, area)]
        ..sort((a, b) {
          final byIntensity = b.$2.intensity.compareTo(a.$2.intensity);
          return byIntensity != 0 ? byIntensity : a.$1.compareTo(b.$1);
        });
  return [
    for (final (_, area) in areas.take(limit))
      (code: area.townCode, intensity: area.intensity),
  ];
}
