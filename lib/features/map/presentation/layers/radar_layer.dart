import 'package:dpip/features/map/presentation/layers/radar_scan_range.dart';
import 'package:dpip/features/map/presentation/layers/scan_range_overlay_chrome.dart';
import 'package:dpip/features/map/presentation/widgets/radar_overlay_menu.dart';
import 'package:dpip/features/weather/domain/radar_repository.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
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
class RadarMapLayer extends RasterTimelineLayer with ScanRangeOverlayChrome {
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
  static const String _rangeColor = '#78909C';

  /// The echo covers the base style's borders instead of passing under them —
  /// this layer supplies its own on top, and showing both would draw every
  /// boundary twice at two weights.
  @override
  String? get rasterBelowLayerId => null;

  @override
  Widget buildTopTrailingChrome(
    BuildContext context, {
    required ValueListenable<bool> showTownLabels,
    required ValueChanged<bool> onShowTownLabelsChanged,
    required Future<void> Function() onReloadActive,
  }) => RadarOverlayMenu(
    layer: this,
    showTownLabels: showTownLabels,
    onShowTownLabelsChanged: onShowTownLabelsChanged,
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

  @override
  Widget buildLegend(BuildContext context) => ListenableBuilder(
    listenable: chromeListenable,
    builder: (context, _) {
      return MapLegendCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ColorScaleLegend(
              unit: 'dBZ',
              stops: [
                (0, '#00FFFF'),
                (5, '#00A3FF'),
                (10, '#005BFF'),
                (15, '#0000FF'),
                (20, '#00D300'),
                (25, '#00A000'),
                (30, '#CCEA00'),
                (35, '#FFD300'),
                (40, '#FF8800'),
                (45, '#FF1800'),
                (50, '#D30000'),
                (55, '#A00000'),
                (60, '#EA00CC'),
                (65, '#9600FF'),
              ],
            ),
            chromeLegendSection(context),
          ],
        ),
      );
    },
  );
}
