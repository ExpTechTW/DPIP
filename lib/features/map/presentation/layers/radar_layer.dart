import 'dart:async';

import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/shared/map/admin_outline.dart';
import 'package:dpip/features/map/presentation/layers/radar_scan_range.dart';
import 'package:dpip/features/map/presentation/widgets/radar_overlay_menu.dart';
import 'package:dpip/features/weather/domain/radar_repository.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/map_style.dart';
import 'package:dpip/shared/map/raster_timeline_layer.dart';
import 'package:dpip/shared/widgets/map_color_legend.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// The radar echo (雷達回波) raster overlay.
///
/// Everything about scrubbing — the preload ring, tile warming, scoped cancels —
/// lives in [RasterTimelineLayer]; this supplies only radar's identity, its
/// opacity, the dBZ colour key, and the three overlays its options chip toggles.
///
/// The echo is mounted **above** the base style's borders (see
/// [rasterBelowLayerId]) and the borders are put back on top as switchable
/// layers. That is what makes them switchable at all: while they came through
/// from underneath there was no way to get an uninterrupted raster.
///
/// All three default **on**, because each answers a question the echo alone
/// cannot — where the composite stops observing, and which county or township
/// a cell is over.
class RadarMapLayer extends RasterTimelineLayer {
  RadarMapLayer(RadarRepository super.repository);

  /// Whether the composite's observed area is outlined.
  ///
  /// On by default: outside it, blank means *not observed*, not *no rain*, and
  /// on a disaster-prevention map that distinction should not have to be
  /// discovered in a menu.
  ///
  /// Lives on the layer, not in settings: it is a property of *this map view*,
  /// the same way the typhoon overlays are, so it is reachable from the map's
  /// own options chip and resets with the session.
  final ValueNotifier<bool> showScanRange = ValueNotifier(true);

  /// Whether 縣市 borders are redrawn above the echo.
  final ValueNotifier<bool> showCountyOutline = ValueNotifier(true);

  /// Whether 鄉鎮 borders are redrawn above the echo. Separate from the county
  /// toggle: they are different questions ("which city" vs "which township"),
  /// and the finer mesh is the first thing a reader wants gone when studying a
  /// single cell.
  final ValueNotifier<bool> showTownOutline = ValueNotifier(true);

  MapLibreMapController? _controller;
  bool _rangeShown = false;
  final Set<AdminBoundary> _boundariesShown = {};

  /// Blue-grey: distinct from every dBZ colour in the scale below, so the
  /// outline is never mistaken for an echo.
  static const String _rangeColor = '#78909C';

  /// The echo covers the base style's borders instead of passing under them —
  /// this layer supplies its own on top, and showing both would draw every
  /// boundary twice at two weights.
  @override
  String? get rasterBelowLayerId => null;

  /// Turns the coverage outline on/off, applying it to a live map immediately.
  void setShowScanRange(bool value) {
    if (showScanRange.value == value) return;
    showScanRange.value = value;
    unawaited(_syncRange());
  }

  /// Turns the 縣市 borders on/off, applying it to a live map immediately.
  void setShowCountyOutline(bool value) {
    if (showCountyOutline.value == value) return;
    showCountyOutline.value = value;
    unawaited(_syncBoundaries());
  }

  /// Turns the 鄉鎮 borders on/off, applying it to a live map immediately.
  void setShowTownOutline(bool value) {
    if (showTownOutline.value == value) return;
    showTownOutline.value = value;
    unawaited(_syncBoundaries());
  }

  /// Which boundary sets should currently be on the map.
  Set<AdminBoundary> get _wantedBoundaries => {
    // Town first so a later insert of county lands above it: the coarse frame
    // should win where the two run together along a coastline.
    if (showTownOutline.value) AdminBoundary.town,
    if (showCountyOutline.value) AdminBoundary.county,
  };

  @override
  Future<void> onAttached(MapLibreMapController controller) async {
    _controller = controller;
    await _syncRange();
    // Borders last, so they end up above the scan range as well as the raster —
    // the range is a dashed hint, the borders are the reference frame.
    await _syncBoundaries();
  }

