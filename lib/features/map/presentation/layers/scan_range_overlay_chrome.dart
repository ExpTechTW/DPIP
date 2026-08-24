/// Switchable reference chrome for a weather raster: the scan-range outline
/// plus the county and township borders, all redrawn **over** the raster.
library;

import 'dart:async';

import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/a11y/color_vision.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/features/map/presentation/layers/admin_outline_chrome.dart';
import 'package:dpip/features/map/presentation/layers/radar_scan_range.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
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
/// The county / township half of that chrome is [AdminOutlineChrome], which
/// the wind forecast layer shares; this adds the coverage outline on top of it.
/// The geometry defaults to the radar composite's ([RadarScanRange]) and is
/// overridable, because coverage is a fact about the source and not about this
/// chrome: the QPESUMS forecast is published over a plain rectangle, so drawing
/// it with the composite's range circles both claimed coverage it does not have
/// on the corners and denied coverage it does have along the arcs. The ids are
/// per-layer too, so a map showing radar and QPESUMS at once draws two outlines
/// instead of clashing over one.
mixin ScanRangeOverlayChrome on AdminOutlineChrome {
  /// Whether the observed area is outlined. On by default — see the class doc.
  bool get showScanRange => referenceOutline.showScanRange;

  bool _rangeShown = false;

  /// Source id this layer's scan-range outline is drawn under — distinct per
  /// layer, so two rasters sharing the composite geometry never clash.
  String get scanRangeSourceId;

  /// Line-layer id for this layer's scan-range outline.
  String get scanRangeLayerId;

  /// Blue-grey: distinct from every dBZ/mm/h colour in the scales, so the
  /// outline is never mistaken for precipitation.
  String get scanRangeColor;

  /// The shape this layer outlines as its observed area.
  ///
  /// Defaults to the radar composite's union of range circles; a source whose
  /// data covers something else overrides it.
  Map<String, dynamic> get scanRangeGeoJson => RadarScanRange.geoJson();

  /// All chrome listenables, for a legend that follows the toggles — scan
  /// range and the admin outlines are all one shared controller now, so this
  /// is just it.
  Listenable get chromeListenable => adminChromeListenable;

  /// Turns the coverage outline on/off, applying it to every attached layer
  /// sharing [referenceOutline] immediately.
  void setShowScanRange(bool value) => referenceOutline.setShowScanRange(value);

  @override
  Future<void> onAttached(MapLibreMapController controller) async {
    super.onAttached(controller);
    referenceOutline.addListener(_onReferenceOutlineChanged);
    await _syncRange();
  }

  @override
  Future<void> onDetached(MapLibreMapController controller) async {
    super.onDetached(controller);
    referenceOutline.removeListener(_onReferenceOutlineChanged);
    if (_rangeShown) {
      _rangeShown = false;
      await RadarScanRange.remove(
        controller,
        sourceId: scanRangeSourceId,
        layerId: scanRangeLayerId,
      );
    }
  }

  void _onReferenceOutlineChanged() {
    unawaited(_syncRange());
  }

  @override
  void onStyleReset() {
    // The style reload dropped every runtime layer, these included; forget them
    // so the next attach re-adds instead of no-oping on stale state.
    _rangeShown = false;
    super.onStyleReset();
  }

  /// Adds or removes the coverage outline to match [showScanRange].
  Future<void> _syncRange() async {
    final controller = this.controller;
    if (controller == null) return;

    final wanted = showScanRange;
    if (wanted == _rangeShown) return;
    _rangeShown = wanted;

    try {
      if (wanted) {
        await RadarScanRange.add(
          controller,
          outlineColor: scanRangeColor,
          // The layer's chrome anchor, not the base style's county outline:
          // that one sits *below* the raster, so the circle was being drawn
          // under the echo it exists to bound.
          belowLayerId: chromeBelowLayerId,
          sourceId: scanRangeSourceId,
          layerId: scanRangeLayerId,
          data: scanRangeGeoJson,
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

  /// The chrome's legend entries, following the toggles — a legend naming a
  /// line that is not on the map is worse than no legend.
  List<SymbolLegendItem> chromeLegendItems(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return [
      if (showScanRange)
        SymbolLegendItem(
          // The same blue-grey the outline is drawn in, and corrected the same
          // way: the ring is a vector line this app draws, not raster pixels.
          swatch: LineSwatch(
            color: const Color(0xFF78909C).vision,
            width: 1.5,
            opacity: 0.7,
            dash: const [3, 2],
          ),
          label: l10n.radarScanRange,
        ),
      ...adminLegendItems(context),
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
          color: Theme.of(context).colorScheme.outlineVariant
              .withValues(alpha: 0.5),
        ),
        const SizedBox(height: AppSpacing.sm),
        SymbolLegend(items: overlays),
      ],
    );
  }
}
