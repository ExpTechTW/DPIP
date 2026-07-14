/// Access to v5 meteor lightning data (strike snapshots).
library;

import 'package:dpip/core/error/result.dart';
import 'package:dpip/features/weather/domain/lightning_snapshot.dart';

/// Lightning-strike snapshots from the v5 meteor API. Returns a [Result] so a
/// failed fetch/decode is explicit (never a silently empty strike layer); the
/// impl in `data/` maps transport/decode errors to a typed `Failure`.
abstract interface class MeteorLightningRepository {
  /// The latest strike snapshot.
  Future<Result<LightningSnapshot>> latest();

  /// Available history snapshot times (Unix seconds, ascending); `Ok([])` when
  /// none.
  Future<Result<List<int>>> history();

  /// The historical snapshot at [second].
  Future<Result<LightningSnapshot>> at(int second);
}
