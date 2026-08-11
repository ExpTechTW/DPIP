/// [MeteorLightningRepository] backed by [MeteorSnapshotApi].
library;

import 'package:dpip/features/weather/data/meteor_snapshot_repository_impl.dart';
import 'package:dpip/features/weather/domain/lightning_snapshot.dart';
import 'package:dpip/features/weather/domain/meteor_lightning_repository.dart';

/// Maps the datasource's raw JSON to domain models, converting transport/decode
/// errors to typed failures via [guardResult].
class MeteorLightningRepositoryImpl
    extends MeteorSnapshotRepositoryImpl<LightningSnapshot>
    implements MeteorLightningRepository {
  const MeteorLightningRepositoryImpl(super.api);

  @override
  LightningSnapshot decodeSnapshot(Map<String, dynamic> json) =>
      LightningSnapshot.decode(json);
}
