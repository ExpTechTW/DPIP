/// [MeteorTyphoonRepository] backed by [MeteorTyphoonApi].
library;

import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/network/api_exception.dart';
import 'package:dpip/core/network/meteor_decode.dart';
import 'package:dpip/features/typhoon/data/meteor_typhoon_api.dart';
import 'package:dpip/features/typhoon/domain/meteor_typhoon_repository.dart';
import 'package:dpip/features/typhoon/domain/typhoon_cyclone.dart';
import 'package:dpip/features/typhoon/domain/typhoon_kind.dart';
import 'package:dpip/features/typhoon/domain/typhoon_potential.dart';
import 'package:dpip/features/typhoon/domain/typhoon_probability.dart';
import 'package:dpip/features/typhoon/domain/typhoon_track.dart';
import 'package:dpip/features/typhoon/domain/typhoon_warning.dart';

/// Maps the datasource's raw JSON to domain models, converting transport/decode
/// errors to typed failures via [guardResult]. Object payloads (cyclone index,
/// track, warning) round-trip through `fromJson` / `decode`; the coordinate-
/// array payloads (potential, probability) use their custom `decode`.
class MeteorTyphoonRepositoryImpl implements MeteorTyphoonRepository {
  const MeteorTyphoonRepositoryImpl(this._api);

  final MeteorTyphoonApi _api;

  @override
  Future<Result<CycloneIndex>> cyclones() =>
      guardResult(() async => CycloneIndex.fromJson(await _api.getCyclones()));

  @override
  Future<Result<TrackPayload>> track() =>
      guardResult(() async => TrackPayload.fromJson(await _api.getTrack()));

  @override
  Future<Result<PotentialPayload>> potential() => guardResult(
    () async => PotentialPayload.decode(await _api.getPotential()),
  );

  @override
  Future<Result<TyphoonProbability>> probability() => guardResult(
    () async => TyphoonProbability.decode(await _api.getProbability()),
  );

  @override
  Future<Result<WarningPayload>> warning() =>
      guardResult(() async => WarningPayload.decode(await _api.getWarning()));

  @override
  Future<Result<List<int>>> history(TyphoonKind kind) => guardResult(
    () async => MeteorDecode.deltaSeconds(await _api.getList(kind)),
  );

  @override
  Future<Result<TrackPayload>> trackAt(int second) => guardResult(
    () async =>
        TrackPayload.fromJson(await _api.getAt(TyphoonKind.track, second)),
  );

  @override
  Future<Result<PotentialPayload>> potentialAt(int second) => guardResult(
    () async => PotentialPayload.decode(
      await _api.getAt(TyphoonKind.potential, second),
    ),
  );

  @override
  Future<Result<TyphoonProbability>> probabilityAt(int second) => guardResult(
    () async => TyphoonProbability.decode(
      await _api.getAt(TyphoonKind.probability, second),
    ),
  );

  @override
  Future<Result<WarningPayload>> warningAt(int second) => guardResult(
    () async =>
        WarningPayload.decode(await _api.getAt(TyphoonKind.warning, second)),
  );
}
