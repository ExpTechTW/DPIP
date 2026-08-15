import 'package:dpip/core/a11y/color_vision.dart';
import 'package:dpip/features/map/presentation/layers/admin_outline_chrome.dart';
import 'package:dpip/features/map/presentation/layers/radar_scan_range.dart';
import 'package:dpip/features/map/presentation/layers/scan_range_overlay_chrome.dart';
import 'package:dpip/features/map/presentation/widgets/radar_overlay_menu.dart';
import 'package:dpip/features/weather/domain/radar_repository.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/map_style.dart' show townLabelLayerId;
import 'package:dpip/shared/map/raster_timeline_layer.dart';
import 'package:dpip/shared/widgets/map_color_legend.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// The radar echo (雷達回波) raster overlay.
///
/// Everything about scrubbing — the preload ring, tile warming, scoped cancels —
/// lives in [RasterTimelineLayer]; this supplies only radar's identity, its
/// opacity, the dBZ colour key, and the three overlays its options chip toggles.
///
/// The echo is mounted **above** the base style's borders (see
/// [rasterBelowLayerId]) and the borders are put back on top as switchable
/// layers ([ScanRangeOverlayChrome]). That is what makes them switchable at
/// all: while they came through from underneath there was no way to get an
/// uninterrupted raster.
class RadarMapLayer extends RasterTimelineLayer
    with AdminOutlineChrome, ScanRangeOverlayChrome {
  RadarMapLayer(RadarRepository super.repository);

  /// The radar composite's own ids — the default geometry and layer naming.
  @override
  String get scanRangeSourceId => RadarScanRange.sourceId;

  @override
  String get scanRangeLayerId => RadarScanRange.outlineLayerId;

  @override
  String get scanRangeColor => _rangeColor;

  /// Blue-grey: distinct from every dBZ colour in the scale below, so the
  /// outline is never mistaken for an echo.
  ///
  /// A vector line this app draws, so it *is* colour-vision corrected — unlike
  /// the dBZ scale below. A getter rather than a `const` because the correction
  /// depends on the current setting.
  static String get _rangeColor => '#78909C'.vision;

  /// The echo covers the base style's borders instead of passing under them —
  /// this layer supplies its own on top, and showing both would draw every
  /// boundary twice at two weights. The raster still anchors **under** the
  /// township-name labels, so a place name is never buried under the echo;
  /// the admin borders this layer redraws sit between the two (they mount
  /// after the raster, closer to the labels — see [AdminOutline]).
  @override
  String? get rasterBelowLayerId => townLabelLayerId;

  @override
  Widget buildTopTrailingChrome(
    BuildContext context, {
    required ValueListenable<bool> showTownLabels,
    required ValueChanged<bool> onShowTownLabelsChanged,
    required ValueListenable<bool> showTerrain,
    required ValueChanged<bool> onShowTerrainChanged,
    required Future<void> Function() onReloadActive,
  }) => RadarOverlayMenu(
    layer: this,
    showTownLabels: showTownLabels,
    onShowTownLabelsChanged: onShowTownLabelsChanged,
    showTerrain: showTerrain,
    onShowTerrainChanged: onShowTerrainChanged,
  );

  @override
  String get id => 'radar';

  @override
  String label(BuildContext context) =>
      AppLocalizations.of(context).mapLayerRadar;

  @override
  IconData get icon => Icons.radar_outlined;

  /// Slightly translucent so terrain and boundaries read through the echo.
  @override
  double get opacity => 0.85;

  /// The dBZ key — CWA's own echo palette.
  ///
  /// **Deliberately not colour-vision corrected.** The echo is a
  /// server-rendered raster and MapLibre's raster layer exposes no colour
  /// matrix, so those pixels keep their original hues; correcting the key would
  /// leave it naming colours that are nowhere on the map, which is worse than a
  /// key that is merely hard to read. Every stop is therefore marked
  /// [ColorVisionFilter.rasterExemptHex] rather than left looking overlooked.
  static final List<ColorStop> _dbzStops = [
    (0, ColorVisionFilter.rasterExemptHex('#00FFFF')),
    (5, ColorVisionFilter.rasterExemptHex('#00A3FF')),
    (10, ColorVisionFilter.rasterExemptHex('#005BFF')),
    (15, ColorVisionFilter.rasterExemptHex('#0000FF')),
    (20, ColorVisionFilter.rasterExemptHex('#00D300')),
    (25, ColorVisionFilter.rasterExemptHex('#00A000')),
    (30, ColorVisionFilter.rasterExemptHex('#CCEA00')),
    (35, ColorVisionFilter.rasterExemptHex('#FFD300')),
    (40, ColorVisionFilter.rasterExemptHex('#FF8800')),
    (45, ColorVisionFilter.rasterExemptHex('#FF1800')),
    (50, ColorVisionFilter.rasterExemptHex('#D30000')),
    (55, ColorVisionFilter.rasterExemptHex('#A00000')),
    (60, ColorVisionFilter.rasterExemptHex('#EA00CC')),
    (65, ColorVisionFilter.rasterExemptHex('#9600FF')),
  ];

  @override
  Widget buildLegend(BuildContext context) => ListenableBuilder(
    listenable: chromeListenable,
    builder: (context, _) {
      return MapLegendCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ColorScaleLegend(unit: 'dBZ', stops: _dbzStops),
            chromeLegendSection(context),
          ],
        ),
      );
    },
  );
}
