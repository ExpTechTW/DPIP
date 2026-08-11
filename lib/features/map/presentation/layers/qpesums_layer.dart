import 'package:dpip/features/map/presentation/layers/admin_outline_chrome.dart';
import 'package:dpip/features/map/presentation/layers/scan_range_overlay_chrome.dart';
import 'package:dpip/features/map/presentation/widgets/scan_range_overlay_menu.dart';
import 'package:dpip/features/weather/domain/qpesums_repository.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/raster_timeline_layer.dart';
import 'package:dpip/shared/widgets/map_color_legend.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// The QPESUMS next-1-hour precipitation forecast (未來一小時降水預報) raster
/// overlay.
///
/// Everything about scrubbing lives in [RasterTimelineLayer]; this supplies
/// only the layer's identity, its opacity, and the QPESUMS hourly-rate colour
/// key. Frame ids are Unix milliseconds, which [parseFrameTime] already reads.
///
/// The forecast covers the same grid the radar composite observes, so it shares
/// the radar's scan-range geometry — and, like radar, it redraws its own
/// scan-range outline plus county/town borders **over** the raster
/// ([ScanRangeOverlayChrome]), switchable from its options chip.
class QpesumsMapLayer extends RasterTimelineLayer
    with AdminOutlineChrome, ScanRangeOverlayChrome {
  QpesumsMapLayer(QpesumsRepository super.repository);

  /// Distinct from radar's ids: both layers can be on the map at once, and each
  /// draws its own outline instead of clashing over one source/layer pair.
  @override
  String get scanRangeSourceId => 'qpesums-scan-range';

  @override
  String get scanRangeLayerId => 'qpesums-scan-range-outline';

  @override
  String get scanRangeColor => '#78909C';

  /// The forecast covers the base style's borders, so this layer supplies its
  /// own on top — same reasoning as radar, and the same chrome.
  @override
  String? get rasterBelowLayerId => null;

  @override
  String get id => 'qpesums';

  @override
  String label(BuildContext context) =>
      AppLocalizations.of(context).mapLayerQpesums;

  @override
  IconData get icon => Icons.cloud_outlined;

  /// Slightly translucent so terrain and boundaries read through the forecast.
  @override
  double get opacity => 0.85;

  /// The frame times are forecast valid times, not observations — the timeline
  /// caption must say so instead of the shared "observed" default.
  @override
  String timelineCaption(BuildContext context) =>
      AppLocalizations.of(context).mapTimelineForecast;

  @override
  Widget buildTopTrailingChrome(
    BuildContext context, {
    required ValueListenable<bool> showTownLabels,
    required ValueChanged<bool> onShowTownLabelsChanged,
    required Future<void> Function() onReloadActive,
  }) => ScanRangeOverlayMenu(
    layer: this,
    tooltip: AppLocalizations.of(context).qpesumsOverlayMenuTooltip,
    showTownLabels: showTownLabels,
    onShowTownLabelsChanged: onShowTownLabelsChanged,
  );

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
              unit: 'mm/h',
              stops: [
                (1, '#9CFCFF'),
                (2, '#03C8FF'),
                (6, '#059BFF'),
                (10, '#0165FF'),
                (15, '#329400'),
                (20, '#38FF00'),
                (30, '#FFFB00'),
                (40, '#FFC800'),
                (50, '#FF9600'),
                (70, '#FF0000'),
                (90, '#CC0000'),
                (110, '#A00000'),
                (130, '#96009B'),
                (150, '#C900CC'),
                (200, '#FF00F0'),
                (300, '#FFC8FF'),
              ],
            ),
            chromeLegendSection(context),
          ],
        ),
      );
    },
  );
}
