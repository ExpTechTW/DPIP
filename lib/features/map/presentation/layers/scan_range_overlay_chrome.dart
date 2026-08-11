/// Switchable reference chrome for a weather raster: the scan-range outline
/// plus the county and township borders, all redrawn **over** the raster.
library;

import 'dart:async';

import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/features/map/presentation/layers/radar_scan_range.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/color_hex.dart';
import 'package:dpip/shared/map/admin_outline.dart';
import 'package:dpip/shared/map/map_style.dart';
import 'package:dpip/shared/map/raster_timeline_layer.dart';
import 'package:dpip/shared/widgets/map_color_legend.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// The reference chrome a weather raster can sit over.
///
/// A full-saturation raster (radar echo, QPESUMS forecast) covers the base
/// style's borders exactly where the weather is worth looking at, so the layer
/// draws its own scan-range outline and admin borders **on top** of the raster,
/// each switchable. The three questions are independent — "where is this
/// observed", "which county", "which township" — so they are three toggles, and
/// all three ship **on**, because a blank area means *not observed*, not *no
/// rain*, and an unidentified county is one you cannot act on.
///
/// The geometry is the radar composite's ([RadarScanRange]) for every consumer:
/// QPESUMS forecasts the same grid the radars observe, so its coverage is the
/// same union of range circles. Only the ids differ, so a map showing radar and
/// QPESUMS at once draws two outlines instead of clashing over one.
mixin ScanRangeOverlayChrome on RasterTimelineLayer {
  /// Whether the observed area is outlined. On by default — see the class doc.
  final ValueNotifier<bool> showScanRange = ValueNotifier(true);

  /// Whether 縣市 borders are redrawn above the raster.
  final ValueNotifier<bool> showCountyOutline = ValueNotifier(true);

  /// Whether 鄉鎮 borders are redrawn above the raster. Separate from the
  /// county toggle: they are different questions ("which city" vs "which
  /// township"), and the finer mesh is the first thing a reader wants gone when
  /// studying a single cell.
  final ValueNotifier<bool> showTownOutline = ValueNotifier(true);

  MapLibreMapController? _controller;
  bool _rangeShown = false;
  final Set<AdminBoundary> _boundariesShown = {};

  /// Source id this layer's scan-range outline is drawn under — distinct per
  /// layer, so two rasters sharing the composite geometry never clash.
  String get scanRangeSourceId;

  /// Line-layer id for this layer's scan-range outline.
  String get scanRangeLayerId;

  /// Blue-grey: distinct from every dBZ/mm/h colour in the scales, so the
  /// outline is never mistaken for precipitation.
  String get scanRangeColor;

  /// All chrome listenables, for a legend that follows the toggles.
  Listenable get chromeListenable =>
      Listenable.merge([showScanRange, showCountyOutline, showTownOutline]);

  /// Which boundary sets should currently be on the map.
  Set<AdminBoundary> get _wantedBoundaries => {
    // Town first so a later insert of county lands above it: the coarse frame
    // should win where the two run together along a coastline.
    if (showTownOutline.value) AdminBoundary.town,
    if (showCountyOutline.value) AdminBoundary.county,
  };

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

  @override
  Future<void> onAttached(MapLibreMapController controller) async {
    super.onAttached(controller);
    _controller = controller;
    await _syncRange();
    // Borders last, so they end up above the scan range as well as the raster —
    // the range is a dashed hint, the borders are the reference frame.
    await _syncBoundaries();
  }

  @override
  Future<void> onDetached(MapLibreMapController controller) async {
    super.onDetached(controller);
    _controller = null;
    // Only undo what was actually added — tearing down an overlay that was
    // never mounted issues removals the map never asked for.
    for (final boundary in _boundariesShown.toList()) {
      _boundariesShown.remove(boundary);
      await AdminOutline.remove(controller, boundary);
    }
    if (_rangeShown) {
      _rangeShown = false;
      await RadarScanRange.remove(
        controller,
        sourceId: scanRangeSourceId,
        layerId: scanRangeLayerId,
      );
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
          outlineColor: scanRangeColor,
          belowLayerId: outlineLayerId,
          sourceId: scanRangeSourceId,
          layerId: scanRangeLayerId,
        );
      } else {
        await RadarScanRange.remove(
          controller,
          sourceId: scanRangeSourceId,
          layerId: scanRangeLayerId,
        );
      }
    } catch (error, stackTrace) {
      // A style reload can race the toggle; the next sync recovers.
      _rangeShown = !wanted;
      Log.handle(error, stackTrace, 'Failed to sync the scan range');
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
      Log.handle(error, stackTrace, 'Failed to sync the admin outlines');
    }
  }

  /// The chrome's legend entries, following the toggles — a legend naming a
  /// line that is not on the map is worse than no legend.
  List<SymbolLegendItem> chromeLegendItems(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return [
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
            color: colorFromHexRgb(AdminOutline.lineColor)!,
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
            color: colorFromHexRgb(AdminOutline.lineColor)!,
            width: AdminBoundary.town.lineWidth,
            opacity: AdminBoundary.town.lineOpacity,
            casingColor: const Color(0xFF000000),
            casingWidth: AdminBoundary.town.casingWidth,
            casingOpacity: AdminBoundary.town.casingOpacity,
          ),
          label: l10n.radarTownOutline,
        ),
    ];
  }

  /// A legend card that follows the chrome toggles: the swatches are inserted
  /// under the caller's scale block, joined by a divider.
  Widget chromeLegendSection(BuildContext context) {
    final overlays = chromeLegendItems(context);
    if (overlays.isEmpty) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
    );
  }
}
