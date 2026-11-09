/// Where the monitor's township colours come from: the model when it can
/// answer, the attenuation formula whenever it cannot.
///
/// The fallback is the safety property. The model is fetched on first use and
/// may be missing, still loading, or fail to score one quake — and in every
/// one of those cases an alert must still colour the island rather than leave
/// it blank.
///
/// The legend's ceiling is the other property: whatever the wash paints has to
/// have a row beside it, and the wash is scored here rather than taken from the
/// warning's reported maximum.
library;

import 'package:dpip/core/models/lat_lng.dart';
import 'package:dpip/features/earthquake/domain/eew.dart';
import 'package:dpip/features/earthquake/domain/eew_town_levels.dart';
import 'package:flutter_test/flutter_test.dart';

class _Model implements MlIntensityEstimator {
  _Model(this.answer);

  final Map<String, int>? answer;

  @override
  bool get ready => answer != null;

  @override
  Future<bool> prepare() async => ready;

  @override
  Future<Map<String, int>?> townLevels(EewInfo info) async => answer;
}

const _quake = EewInfo(
  time: 0,
  longitude: 121.6,
  latitude: 23.9,
  depth: 10,
  magnitude: 6.5,
  location: '',
  max: 6,
);

const _centroids = {'970': LatLng(23.98, 121.6), '100': LatLng(25.04, 121.52)};

void main() {
  test('the model\'s levels when it answers', () async {
    final estimate = await eewTownLevels(
      _quake,
      model: _Model({'970': 7}),
      centroids: _centroids,
    );

    expect(estimate.fromModel, isTrue);
    expect(estimate.levels, {'970': 7});
  });

  test('the formula when the model cannot answer, or there is none', () async {
    for (final model in [_Model(null), null]) {
      final estimate = await eewTownLevels(
        _quake,
        model: model,
        centroids: _centroids,
      );

      expect(estimate.fromModel, isFalse);
      expect(estimate.levels.keys, containsAll(['970', '100']));
      expect(estimate.levels['970']!, greaterThan(estimate.levels['100']!));
    }
  });

  test('the highest painted level ignores townships left transparent', () {
    expect(highestPaintedLevel(const {}), isNull);
    expect(highestPaintedLevel(const {'970': 0, '100': 0}), isNull);
    expect(highestPaintedLevel(const {'970': 7, '100': 3, '630': 0}), 7);
  });

  test('the legend ceiling covers every colour the wash paints', () {
    expect(legendCeiling(reportedMax: null, paintedMax: null), isNull);
    expect(legendCeiling(reportedMax: 5, paintedMax: null), 5);
    expect(legendCeiling(reportedMax: null, paintedMax: 6), 6);
    // The wash scoring a township above the warning's own maximum is the case
    // this exists for: the map would otherwise paint a colour with no row.
    expect(legendCeiling(reportedMax: 5, paintedMax: 6), 6);
    expect(legendCeiling(reportedMax: 6, paintedMax: 5), 6);
  });
}
