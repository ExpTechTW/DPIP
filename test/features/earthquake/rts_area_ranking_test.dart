/// The 震度排行榜's selection rule: what may be shown, and in what order.
///
/// Both the live monitor and the replay page render the same ranking, so this
/// is the one place the freshness gate is enforced — a ranking is a statement
/// about how the ground is shaking *now*.
library;

import 'package:dpip/core/realtime/realtime_state.dart';
import 'package:dpip/features/earthquake/domain/rts.dart';
import 'package:dpip/features/earthquake/domain/rts_area_ranking.dart';
import 'package:flutter_test/flutter_test.dart';

Rts _rts(List<(int code, int intensity)> areas) => Rts(
  intensities: [
    for (final (code, intensity) in areas)
      RtsAreaIntensity(code: code, intensity: intensity),
  ],
);

RealtimeState<Rts> _state(RealtimeStatus status, {List<(int, int)>? areas}) =>
    RealtimeState(status: status, data: areas == null ? null : _rts(areas));

void main() {
  test('ranks strongest first and caps at three', () {
    final ranked = rtsAreaRanking(
      _state(
        RealtimeStatus.live,
        areas: [(100, 2), (970, 5), (400, 3), (800, 1)],
      ),
    );

    expect(ranked, [
      (code: '970', intensity: 5),
      (code: '400', intensity: 3),
      (code: '100', intensity: 2),
    ]);
  });

  test('breaks ties on the feed order, not the sort', () {
    final ranked = rtsAreaRanking(
      _state(RealtimeStatus.live, areas: [(100, 1), (970, 1), (400, 1)]),
    );

    expect(ranked?.map((a) => a.code), ['100', '970', '400']);
  });

  test('a live but calm feed ranks nothing — and is not nothing to show', () {
    expect(rtsAreaRanking(_state(RealtimeStatus.live, areas: [])), isEmpty);
  });

  test('a stale or offline feed shows no ranking at all', () {
    // The data is still in hand (the channel retains the last payload across a
    // dropped poll) — it just may no longer describe the ground right now.
    for (final status in [RealtimeStatus.stale, RealtimeStatus.offline]) {
      expect(
        rtsAreaRanking(_state(status, areas: [(970, 5)])),
        isNull,
        reason: '$status must not be presented as current',
      );
    }
  });

  test('no snapshot yet shows no ranking — the replay 404 case', () {
    expect(rtsAreaRanking(const RealtimeState.connecting()), isNull);
    expect(rtsAreaRanking(_state(RealtimeStatus.live)), isNull);
  });
}
