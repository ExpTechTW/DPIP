/// Base impl for the meteor snapshot repositories — the latest / history / at
/// trio is identical across weather, rain, and lightning; only the snapshot
/// type's decode differs.
library;

import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/network/api_exception.dart';
import 'package:dpip/features/weather/data/meteor_snapshot_api.dart';
import 'package:dpip/features/weather/data/meteor_station_decode.dart';
import 'package:flutter/foundation.dart';

/// Maps the datasource's raw JSON to [S], converting transport/decode errors to
/// typed failures via [guardResult]. Subclasses supply [decodeSnapshot] plus
/// any endpoints the dataset doesn't share (stations / trend).
abstract class MeteorSnapshotRepositoryImpl<S> {
  const MeteorSnapshotRepositoryImpl(this._api);

  final MeteorSnapshotApi _api;

  /// The shared snapshot API — for subclasses exposing the dataset's station
  /// directory or trends.
  @protected
  MeteorSnapshotApi get api => _api;

  /// Decodes the raw field-array snapshot payload into the domain model.
  S decodeSnapshot(Map<String, dynamic> json);

  /// The latest snapshot.
  Future<Result<S>> latest() =>
      guardResult(() async => decodeSnapshot(await _api.getLatest()));

  /// Available snapshot times (Unix seconds, ascending); `Ok([])` when none.
  Future<Result<List<int>>> history() => fetchHistory(_api.getList);

  /// The historical snapshot at [second].
  Future<Result<S>> at(int second) =>
      guardResult(() async => decodeSnapshot(await _api.getAt(second)));
}
