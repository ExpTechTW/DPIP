import 'package:dpip/core/a11y/color_vision.dart';
import 'package:dpip/core/settings/map_reference_outline_controller.dart';
import 'package:dpip/features/map/presentation/layers/admin_outline_chrome.dart';
import 'package:dpip/features/map/presentation/layers/qpesums_scan_range.dart';
import 'package:dpip/features/map/presentation/layers/scan_range_overlay_chrome.dart';
import 'package:dpip/features/map/presentation/widgets/scan_range_overlay_menu.dart';
import 'package:dpip/features/weather/domain/qpesums_repository.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/map_style.dart' show townLabelLayerId;
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
/// Like radar, it redraws its own coverage outline plus county/town borders
/// **over** the raster ([ScanRangeOverlayChrome]), switchable from its options
/// chip — but not with radar's geometry: the forecast is published over a plain
/// rectangle ([QpesumsScanRange]), while the composite the radars observe is a
/// union of range circles.
class QpesumsMapLayer extends RasterTimelineLayer
    with AdminOutlineChrome, ScanRangeOverlayChrome {
  QpesumsMapLayer(QpesumsRepository super.repository, this.referenceOutline);

  @override
  final MapReferenceOutlineController referenceOutline;

  /// Distinct from radar's ids: both layers can be on the map at once, and each
  /// draws its own outline instead of clashing over one source/layer pair.
  @override
  String get scanRangeSourceId => QpesumsScanRange.sourceId;

  @override
  String get scanRangeLayerId => QpesumsScanRange.outlineLayerId;

  /// The forecast grid's own rectangle, not the radar composite's circles.
  @override
  Map<String, dynamic> get scanRangeGeoJson => QpesumsScanRange.geoJson();

  @override
  String get scanRangeColor => '#78909C'.vision;

  /// The forecast covers the base style's borders, so this layer supplies its
  /// own on top — same reasoning as radar, and the same chrome. The raster
  /// still anchors **under** the township-name labels, so a place name is never
  /// buried under the forecast; the admin borders redraw between the two (they
  /// mount after the raster, closer to the labels — see [AdminOutline]).
  @override
  String? get rasterBelowLayerId => townLabelLayerId;

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

  /// Each frame is a one-hour forecast window: the tile at 21:00 estimates
  /// rain for 21:00–22:00, so the timeline shows that range rather than a bare
  /// instant the user could read as a point measurement.
  @override
  Duration? get framePeriod => const Duration(hours: 1);

  @override
  Widget buildTopTrailingChrome(
    BuildContext context, {
    required ValueListenable<bool> showTownLabels,
    required ValueChanged<bool> onShowTownLabelsChanged,
    required ValueListenable<bool> showTerrain,
    required ValueChanged<bool> onShowTerrainChanged,
    required Future<void> Function() onReloadActive,
  }) => ScanRangeOverlayMenu(
    layer: this,
    tooltip: AppLocalizations.of(context).qpesumsOverlayMenuTooltip,
    showTownLabels: showTownLabels,
    onShowTownLabelsChanged: onShowTownLabelsChanged,
    showTerrain: showTerrain,
    onShowTerrainChanged: onShowTerrainChanged,
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
