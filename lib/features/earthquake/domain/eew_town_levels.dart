/// Each township's estimated shaking level for an EEW — the wash the
/// 強震監視器 paints over the island while an alert is up.
///
/// From the ML v1 intensity model when it is on this device (the level
/// TREM-Lite and the server give the same township for the same quake), and
/// from the attenuation formula ([EewEstimator.areaPga]) until then: the model
/// is fetched the first time the monitor opens, and an alert that arrives
/// before it has must still colour the map.
library;

import 'package:dpip/core/models/lat_lng.dart';
import 'package:dpip/features/earthquake/domain/eew.dart';
import 'package:dpip/features/earthquake/domain/eew_estimator.dart';
import 'package:dpip/shared/seismic/intensity.dart';

/// The ML v1 model, loaded on demand.
abstract interface class MlIntensityEstimator {
  /// Whether [townLevels] answers from the model.
  bool get ready;

  /// Makes the model ready: loads the copy kept on this device, downloading it
  /// first if there is none. Safe to call again and again — a load already
  /// under way is joined, and a failed download is not retried for a minute.
  /// Resolves to [ready].
  Future<bool> prepare();

  /// Each township's level (0–9) by code, or null while the model is not
  /// ready (or could not score this quake).
  Future<Map<String, int>?> townLevels(EewInfo info);
}

/// [info]'s township levels — the model's, or the formula's over [centroids]
/// while the model is unavailable. [fromModel] says which.
Future<({Map<String, int> levels, bool fromModel})> eewTownLevels(
  EewInfo info, {
  required MlIntensityEstimator? model,
  required Map<String, LatLng> centroids,
}) async {
  final levels = await model?.townLevels(info);
  if (levels != null) return (levels: levels, fromModel: true);
  final estimate = EewEstimator.areaPga(
    epicenter: info.latlng,
    depth: info.depth,
    mag: info.magnitude,
    regionCentroids: centroids,
  );
  return (
    levels: {
      for (final entry in estimate.regions.entries)
        entry.key: Intensity.toScale(entry.value.i),
    },
    fromModel: false,
  );
}
