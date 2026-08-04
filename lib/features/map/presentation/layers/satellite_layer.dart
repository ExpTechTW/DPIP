import 'package:dpip/features/weather/domain/satellite_repository.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/map_style.dart';
import 'package:dpip/shared/map/raster_timeline_layer.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// The satellite IR cloud (衛星雲圖) raster overlay.
///
/// Scrubbing behaviour is [RasterTimelineLayer]'s; what is specific here is the
/// black boundary outline. The imagery is fully opaque and mostly white, so the
/// base style's light borders vanish underneath it — this layer draws its own
/// dark ones while it is active.
class SatelliteMapLayer extends RasterTimelineLayer {
  SatelliteMapLayer(SatelliteRepository super.repository);

  @override
  String get id => 'satellite';

  @override
  String label(BuildContext context) =>
      AppLocalizations.of(context).mapLayerSatellite;

  @override
  IconData get icon => Icons.satellite_alt_outlined;

  /// Fully opaque — IR brightness is the whole signal; blending it with the
  /// basemap would misread as thinner cloud.
  @override
  double get opacity => 1;

  @override
  Future<void> onAttached(MapLibreMapController controller) async {
    try {
      for (final (layerId, sourceLayer) in const [
        (satelliteGlobalOutlineLayerId, 'global'),
        (satelliteCountyOutlineLayerId, 'city'),
      ]) {
        await controller.addLineLayer(
          'exptech',
          layerId,
          const LineLayerProperties(
            lineColor: satelliteOutlineColor,
            lineWidth: 1.0,
          ),
          sourceLayer: sourceLayer,
          enableInteraction: false,
        );
      }
    } catch (_) {
      // Half-added outlines are worse than none — roll back and carry on.
      await onDetached(controller);
    }
  }

  @override
  Future<void> onDetached(MapLibreMapController controller) async {
    for (final layerId in const [
      satelliteCountyOutlineLayerId,
      satelliteGlobalOutlineLayerId,
    ]) {
      try {
        await controller.removeLayer(layerId);
      } catch (_) {}
    }
  }

  @override
  Widget buildLegend(BuildContext context) => const SizedBox.shrink();
}
