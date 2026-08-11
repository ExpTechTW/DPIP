import 'package:dpip/features/weather/domain/satellite_channel.dart';
import 'package:dpip/features/weather/domain/satellite_repository.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/map_style.dart';
import 'package:dpip/shared/map/raster_timeline_layer.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// The satellite cloud (衛星雲圖) raster overlay for one [SatelliteChannel] —
/// a raw AHI band or a derived product, keyed by the channel's `?channel=`.
///
/// Scrubbing behaviour is [RasterTimelineLayer]'s; what is specific here is the
/// black boundary outline. The imagery is fully opaque and mostly white, so the
/// base style's light borders vanish underneath it — this layer draws its own
/// dark ones while it is active.
class SatelliteMapLayer extends RasterTimelineLayer {
  SatelliteMapLayer(
    SatelliteRepository super.repository, {
    required this.channel,
  });

  /// Which view of Himawari this layer renders — sets both the tile URL's
  /// `?channel=` and the picker label.
  final SatelliteChannel channel;

  /// The plain IR (B13) layer keeps the historical `satellite` id — the
  /// default-layer preference and any saved layer order predate the
  /// multi-channel split and name this exact layer. Every other channel gets a
  /// `satellite-<channel>` id namespaced off it.
  @override
  String get id => channel == SatelliteChannel.irClean
      ? 'satellite'
      : 'satellite-${channel.key}';

  @override
  String label(BuildContext context) =>
      satelliteChannelLabel(channel, AppLocalizations.of(context));

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

/// Localised picker label for a satellite [channel] — the `ひまわり <name>`(B##)
/// convention the layer names share.
String satelliteChannelLabel(SatelliteChannel channel, AppLocalizations l10n) =>
    switch (channel) {
      SatelliteChannel.visibleBlue => l10n.mapLayerSatelliteB01,
      SatelliteChannel.visibleGreen => l10n.mapLayerSatelliteB02,
      SatelliteChannel.visibleRed => l10n.mapLayerSatelliteB03,
      SatelliteChannel.nir => l10n.mapLayerSatelliteB04,
      SatelliteChannel.nirPhase => l10n.mapLayerSatelliteB05,
      SatelliteChannel.nirCloud => l10n.mapLayerSatelliteB06,
      SatelliteChannel.swir => l10n.mapLayerSatelliteB07,
      SatelliteChannel.wvUpper => l10n.mapLayerSatelliteB08,
      SatelliteChannel.wvMid => l10n.mapLayerSatelliteB09,
      SatelliteChannel.wvLow => l10n.mapLayerSatelliteB10,
      SatelliteChannel.so2 => l10n.mapLayerSatelliteB11,
      SatelliteChannel.ozone => l10n.mapLayerSatelliteB12,
      SatelliteChannel.irClean => l10n.mapLayerSatelliteB13,
      SatelliteChannel.irLong => l10n.mapLayerSatelliteB14,
      SatelliteChannel.irLong2 => l10n.mapLayerSatelliteB15,
      SatelliteChannel.co2 => l10n.mapLayerSatelliteB16,
      SatelliteChannel.truecolor => l10n.mapLayerSatelliteTruecolor,
      SatelliteChannel.naturalcolor => l10n.mapLayerSatelliteNaturalcolor,
      SatelliteChannel.ash => l10n.mapLayerSatelliteAsh,
      SatelliteChannel.dust => l10n.mapLayerSatelliteDust,
      SatelliteChannel.airmass => l10n.mapLayerSatelliteAirmass,
      SatelliteChannel.nightmicrophysics =>
        l10n.mapLayerSatelliteNightmicrophysics,
      SatelliteChannel.watervapor => l10n.mapLayerSatelliteWatervapor,
      SatelliteChannel.btdSplit => l10n.mapLayerSatelliteBtdSplit,
      SatelliteChannel.btdFog => l10n.mapLayerSatelliteBtdFog,
      SatelliteChannel.btdWvirw => l10n.mapLayerSatelliteBtdWvirw,
      SatelliteChannel.btdSo2 => l10n.mapLayerSatelliteBtdSo2,
      SatelliteChannel.btdCo2 => l10n.mapLayerSatelliteBtdCo2,
      SatelliteChannel.btdOzone => l10n.mapLayerSatelliteBtdOzone,
      SatelliteChannel.cloudtop => l10n.mapLayerSatelliteCloudtop,
      SatelliteChannel.cloudmask => l10n.mapLayerSatelliteCloudmask,
      SatelliteChannel.sst => l10n.mapLayerSatelliteSst,
      SatelliteChannel.ndvi => l10n.mapLayerSatelliteNdvi,
      SatelliteChannel.ndwi => l10n.mapLayerSatelliteNdwi,
      SatelliteChannel.mndwi => l10n.mapLayerSatelliteMndwi,
    };
