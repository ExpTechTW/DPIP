import 'dart:async';

import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/realtime/realtime_source.dart';
import 'package:dpip/features/earthquake/domain/eew.dart';
import 'package:dpip/features/earthquake/domain/eew_town_levels.dart';
import 'package:flutter/foundation.dart' show listEquals;

/// Replaces each EEW payload's agency-reported `max` with the ML model's
/// nationwide township maximum before the alert reaches any app consumer.
///
/// The raw value remains available while the model loads or when it cannot
/// score a solution. Loading never delays delivery of a safety-critical alert;
/// the channel's next fetch publishes the ML value once the model is ready.
class EewMlMaxSource extends RealtimeSource<List<Eew>> {
  EewMlMaxSource(this._source, this._model);

  final RealtimeSource<List<Eew>> _source;
  final MlIntensityEstimator _model;

  @override
  Future<Result<List<Eew>>> fetch() async {
    final result = await _source.fetch();
    final alerts = result.valueOrNull;
    if (alerts == null || !alerts.any((alert) => !alert.isCancelled)) {
      return result;
    }
    if (!_model.ready) {
      unawaited(_model.prepare());
      return result;
    }
    return switch (result) {
      Ok(:final value, :final stale) => Ok(
        await Future.wait(value.map(_withMlMaximum)),
        stale: stale,
      ),
      Err(:final failure) => Err(failure),
    };
  }

  Future<Eew> _withMlMaximum(Eew alert) async {
    if (alert.isCancelled) return alert;
    final levels = await _model.townLevels(alert.info);
    if (levels == null || levels.isEmpty) return alert;
    final maximum = levels.values.reduce((a, b) => a > b ? a : b);
    return alert.copyWith(info: alert.info.copyWith(max: maximum));
  }

  @override
  DateTime? timestampOf(List<Eew> value) => _source.timestampOf(value);

  @override
  bool sameData(List<Eew>? a, List<Eew>? b) => listEquals(a, b);

  @override
  bool get servingFallback => _source.servingFallback;

  @override
  bool isIgnorableFailure(Failure failure) =>
      _source.isIgnorableFailure(failure);

  @override
  void pause() => _source.pause();

  @override
  void resume() => _source.resume();

  @override
  void networkChanged() => _source.networkChanged();

  @override
  void dispose() => _source.dispose();
}
