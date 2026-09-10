/// The lightning (閃電) timeline [MapLayer] — scrubbable strike snapshots.
///
/// Identity and timeline plumbing only: every mark on the map is drawn by
/// [LightningStrikeOverlay], which the radar echo's lightning option mounts
/// too, so the two surfaces cannot drift into two different-looking keys.
library;

import 'package:dpip/core/error/result.dart';
import 'package:dpip/features/map/presentation/layers/lightning_strike_overlay.dart';
import 'package:dpip/features/weather/domain/meteor_lightning_repository.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/map_layer.dart';
import 'package:dpip/shared/widgets/map_color_legend.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

class LightningMapLayer with MapLayerDefaults implements MapLayer {
  LightningMapLayer(MeteorLightningRepository repository)
    : _overlay = LightningStrikeOverlay(repository);

  final LightningStrikeOverlay _overlay;

  @override
  String get id => 'lightning';

  @override
  IconData get icon => Icons.bolt_outlined;

  @override
  String label(BuildContext context) =>
      AppLocalizations.of(context).mapLayerLightning;

  @override
  bool get usesTimeline => true;

  @override
  double get bottomChromeFraction => 0;

  @override
  Widget buildLegend(BuildContext context) => MapLegendCard(
    child: SymbolLegend(items: LightningStrikeOverlay.legendItems(context)),
  );

  @override
  Future<Result<List<MapFrame>>> frames() async {
    final result = await _overlay.history();
    return result.map(
      (secs) => [
        for (final sec in secs)
          MapFrame(
            id: '$sec',
            time: DateTime.fromMillisecondsSinceEpoch(sec * 1000, isUtc: true),
          ),
      ],
    );
  }

  @override
  Future<void> prepare(
    MapLibreMapController controller,
    List<MapFrame> frames,
  ) => _overlay.prepare(controller, [for (final frame in frames) frame.id]);

  @override
  Future<void> show(
    MapLibreMapController controller,
    MapFrame frame, {
    bool scrubbing = false,
  }) => _overlay.show(controller, frame.id, scrubbing: scrubbing);

  @override
  Future<void> clear(MapLibreMapController controller) =>
      _overlay.clear(controller);

  @override
  void onStyleReset() => _overlay.onStyleReset();
}
