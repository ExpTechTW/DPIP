/// Switchable administrative borders (縣市 / 鄉鎮) for a weather raster that
/// covers the base style's borders, redrawn **over** the raster.
library;

import 'dart:async';

import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/color_hex.dart';
import 'package:dpip/shared/map/admin_outline.dart';
import 'package:dpip/shared/map/raster_timeline_layer.dart';
import 'package:dpip/shared/widgets/map_color_legend.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// The reference admin frame a weather raster can sit over.
///
/// A full-saturation raster (radar echo, QPESUMS forecast, wind forecast)
/// covers the base style's borders exactly where the weather is worth looking
/// at, so the layer draws its own county and township borders **on top** of the
/// raster, each switchable. The two questions are independent — "which county"
/// and "which township" — so they are two toggles, and both ship **on**, because
/// an unidentified county is one you cannot act on.
///
/// The geometry is [AdminOutline]'s shared casing construction for every
/// consumer; only the ids come from the base style's own source, so a map
/// showing two rasters at once draws two independent border sets.
mixin AdminOutlineChrome on RasterTimelineLayer {
  /// Whether 國界 (world country borders) are redrawn above the raster.
  ///
  /// On by default: the neighbours' outlines are the frame a reader navigates
  /// by on a basin-wide view, and 鄉鎮/縣市 lines alone read as floating once
  /// the island fills the screen. A reader who wants the clean raster can turn
  /// it off.
  final ValueNotifier<bool> showGlobalOutline = ValueNotifier(true);

  /// Whether 縣市 borders are redrawn above the raster.
  final ValueNotifier<bool> showCountyOutline = ValueNotifier(true);

  /// Whether 鄉鎮 borders are redrawn above the raster. Separate from the
  /// county toggle: they are different questions ("which city" vs "which
  /// township"), and the finer mesh is the first thing a reader wants gone when
  /// studying a single cell.
  final ValueNotifier<bool> showTownOutline = ValueNotifier(true);

  /// The live map controller, set on attach and cleared on detach. Shared with
  /// chrome mixins layered above this one, so it is protected rather than
  /// library-private.
  @protected
  MapLibreMapController? controller;
  final Set<AdminBoundary> _boundariesShown = {};

  /// All admin-chrome listenables, for a legend that follows the toggles.
  Listenable get adminChromeListenable =>
      Listenable.merge([showGlobalOutline, showCountyOutline, showTownOutline]);

  /// Which boundary sets should currently be on the map.
  Set<AdminBoundary> get _wantedBoundaries => {
    // Inserted finest → coarsest so the later, coarser frame wins where two
    // run together along a coastline.
    if (showTownOutline.value) AdminBoundary.town,
    if (showCountyOutline.value) AdminBoundary.county,
    if (showGlobalOutline.value) AdminBoundary.global,
  };

  /// The id of the **topmost** admin line actually on the map, or null when
  /// none is.
  ///
  /// [_syncBoundaries] adds sets in [AdminBoundary.values] order (global →
  /// county → town) and each pair casing-first, so the last *shown* set's line
  /// is the topmost admin stroke. A consuming raster mounts *below* it — which,
  /// because every admin pair stacks above it in that same order, puts the
  /// frame under **all** admin strokes (casings included) at once.
  ///
  /// Anchoring on the *bottommost* set instead would be wrong once 國界 is on:
  /// the global frame sits lowest, so a raster hung under its casing would
  /// still cover the county and town lines above it — exactly what the
  /// timeline scrub used to do to the borders.
  ///
  /// Gated on [_boundariesShown] (not the toggles): after a style reload the
  /// native layers are gone while the toggles still read on, so anchoring on a
  /// toggle would point a mount at a layer that does not exist and the frame
  /// would fail to render. With nothing actually drawn, null (top of the
  /// style) is the honest answer — the reload path re-adds the borders right
  /// after the first frame, above it.
  String? get adminBaseLayerId {
    if (_boundariesShown.isEmpty) return null;
    for (final boundary in AdminBoundary.values.reversed) {
      if (_boundariesShown.contains(boundary)) return boundary.lineLayerId;
    }
    return null;
  }

  /// Turns the 國界 borders on/off, applying it to a live map immediately.
  void setShowGlobalOutline(bool value) {
    if (showGlobalOutline.value == value) return;
    showGlobalOutline.value = value;
    unawaited(_syncBoundaries());
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
    this.controller = controller;
    await _syncBoundaries();
  }

  @override
  Future<void> onDetached(MapLibreMapController controller) async {
    super.onDetached(controller);
    this.controller = null;
    // Only undo what was actually added — tearing down an overlay that was
    // never mounted issues removals the map never asked for.
    for (final boundary in _boundariesShown.toList()) {
      _boundariesShown.remove(boundary);
      await AdminOutline.remove(controller, boundary);
    }
  }

  @override
  void onStyleReset() {
    // The style reload dropped every runtime layer, these included; forget them
    // so the next attach re-adds instead of no-oping on stale state.
    _boundariesShown.clear();
    super.onStyleReset();
  }

  /// Brings the drawn boundary sets in line with the toggles.
  Future<void> _syncBoundaries() async {
    final controller = this.controller;
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

  /// The admin chrome's legend entries, following the toggles — a legend naming
  /// a line that is not on the map is worse than no legend.
  List<SymbolLegendItem> adminLegendItems(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return [
      if (showGlobalOutline.value)
        SymbolLegendItem(
          swatch: LineSwatch(
            color: colorFromHexRgb(AdminOutline.lineColor)!,
            width: AdminBoundary.global.lineWidth,
            opacity: AdminBoundary.global.lineOpacity,
            casingColor: const Color(0xFF000000),
            casingWidth: AdminBoundary.global.casingWidth,
            casingOpacity: AdminBoundary.global.casingOpacity,
          ),
          label: l10n.radarGlobalOutline,
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

  /// A legend card that follows the admin toggles: the swatches are inserted
  /// under the caller's scale block, joined by a divider.
  Widget adminLegendSection(BuildContext context) {
    final overlays = adminLegendItems(context);
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
