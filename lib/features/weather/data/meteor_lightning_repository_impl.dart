/// [MeteorLightningRepository] backed by [MeteorLightningApi].
library;

import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/network/api_exception.dart';
import 'package:dpip/core/network/meteor_decode.dart';
import 'package:dpip/features/weather/data/meteor_lightning_api.dart';
import 'package:dpip/features/weather/domain/lightning_snapshot.dart';
import 'package:dpip/features/weather/domain/meteor_lightning_repository.dart';

/// Maps the datasource's raw JSON to domain models, converting transport/decode
/// errors to typed failures via [guardResult].
class MeteorLightningRepositoryImpl implements MeteorLightningRepository {
  const MeteorLightningRepositoryImpl(this._api);

  final MeteorLightningApi _api;

  @override
  Future<Result<LightningSnapshot>> latest() =>
      guardResult(() async => LightningSnapshot.decode(await _api.getLatest()));

  @override
  Future<Result<List<int>>> history() =>
      guardResult(() async => MeteorDecode.deltaSeconds(await _api.getList()));

  @override
  Future<Result<LightningSnapshot>> at(int second) => guardResult(
    () async => LightningSnapshot.decode(await _api.getAt(second)),
  );
}
