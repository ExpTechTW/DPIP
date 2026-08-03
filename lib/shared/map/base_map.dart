import 'dart:math' show Point;

import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/shared/map/map_style.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// Layer-chip band under the safe-area top: outer pad ([AppSpacing.lg]) + chip
/// height (~36) + a tight gap. iOS MapLibre already anchors ornaments to the
/// safe top, so this is the full Y margin there; Android still needs safe-area
/// padding added on top (see [BaseMap.build]).
const double _layerChipBand = AppSpacing.lg + 36 + AppSpacing.xs;

/// The app's reusable base map — a MapLibre map centred on Taiwan, rendered from
/// the ExpTech vector style tinted by [MapColors] for the active brightness.
///
/// This is the shared foundation every map surface builds on (home backdrop,
/// map tab, radar preview, event viewers). It is layer-agnostic: callers add
/// their own sources/layers in [onMapCreated] via the [MapLibreMapController],
/// typically anchoring overlays below [outlineLayerId] so the borders stay on
/// top.
///
/// [interactive] toggles pan/zoom/rotate and the compass at once — pass
/// `false` for a display-only surface like the home backdrop, where the map is
/// driven entirely from code and the page's own gestures (tap to open, swipe
/// to switch) must pass straight through. Tilt is always off.
class BaseMap extends StatelessWidget {
  const BaseMap({
    super.key,
    this.onMapCreated,
    this.onStyleLoaded,
    this.onMapClick,
    this.onCameraIdle,
    this.interactive = true,
    this.minZoomPreference = defaultMinZoom,
  });

  /// Bounding box for the nationwide (全國) framing — the Taiwan main island
  /// **plus Kinmen**, fit to the viewport (never a hardcoded zoom). Penghu falls
  /// inside the span already; Matsu does not (it sits at ~26.15°N, north of the
  /// box) — add it here if it should be framed too.
  ///
  /// The corners are the real extremes, with a little margin: Fugui Cape
  /// 25.30°N, Eluanbi 21.90°N, Sandiao Cape 122.01°E, and Lieyu (Little Kinmen)
  /// ~118.20°E.
  ///
  /// An earlier box read `(22.2, 119) → (25.35, 121.05)`: it reached ~110 km into
  /// the strait on the west yet stopped at 121.05°E — *inside* the island — so
  /// the whole east coast (Yilan / Hualien / Taitung) fell outside the box and the
  /// fit centred on 120.02°E, pushing Taiwan against the right edge with open sea
  /// filling the left.
  ///
  /// A getter, not a `static final`: a lazily-initialised static keeps its first
  /// value across hot reload, so editing these numbers would appear to do nothing.
  static LatLngBounds get taiwanBounds => LatLngBounds(
    southwest: const LatLng(21.87, 118.15),
    northeast: const LatLng(25.32, 122.05),
  );

  /// Centre of [taiwanBounds] — only the pre-layout camera target, before a
  /// fit-to-bounds frames the island properly. Derived, so it can't drift from
  /// the bounds.
  static LatLng get taiwanCenter => LatLng(
    (taiwanBounds.southwest.latitude + taiwanBounds.northeast.latitude) / 2,
    (taiwanBounds.southwest.longitude + taiwanBounds.northeast.longitude) / 2,
  );

  /// Default floor for most map surfaces (radar tiles need it).
  static const double defaultMinZoom = 4;

  /// Alias for call sites / framing that still reference [BaseMap.minZoom].
  static const double minZoom = defaultMinZoom;

  static const double maxZoom = 11;

  /// Called with the controller once the map is ready — add overlay layers here.
  final void Function(MapLibreMapController controller)? onMapCreated;

  /// Called once the style has finished loading (safe to add layers after this).
  final VoidCallback? onStyleLoaded;

  /// Called on a map tap with the tapped point + coordinate — for tap-driven
  /// layers (e.g. selecting the nearest weather station).
  final OnMapClickCallback? onMapClick;

  /// Fires when the camera stops moving — for screen-space Flutter overlays
  /// that need a fresh `toScreenLocation` projection.
  final OnCameraIdleCallback? onCameraIdle;

  /// Whether the user can pan/zoom/rotate the map. `false` makes it display-only
  /// (all gestures + the compass off) so the surrounding page owns every gesture.
  final bool interactive;

  /// Per-surface zoom floor (typhoon may go lower so the whole basin fits).
  /// Other layers keep [defaultMinZoom].
  final double minZoomPreference;

  @override
  Widget build(BuildContext context) {
    final palette = MapColors.of(Theme.of(context).brightness);
    // MapScaffold parks the layer switcher at top-right (SafeArea + lg). Drop
    // the native compass just under that chip. iOS ornaments are already
    // constrained to the safe-area top — adding MediaQuery.padding again left
    // a huge gap under the chip. Android margins are from the view edge.
    final safeTop = Theme.of(context).platform == TargetPlatform.iOS
        ? 0.0
        : MediaQuery.paddingOf(context).top;
    final compassTop = safeTop + _layerChipBand;
    final floor = minZoomPreference;
    return MapLibreMap(
      // Pre-layout placeholder only; each surface fits [taiwanBounds] (or its
      // own selection) once the map is laid out, so no hardcoded framing zoom.
      initialCameraPosition: CameraPosition(
        target: taiwanCenter,
        zoom: floor,
      ),
      // Brightness flip changes this string → MapLibre reloads style; layers
      // re-attach via [onStyleLoaded] (see [MapScaffold]).
      styleString: exptechVectorStyle(palette),
      minMaxZoomPreference: MinMaxZoomPreference(floor, maxZoom),
      trackCameraPosition: true,
      compassEnabled: interactive,
      compassViewPosition: CompassViewPosition.topRight,
      compassViewMargins: Point(AppSpacing.lg, compassTop),
      scrollGesturesEnabled: interactive,
      zoomGesturesEnabled: interactive,
      rotateGesturesEnabled: interactive,
      tiltGesturesEnabled: false,
      dragEnabled: interactive,
      onMapClick: onMapClick,
      onMapCreated: onMapCreated,
      onStyleLoadedCallback: onStyleLoaded,
      onCameraIdle: onCameraIdle,
    );
  }
}
