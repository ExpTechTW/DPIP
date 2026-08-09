import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/network/api_exception.dart';
import 'package:dpip/core/realtime/realtime_source.dart';
import 'package:dpip/core/realtime/replay_clock.dart';
import 'package:dpip/features/earthquake/data/earthquake_api.dart';
import 'package:dpip/features/earthquake/domain/eew.dart';
import 'package:flutter/foundation.dart' show listEquals;

/// Replays the EEW feed at a fixed point in the past — the [RtsReplaySource]
/// counterpart: each [fetch] asks [EarthquakeApi.getEewAt] for the list at
/// the current second of [clock].
class EewReplaySource extends RealtimeSource<List<Eew>> {
  EewReplaySource(this._api, this.clock);

  final EarthquakeApi _api;

  /// Ticks forward from the replay's start instant; shared with the paired
  /// [RtsReplaySource] so both feeds replay the same instant.
  final ReplayClock clock;

  @override
  Future<Result<List<Eew>>> fetch() => guardResult(() async {
    final seconds = clock.now().millisecondsSinceEpoch ~/ 1000;
    final json = await _api.getEewAt(seconds);
    return [
      for (final item in json) Eew.fromJson(item as Map<String, dynamic>),
    ];
  });

  /// Null: same fetch-freshness rationale as the live [EewRealtimeSource] —
  /// here doubly so, since the payload's own time is deliberately historical.
  @override
  DateTime? timestampOf(List<Eew> value) => null;

  /// Element-wise equality, mirroring [EewRealtimeSource] — a fresh `List`
  /// each fetch would otherwise never compare `==`.
  @override
  bool sameData(List<Eew>? a, List<Eew>? b) => listEquals(a, b);
}
