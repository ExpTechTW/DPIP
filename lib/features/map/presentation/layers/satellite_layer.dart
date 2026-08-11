import 'dart:async';

import 'package:dpip/features/map/presentation/widgets/satellite_legend.dart';
import 'package:dpip/features/map/presentation/widgets/satellite_style_menu.dart';
import 'package:dpip/features/weather/domain/satellite_channel.dart';
import 'package:dpip/features/weather/domain/satellite_repository.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/map_style.dart';
import 'package:dpip/shared/map/raster_timeline_layer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// The satellite cloud (衛星雲圖) raster overlay for one [SatelliteChannel] —
/// a raw AHI band or a derived product, keyed by the channel's `?channel=`.
///
/// Scrubbing behaviour is [RasterTimelineLayer]'s; what is specific here is the
/// bright-yellow boundary outline and — for raw bands — a live colour [style]
/// switch (`?style=`), re-mounted through the scaffold's reload when it changes.
class SatelliteMapLayer extends RasterTimelineLayer {
  SatelliteMapLayer(
    SatelliteRepository super.repository, {
    required this.channel,
  });

  /// Which view of Himawari this layer renders — sets both the tile URL's
  /// `?channel=` and the picker label.
  final SatelliteChannel channel;

  /// Colour rendering of a raw band (JMA grayscale default); ignored for named
  /// products, which carry their own palette. Non-default ⇒ the settings chip
  /// shows its marker dot.
  final ValueNotifier<SatelliteStyle> style = ValueNotifier(
    SatelliteStyle.gray,
  );

  /// Switches [style] and re-mounts the layer so the map picks up the new
  /// `?style=` tiles. The reload is the scaffold's job ([onReloadActive]); a
  /// no-op for named-product channels, and for bands whose only rendering is
  /// grayscale ([SatelliteChannel.isThermal] bands alone take the temperature
  /// styles).
  void setStyle(
    SatelliteStyle value, {
    required Future<void> Function() onReloadActive,
  }) {
    if (!channel.isBand ||
        style.value == value ||
        (!channel.isThermal && value != SatelliteStyle.gray)) {
      return;
    }
    style.value = value;
    (source as SatelliteRepository).setStyle(value.key);
    unawaited(onReloadActive());
  }

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
  String? subtitle(BuildContext context) => channel.subtitle;

  @override
  IconData get icon => Icons.satellite_alt_outlined;

  /// Fully opaque — IR brightness is the whole signal; blending it with the
  /// basemap would misread as thinner cloud.
  @override
  double get opacity => 1;

  /// Thermal bands offer the colour-style menu (and the township-label
  /// toggle); everything else — named products and the reflectance bands
  /// (B01–B06, whose only rendering is grayscale) — has no style to pick and
  /// gets the scaffold's standalone labels menu instead.
  @override
  Widget buildTopTrailingChrome(
    BuildContext context, {
    required ValueListenable<bool> showTownLabels,
    required ValueChanged<bool> onShowTownLabelsChanged,
    required Future<void> Function() onReloadActive,
  }) {
    if (!channel.isBand || !channel.isThermal) return const SizedBox.shrink();
    return SatelliteStyleMenu(
      layer: this,
      onReloadActive: onReloadActive,
      showTownLabels: showTownLabels,
      onShowTownLabelsChanged: onShowTownLabelsChanged,
    );
  }

  @override
  Future<void> onAttached(MapLibreMapController controller) async {
    try {
      // Country/global edges + county frame in bright yellow, township mesh in
      // dark yellow — the hue set that stays legible on imagery which is
      // overall dark. Country + county share the same colour because both are
      // the "which administrative unit" frame.
      for (final (layerId, sourceLayer, color, width) in const [
        (satelliteGlobalOutlineLayerId, 'global', satelliteOutlineColor, 1.0),
        (satelliteCountyOutlineLayerId, 'city', satelliteOutlineColor, 1.0),
        (satelliteTownOutlineLayerId, 'town', satelliteTownOutlineColor, 0.7),
      ]) {
        await controller.addLineLayer(
          'exptech',
          layerId,
          LineLayerProperties(lineColor: color, lineWidth: width),
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
      satelliteTownOutlineLayerId,
      satelliteCountyOutlineLayerId,
      satelliteGlobalOutlineLayerId,
    ]) {
      try {
        await controller.removeLayer(layerId);
      } catch (_) {}
    }
  }

  @override
  Widget buildLegend(BuildContext context) =>
      SatelliteLegend(channel: channel, style: style);
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