  @override
  Future<void> onDetached(MapLibreMapController controller) async {
    _controller = null;
    // Only undo what was actually added — tearing down an overlay that was
    // never mounted issues removals the map never asked for.
    for (final boundary in _boundariesShown.toList()) {
      _boundariesShown.remove(boundary);
      await AdminOutline.remove(controller, boundary);
    }
    if (_rangeShown) {
      _rangeShown = false;
      await RadarScanRange.remove(controller);
    }
  }

  /// Adds or removes the coverage outline to match [showScanRange].
  Future<void> _syncRange() async {
    final controller = _controller;
    if (controller == null) return;

    final wanted = showScanRange.value;
    if (wanted == _rangeShown) return;
    _rangeShown = wanted;

    try {
      if (wanted) {
        await RadarScanRange.add(
          controller,
          outlineColor: _rangeColor,
          belowLayerId: outlineLayerId,
        );
      } else {
        await RadarScanRange.remove(controller);
      }
    } catch (error, stackTrace) {
      // A style reload can race the toggle; the next sync recovers.
      _rangeShown = !wanted;
      Log.handle(error, stackTrace, 'Failed to sync the radar scan range');
    }
  }

  /// Brings the drawn boundary sets in line with the toggles.
  Future<void> _syncBoundaries() async {
    final controller = _controller;
    if (controller == null) return;

    final wanted = _wantedBoundaries;
    try {
      for (final boundary in AdminBoundary.values) {
        final shown = _boundariesShown.contains(boundary);
        if (wanted.contains(boundary) == shown) continue;
        if (shown) {
          _boundariesShown.remove(boundary);
          await AdminOutline.remove(controller, boundary);
        } else {
          _boundariesShown.add(boundary);
          await AdminOutline.add(controller, boundary);
        }
      }
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'Failed to sync the radar admin outlines');
    }
  }

  @override
  void onStyleReset() {
    // The style reload dropped every runtime layer, these included; forget them
    // so the next attach re-adds instead of no-oping on stale state.
    _rangeShown = false;
    _boundariesShown.clear();
    super.onStyleReset();
  }

  @override
  Widget buildTopTrailingChrome(BuildContext context) =>
      RadarOverlayMenu(layer: this);

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
    listenable: Listenable.merge([
      showScanRange,
      showCountyOutline,
      showTownOutline,
    ]),
    builder: (context, _) {
      final l10n = AppLocalizations.of(context);
      // The overlays are switchable, so the key has to follow them: a legend
      // naming a line that is not on the map is worse than no legend.
      final overlays = <SymbolLegendItem>[
        if (showScanRange.value)
          SymbolLegendItem(
            swatch: const LineSwatch(
              color: Color(0xFF78909C),
              width: 1.5,
              opacity: 0.7,
              dash: [3, 2],
            ),
            label: l10n.radarScanRange,
          ),
        if (showCountyOutline.value)
          SymbolLegendItem(
            swatch: LineSwatch(
              color: const Color(0xFFFFFFFF),
              width: AdminBoundary.county.lineWidth,
              opacity: AdminBoundary.county.lineOpacity,
              casingColor: const Color(0xFF000000),
              casingWidth: AdminBoundary.county.casingWidth,
              casingOpacity: AdminBoundary.county.casingOpacity,
            ),
            label: l10n.radarCountyOutline,
          ),
        if (showTownOutline.value)
          SymbolLegendItem(
            swatch: LineSwatch(
              color: const Color(0xFFFFFFFF),
              width: AdminBoundary.town.lineWidth,
              opacity: AdminBoundary.town.lineOpacity,
              casingColor: const Color(0xFF000000),
              casingWidth: AdminBoundary.town.casingWidth,
              casingOpacity: AdminBoundary.town.casingOpacity,
            ),
            label: l10n.radarTownOutline,
          ),
      ];

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
            if (overlays.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Divider(
                height: 1,
                color: Theme.of(
                  context,
                ).colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(height: AppSpacing.sm),
              SymbolLegend(items: overlays),
            ],
          ],
        ),
      );
    },
  );
}
