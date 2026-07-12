import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/realtime/realtime_source.dart';
import 'package:dpip/features/earthquake/domain/eew.dart';
import 'package:dpip/features/earthquake/domain/eew_repository.dart';
import 'package:flutter/foundation.dart' show listEquals;

/// Feeds the realtime channel from the existing [EewRepository], so EEW gains a
/// polled [Stream] with zero new JSON mapping and the same [Result]/[Failure]/
/// region-failover behaviour as one-shot fetches.
class EewRealtimeSource extends RealtimeSource<List<Eew>> {
  EewRealtimeSource(this._repository);

  final EewRepository _repository;

  @override
  Future<Result<List<Eew>>> fetch() => _repository.activeEews();

  /// Null on purpose: EEW uses fetch-freshness. `EewInfo.time` recedes within a
  /// single active event while fresh updates keep arriving, so payload age would
  /// false-positive "stale" mid-alert; time-since-last-successful-fetch measures
  /// feed liveness instead.
  @override
  DateTime? timestampOf(List<Eew> value) => null;

  /// Element-wise equality (the repository returns a fresh list each poll, so
  /// the default identity `==` would never dedup). `Eew` is a value type.
  @override
  bool sameData(List<Eew>? a, List<Eew>? b) => listEquals(a, b);
}
